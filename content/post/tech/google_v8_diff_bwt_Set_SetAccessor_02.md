---
title: "谷歌V8引擎探秘：Set/SetAccessor - 定义与区别"
date: 2018-01-31T15:19:45+08:00
lastmod: 2018-01-31T15:19:45+08:00
draft: true
keywords: ["V8", "源代码", "C++", "cpp", "编程"]
description: "讨论一下V8引擎中，ObjectTemplate的Set与SetAccessor之间的区别"
tags: ["V8", "源代码", "C++", "cpp", "编程"]
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

本文章是此系列的第二篇，主要记录了我对V8 ObjectTemplate对象的疑问与解答。大问题就是ObjectTemplate的Set与SetAccessor方法的区别。

<!--more-->

## Set

ObjectTemplate的Set函数继承于其母对象Template，其源码如下：

```
