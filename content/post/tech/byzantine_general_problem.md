---
title: "他山之石之Byzantine Generals Problem"
date: 2018-07-14T10:33:02+08:00
lastmod: 2018-07-14T10:33:02+08:00
draft: false
keywords: ["Byzantine General Problem", "拜占庭将军问题"]
description: "如何实现一个可靠的分布式计算系统？"
tags: ["有趣的论文", "NodeJS", "架构设计"]
categories: ["技术"]
author: "丁科"
sequenceDiagrams: 
  enable: true
# you can close something for this content if you open it in config.toml.
# comment: false
# toc: false
# you can define another contentCopyright. e.g. contentCopyright: "This is an another copyright."
# contentCopyright: false
# reward: false
# mathjax: false
---

**论文出处: [https://people.eecs.berkeley.edu/~luca/cs174/byzantine.pdf](https://people.eecs.berkeley.edu/~luca/cs174/byzantine.pdf)**

> Reliable computer systems must handle malfunctioning components that give confilicting information to different parts of the system.
> This situation can be expressed abstractly in terms of a group of generals of the Byzantine army camped with their troops around an enmemy city.
> Communicating only by messenger, the generals must agree upon a common battle plan.
> However, one or more of them may be traitors who will try to confuse the others.
> The problem is to **find an algorithm to ensure that the loyal generals will reach agreement.**
> 
> 一个可靠的计算系统需要得当的处理其子部件因紊乱而向系统的其他部分发送相左的消息的情况。
> 这种情况可以抽象为以下场景：
> 
> 一群拜占庭将军围着一座敌城驻扎了多个军团，每个军团存在一位将军。在只能通过信使通信的情况下，他们需要决定一个共同的作战行动。
> 其中的几位将军有可能是叛徒，会不遗余力得误导其他人。
> 问题的关键就是**找出一个算法，从而确保所有的忠将作出一致的决定。**

<!--more-->

周末闲来无事，希望了解下分布式系统。

在谷歌的过程中发现了这篇论文，名为`The Byzantine Generals Problem`。

对于一个分布式系统，错误即是常量。如何在错误一定会出现的情况下，设计一个稳定可靠的系统，一直是分布式系统设计的关键。
这篇论文设计了一个抽象的问题，即 `The Byzantine Generals Problem`，通过对此问题的推导，作者们为设计分布式系统提出了些许建议。

全篇论文分为六个部分:

1. Introduction
  - 抽象出Byzantine Generals Problem的模型基础和设计目标
2. Impossibility Results
  - 提出和证明了 The Byzantine Generals Problem 在何时无解。
3. A solution with Oral Messages
  - 在问题有解的条件下，作者提出并论证了了 OM(m) 算法的真实性。
4. A solution with Signed Messages
  - 在问题有解的条件下，作者提出并论证了了 SM(m) 算法的真实性。
5. Missing Communication Paths
  - 结合图论，解释了在通讯部分受阻的情况下 OM(m) 与 SM(m) 的变形。
6. Reliable System
  - 将 Byzantine Generals Problem 推而广之到电脑系统。

**论文本身不长，但在后期涉及了图论和一些复杂的算法，所以想读完论文的话，需要反复多次。**
**此文是对论文的第1和第2部分的笔记，之后具体的证明以及发散在此不表，如感兴趣，请直接读论文。**

## 一些表达规范

`n` 代表 `将军的人数`

`m` 代表 `叛徒的人数上限`

`k` 代表 `叛徒的人数`

`i` 代表 `特定的将军i`

`v(i)` 泛指 `某个将军所获得的将军i的决定`

`majority` 指 `OM(m)算法中的决策函数`

## 导论

### 大问题
我们的目标是找出一种算法，从而满足以下两个条件:

**A. 所有的忠将会作出一致的决定。（一致的决定不代表有利的决定)**

**B. 少数的叛徒不会误导忠将们作出 ___不利___ 的决定。（对条件A的加强）**

由于难以定量得定义何为**不利**的决定，论文只讨论这群将军们如何作出决定。

从宏观上，作者提出了一种作出决定的过程，即: 

* 每个将军`i`，将自己的决定 `v(i)` 告诉其他所有的将军。
* 在经过一段消息传递后，每个将军都知道其他将军的决定，即每人手上有一个决定集合S
* 根据S，每个将军使用少数服从多数的原则作出决定。

