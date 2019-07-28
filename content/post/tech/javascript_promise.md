---
title: "[简明JavaScript]之Promise"
date: 2016-04-11T09:33:05+08:00
lastmod: 2016-04-11T09:33:05+08:00
draft: false
keywords: ["NodeJS", "JavaScript"]
description: ""
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

```JavaScript
const readline = require('readline')
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
})

// 请原谅我这庸俗的剧情
said('Alice', "Will you always be here with me?")
said('Bob', "Oh dear Alice, why would I ever want to leave you?")
said('Alice', "Promise me!")

let promise = makePromise()

promise
  .then(() => {
    console.log('Alice and Bob were happy ever after.')
  })
  .catch(e => {
    console.log('Bob eventually left Alice, what a jerk.')
  })

function said (who, words) {
  console.log(`${who} said: ${words}`)
}

// 到了这里会有一个问题，试着跑一下？
function makePromise () {
  said('Bob', 'I promise I would never leave you.')
  return new Promise(function (resolve, reject) {
    rl.question('你来决定故事的走向: ', answer => {
      if (answer === 'good')
        return resolve('Bob is true to his words')
      return reject('Bob is a total ass')
    })
  })
}

```
女士们，先生们，看到了吗，这就是我们今天的主角 Promise。照例，以下是学习资料:

