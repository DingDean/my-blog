---
title: "[简明JavaScript]之async/await"
date: 2017-06-10T14:40:04+08:00
lastmod: 2017-06-10T14:40:04+08:00
draft: false
keywords: ["NodeJs", "JavaScript"]
description: "NodeJS"
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

> It will be legen, wait for it..., and I hope you're not lactose intolerant because the second half of that word is... dairy!   
> -[Barney Stinson](https://en.wikipedia.org/wiki/Barney_Stinson)

```JavaScript
const echo = console.log

function waitForIt (words) {
  echo("-wait for it... and I hope you're not lactose intolerant because the second half of that word is—")

  return new Promise(function (resolve, reject) {
    setTimeout(() => {
      resolve("dairy!")
    }, 5000)
  })
}

async function barneySays () {
  echo("It will be legen")
  let word = await waitForIt()
  echo(word)
}

barneySays()
// It will be legen-wait for it... and I hope you're not lactose intolerant because the second half of that word is—dairy!
```

照例，以下是学习资料:

* [MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function)
* [Why async/await is better than Promise](https://hackernoon.com/6-reasons-why-javascripts-async-await-blows-promises-away-tutorial-c7ec10518dd9)
* [JavaScript.Info](https://javascript.info/async-await)

<!--more-->

## 等待你兑现承诺

async 函数是 JavaScript 处理异步操作的又一个语法，前两个是回调函数和 Promise。

async 建立在 Promise 之上，其返回值永远是一个 Promise，即使具体的代码并没有返回 Promise。

如果 async 函数只是用来简化创建 Promise 过程的语法，那么其实没什么用处，其关键在于一个相伴的语法 **await**。

await 只能在 async 函数内使用，它的作用在于将一个异步的流程用同步流程的语法呈现。await 顾名思义就是等待，等待什么呢？
等待一个 Promise 被完成或者失败。在 async 函数中，只要碰到 await，那么 await 后面的代码都将在 await 完成后再执行。

正如篇首的代码事例所展示的，await 会等待 `waitForIt` 返回的 Promise 完成，并将返回值赋予给`word`，然后再`echo(word)`。

`let word = await waitForIt()` 就像是`waitForIt().then(word => {})`。既然我们有了和`Promise#then`等价的语法，那`Promise#catch`对应的语法是什么？

还是我们的老朋友`try...catch...`

## catch me if you can

在 async 中使用 await 时，我们要使用 `try...catch...` 来捕获错误。

```JavaScript
async function pipeline () {
  try {
    let file = await download() 
  } catch (e) {
    console.log('error downloading')
    console.log(e)
  }
}
```
