---
title: "Cpp_02_calling_constructor_without_new"
date: 2018-03-22T14:31:28+08:00
lastmod: 2018-03-22T14:31:28+08:00
draft: true
keywords: []
description: ""
tags: []
categories: []
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

此篇文章，我们来解答一个问题，同样源自NodeJS源代码：

源码在[此](https://github.com/nodejs/node/blob/master/src/node_contextify.cc#L678):

``` cpp
# 在做出类型声明后，并没有声明一个变量，而是直接调用了一个疑似此类型构造函数的函数:
ScriptOrigin origin(filename.ToLocalChecked(), lineOffset.ToLocalChecked(),
                        columnOffset.ToLocalChecked());
ScriptCompiler::Source source(code, origin, cached_data);
# 这里，origin直接被当作一个变量传入了source函数中。
```
<!--more-->

有用的链接：

1. [Calling constructors in c++ without new](https://stackoverflow.com/questions/2722879/calling-constructors-in-c-without-new)