* [MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)
* [JavaScript Promise 迷你书](http://liubin.org/promises-book/#then-return-new-promise)
* [Promise Chain Error Handling](https://javascript.info/promise-chaining#error-handling)
* [Never Mix Promises and Callbacks in NodeJS](https://spin.atomicobject.com/2017/04/06/nodejs-promises-callbacks/)

<!--more-->

## Finally! Promise 生 Promise

执行上一段代码，然后输入`good`之后，你就会触发美好结局，否则就是悲剧。
但你大概会发现一个问题，就是我们的程序并没有自动退出。
因为`readline`在没有告知`close`的情况下是不会自己退出的。
那我们该在哪里调用`readline#close`呢? 最偷懒的办法就是在`then`和`catch`里面都调用`readline#close`。
这样无论结局如何，程序都会自动退出。
事实上，只要记住`then`和`catch`都会返回一个新的`Promise`，那么我们就可以只需要在`catch`后面再追加一个`then`就好了。

```JavaScript
// ...

promise
  .then(() => {
    console.log('Alice and Bob were happy ever after.')
  })
  .catch(e => {
    console.log('Bob eventually left Alice, what a jerk.')
  })
  .then(() => {
      rl.close()
  })
  
// ...
```
当然，在未来，我们也可以用`Promise#finally`，这样在语意上就更加的通顺。毕竟`Promise#finally`就是用来善后的，无论承诺是否被坚守。
只不过当前（2016-09-08），NodeJS 以及一些主流的浏览器都不支持它。
```JavaScript
// ...

promise
  .then(() => {
    console.log('Alice and Bob were happy ever after.')
  })
  .catch(e => {
    console.log('Bob eventually left Alice, what a jerk.')
  })
  .finally(() => {
      rl.close()
  })
  
// ...
```
这样就干净清爽多了。

言情剧到此位置，让我们开个运动会吧。

## Promise.race: 个人百米冲刺

Promise.race 会在并发的几个 Promise 中挑选出最先完成或者失败的那一个，并且返回对应返回值的 Promise。

比如有些情况下，我要向多个源请求同样一份东西，谁先给我，我就用谁的资源。这就是 Promise.race 的用武之地。

也可以看成是百米冲刺，我们只关心夺得冠军的那一位：

```JavaScript
const echo = console.log

let names = ['Key', 'Omar', 'Patrick']
let runners = names.map(makeRunner)
race(runners)
  .then(() => {
    relay(runners)
  })

function makeRunner (name) {
  return {
    run() {
      return new Promise(function (resolve, reject) {
        let time = Math.random() * 1000
        time = Math.ceil(time)
        setTimeout(() => {
          resolve(`${name} finished the race in ${time}`)
        }, time)
      })
    }
  }
}

function race (runners) {
  echo("The annual race begins")
  let runs = runners.map(r => r.run())
  return Promise.race(runs)
    .then(result => {
      echo(`First! ${result}`)
    })
    .catch(echo)
}
```

## Promise.all: 做咖啡

Promise.all 接受一组 Promise，并且会等所有的 Promise 都完成或失败后，将对应的值，放入一个数组并且包裹在一个 Promise 中供我们使用。

就好比，做一杯咖啡，我得烧水，磨豆粉，加热牛奶，最后再把三样东西合在一起组成咖啡。我既可以串行，也可以并发。我选择并发。

```JavaScript
function boilWater () {
  return new Promise(function (resolve, reject) {
    setTimeout(() => {
      resolve('water is heated')
    }, 5000)
  })
}

function grindBean () {
  return new Promise(function (resolve, reject) {
    setTimeout(() => {
      resolve('bean is grinded')
    }, 1000)
  })
}

function warmMilk () {
  return new Promise(function (resolve, reject) {
    setTimeout(() => {
      resolve('milk is warmed')
    }, 2000)
  })
}

let then = Date.now()
Promise.all(
    [
      boidWater(),
      grindBean(),
      warmMilk()
    ]
).then(([hotwater, bean, milk]) => {
  let diff = Date.now() - then // no less than 5000
  // I have the coffee
}).catch(e => {
  // ...
})
```

## throw 还是 reject

总的来说，能用 reject 则用 reject。

一是与___运行时错误___触发的 throw 所区分，二也是从语意上更加符合 Promise 的语境。

但**最重要的**的一点是，有的时候，catch 函数是捕获不到我们人为抛出的错误的：

当我们在 Promise 中使用一个异步回调函数时，这个异步函数或者回调里抛出的错误，我们的 catch 是捕获不到的
```JavaScript
new Promise(function (resolve, reject) {
  setTimeout(() => {
    throw new Error('I want this error to be handled by catch function')
  }, 0)
})
  .then(() => console.log('it works'))
  .catch(e => console.log("sorry mate, the error won't be caught here"))
// 这段代码只会抛出异常，并不会执行catch中的代码
```

<!-- ## 让程序崩溃 -->

<!-- 既然在大多数情况下，Promise 中用 throw 抛出的错误会被 catch 捕获到，那 ___运行时错误___ 也会被 catch 捕获。这就造成了有的时候程序并不会崩溃的情况，比如 -->

<!-- ``` JavaScript -->
<!-- const readline = require('readline') -->
<!-- rl = readline.createInterface({ -->
<!--   input: process.stdin, -->
<!--   output: process.stdout -->
<!-- }) -->

<!-- process.on('uncaughtException', e => { -->
<!--   console.log(e.stack) -->
<!--   process.exit(1) -->
<!-- }) -->

<!-- new Promise(function (resolve, reject) { -->
<!--   undefined.find() -->
<!-- }).catch(function (e) { -->
<!--   console.log('the error is caught') -->
<!--   console.log(e) -->
<!-- }) -->

<!-- rl.question('yyyy', console.log) -->
<!-- ``` -->

<!-- 一般性情况下，在遇到诸如 `undefined.find` 之类的 `uncaughtException`，程序本质上就得崩溃，从而程序员可以修复代码。但是上述代码并不会崩溃，并且 `uncaughtException` 也不会冒泡到 `process.on('uncaughtException')`里面去。因为异常都已经在 catch 里面被处理了，而 catch 仅仅是打印了错误就完事了。我们可以在 catch 里手动加上一行 `process.exit(1)`，但前提是我们得知道捕获的异常的确是运行时异常，而不是 reject 或者我们自己抛出的异常。所以理想的情况是 -->

<!-- ```JavaScript -->
<!-- const readline = require('readline') -->
<!-- rl = readline.createInterface({ -->
<!--   input: process.stdin, -->
<!--   output: process.stdout -->
<!-- }) -->

<!-- process.on('uncaughtException', e => { -->
<!--   console.log(e.stack) -->
<!--   process.exit(1) -->
<!-- }) -->

<!-- new Promise(function (resolve, reject) { -->
<!--   undefined.find() -->
<!-- }).catch(function (e) { -->
<!--   console.log('the error is caught') -->
<!--   console.log(e) -->
<!-- }) -->

<!-- rl.question('yyyy', console.log) -->
<!-- ``` -->
