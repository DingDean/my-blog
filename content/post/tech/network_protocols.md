---
title: "Network_protocols"
date: 2018-07-18T16:46:11+08:00
lastmod: 2018-07-18T16:46:11+08:00
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

<!--more-->

## 第一节 熟读ip addr

* `ifconfig` 和 `ip addr` 的区别
  - net-tools 和 iproute2
* ip 地址与无类型域间选路(CIDR)
  - 给定ip地址，如何求出广播地址，子网掩码和网络号
  - 广播地址
  - 子网掩码
    * 将子网掩码与ip地址按位计算AND，可以得到网络号
  - 组播地址
* lo (loop back) 环回接口，一般是127.0.0.1
* MAC 地址
  - ether fa:00:64:38:89:01
  - MAC 地址更像是身份证，是一个唯一的标识。
  - MAC 可在子网内通信，但不能跨子网
* 网络设备的状态标识(net\_device flag)
  - \<UP, BROADCAST, SMART...\>
  - UP 表示网卡处于启动状态
  - BROADCAST 表示有广播地址，可以发送广播包
  - MULTICAST 表示网卡可以发送多播包
  - LOWER\_UP 表示L1是启动的，即网线插着
  - MTU1500，最大传输单元1500
* qdisc pfifo\_fast
  - qdisc 全称 queueing discipline，排队规则
  - pfifo 是先入先出的排队规则
  - pfifo\_fast 是分成三个波段(band)的队列，每个波段，先入先出
    * 波段0-2，优先级递减
    * 先处理优先级高的队列
    * 数据包根据TOS分配波段

### 小结

* ___IP 是地址，有定位功能; MAC 是身份证，无定位功能___
* ___CIDR 可以用来判断是不是本地人___
* ___IP 分公有和私有___

### 习题

* IP 地址是怎么来的？

## 第二节 DHCP 与 PXE

### 如何配置 IP 地址？

1. 静态

2. 动态主机配置协议(DHCP) Dynamic Host Configuration Protocol

> 网络管理员配置一段共享的 IP 地址。每一台新接入的机器都通过 DHCP 协议，来这共享的 IP 地址申请，然后自动配置好就行了。用完了就还回去。

流程:

1. DHCP Discover
  * BOOTP 广播
2. DHCP Offer
  * DHCP Server接收广播，出租 IP 地址。
3. DHCP Request
  * 新来的机器发送DHCP Request广播包，告诉所有人自己接受什么地址
4. DHCP ACK
  * DHCP Server 确认选择

### 预启动执行环境 (PXE)

1. 启动 PXE 客户端
2. DHCP后获得 IP 地址和 PXE 服务器地址，以及启动文件地址
3. 使用 TFTP 协议下载启动文件
4. 执行启动文件

## 第三节 从物理层到 MAC 层

* MAC 层是用来解决多路访问的堵车问题
* ARP 是通过吼的方式来寻找目标 MAC 地址的，并有缓存
* 交换机是有 MAC 地址学习能力的

## 第四节 交换机与 VLAN

STP 协议: 解决交换机环路问题

* Root Bridge，根交换机
* Designated Bridges, 指定交换机
* Bridge Protocol Data Units (BPDU) 网桥协议数据单元
* Priority Vector, 优先级向量

虚拟隔离 VLAN: 解决隔离问题

## 第五节 ICMP 与 ping
