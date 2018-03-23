---
title: "NodeJS源码探秘之vm虚拟机"
date: 2017-12-15T22:26:12+08:00
lastmod: 2017-12-15T22:26:12+08:00
draft: true
keywords: ["NodeJS", "源码探秘", "virtual machine"]
description: "NodeJS是时下非常流行的服务器语言, 这个系列将着重研究NodeJS的源码，以期为之做出贡献。第二篇文章要搞清楚NodeJS到底是怎么为每一个JS文件提供单独的作用域的。"
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

*NodeJS是时下非常流行的服务器语言, 这个系列将着重研究NodeJS的源码，以期为之做出贡献。*

第二篇文章要搞清楚NodeJS到底是怎么为每一个JS文件提供单独的作用域的。*

<!--more-->

## 概述

在本系列的第一篇文章里，我们在探索require的运作机制时，遇到了NodeJS的vm模块，我们require来的JS代码之所以能成为独立的模块都要归功于vm模块的一个函数runInThisContext。从字面上看，这个函数所做的事情很直截了当，就是让我们的代码在下面的上下文中运行：
``` JavaScript
(function (exports, require, module, __filename, __dirname) {
});
```
这看上去很简单，但到底这个上下文是怎么运作起来的？v8引擎给这个上下文的作用域是什么？代码隔离的细节是什么？这些问题都是我们这篇文章所要探讨的问题。

## V8 Isolates && Context

NodeJS 会使用几个V8的Isolate? 我们每一个require来的模块是不是都有自己的上下文。

