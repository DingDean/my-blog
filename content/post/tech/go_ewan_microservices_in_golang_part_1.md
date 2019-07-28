---
title: "[译]用GoLang实现微服务（一）"
date: 2018-03-26T20:19:00+08:00
lastmod: 2018-04-07T20:19:00+08:00
draft: false
keywords: ["golang", "microservices", "google", "go", "programming", "grpc", "protobuf", "prot", "proto"]
description: "系列文章的第一篇，讲述用Go实现微服务，同时会用到诸如Docker, Kubernetes, CircleCI, go-micro, MongoDB等技术"
tags: ["Golang", "翻译", "Docker", "Kubernetes", "CI", "Microservice_Golang"]
categories: ["技术"]
author: "Ewan Valentine"
# you can close something for this content if you open it in config.toml.
# comment: false
# toc: false
# you can define another contentCopyright. e.g. contentCopyright: "This is an another copyright."
# contentCopyright: false
# reward: false
# mathjax: false
---

__*此系列文章介绍如何用GoLang实践微服务, 分十篇。此为其首。*__   
__*原著作者：[Ewan Valentine](https://ewanvalentine.io/)*__   
__*原文连接：[https://ewanvalentine.io/microservices-in-golang-part-1/](https://ewanvalentine.io/microservices-in-golang-part-1/)*__    
__*友情提示：系列文章的后五篇翻译请移步至[wuYin's blog](https://wuyin.io)*__

*~~初稿~~ -> 润色*

# 导言
在本文中，我们将了解一些基础的概念，术语。同时将创建我们的第一个微服务，尽管它会非常简陋。

在接下来的文章中，我们会陆续创建以下微服务:

* consignments (货运)
* inventory (仓库)
* users (用户)
* authentication (认证)
* roles (角色)
* vessels (货船)

完整的技术栈如下：golang, mongodb, grpc, docker, Google Cloud, Kubernetes, NATS, CircleCI, Terrafrom and go-micro.

在你跟随此文学习时，请务必设置合适的GOPATH，以及使用这个[git仓库](https://github.com/EwanValentine/shippy)(每篇文章对应一个分支)。

另外，我的工作平台是Macbook，所以如果你的工作平台有所不同，那么文章中的些许地方需要相应的改动，比如Makefiles中的```$GOPATH```和```$(GOPATH)```，请您自行关注。

<!--more-->

# 必要准备

* 了解Golang和它的生态圈
* 安装gRPc/protobuf - [教程在此](https://grpc.io/docs/quickstart/go.html)
* 安装Golang - [教程在此](https://golang.org/doc/install)
* 安装以下库

```bash
go get -u google.golang.org/grpc
go get -u github.com/golang/protobuf/protoc-gen-go
```

# 我们要写一个怎样的项目？
我们要写一个简单的集装箱管理平台。之所以选择它，当然是因为它有一定的复杂性，可以展示微服务的作用，毕竟用微服务来实现一个博客真是大材小用了。好了，让我们开始吧！

# 何为微服务？
在传统的应用中，所有的功能都是存在于单一的代码库(Monotholic Code Base)中。在表面上看，代码库中的代码可以有几种聚合方式。可能会按照其类型分割，比如controllers, entity, factories，也有可能按照其功能拆分成几个包，比如auth, articles等等。但无论如何，整个应用是建立在一个单一代码库上的。

微服务是对于上述第二种聚合方式的拓展。我们依旧将应用按照其功能拆分成几个包，但不同的是，这些功能包现在都是一个可独立运行的代码库。

# 为何用微服务？

降低复杂性 - 将功能拆分成对应的微服务可以将你的整个代码拆分成更小，更易维护的代码库。这有点类似早期Unix的开发哲学“只做一件事，并做到做好“。在传统的单一代码库应用中，代码的耦合性往往更容易往高耦合发展。这就可能导致撰写和维护代码变得很复杂，也更容易出现漏洞。

拓展性 - 在单一代码库应用中，可能某些代码的使用频率会比其他代码高很多。当出现需要拓展我们的应用时，我们此时只能拓展整个代码库而非其中的部分代码。比如现在应用的瓶颈出现在了验证模块上，由于验证模块是和整个应用的代码库高度耦合的，那么我们只能选择拓展整个代码库来摆脱瓶颈。但如果验证模块本身是一个微服务，那么我们只需要拓展验证模块即可。

微服务的理念让你能撰写低耦合的代码，这样更容易横向拓展，这非常适合于如今云端的开发环境。

**Nginx有一系列文章来探讨了有关微服务的诸多概念，可以[在此阅读](https://www.nginx.com/blog/introduction-to-microservices/)。**

# 为何选用Golang?
尽管很多语言都能实现微服务（毕竟微服务只是一种概念而非具体的框架），但有些语言对于微服务的支持会更好。Golang就是其中之一。

Golang本身非常的轻量，速度飞快。最重要的是，它对并发提供了非常好的支持，这一点能更好的利用多核处理器，以及帮助我们同时在不同的机器上运行代码。

Golang的标准库对网络服务有非常好的支持。

最后，Golang有一个非常棒的微服务框架，go-mirco，我们将在以后用到他。

# 何为protobuf/gRPC
由于每个微服务对应一个独立运行的代码库，一个很自然的问题就是如何在这些微服务之间通信。

我们可以使用传统的REST，用http传输JSON或者XML。但用这种方法的一个问题在于，当两个微服务A和B之间要通信时，A要先把数据编码成JSON/XML，然后发送一个大字符串给B，然后B在将数据从JSON/XML解码。这在大型应用中可能会造成大量的开销。尽管我们在和浏览器交互时必须使用这种方法，但微服务之间可以选择其他方式。

gRPC就是这另外一种方式。gRPC是谷歌出品的一个RPC通信工具，它很轻量，且其协议是基于二进制的。让我们来仔细研究下这个定义。gRPC将二进制当作其核心的编码格式。在我们使用JSON的RESTful例子中，我们的数据会以字符串的格式通过http传输。字符串包含了相对大量的元数据，用于描述其编码格式，长度，内容格式以及其他必要数据。之所以包含这些元数据，是因为要让传统的网页浏览器知道收到的数据会是怎样的。但是在两个微服务之间通信时，我们不一定需要这么多元数据。我们可以只需要更轻量的二进制数据。gRPC支持全新的HTTP 2协议，正好可以使用二进制数据。gRPC甚至可以建立双向的流数据。HTTP 2是gRPC的基础，如果你想了解更多HTTP 2的内容，可以看[Google的这篇文章](https://developers.google.com/web/fundamentals/performance/http2/)。

那么我们该怎么用二进制数据呢？gRPC使用protobuf来描述数据格式。使用Protobuf，你可以清晰的定义一个微服务的界面。关于gRPC，我建议你读一读[这篇文章](https://blog.gopheracademy.com/advent-2017/go-grpc-beyond-basics/)。

那么现在让我们开始定义第一个微服务吧。在你项目的根目录下建立以下文件`consignment-service/proto/consignment/consignment.proto`。值得一提的是，目前我会把所有的微服务代码放在一个统一的项目下。这种项目结构被称为"mono-repo"。之所以采用这种结构，只是想让教学更加简单。网络上有许多针对这种项目结构的争论，在此就不细究了。如果你喜欢，你当然也可以把每个微服务独立成一个新的项目。

`consignment.proto`的内容如下：

```protobuf
// consignment-service/proto/consignment/consignment.proto
syntax = "proto3";

package go.micro.srv.consignment; 

service ShippingService {
  rpc CreateConsignment(Consignment) returns (Response) {}
}

message Consignment {
  string id = 1;
  string description = 2;
  int32 weight = 3;
  repeated Container containers = 4;
  string vessel_id = 5;
}

message Container {
  string id = 1;
  string customer_id = 2;
  string origin = 3;
  string user_id = 4;
}

message Response {
  bool created = 1;
  Consignment consignment = 2;
}
```

尽管这是一个非常简单的例子，但这里有几点需要注意。首先，你得定义`service`。一个`service`定义了此服务暴露给外界的交互界面。然后，你得定义`message`。宽泛的讲，`message`就是你的数据结构

这个文件里，`message`由protobuf处理，而`service`则是由protobuf的grpc插件处理。这个grpc插件使我们定义的`service`能使用`message`。

有了这个proto文件还不够，我们需要使用protobuf的工具来编译它。为了方便，让我们写一个`Makefile`来帮助我们编译文件。`consignment-service/Makefile`内容如下：
```Makefile
build:
	protoc -I. --go_out=plugins=grpc:$(GOPATH)/src/github.com/ewanvalentine/shipper/consignment-service \
	  proto/consignment/consignment.proto
```
这段代码会调用protoc，它负责将我们的protobuf文件编译成代码。同时我们还指定了grpc的插件，以及最终输出文件的位置。

现在，如果你运行`$ make build`，然后前往文件夹`proto/consignment`，你应该可以看到一个新的Golang文件`consignment.pb.go`。这个文件是protoc自动生成的，它将proto文件中的`service`转化成了需要我们在Golang代码中需要编写的`interface`。

让我们现在来满足这个`interface`。创建`consignment-service/main.go`:
```go
// consignment-service/main.go
package main

import (
    "log"
    "net"

    // 导入生成的consignment.pb.go文件
    pb "github.com/ewanvalentine/shipper/consignment-service/proto/consignment"
    "golang.org/x/net/context"
    "google.golang.org/grpc"
    "google.golang.org/grpc/reflection"
    )

const (
    port = ":50051"
    )

type IRepository interface {
  Create(*pb.Consignment) (*pb.Consignment, error)
}

// Repository - 模拟一个数据库，我们会在此后使用真正的数据库替代他
type Repository struct {
  consignments []*pb.Consignment
}

func (repo *Repository) Create(consignment *pb.Consignment) (*pb.Consignment, error) {
updated := append(repo.consignments, consignment)
           repo.consignments = updated
           return consignment, nil
}

// service要实现在proto中定义的所有方法。当你不确定时
// 可以去对应的*.pb.go文件里查看需要实现的方法及其定义
type service struct {
  repo IRepository
}

// CreateConsignment - 在proto中，我们只给这个微服务定一个了一个方法
// 就是这个CreateConsignment方法，它接受一个context以及proto中定义的
// Consignment消息，这个Consignment是由gRPC的服务器处理后提供给你的
func (s *service) CreateConsignment(ctx context.Context, req *pb.Consignment) (*pb.Response, error) {

  // 保存我们的consignment
  consignment, err := s.repo.Create(req)
    if err != nil {
      return nil, err
    }

  // 返回的数据也要符合proto中定义的数据结构
  return &pb.Response{Created: true, Consignment: consignment}, nil
}

func main() {

repo := &Repository{}

      // 设置gRPC服务器
      lis, err := net.Listen("tcp", port)
        if err != nil {
          log.Fatalf("failed to listen: %v", err)
        }
s := grpc.NewServer()

     // 在我们的gRPC服务器上注册微服务，这会将我们的代码和*.pb.go中
     // 的各种interface对应起来
     pb.RegisterShippingServiceServer(s, &service{repo})

     // 在gRPC服务器上注册reflection
     reflection.Register(s)
     if err := s.Serve(lis); err != nil {
       log.Fatalf("failed to serve: %v", err)
     }
}
```
总的来说，我们实现了consignment微服务所需要的方法，并建立了一个服务器监听50051端口。如果你此时运行`go run main.go`，你肯定看不见任何输出，因为我们还没写客户端代码呢！

现在就让我们看看怎么写客户端代码。在这里我们要一个命令行工具, 它会读取JSON文件并和我们的服务器交互。

请在项目的根目录下建立一个新的文件夹`mkdir consingment-cli`。在这个文件夹中，我们创建`cli.go`:
```go
// consignment-cli/cli.go
package main

import (
    "encoding/json"
    "io/ioutil"
    "log"
    "os"

    pb "github.com/ewanvalentine/shipper/consignment-service/proto/consignment"
    "golang.org/x/net/context"
    "google.golang.org/grpc"
    )

const (
    address         = "localhost:50051"
    defaultFilename = "consignment.json"
    )

func parseFile(file string) (*pb.Consignment, error) {
  var consignment *pb.Consignment
    data, err := ioutil.ReadFile(file)
    if err != nil {
      return nil, err
    }
  json.Unmarshal(data, &consignment)
    return consignment, err
}

func main() {
  // Set up a connection to the server.
  conn, err := grpc.Dial(address, grpc.WithInsecure())
    if err != nil {
      log.Fatalf("Did not connect: %v", err)
    }
  defer conn.Close()
    client := pb.NewShippingServiceClient(conn)

    // Contact the server and print out its response.
    file := defaultFilename
    if len(os.Args) > 1 {
      file = os.Args[1]
    }

  consignment, err := parseFile(file)

    if err != nil {
      log.Fatalf("Could not parse file: %v", err)
    }

  r, err := client.CreateConsignment(context.Background(), consignment)
    if err != nil {
      log.Fatalf("Could not greet: %v", err)
    }
  log.Printf("Created: %t", r.Created)
}
```
现在让我们创建一个`consignment-cli/consignment.json`:
```json
{
  "description": "This is a test consignment",
  "weight": 550,
  "containers": [
    { "customer_id": "cust001", "user_id": "user001", "origin": "Manchester, United Kingdom" }
  ],
  "vessel_id": "vessel001"
}
```
在`consignment-service`下运行`go run main.go`, 在另一个终端中，在`consignment-cli`下运行`go run cli.go`, 你应该能看到一条消息说`Created: true`。我们怎么确定一个`consignment`真的被创建了呢？让我们更新一下我们的微服务，加入一个`GetConsignments`方法，这样，我们就能看到所有存在的`consignment`了：
```proto
// consignment-service/proto/consignment/consignment.proto
syntax = "proto3";

package go.micro.srv.consignment;

service ShippingService {
  rpc CreateConsignment(Consignment) returns (Response) {}

  // Created a new method
  rpc GetConsignments(GetRequest) returns (Response) {}
}

message Consignment {
  string id = 1;
  string description = 2;
  int32 weight = 3;
  repeated Container containers = 4;
  string vessel_id = 5;
}

message Container {
  string id = 1;
  string customer_id = 2;
  string origin = 3;
  string user_id = 4;
}

// Created a blank get request
message GetRequest {}

message Response {
  bool created = 1;
  Consignment consignment = 2;

  // Added a pluralised consignment to our generic response message
  repeated Consignment consignments = 3;
}
```
现在运行`make build`来获得最新编译后的微服务界面。如果此时你运行`go run main.go`，你会获得一个类似这样的错误信息: `*service does not implement go_micro_srv_consignment.ShippingServiceServer (missing GetConsignments method)`。熟悉Go的你肯定知道，你忘记实现一个`interface`所需要的方法了。让我们更新`consignment-service/main.go`:
```go
package main

import (
	"log"
	"net"

	// Import the generated protobuf code
	pb "github.com/ewanvalentine/shipper/consignment-service/proto/consignment"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

const (
	port = ":50051"
)

type IRepository interface {
	Create(*pb.Consignment) (*pb.Consignment, error)
	GetAll() []*pb.Consignment
}

// Repository - Dummy repository, this simulates the use of a datastore
// of some kind. We'll replace this with a real implementation later on.
type Repository struct {
	consignments []*pb.Consignment
}

func (repo *Repository) Create(consignment *pb.Consignment) (*pb.Consignment, error) {
	updated := append(repo.consignments, consignment)
	repo.consignments = updated
	return consignment, nil
}

func (repo *Repository) GetAll() []*pb.Consignment {
	return repo.consignments
}

// Service should implement all of the methods to satisfy the service
// we defined in our protobuf definition. You can check the interface
// in the generated code itself for the exact method signatures etc
// to give you a better idea.
type service struct {
	repo IRepository
}

// CreateConsignment - we created just one method on our service,
// which is a create method, which takes a context and a request as an
// argument, these are handled by the gRPC server.
func (s *service) CreateConsignment(ctx context.Context, req *pb.Consignment) (*pb.Response, error) {

	// Save our consignment
	consignment, err := s.repo.Create(req)
	if err != nil {
		return nil, err
	}

	// Return matching the `Response` message we created in our
	// protobuf definition.
	return &pb.Response{Created: true, Consignment: consignment}, nil
}

func (s *service) GetConsignments(ctx context.Context, req *pb.GetRequest) (*pb.Response, error) {
	consignments := s.repo.GetAll()
	return &pb.Response{Consignments: consignments}, nil
}

func main() {

	repo := &Repository{}

	// Set-up our gRPC server.
	lis, err := net.Listen("tcp", port)
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()

	// Register our service with the gRPC server, this will tie our
	// implementation into the auto-generated interface code for our
	// protobuf definition.
	pb.RegisterShippingServiceServer(s, &service{repo})

	// Register reflection service on gRPC server.
	reflection.Register(s)
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
```
如果现在使用`go run main.go`，一切应该正常。

最后让我们更新`consignment-cli/cli.go`来获得`consignment`信息：
```go
func main() {
    ... 

	getAll, err := client.GetConsignments(context.Background(), &pb.GetRequest{})
	if err != nil {
		log.Fatalf("Could not list consignments: %v", err)
	}
	for _, v := range getAll.Consignments {
		log.Println(v)
	}
}
```
此时再运行`go run cli.go`，你应该能看到所创建的所有`consignment`。

至此，我们使用protobuf和grpc创建了一个微服务以及一个客户端。在下一篇文章中，我们将介绍使用`go-micro`框架，以及创建我们的第二个微服务。同时在下一篇文章中，我们将介绍如何容Docker来容器化我们的微服务。

如果你觉得这篇文章对你有所帮助，你可以请原作者喝杯咖啡！链接如下：[https://monzo.me/ewanvalentine](https://monzo.me/ewanvalentine)

# 一些有用的资源

## 文章

[https://www.nginx.com/blog/introduction-to-microservices/](https://www.nginx.com/blog/introduction-to-microservices/)

[https://martinfowler.com/articles/microservices.html](https://martinfowler.com/articles/microservices.html)

[https://www.microservices.com/talks/](https://www.microservices.com/talks/)

[https://medium.facilelogin.com/ten-talks-on-microservices-you-cannot-miss-at-any-cost-7bbe5ab7f43f#.ui0748oat](https://medium.facilelogin.com/ten-talks-on-microservices-you-cannot-miss-at-any-cost-7bbe5ab7f43f#.ui0748oat)

[https://microserviceweekly.com/](https://microserviceweekly.com/)

## 书籍

[https://www.amazon.co.uk/Building-Microservices-Sam-Newman/dp/1491950358](https://www.amazon.co.uk/Building-Microservices-Sam-Newman/dp/1491950358)

[https://www.amazon.co.uk/Devops-Handbook-World-Class-Reliability-Organizations/dp/1942788002](https://www.amazon.co.uk/Devops-Handbook-World-Class-Reliability-Organizations/dp/1942788002)

[https://www.amazon.co.uk/Phoenix-Project-DevOps-Helping-Business/dp/0988262509](https://www.amazon.co.uk/Phoenix-Project-DevOps-Helping-Business/dp/0988262509)

## Podcasts

[https://softwareengineeringdaily.com/tag/microservices/](https://softwareengineeringdaily.com/tag/microservices/)

[https://martinfowler.com/tags/podcast.html](https://martinfowler.com/tags/podcast.html)

[https://www.infoq.com/microservices/podcasts/](https://www.infoq.com/microservices/podcasts/)
