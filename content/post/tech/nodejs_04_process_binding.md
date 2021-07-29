---
title: "[NodeJS源码探秘]之process.binding()"
date: 2018-03-22T17:22:42+08:00
lastmod: 2018-03-22T17:22:42+08:00
draft: false
keywords: ["NodeJs", "源码探秘", "process.binding"]
description: "NodeJS是时下非常流行的服务器语言, 这个系列将着重研究NodeJS的源码，以期为之做出贡献。 这篇文章是要写给初读NodeJS源码的朋友们。process.binding()大概是初读源码时我们最常碰见的函数。现在我们就聊聊它干了什么和它具体的代码。"
tags: ["NodeJS", "JavaScript", "NodeJS源码探秘", "cpp"]
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

*NodeJS是时下非常流行的服务器语言, 这个系列将着重研究NodeJS的源码，以期为之做出贡献。*

这篇文章写给初读NodeJS源码的朋友们。process.binding()大概是初读源码时我们最常碰见的函数。现在我们就聊聊它干了什么和它具体的代码。

我们都知道NodeJS的底层是用C++写的。所以一个NodeJS程序从宏观上看有两个世界：JavaScript 以及 C++。在JS中，我们出于追求性能或者结构限制，需要使用C++的代码。在这种情况下，process.binding()就起到了连接C++函数到JS的功能。简单点将，我们可以将它比作require函数。

当然process.binding()不是process模块公开API的一部分。它只在我们bootstrap NodeJS的内部C++函数时使用。

接下来，让我们会看一下其源码。
<!--more-->

首先，让我们在[lib/internal/bootstrap/loader.js](https://github.com/nodejs/node/blob/master/lib/internal/bootstrap/loaders.js#L58)中看一下process.binding()在JS世界的定义:
```JavaScript
(function bootstrapInternalLoaders(process, getBinding, getLinkedBinding,
                                   getInternalBinding) {
  // Set up process.moduleLoadList
  const moduleLoadList = [];
  Object.defineProperty(process, 'moduleLoadList', {
    value: moduleLoadList,
    configurable: true,
    enumerable: true,
    writable: false
  });

  // process.binding()的逻辑很简单
  // 先检查传入的模块名称module
  // 然后再看缓存bindingObj中是否有对应的代码
  // 如果有，那么返回缓存中的代码
  // 否则，调用getBinding函数来获取模块代码
  {
    const bindingObj = Object.create(null);

    process.binding = function binding(module) {
      module = String(module);
      let mod = bindingObj[module];
      if (typeof mod !== 'object') {
        mod = bindingObj[module] = getBinding(module);
        moduleLoadList.push(`Binding ${module}`);
      }
      return mod;
    };
  }
  
  // ....
}
```
这个loader.js是在NodeJS启动过程中非常重要的一步，它进一步在process对象上添加辅助函数，比如binding。让我们看看getBinding函数是怎么样的。让我们移步至文件[src/node.cc](https://github.com/nodejs/node/blob/master/src/node.cc#L3356)，这里有一个LoadEnvironment函数值得我们注意：
```cpp
void LoadEnvironment(Environment* env) {
  // ...省略
  
  // 这就是我们的loader.js
  Local<String> loaders_name =
      FIXED_ONE_BYTE_STRING(env->isolate(), "internal/bootstrap/loaders.js");
  Local<Function> loaders_bootstrapper =
      GetBootstrapper(env, LoadersBootstrapperSource(env), loaders_name);
      
  // 以下三个以_fn结尾的函数对应着我们loader.js的三个加载函数
  // 如果你不了解V8，其实没关系，下面这行代码的意思就是说
  // 将C++中的一个原生函数GetBinding转换成能给V8中的JS代码使用的函数
  v8::Local<v8::Function> get_binding_fn =
      env->NewFunctionTemplate(GetBinding)->GetFunction(env->context())
          .ToLocalChecked();

  v8::Local<v8::Function> get_linked_binding_fn =
      env->NewFunctionTemplate(GetLinkedBinding)->GetFunction(env->context())
          .ToLocalChecked();

  v8::Local<v8::Function> get_internal_binding_fn =
      env->NewFunctionTemplate(GetInternalBinding)->GetFunction(env->context())
          .ToLocalChecked();

  Local<Value> loaders_bootstrapper_args[] = {
    env->process_object(),
    get_binding_fn, // 这就是loader.js中的getBinding
    get_linked_binding_fn,
    get_internal_binding_fn
  };

  // Bootstrap internal loaders
  Local<Value> bootstrapped_loaders;
  if (!ExecuteBootstrapper(env, loaders_bootstrapper,
                           arraysize(loaders_bootstrapper_args),
                           loaders_bootstrapper_args,
                           &bootstrapped_loaders)) {
    return;
  }
```
按理说，我们应该继续追看GetBinding函数的源码，但我个人认为已经可以了。毕竟剩余的代码部分大概就属于['80/20'](https://www.entrepreneur.com/article/229813)中的20吧。
