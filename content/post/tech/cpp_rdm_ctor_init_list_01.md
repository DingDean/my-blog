---
title: "C++杂记：Initialization List v.s Assignment && 不带new的使用构造函数"
date: 2018-01-27T09:45:59+08:00
lastmod: 2018-01-27T09:45:59+08:00
draft: true
keywords: ["C++", "cpp", "编程"]
description: "从使用C++的项目的源码学到的知识点以及技巧"
tags: ["C++", "V8", "NodeJS"]
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

此篇文章，我们来解答一个问题，源自谷歌V8引擎源代码以及NodeJS源代码：

* 先看第一个问题，源码在[此](https://github.com/v8/v8/blob/master/include/v8.h#L9427):

``` cpp
# 存在一个构造函数，其在声明完所需的参数之后，紧跟了一个冒号":", 然后才是函数本体{}。
ClassA::ClassA(ANY_TYPE varA, ANYTYPE varB)
    : varA_(varA),
      varB_(varB) {}
# 这个冒号在这里是做什么的？
# 简单的说，这是C++中构造函数的Initialization List写法。
# 功能和我们平常使用的赋值写法是一样的，即上段代码和下面这段代码从功能上看是等价的:

ClassA::ClassA(ANY_TYPE varA, ANYTYPE varB) {
  varA_ = varA;
  varB_ = varB;
}
```

* 第二个问题，源码在[此](https://github.com/nodejs/node/blob/master/src/node_contextify.cc#L678):

``` cpp
# 在做出类型声明后，并没有声明一个变量，而是直接调用了一个疑似此类型构造函数的函数:
ScriptOrigin origin(filename.ToLocalChecked(), lineOffset.ToLocalChecked(),
                        columnOffset.ToLocalChecked());
ScriptCompiler::Source source(code, origin, cached_data);
# 这里，origin直接被当作一个变量传入了source函数中。
```

这两种写法存在的很大一部分原因都是为了追求性能，详情如下。
<!--more-->