事实上，如果我们将场景简化成一群将军在**同一个**房间里做决定的话，上述的决定过程根本用不到什么复杂的算法来确保一致性，因为每个将军所获得的S肯定是一致的。

### 化繁为简

现在由于只能通过信使来传递信息，那么就会出现 S 并不一致的情况，比如叛徒会对每个将军传递不一样的 `v(i)`。所以现在系统设计的关键就是如何让每个将军，或者更有效得说，是让每个**忠将**手上的 S 一致，从而使系统满足**条件A**。为此，作者细化了条件A的等价条件：

1. **所有的忠将必须持有相同的决定集，`v(1), ..., v(n)`**
2. **如果将军`i`是忠诚的，那么另外所有忠将手中`v(i)`的值，一定是将军`i`发出的值**

此后，作者更进一步细化考虑问题的颗粒度。我们可以看到，条件2的颗粒度是单个`v(i)`的值，而条件1的颗粒度依然还是集合 S。如果条件1的颗粒度也能细化为单个元素，那么我们就能将整个问题从讨论集合细化为讨论元素，这也是论文经一步推理获得条件1的等价条件的所在：

1'. **对于`v(i)`, 忠将之间两两相同。**

### Interactive Consistency
细化到这里，论文终于祭出了Byzantine Generals Problem的模型：

> ___拜占庭将军问题___ 一个指挥官要向其`n-1`个副官下达指令，从而   
> IC1. 所有忠诚的副官（此后称为忠臣）执行相同的命令   
> IC2. 如果指挥官是忠诚的，那么忠臣们所执行的命令一定是指挥官所下达的命令

IC1，IC2 合称为 ___interactive consistency___ 条件。

**为了通论的便利，让我们将命令的内容限定为`进攻`或者`撤退`。** 

让我们思考一下拜占庭将军问题为什么会称为问题。最重要的一点就是副官们不能信任从指挥官处获取的命令。指挥官有可能是叛徒。
正是对命令的怀疑，导致副官们需要额外的信息输入，即副官需要知道其他副官所收到的指令。
但同样的，副官们也不能信任从其他副官发来的消息。而唯一的信任都需要建立在整个通讯算法的数学基础之上，因为这是不会骗人的。（区块链了解下)

下图展示了这个非常自然的猜疑和求证逻辑。

```sequence
指挥官->A: v(i) = 进攻
指挥官->B: v(i) = 进攻
指挥官->C: v(i) = 进攻
Note right of A: A想v(i)有可能会被篡改, 需要求证
A->B: 于是向别的副官发送v(i) = 进攻
A->C: 于是向别的副官求证v(i) = 进攻
B->A: v(i) = 撤退
C->A: v(i) = 进攻
Note right of A: A手上有三个v(i)的值\n {进攻，撤退，进攻}\n作出正确决定:进攻
```

### 可能无解
拜占庭将军问题在特定情况下是无解的。如果指挥官和副官之间只能发送口头消息(Oral Messages)，那么
$$ \forall m > 0, 若 n \leq 3m, 则问题无解。 $$
口头消息即代表消息的内容完全由发送者决定，因此存在发送者向不同对象发送不同内容的可能。

可以试着考虑最简单的初始情况，即`m=1, n=3`。既然只有一个叛徒，那么我们可以将这个情况一分为二：

1. 指挥官不是叛徒。
2. 指挥官是叛徒。

当指挥官不是叛徒时，那么其中一个副官肯定就是叛徒了。设两个副官为 A 和 B。
```sequence
指挥官->A: v(i) = 进攻
指挥官->B: v(i) = 进攻
Note right of B: B 乃叛徒
B->A: v(i) = 撤退
Note right of A:  A手上有两个v(i)的值\n {进攻，撤退}\n 无法作出决定
```

当指挥官是叛徒时，
```sequence
指挥官->A: v(i) = 进攻
指挥官->B: v(i) = 撤退
Note left of 指挥官: 指挥官乃叛徒
A->B: v(i) = 进攻
B->A: v(i) = 撤退
Note right of A:  A手上有两个v(i)的值\n {进攻，撤退}\n 无法作出决定
Note right of B:  B手上有两个v(i)的值\n {进攻，撤退}\n 无法作出决定
```
这两种情况展示了在这种情况下，问题无解。具体的推广大家可以直接看论文，这里就不赘述了。
当然，这里无解的条件是建立在每个指挥官和副官只能发送口头信息的基础上的。
如果可以发送签名信息(Signed Messages)的话，那么情况会有所不同。具体同样还是直接看论文吧。
