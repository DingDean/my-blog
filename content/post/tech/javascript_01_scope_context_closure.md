---
title: "简明JavaScript之Context, Scope与Closure"
date: 2017-12-16T10:37:10+08:00
lastmod: 2017-12-16T10:37:10+08:00
draft: true
keywords: ["JavaScript", "scope", "context", "closure", "let", "var"]
description: "JavaScript愈加流行，此系列文章旨在帮助大家理解它的一些重要概念。其中的基础就是作用域(Scope), 上下文(Context), 闭包(Closure)的概念及它们之间的区别。"
tags: ["NodeJS", "JavaScript"]
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

*JavaScript愈加流行，此系列文章旨在帮助大家理解它的一些重要概念。*

其中的基础就是上下文(Context)，作用域(Scope)，闭包(Closure)的概念及它们之间的区别。

<!--more-->

## 上下文 Context

简单的说，上下文即```this```的值。

## 作用域 Scope

可视作用域为数学意义上的集合。当你在执行一段代码时，此集合包含了此段代码能获取的所有变量，函数和对象。

把你的代码想象成一个工程任务，比如盖房子。那么作用域就是这项工程任务能使用到的所有工具，钉子，锤子等。

作用域和上下文一样，不是一尘不变的。
