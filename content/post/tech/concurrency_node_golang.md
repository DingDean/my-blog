---
title: "NodeJS的并发模型"
date: 2018-03-18T10:34:20+08:00
lastmod: 2018-03-18T10:34:20+08:00
draft: true
keywords: ["NodeJS", "并发"]
description: "并发是一个实现一个复杂系统的自然选择。在其解决方案上，我们大致有两条技术线，一是NodeJS的基于事件的，异步的并发模型，一种是GoLang使用同步Channel沟通的并发模型。这篇文章主要是要用NodeJS和GoLang实现同一个复杂系统，比较两者的优缺点和异同，加深对并发模型的理解。"
tags: ["NodeJS", "GoLang"]
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

这篇文章旨在讨论NodeJS的并发模型。按理说，这应该是深入NodeJS的第一篇文章。然而NodeJS的异步模型无论是在逻辑方面还是语法层面都太自然了，以致我根本就没想到要去讨论它。这是在偷懒。于是，让我们在这里好好聊一聊它。

本篇文章会具体回答以下问题：

1. 何为并发？
2. NodeJS是单线程的吗？
3. NodeJS的并发模型是什么？
4. NodeJS的并发模型适用于什么场景？
5. 如何优化NodeJS的并发模型？
6. 还有其他的并发模型吗？

<!--more-->

## 何为并发

并发，指的是在一时间段内多样事物同时发生。比如在生活中，假设我们开了一家咖啡店，那么在某一时间段内，可能会有很多顾客下单并要求我们提供咖啡。

并发有一个和他非常相近的概念，叫做并行。

并行，指的是在一时间段内多样事物同时发展。我们的咖啡馆里并发了很多下单请求，那么我们可以一杯咖啡做完之后再开始做下一杯咖啡，也可以好几杯咖啡同时做。前者非并行，后者并行。

并发是关乎结构的，而并行则是关乎执行的。

Rob Pike大神在油管上的[这个视频](https://www.youtube.com/watch?v=cN_DpYBzKso)里，在GoLang的语境下解释了并发和并行的区别。这个视频其实也是我会想到写NodeJS的并发模型的原因。大家有空看一下，还是很好的！

## NodeJS是多线程的，但更是单线程的

NodeJS是多线程的，它由一个主线程(Event Loop / Main Thread)，和一个线程池(Worker Pool)组成。

但NodeJS更是单进程的，因为对于开发者而言，Worker Pool在绝大多数时间都是由NodeJS在底层操办的，开发者只需要关心Event Loop中的代码逻辑。

我们在接下来的文章会发现，正是因为NodeJS有这样的一个线程组合，才造就了它非常自然的并发模型。

## NodeJS的并发模型

NodeJS的并发模型非常聪明，我个人的理解就是它用“单线程”实现了一个多线程程序所能实现的并发模型。它的特点，正如其文档所说，在于“事件驱动”以及“非阻塞I/O“。

并发需有解决一个复杂系统的输出问题。我们在此就把这个复杂系统定为大家熟悉的网页服务器吧。假设我们需要向用户
