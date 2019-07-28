---
title: "[简明JavaScript]之Context, Scope与Closure"
date: 2016-03-16T10:37:10+08:00
lastmod: 2016-03-16T10:37:10+08:00
draft: true
keywords: ["JavaScript", "scope", "context", "closure", "let", "var"]
description: "JavaScript愈加流行，此系列文章旨在帮助大家理解它的一些重要概念。其中的基础就是作用域(Scope), 上下文(Context), 闭包(Closure)的概念及它们之间的区别。"
tags: ["NodeJS", "JavaScript"]
categories: ["技术", "简明JavaScript"]
author: "丁科"
# you can close something for this content if you open it in config.toml.
# comment: false
# toc: false
# you can define another contentCopyright. e.g. contentCopyright: "This is an another copyright."
# contentCopyright: false
# reward: false
# mathjax: false
---

___**简明 JavaScript 系列是我自己学习 JavaScript 概念时的笔记，旨在记录学习资料以及自己在实践中的感想。每一期尽量有一个有趣的 Demo 。**___

其中的基础就是上下文(Context)，作用域(Scope)，闭包(Closure)的概念及它们之间的区别。

<!--more-->

## 上下文 Context

简单的说，上下文即```this```的值。

上下文随着其所在的函数及函数的调用方式而变。分为以下几种情况：

1. 在全局环境中简单调用this
2. 严格调用函数
3. 非严格调用函数

## 作用域 Scope

可视作用域为数学意义上的集合。当你在执行一段代码时，此集合包含了此段代码能获取的所有变量，函数和对象。

把你的代码想象成一个工程任务，比如盖房子。那么作用域就是这项工程任务能使用到的所有工具，钉子，锤子等。

## 闭包 Closure

一个函数本身就是一个闭包。

## 例子

``` JavaScript
const db = (function () {
  return {
    desc: "a db mock"
  }
})()

const B = function (db) {
  this.db = db
}

B.prototype.echo = function () {
  console.log(this.db.desc)
}

const b = new B(db)

b.echo() // "a db mock"
setTimeout(b.echo, 1000) // uncaughtException
setTimeout(() => b.echo(), 1000) // "a db mock"
```
