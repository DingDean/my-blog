---
title: "谷歌V8引擎探秘：基础概念"
date: 2018-01-27T17:18:37+08:00
lastmod: 2018-01-31T15:02:37+08:00
draft: false
keywords: ["V8", "C++", "编程"]
description: "在深入研究NodeJS时，不可避免要触及谷歌的V8引擎，同时也有必要去深入了解它。此系列文章就是我自己探索学习V8引擎的笔记。"
tags: ["V8", "NodeJS", "C++"]
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

*V8引擎是驱动NodeJS的核心。为此有必要深入了解其API和运行机制。此系列文章旨在记录我自己探索学习V8引擎的记录。*

本文章是此系列的第一篇，将梳理一遍V8引擎的几个总要概念：

1. Context
2. Handle
3. Handle Scope
4. Templates
5. Isolates

<!--more-->

## Isolates 和 Context

Isolate是一个完整的V8实例，有着完整的堆栈和Heap。

Context顾名思义，是一个上下文。所有的JS代码都是在某个V8 Context中运行的。

在Stack Overflow有个回答解释了[Isolate与Context的差别](https://stackoverflow.com/questions/19383724/what-exactly-is-the-difference-between-v8isolate-and-v8context/19384199)，在此直接翻译：

> An isolate is an independent copy of the V8 runtime, including a heap manager, a garbage collector, etc. Only one thread may access a given isolate at a time, but different threads may access different isolates simultaneously.
>
> 一个Isolate是一份独立的V8 runtime, 包括但不限于一个heap管理器，垃圾回收器等。在一个时间段内，有且只有一个线程能使用此isolate。不过，多个线程可以同时使用多个isolate。    
>
> An isolate is not sufficient for running scripts, however. You also need a global (root) object. A context defines a complete script execution environment by designating an object in an isolate's heap as a global object.
> 
> 单独的Isolate是不足以运行脚本的，我们在此需要一个全局对象。Context就是提供此全局变量的工具。它在其所处的Isolate管理的heap中建立一个对象，并以此为全局变量构建出一个完成的执行环境供我们的脚本使用。     
>
> Therefore, not only can many contexts "exist" in a given isolate, but they can also share any or all of their objects easily and safely. That's because their objects actually belong to the isolate and are protected by the isolate's exclusive lock.
>
> 因此，对于一个给定的Isolate, 不仅其可以有多个Context，并且这些Context之间可以共享某些对象。

V8的官方文档告诉我们，我们可以随时在代码中步入任意一个Context:

``` cpp
// create contextA和contextB, 并且步入ContextA
Local<Context> contextA = Context::New(isolate);
Local<Context> contextB = Context::New(isolate);
Context::Scope enter_scope(contextA);
// ...

Context::Scope enter_scope(contextB);
// ... 在contextB中执行操作
Context:~Scope contextB; // 步出contextB, 回到contextA
// ... 在contextA中执行操作
```

## Handle 和 Handle Scope
Handle，简单的说，是对一个特定JS对象的索引。它指向此JS对象在V8所管理的Heap中的位置。需要注意的是，Handle不存于Heap中，而是存在于stack中。只有一个Handle被释放后，此Handle才会从stack中推出。这就带来一个问题，在执行特定操作时，我们可能需要声明很多Handle。如果要一个个手动释放，未免太麻烦。为此，我们使用Handle Scope来集中释放这些Handle。

Handle Scope，形象的说是一个可以包含很多Handle的工作区。当这个工作区Handle Scope被移出堆栈时，其所包含的所有Handle都会被移出堆栈，并且被垃圾管理器标注，从而在后续的垃圾回收过程快速的定位到这些可能需要被销毁的Handle。

Handle有几种类型:

* Local Handle
* Persistent Handle
* UniquePersistent Handle
* Eternal Handle

## Templates
Templates用于在C++中自定义一个JS函数。它有两种类型：

1. Function Template: 用于生成JS函数的C++对象。
2. Object Template: 每一个Function Template都有一个对应的Object Template。当一个Function Template对应的JS函数被当作构造器创建对象时，V8会实际使用Object Template来实例化此对象。

我们可以用一个具体的例子来理解Template。在V8源码的[Samples](https://github.com/v8/v8/tree/master/samples)中，我们可以找到```process.cc```以及```count-host.js```文件。因为```count-host.js```非常简短，那么直接摘抄如下:

``` js
function Initialize() { }

function Process(request) {
  if (options.verbose) {
    log("Processing " + request.host + request.path +
        " from " + request.referrer + "@" + request.userAgent);
  }
  if (!output[request.host]) {
    output[request.host] = 1;
  } else {
    output[request.host]++
  }
}

Initialize();
```
 在这里，我们需要使用到options, log, output这几个全局函数。
 它们都是V8事先用Template在C++中生成对应的C++对象或者函数,
 然后再注入到此JS作用域的全局对象中。
 同时，我们定义的这个Process函数同样可以在C++中被获取和使用。
 我们可以在[process.cc](https://github.com/v8/v8/blob/master/samples/process.cc)脚本中看到V8是如何做到这两点的。
 
 
### Function Template
 
 首先，我们看一下Function Template的用法。它使得我们可以在JS中调用在C++里定义的函数。以log函数为例:
 
``` cpp
HandleScope handle_scope(GetIsolate());    

// Create a template for the global object where we set the
// built-in global functions.
Local<ObjectTemplate> global = ObjectTemplate::New(GetIsolate());

// 这是最重要的一行。LogCallback是一个原生的C++函数。
// 通过使用FunctionTemplate，V8可以将其绑定到JS环境下的log函数。
global->Set(String::NewFromUtf8(GetIsolate(), "log", 
          NewStringType::kNormal).ToLocalChecked(),
          FunctionTemplate::New(GetIsolate(), LogCallback)); 
```

### Object Template
现在，我们来看一下ObjectTemplate的使用方法。ObjectTemplate是一个JS对象在C++中的模版。这个ObjectTemplate会有属性值，这些属性值可以是静态变量，也可以是动态变量。在V8中，这两种区别会使用不同的方法来设置一个ObjectTemplate的属性值。

我们依旧像上段代码一样，想要给JS上下文提供一个```global```作为全局对象。```global```本身是一个ObjectTemplate的实例。

#### 静态变量

假设我们想要暴露一个静态变量x做为```global```的一个属性值。我们可以使用SetAccessor方法来实现这一点。SetAccessor是给一个ObjectTemplate设置属性的一种方法，其细节在此不表，但它给JS提供了访问C++对象属性的能力。

SetAccessor需要两个函数回调，一个Getter, 一个Setter。这非常好理解，其作用就是读取和修改对象属性值。

具体实例可以在[Embedder's Guide](https://github.com/v8/v8/wiki/Embedder%27s-Guide#accessing-static-global-variables)看到：

``` cpp
HandleScope handle_scope(GetIsolate());    
Local<ObjectTemplate> global_templ = ObjectTemplate::New(isolate);
global_templ->SetAccessor(String::NewFromUtf8(isolate, "x"), XGetter, XSetter); // x的值由XGetter提供，而XSetter则可以将JS中对x值的修改反映到C++中。
Persistent<Context> context = Context::New(isolate, NULL, global_templ);
```

可以看到，当设置静态变量为属性值时，流程是比较简单的。相对而言，设置动态变量则要麻烦一下。
#### 动态变量

在设置动态变量时，我们需要一个媒介来让JS获取到我们的动态变量。这个媒介被称为```External Value```， 其是对一个动态变量的简单封装。我们可以在下面代码中看到其在[process.cc](https://github.com/v8/v8/blob/master/samples/process.cc)的应用：

``` cpp
// 我们可以看到，opts和output都是动态变量
bool JsHttpRequestProcessor::InstallMaps(map<string, string>* opts,
                                         map<string, string>* output) {
  HandleScope handle_scope(GetIsolate());

  // 因为opts是动态变量，我们需要将其封装起来。
  // 在源文件中，封装函数名为WrapMap。为了方便讲解，我直接提取其流程于下方。
  // 这是源码中的代码: Local<Object> opts_obj = WrapMap(opts)
  
  // 下面是提取WrapMap后的代码
  Local<ObjectTemplate> templ = ObjectTemplate::New(isolate);
  // 下面这一行非常关键
  // 它相当于提供了一个指针，至于指向什么，请继续向下看
  templ->SetInternalFieldCount(1); 
  templ->SetHandler(NamedPropertyHandlerConfiguration(MapGet, MapSet)); // 这一样类似SetAccessor

  // Create an empty map wrapper.
  Local<Object> result = templ->NewInstance(GetIsolate()->GetCurrentContext()).ToLocalChecked();

  // 在这里，我们的opts被封装进了map_ptr这个External Value中
  Local<External> map_ptr = External::New(GetIsolate(), opts);

  // 就这样，Internal Field的第一个位置指向了我们的动态变量opts所在的External Value
  result->SetInternalField(0, map_ptr);  
}
```

