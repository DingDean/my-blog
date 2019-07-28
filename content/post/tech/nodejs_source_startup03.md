---
title: "[NodeJS源码探秘]之启动全流程"
date: 2018-03-21T16:53:53+08:00
lastmod: 2018-03-22T16:53:53+08:00
draft: false
keywords: ["NodeJS", "源码探秘", "启动流程"]
description: "NodeJS是时下非常流行的服务器语言, 这个系列将着重研究NodeJS的源码，以期为之做出贡献。这篇文章将详细记录和解释NodeJS启动的全流程。"
tags: ["NodeJS", "C++", "V8", "libuv", "NodeJS源码探秘"]
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

这篇文章将研究NodeJS的启动全流程。

<!--more-->

NodeJS的启动全流程涉及到以下几个主要的文件：

1. [src/node_main.cc](https://github.com/nodejs/node/blob/master/src/node_main.cc)
2. [src/node.cc](https://github.com/nodejs/node/blob/master/src/node.cc)
3. [src/env.cc](https://github.com/nodejs/node/blob/master/src/env.cc)
4. [lib/internal/bootstrap/loader.js](https://github.com/nodejs/node/blob/master/lib/internal/bootstrap/loaders.js)
5. [lib/internal/bootstrap/node.js](https://github.com/nodejs/node/blob/master/lib/internal/bootstrap/node.js)

首先，我们看node_main.cc。这个文件源码比较简单，主要是根据操作系统的不同运行了对应的变量设置。最重要的一行代码就是调用node.cc中的__Start()__函数

```cpp
int main(int argc, char *argv[]) {
#if defined(__POSIX__) && defined(NODE_SHARED_MODE)
  // ...
#endif

#if defined(__linux__)
  // ...
#endif
  // Disable stdio buffering, it interacts poorly with printf()
  // calls elsewhere in the program (e.g., any logging from V8.)
  setvbuf(stdout, nullptr, _IONBF, 0);
  setvbuf(stderr, nullptr, _IONBF, 0);
  return node::Start(argc, argv); // <- 从这里，我们进入node.cc文件
}
#endif
```

node.cc里面有三个__Start()__函数，逐级调用，让我们按照调用的顺序来看一下每个__Start()__都干了什么：

首先看第一个Start():
```cpp
int Start(int argc, char** argv) {

  // ...处理argc和argv, 在此省略
  
  // v8_platform是一个匿名struct, 定义了若干涉及V8引擎的辅助函数
  v8_platform.Initialize(v8_thread_pool_size); 
  // 在这里V8被初始化
  V8::Initialize();
  performance::performance_v8_start = PERFORMANCE_NOW();
  v8_initialized = true;
  
  // 在V8初始化成功之后，我们会进入第二个Start()函数
  // 请特别关注此函数的第一个参数
  // 我们很惊喜的发现了有关libuv的代码！
  // uv_default_loop顾名思义，会创建一个默认配置的event loop!
  const int exit_code =
      Start(uv_default_loop(), argc, argv, exec_argc, exec_argv);
      
  // ...一些在Node退出时所需要的清理工作，在此省略
  return exit_code;
}
```
现在看第二个Start():
```cpp
inline int Start(uv_loop_t* event_loop,
                 int argc, const char* const* argv,
                 int exec_argc, const char* const* exec_argv) {
                 
  // 这里，我们生成一个V8的Isolate。
  // 一个Isolate是一份独立的V8 runtime,
  // 包括但不限于一个heap管理器，垃圾回收器等。
  // 在一个时间段内，有且只有一个线程能使用此Isolate。
  Isolate* const isolate = Isolate::New(params);
  if (isolate == nullptr)
    return 12;  // Signal internal error.
    
  // ...给这个isolate定义了一些回调函数，在此省略
  
  int exit_code;
  {
    // 在看NodeJS源码的时候总是会碰到以下代码
    // 总是要申明Scope，有isolate_scope, handle_scope等
    // 只需要知道isolate_scope是让v8步入指定的isolate
    // handle_scope是让步入特定isolate之后的v8创建一个
    // 具有垃圾回收功能的工作区，我们可以在此工作区中
    // 索引多个JS对象。
    Locker locker(isolate);
    Isolate::Scope isolate_scope(isolate);
    HandleScope handle_scope(isolate);
    
    // IsolateData是个辅助类
    // 它是我们以后在Node中获得此前定义的
    // isolate, event_loop的统一入口
    // 它在env.cc中被定义
    IsolateData isolate_data(
        isolate,
        event_loop,
        v8_platform.Platform(),
        allocator.zero_fill_field());
    if (track_heap_objects) {
      isolate->GetHeapProfiler()->StartTrackingHeapObjects(true);
    }
    // 在这里，我们进入第三个Start()
    // 由isolate参数我们便知道，这个Start()要开始编译我们的JS代码了！
    // 而且它还用到了isolate_data，其中有event loop,
    // 所以相应的，我们肯定会看到很多libuv的代码！
    exit_code = Start(isolate, &isolate_data, argc, argv, exec_argc, exec_argv);
  }
}
```

让我们来看看第三个Start():
```cpp
inline int Start(Isolate* isolate, IsolateData* isolate_data,
                 int argc, const char* const* argv,
                 int exec_argc, const char* const* exec_argv) {
  HandleScope handle_scope(isolate);
  // 一个Context是一个V8的上下文，它存在于一个特定的Isolate中
  // 一个Isolate可以有多个Context，且Context可以嵌套
  // context_scope就是步入指定的context
  Local<Context> context = NewContext(isolate);
  Context::Scope context_scope(context);
  
  // 请关注下面的这个env，以后我们会经常看到他！
  // env顾名思义是是一个抽象出来的node运行环境
  // 它记录了v8的实例，其对应的isolate，
  // 也记录了libuv生成的event loop
  // 我们以后如果想获得event loop就可以使用env的函数调取
  Environment env(isolate_data, context);
  
  // 好了，我们有碰到了一个Start()
  // 这个Start()最主要的做了两件事情：
  // 1. 设置libuv的一些handle函数，最最重要的两个prepare和idle
  // 2. 设置了我们未来在JS中会用到的全局变量process在C++中的原型
  // 这两个在此就不展开了，将在独立的文章中解析！
  env.Start(argc, argv, exec_argc, exec_argv, v8_is_profiling);

  const char* path = argc > 1 ? argv[1] : nullptr;
  StartInspector(&env, path, debug_options);

  if (debug_options.inspector_enabled() && !v8_platform.InspectorStarted(&env))
    return 12;  // Signal internal error.

  env.set_abort_on_uncaught_exception(abort_on_uncaught_exception);

  if (no_force_async_hooks_checks) {
    env.async_hooks()->no_force_checks();
  }

  // 在这个代码块中，发生了很多重要的事情
  // 最主要的就是Node加载原生模块
  // 以及编译我们自己的JS代码！
  // 因为这个要涉及另外几个文件的代码，
  // 为了方便，此代码块的细节留在后面再讨论
  {
    Environment::AsyncCallbackScope callback_scope(&env);
    env.async_hooks()->push_async_ids(1, 0);
    LoadEnvironment(&env);
    env.async_hooks()->pop_async_id(1);
  }

  env.set_trace_sync_io(trace_sync_io);

  {
    SealHandleScope seal(isolate);
    bool more;
    env.performance_state()->Mark(
        node::performance::NODE_PERFORMANCE_MILESTONE_LOOP_START);
    
    // 在这里我们是真正的步入到了event loop!
    do {
      // uv_run会执行一个对应event loop的所有阶段
      // 这些阶段在libuv的文档中都有记载
      uv_run(env.event_loop(), UV_RUN_DEFAULT);

      v8_platform.DrainVMTasks(isolate);

      more = uv_loop_alive(env.event_loop());
      if (more)
        continue;

      // 当我们的event loop中没有待处理的事件时，
      // NodeJS会在此函数内抛出一个'beforeExit'时间，
      // 我们可以在自己的JS代码中捕捉此时间并执行代码
      // 可以同步，也可以异步
      RunBeforeExit(&env);

      // 如果在RunBeforeExit中，
      // 我们的JS代码给event loop新增了事件，
      // 那么，我们是不会真的结束进程的！
      // 所以收到'beforeExit'并不意味着一定会退出进程
      more = uv_loop_alive(env.event_loop());
    } while (more == true);
    env.performance_state()->Mark(
        node::performance::NODE_PERFORMANCE_MILESTONE_LOOP_EXIT);
  }

  env.set_trace_sync_io(false);

  // 这里会抛出'exit'事件, 可以看到
  // 这里的回调已经不在我们libuv的event loop中了
  // 所以在这里我们无法执行任何异步代码
  // 同时这里是真的要退出进程了！
  const int exit_code = EmitExit(&env);
  RunAtExit(&env);

  v8_platform.DrainVMTasks(isolate);
  v8_platform.CancelVMTasks(isolate);
  WaitForInspectorDisconnect(&env);
#if defined(LEAK_SANITIZER)
  __lsan_do_leak_check();
#endif

  return exit_code;
}
```
通过这三个Start()函数，我们大体了解了NodeJS的一个启动流程。我们知道了Node会先初始化V8实例，并使用唯一一个Isolate来运行我们所有的JS代码，然后设置了libuv的event loop，加载内置模块和编译我们的JS文件，最后进入event loop。这个流程中，与我们NodeJS使用者最相关的，应该就是加载和编译我们自己的JS文件了。关于这部分的分析，我们将在下一篇文章中仔细讨论。
