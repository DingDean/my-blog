---
title: "gRPC踩坑实录"
date: 2018-06-08T11:06:41+08:00
lastmod: 2018-06-08T11:06:41+08:00
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

1. 在protobuf中定义的int64字段，在NodeJS中收到时，其值类型为String而非Number
