---
title: "NodeJS源码探秘之require()"
date: 2017-11-17T14:16:22+08:00
lastmod: 2017-11-25T14:16:22+08:00
draft: false
keywords: ["NodeJS", "源码探秘", "require"]
description: "NodeJS是时下非常流行的服务器语言, 这个系列将着重研究NodeJS的源码，以期为之做出贡献。第一篇文章就是要搞清楚我们经常使用的require()函数到底是如何运作的。"
tags: ["NodeJS", "JavaScript", "NodeJS源码探秘"]
categories: ["技术"]
author: "丁科"
# you can close something for this content if you open it in config.toml.
# comment: false
# toc: false
# you can define another contentCopyright. e.g. contentCopyright: "This is an another copyright."
# contentCopyright: false
# reward: false
# mathjax: false
---

__*部分源码已过时 -> 升级至9.11*__ 

*NodeJS是时下非常流行的服务器语言, 这个系列将着重研究NodeJS的源码，以期为之做出贡献。*

第一篇文章就是要搞清楚我们经常使用的require()函数到底是如何运作的。

<!--more-->

## 概述

require大概是我在NodeJS最经常使用的函数了。在使用它的过程中，我对它到底是如何运作的感到非常好奇：

* require函数看起来像是一个全局变量，那么它的确是吗？
* 为什么通过require函数所调用的JS文件不会污染当前文件？
* NodeJS的模块(Module)系统和require的关系又是如何？

简单的说，require函数是一个闭包的返回值，此闭包封装了此require函数所在的模块(Module)实例。进一步说，我们所使用的require函数是对Module.require的简单封装。后文会对Module模块做出更详细的解释。

require同时还拥有以下属性：resolve, main, extension以及cache。后文会介绍这几个属性的作用。

