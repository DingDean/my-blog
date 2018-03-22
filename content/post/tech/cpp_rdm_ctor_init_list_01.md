---
title: "C++杂记：Initialization List"
date: 2018-01-27T09:45:59+08:00
lastmod: 2018-01-27T09:45:59+08:00
draft: false
keywords: ["C++", "cpp", "V8"]
description: "从使用C++的项目的源码学到的知识点以及技巧"
tags: ["C++", "V8"]
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

*此系列文章是我自己在阅读一些使用C++的项目的源代码时遇到的问题以及这些问题的解答。问题有深有浅，有专业的，有业余的。学习嘛，总得由浅入深，循序渐进。*

此篇文章，我们来解答一个问题，源自谷歌V8引擎源代码:

源码在[此](https://github.com/v8/v8/blob/master/include/v8.h#L9514):
```cpp
ScriptOrigin::ScriptOrigin(Local<Value> resource_name,
                           Local<Integer> resource_line_offset,
                           Local<Integer> resource_column_offset,
                           Local<Boolean> resource_is_shared_cross_origin,
                           Local<Integer> script_id,
                           Local<Value> source_map_url,
                           Local<Boolean> resource_is_opaque,
                           Local<Boolean> is_wasm, Local<Boolean> is_module,
                           Local<PrimitiveArray> host_defined_options)
    : resource_name_(resource_name),
      resource_line_offset_(resource_line_offset),
      resource_column_offset_(resource_column_offset),
      options_(!resource_is_shared_cross_origin.IsEmpty() &&
                   resource_is_shared_cross_origin->IsTrue(),
               !resource_is_opaque.IsEmpty() && resource_is_opaque->IsTrue(),
               !is_wasm.IsEmpty() && is_wasm->IsTrue(),
               !is_module.IsEmpty() && is_module->IsTrue()),
      script_id_(script_id),
      source_map_url_(source_map_url),
      host_defined_options_(host_defined_options) {}
```

这冒号后面这一串貌似函数调用的代码是干嘛的？
<!--more-->
## 简单的解释

简单的说，这是C++中构造函数的Initialization List写法。

其功能和我们平常使用的赋值写法是一样的，即以下两种写法从功能上看是等价的：
```cpp
class Ke
{
        public:
                Ke( bool isDumb ) : isDumb_( isDumb ) { }
        private:
            bool isDumb_;
};

class Ke
{
        public:
          Ke( bool isDumb ) {
            this.isDumb_ = isDumb;
          }
        private:
            bool isDumb_;
}
```