请允许我直接给出[源码](https://github.com/nodejs/node/blob/604578f47ea360980110e2cd7d4a636f9942b1f0/lib/internal/module.js#L5)中对require的定义：
``` JavaScript
function makeRequireFunction(mod) {
  const Module = mod.constructor;

  function require(path) {
    try {
      exports.requireDepth += 1;
      return mod.require(path);
    } finally {
      exports.requireDepth -= 1;
    }
  }

  function resolve(request) {
    return Module._resolveFilename(request, mod);
  }

  require.resolve = resolve;

  require.main = process.mainModule;

  // Enable support to add extra extension types.
  require.extensions = Module._extensions;

  require.cache = Module._cache;

  return require;
}

```
可以看到，require是闭包makeRequireFunction的返回值。那问题在于，此闭包它什么时候被执行呢？返回的require又是怎么提供给我们的JS代码的呢？

假设我们有一个非常简单的a.js如下:
``` JavaScript
# a.js
const B = require('b.js');
```
然后我们用node运行此文件：
``` bash
node a.js
```

此时，node会做以下几个事情：

1. 生成一个Module实例，此实例可以看成是a.js这个文件的抽象。
2. 读取a.js的文件内容
3. 将a.js封装在一个匿名函数中
4. 执行此匿名函数

我们的require函数就是在步骤2和步骤3之间被生成的, 同时在步骤4时传入3中的匿名函数。可以在源码[lib/module.js](https://github.com/nodejs/node/blob/604578f47ea360980110e2cd7d4a636f9942b1f0/lib/module.js#L652)中看到这些步骤的部分细节：
``` JavaScript
// 这里的content就是a.js中的代码
Module.prototype._compile = function(content, filename) {

  content = internalModule.stripShebang(content);

  // Module.wrap将content封装在下面这个匿名函数里
  // (function (exports, require, module, __filename, __dirname) { 
  //    ...a.js的代码会被注入到这里
  // })
  var wrapper = Module.wrap(content);

  var compiledWrapper = vm.runInThisContext(wrapper, {
    filename: filename,
    lineOffset: 0,
    displayErrors: true
  });
  
  // ....
  var dirname = path.dirname(filename); // 这是我们常用的__dirname变量
  var require = internalModule.makeRequireFunction(this); // 这是require
  var depth = internalModule.requireDepth;
  if (depth === 0) stat.cache = new Map();
  var result;
  if (//...)
    // ...
  } else {
    // 这里执行了我们上面得到的闭包
    result = compiledWrapper.call(this.exports, this.exports, require, this,
                                  filename, dirname);
  }
  if (depth === 0) stat.cache = null;
  return result;
}
```
通过上述代码，我们可以看到，require函数其实是我们的JS代码执行时所在的函数作用域的一个参数，所以我们才可以直接使用require。

那么require到底会做什么事情呢？

在此之前，我们要来熟悉一下[lib/module.js](https://github.com/nodejs/node/blob/master/lib/module.js)中定义的类，Module。

## Module类

[lib/module.js](https://github.com/nodejs/node/blob/ad80c2120672975018f5d93dad5e5cb9cf900de2/lib/module.js#L586)定义了一个类，Module。我们用node引入的任何JS文件，在最后都是一个Module实例的一部分。Module类定义了许多变量和函数，比较重要的如下:

### Module的静态变量

- Module._cache:   
   对象，其值均为Module实例的缓存
- Module._extension:   
   对象，其值均为函数，用于加载属于特定文件格式的文件，其中就包括加载JS文件的函数

### Module的静态函数

- Module.load():   
   当一个模块要加载另一个模块时，会先通过调用此函数查看是否已经对应模块的缓存
- Module.wrapper():   
   封装我们用户代码的函数

### Module的公有变量

- exports:   
   暴露给其他模块的对象

### Module的公有函数

- Module.prototype.load():   
   输入一个文件名，load函数会根据文件的格式使用对应的Module._extension加载此文件。
- Module.prototype.require():   
   这个就是著名的require()函数的真身了，我们将在之后研究单独的require()是如何与Module.prototype.require联系在一起的。
- Module.prototype._compile():    
   load()函数在加载JS文件的过程中，会调用此函数来封装加载的JS文件，使其有独立的作用域。
 
## require()后都发生了什么？

### 调用Module._load()

当a.js被node加载后，a.js其实就是一个Module的实例了，所以相应的我们可以在代码中调用require。实际上，我们调用的是Module.prototype.require。而Module.prototype.require又是简单得封装了Module._load()

Module._load()函数会做以下三种事情，这里直接贴上源代码中对其的注释:
``` JavaScript
// Check the cache for the requested file.
// 1. If a module already exists in the cache: return its exports object.
// 2. If the module is native: call `NativeModule.require()` with the
//    filename and return the result.
// 3. Otherwise, create a new module for the file and save it to the cache.
//    Then have it load  the file contents before returning its exports
//    object.
Module._load = function(request, parent, isMain) {
}
```
在此我就不讨论前两种情况了，因为重要的还是第三点，即加载一个未缓存的JS文件的流程。


### 调用Module.prototype.load()

因为b.js是第一次被加载，所以Module.prototype._load会先实例化一个Module, 并调用此实例的load()函数。依旧还是贴上代码:
``` JavaScript
Module._load = function(request, parent, isMain) {
  // 1. 有缓存否
  // 2. 是NativeModule否
  // 3. 我们所要研究的重点
  // filename即我们所要加载的文件b.js
  // parent则是请求加载此文件的Module实例，在我们的预设下，parent为a.js所对应的实例
  var module = new Module(filename, parent);

  if (isMain) {
    process.mainModule = module;
    module.id = '.';
  }

  Module._cache[filename] = module;

  // tryModuleLoad其实调用的就是module.load()
  tryModuleLoad(module, filename);

  return module.exports;
}
```
正如代码所示，最终实例后的b.js其实只是一个空壳，因为b.js中的代码还未被编译，这也是tryModuleLoad所要完成的任务。tryModuleLoad只是try & catch了module.load()函数。而module.load()函数最需要关注的则是它调用了Module._extension中加载JS文件的函数
``` JavaScript
Module.prototype.load = function(filename) {
  // ...
  
  var extension = path.extname(filename) || '.js';
  if (!Module._extensions[extension]) extension = '.js';
  Module._extensions[extension](this, filename);
  this.loaded = true;

  // ...
};

Module._extensions['.js'] = function(module, filename) {
  var content = fs.readFileSync(filename, 'utf8');
  module._compile(internalModule.stripBOM(content), filename);
};
```

### 调用Module.prototype._compile()

终于，我们来到了最重要的一步，真正的编译b.js中的代码，这由module._compile实现。
``` JavaScript
Module.prototype._compile = function(content, filename) {

  content = internalModule.stripShebang(content);

  // create wrapper function
  var wrapper = Module.wrap(content);

  var compiledWrapper = vm.runInThisContext(wrapper, {
    filename: filename,
    lineOffset: 0,
    displayErrors: true
  });
  
  // 到这一步，b.js中的代码都被封装进了 '(function (exports, require, module, __filename, __dirname) { })'中
  // ....
  var dirname = path.dirname(filename); // 这是我们常用的__dirname变量
  var require = internalModule.makeRequireFunction(this); // 这是require
  var depth = internalModule.requireDepth;
  if (depth === 0) stat.cache = new Map();
  var result;
  if (//...)
    // ...
  } else {
    // 这里执行了我们上面得到的闭包
    result = compiledWrapper.call(this.exports, this.exports, require, this,
                                  filename, dirname);
  }
  if (depth === 0) stat.cache = null;
  return result;
}
```

## 总结

至此，我们应该明白了require本质上是我们所在的JS文件所引用的变量。但说实话，我们的源码探秘还只是象征性地在源码的边界打了个转。但这是值得的，在这个过程中，我又看到了更多需要探秘的问题，其中就有一个我个人非常好奇的地方，即在_compile的过程中，下面这一段代码底下到底发生了什么:
``` JavaScript
var compiledWrapper = vm.runInThisContext(wrapper, {
  filename: filename,
  lineOffset: 0,
  displayErrors: true
});
```
既然函数的名字牵扯到了compile, context, vm这样的字眼，我们的代码会被编译成什么？vm是什么？compiledWrapper到底是怎么样的？

好了，探秘继续，感谢您看到最后，下回见！

