---
title: "[译]用GoLang实现微服务（二）"
date: 2018-04-02T12:34:31+08:00
lastmod: 2018-04-08T12:34:31+08:00
draft: false
keywords: ["golang", "microservices", "google", "go", "programming", "grpc", "protobuf", "prot", "proto"]
description: "系列文章的第二篇，讲述用Go实现微服务，同时会用到诸如Docker, Kubernetes, CircleCI, go-micro, MongoDB等技术"
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

__*此系列文章介绍如何用GoLang实践微服务, 分十篇。此为其二。*__   
__*原著作者：[Ewan Valentine](https://ewanvalentine.io/)*__   
__*原文连接：[https://ewanvalentine.io/microservices-in-golang-part-2/](https://ewanvalentine.io/microservices-in-golang-part-2/)*__    
__*友情提示：系列文章的后五篇翻译请移步至[wuYin's blog](https://wuyin.io)*__

~~___初稿___~~ -> ___润色___

在[上一篇文章中](https://blog.dingkewz.com/post/tech/go_ewan_microservices_in_golang_part_1/), 我们大致掌握了如何用gRPC来构建微服务。在这篇文章中，我们要介绍如何容器化(Dockerize)我们的微服务，在此过程中，我们将引入使用go-micro以及写下我们的第二个微服务。

<!--more-->

# 何为Docker

在云计算如火如荼的时代，我们需要大量的在云端部署，维护和运行许多代码库，即我们的微服务。为了能持续，稳定，快速的部署， 维护和运行微服务，产业界创新和运用了诸多新概念和新技术，其中的关键便是[容器](https://en.wikipedia.org/wiki/Operating-system-level_virtualization)(containers)。

传统的部署方案，大致可以被描述成以下流程：一个整体式应用(monolithic app)被部署于指定操作系统的服务器，这台服务器上有提前定义好且持续维护的供产品使用的依赖。这些服务器可以是物理的服务器，或者一台物理服务器上的诸多由Chef或者Puppet管理的虚拟机群。这种部署流程在拓展时耗费颇多且效率不高。

随后，为了管理大量虚拟机，诸如[vagrant](https://www.vagrantup.com/)的工具被采用。尽管这些工具让部署虚拟机更加便利，但虚拟机本身并不轻量，毕竟每一个虚拟机都是运行着一个完整的操作系统，各自有它们的Kernel。这可以说是对服务器资源的一种浪费。如果要让大量的微服务都运行在虚拟机上，这只会使部署来得更加低效和难以维护。

# 容器

容器，可以被看成是精简版的操作系统。容器本身并不运行一个kernel或者任何常见于操作系统的底层结构。相对的，容器只包含一些上层库和它的运行时(runtime)。不同于虚拟机各自有各自的Kernel，不同的容器是共享底层操作系统的Kernel的。尽管容器之间共享Kernel，但每个容器都是独立的，相互之间并不影响。可以参见[此处](https://www.redhat.com/en/topics/containers/whats-a-linux-container)深入了解容器。

容器本身由于其自身特性，它比传统的虚拟机来得更为轻量。也正因为容器更为轻量，它是支撑微服务的重要技术。

所以，Docker到底是什么？我们一直都在讨论容器啊！事实上，容器是基于的linux的一项技术，它规定了这套技术所需提供的功能。而我们所说的Docker是容器技术的一种实现。Docker本身使用非常便利，这也是为什么它如此流行。但容器技术的实现并不止Docker, 还有[其他的实现](https://www.contino.io/insights/beyond-docker-other-types-of-containers)。不过在我们的系列文章中，我们将一直使用Docker，毕竟它流行且简单易用。

说了这么多，接下来让我们开始容器化我们的微服务吧！新建`consignment-service/Dockerfile`，其内容如下:
```
FROM alpine:latest

RUN mkdir /app
WORKDIR /app
ADD consignment-service /app/consignment-service

CMD ["./consignment-service"]
```
___(如果您的操作系统是Linux，那么 `alpine` 可能会和您不太对付。不过不用担心，如果你想在Linux上运行这段代码，只需要将 `alpine` 替换成 `debian` 就好了。在此后的文章，我们会介绍更好的方式来构建我们的二进制文件)___

那么这几行代码做了什么呢？  

首先，它告诉Docker我们需要最新版的[Linux Alpine](https://alpinelinux.org/)。`Linux Alpine`是一个轻量的`Linux`发行版，专门为运行容器化的应用而生。这意味着，`Linux Alpine`只会包括运行我们软件的必须条件，它最终的大小大概就只有8MB！要知道，一个在虚拟机中运行的Ubuntu可是得要1GB大小呢！

其次，我们告诉Docker说我们需要为我们的应用创建一个文件夹，即 `/app`，并且这个文件夹就是我们的工作目录。随后，我们往这个工作目录添加并运行我们编译好的二进制文件。所以我们的二进制文件是什么？这个二进制文件就是我们容器化后的微服务。下面我们介绍一下容器化的流程。向我们的 `Makefile` 中添加以下内容：
```
build:
    ... 
    GOOS=linux GOARCH=amd64 go build
    docker build -t consignment-service .
```
让我们仔细看看这两行代码做了什么。

首先，它我们编译了我们Go的二进制文件。你可能会注意到我们在 `go build` 之前添加了两个系统变量 `GOOS` 和 `GOARCH` 。熟悉Golang的朋友会知道，这是指定这个二进制文件将要运行在什么操作系统和其对应的系统架构上。如果你的开发主机是用 `Linux`的，那么这两个系统变量大可不必添加。但因为我的开发主机是 `Macbook`，如果不指定这两个变量就编译二进制文件，那么这个二进制文件是不能在 `Linux` 上运行的。

其次，第二行使用Docker容器化了我们的微服务。首先它会找到我们写好的 `Dockerfile`，根据其中的配置编译一个名为 `consignment-service`的项目。那个句号就是项目所在的代码目录，即 `Makefile`所在的当前目录。

现在，我想往 `Makefile` 中多加几行：
```
run: 
    docker run -p 50051:50051 consignment-service
```
在这里，我们会运行已经编译好的 `consignment-service`, 暴露出它的50051端口。由于一个容器有其独立的网络层，我们必须告诉Docker哪个借口是为我们的微服务工作的。在 `Makefile`中，"50051:50051"指的是，将我们系统的50051端口转发到容器的50051端口。如果你想让我们的微服务从外面看来是运行在8080端口上的，只需要对应的改成"8080:50051"即可。Docker也可以运行一个后台进程，`docker run -d -p "50051:50051" consignment-service`。你可以在[此](https://docs.docker.com/network/)更多的了解Docker的网络设置。

现在，运行 `make run`，然后在另一个终端中 `go run cli.go`，检查一下结果是不是如你所愿。

当你在运行 `docker run` 时，你其实是将你的代码以及代码所需的运行时环境整合进了一个镜像。这个镜像相当于一个你程序所需的环境及依赖的快照。你可以将这个镜像发布于 docker hub 上。docker hub 之于 docker, 就像 npm 之于 nodejs。当你在 `Dockerfile` 中定义了一个 `FROM` 属性时，你是在告诉 Docker 去 Docker Hub 上找到并获取 `FROM` 属性值对应的镜像文件作为我们 Docker 镜像的基础。我们镜像的基础不一定只有一个镜像，我们可以同时指定多个不同的镜像作为我们的基础。去[Docker Hub](https://hub.docker.com/explore/)看一下吧，你会发现有非常多的软件已经被容器化了！如果您有时间，请看一下这个[视频](https://www.youtube.com/watch?v=GsLZz8cZCzc)吧，你会发现用Docker可以实现多么美妙的事情。

`Dockerfile` 中的指令在编译的过程会被缓存起来。Docker 在你修改代码的过程中，只重新编译你修改过的地方。这让整个编译的过程异常迅速。

好了，说了这么多容器，想必您应该对其有所了解了！让我们回到自己的代码上了吧！

# Go-Micro

在创建一个使用 gRPC 的微服务时，我们会遇到相当多的样板代码来创建网络连接，比如要在客户端代码中写死远端服务器的端口，或者在一个微服务中指定另一个微服务所在服务器地址和端口。这是一个麻烦所在。当你有数个，数十个，甚至上百个微服务需要维护时，每个微服务有各自的地址和端口，如果没有一个合理的管理方法，维护和使用你的微服务会是一件噩梦！

这时候就需要一项业务来发现我们的微服务。这个“服务发现“(Service Discovery)业务实时记录和追踪各个微服务，以及它们的地址和端口。每个微服务在上线时会在“服务发现”业务上注册，在下线时注销。每个微服务有唯一的名字指向它自己，无论这个微服务是不是运行在之前的地址或者端口。这一层抽象能让我们更加方便的调用微服务。

“服务发现“业务有许多实现，我们在此会使用简单易用的[go-micro](https://github.com/micro/go-micro)。

Go-Micro 是用于Go的一个微服务框架。它的许多强大的功能，其中之一就是我们即将用到的“服务发现“。Go-Micro 集成到了protoc的插件之中，所以我们需要替换标准的grpc插件。

首先，安装 Go-Micro 依赖:
```bash
go get -u github.com/micro/protobuf/{proto,protoc-gen-go}
```
同时修改我们的 `Makefile`:
```
build:
	protoc -I. --go_out=plugins=micro:$(GOPATH)/src/github.com/EwanValentine/shippy/consignment-service \
		proto/consignment/consignment.proto
	...

...
```
替换完grpc插件后，我们就要在代码 `consignment-service/main.go` 中使用 go-micro:
```
// consignment-service/main.go
package main

import (
	"fmt"
	pb "github.com/EwanValentine/shippy/consignment-service/proto/consignment"
        // 使用 go-mircro
	micro "github.com/micro/go-micro"
	"golang.org/x/net/context"
)

type IRepository interface {
	Create(*pb.Consignment) (*pb.Consignment, error)
	GetAll() []*pb.Consignment
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

func (repo *Repository) GetAll() []*pb.Consignment {
	return repo.consignments
}

// service要实现在proto中定义的所有方法。当你不确定时
// 可以去对应的*.pb.go文件里查看需要实现的方法及其定义
type service struct {
	repo IRepository
}

// CreateConsignment - 在proto中，我们只给这个微服务定一个了一个方法
// 就是这个CreateConsignment方法，它接受一个context以及proto中定义的
// Consignment消息，这个Consignment是由gRPC的服务器处理后提供给你的
func (s *service) CreateConsignment(ctx context.Context, req *pb.Consignment, res *pb.Response) error {

	consignment, err := s.repo.Create(req)
	if err != nil {
		return err
	}

	res.Created = true
	res.Consignment = consignment
	return nil
}

func (s *service) GetConsignments(ctx context.Context, req *pb.GetRequest, res *pb.Response) error {
	consignments := s.repo.GetAll()
	res.Consignments = consignments
	return nil
}

func main() {

	repo := &Repository{}

	// 注意，在这里我们使用go-micro的NewService方法来创建新的微服务服务器，
        // 而不是上一篇文章中所用的标准
	srv := micro.NewService(

		// This name must match the package name given in your protobuf definition
		// 注意，Name方法的必须是你在proto文件中定义的package名字
		micro.Name("go.micro.srv.consignment"),
		micro.Version("latest"),
	)

	// Init方法会解析命令行flags
	srv.Init()

	pb.RegisterShippingServiceHandler(srv.Server(), &service{repo})

	if err := srv.Run(); err != nil {
		fmt.Println(err)
	}
}
```
使用 go-micro 给我们的代码引入了三个较大的变化。

第一，我们修改了创建 gRPC 服务器的流程。`micro.NewService()` 抽象出了原本复杂的流程。对应的，我们使用抽象过的 `micro.Run()`来取代之前的 `sv.Serve()`。

第二，我们微服务interface所包含的方法不变，但是各个方法所接受的参数发生了变化，返回的参数也不同了。原始的 gRPC 代码有四种不同的方法申明，对应四种不同的 gRPC 数据传输手段。而 go-micro 统一了四种接口，抽象出了 `req` 和 `res`。

最后，大家应该欣喜的看到，我们在代码中并没有写死我们微服务的端口，其实，我们根本就不需要考虑这个问题，至少在代码中看是这样的！我们需要系统变量或者命令行变量 `MICRO_SERVER_ADDRESS`中指定地址和端口。用 Docker 运行微服务时，可以通过命令行设置这个变量，让我们修改一下 `Makefile`:
```
run:
    docker run -p 50051:50051 \
        -e MICRO_SERVER_ADDRESS=:50051 \
        -e MICRO_REGISTRY=mdns consignment-service
```
`MICRO_REGISTRY=mdns` 告诉 go-micro 我们要使用 [mdns(multicast dns)](https://en.wikipedia.org/wiki/Multicast_DNS) 作为本地使用的 service broker。我们不会在生产环境中使用 mdns, 但在开发阶段，为了便利，我们可以使用mdns。在以后的文章中我们会再讨论它。

如果你现在执行 `make run`，你将得到一个具有“服务发现”功能的微服务。

是时候更新我们的客户端代码了：
```
import (
    ...
    "github.com/micro/go-micro/cmd"
    microclient "github.com/micro/go-micro/client"

)

func main() {
    cmd.Init()

    // Create new greeter client
    client := pb.NewShippingServiceClient("go.micro.srv.consignment", microclient.DefaultClient)
    ...
}
```
你可以在[这里](https://github.com/EwanValentine/shippy/blob/tutorial-2/consignment-cli/cli.go)看到完整的代码。

如果你这是运行客户端代码，你会发现它是运行不起来的。那是因为我们的微服务现在运行在容器内，而这个容器有它自己的mdns，有别于该容器所在宿主的mdns。修复这个问题最简单的办法就是让客户端也容器化。这样，客户端和服务器都运行在同一个宿主上，且使用相同的网络层。让我们更新一下我们的 `Makefile` 来容器化我们的客户端:
```
build:
	GOOS=linux GOARCH=amd64 go build
	docker build -t consignment-cli .

run:
	docker run -e MICRO_REGISTRY=mdns consignment-cli
```
然后再为我们的客户端写一个 `Dockerfile`:
```
FROM alpine:latest

RUN mkdir -p /app
WORKDIR /app

ADD consignment.json /app/consignment.json
ADD consignment-cli /app/consignment-cli

CMD ["./consignment-cli"]
```
这时候你再在`consignment-cli` 文件夹里执行 `make run`, 将看到 `Created: true`的消息。

我们先前提到过，如果你使用的是Linux，那么你应该使用 Debian 作为基础镜像。现在让我们聊一聊 Docker 的一个功能，即 Multi-Stage Builds。这个功能允许我们在一个 Dockerfile 中使用多个 Docker 镜像。

这在当下对我们非常有用，因为我们可以用一个镜像来编译应用，然后用另一个镜像来运行。让我们试一下这个功能吧，更新我们的 Dockerfile:
```
# consignment-service/Dockerfile

# 我们使用Golang的官方镜像，它包含了所有用于构建Golang应用的依赖和工具
# 请注意`as builder`，这命名了我们这个镜像，以后可以用`builder`来指向它
FROM golang:1.9.0 as builder

# 将工作目录设置为当前微服务在gopath中的完整路径
WORKDIR /go/src/github.com/EwanValentine/shippy/consignment-service

# 将代码复制到工作目录中
COPY . .

# 我们在这里引入godep，它是golang的包/依赖管理器
# 我们将要用godep而不是go get来在Docker中使用sub-packages
RUN go get -u github.com/golang/dep/cmd/dep

# 初始化一个godep项目，运行`dep ensure`会将项目所需的依赖
# 都引入到工作目录中
RUN dep init && dep ensure

# 编译我们的二进制文件
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo .

# 在这里，我们第二次使用了FROM，它告诉Docker，我们从这里
# 要开始第二个构建流程
FROM alpine:latest

# 确保安全性的包
RUN apk --no-cache add ca-certificates

RUN mkdir /app
WORKDIR /app

# 在这里，我们不再直接从我们的宿主机器中直接拷贝二进制文件,
# 而是从一个叫做`builder`的容器中获取。它会从我们起先构建的镜像中
# 获得已经编译好的文件并引入到这个容器里。
COPY --from=builder /go/src/github.com/EwanValentine/shippy/consignment-service/consignment-service .

# 运行二进制文件。不同的是，这个二进制文件是从另一个容器中获取的！
CMD ["./consignment-service"]
```
上述的Dockerfile有一个我会在将来予以改进的问题，那就是Docker只能读取 Dockerfile 所在文件夹及其子文件夹的文件，而不能读取其父目录的任何文件。

这就导致在使用 `$ dep ensure` 和 `$ go get` 时，你必须确保你所有的依赖都已经上传至可被公开访问到的 git 服务器，不然在 Docker 中，那些不能从公开服务器上获得的依赖都将无法被找到。比如我们的 `consignment-service`，它依赖于我们的 `vessel-service`。假设我们的 `vessel-service` 并没有上传到公共的 git 服务器，这意味着我们无法使用 `go get` 获取它，那么我们只能在 `consignment-service` 中使用相对路径 `../service-vessel` 来获取这个服务。然而由于 Docker 是不能读取父目录下的文件内容的，那么在容器化我们的 `consignment-service` 时，我们将找不到依赖 `service-vessel`。 尽管现在这个 Dockerfile 有其局限性，但它已经够用了，我们会在以后继续改进它。

你可以在这里看到更多关于[multi-stage builds](https://docs.docker.com/develop/develop-images/multistage-build/)的信息。

# Vessel Service
让我们创建第二个微服务，即Vessel Service。我们之前写过一个微服务，即货运服务(consignment service)，它主要的功能是记录当前所有需要托运的集装箱，以及对应的货运船。我们需要一个服务来根据集装箱的重量，数量去寻找合适的货运船，这就是我们的货船服务（Vessel Service）。

在你的项目根目录下创建以下几个文件夹 `$ mkdir -p vessel-service/proto/vessel`，并新建一个 protobuf 文件 `vessel-service/proto/vessel/vessel.proto`：
```
// vessel-service/proto/vessel/vessel.proto
syntax = "proto3";

package go.micro.srv.vessel;

service VesselService {
  rpc FindAvailable(Specification) returns (Response) {}
}

message Vessel {
  string id = 1;
  int32 capacity = 2;
  int32 max_weight = 3;
  string name = 4;
  bool available = 5;
  string owner_id = 6;
}

message Specification {
  int32 capacity = 1;
  int32 max_weight = 2;
}

message Response {
  Vessel vessel = 1;
  repeated Vessel vessels = 2;
}
```
如你所见，这个文件内容和之前的 `consignment.proto` 非常类似。我们申明了一个服务 `VesselService`，它只有一个 `FindAvailable` 方法。

现在让我们创建一个 `vessel-service/Makefile` 来记录我们编译流程和执行流程：
```
// vessel-service/Makefile
build:
	protoc -I. --go_out=plugins=micro:$(GOPATH)/src/github.com/EwanValentine/shippy/vessel-service \
    proto/vessel/vessel.proto
	docker build -t vessel-service .

run:
	docker run -p 50052:50051 -e MICRO_SERVER_ADDRESS=:50051 -e MICRO_REGISTRY=mdns vessel-service
```
同样的，这个文件内容和上一个 Makefile 非常相似。但请注意，这回这个微服务不再使用宿主机器的50051端口了，因为这个端口已经被之前的 consignment service 占据了。一个宿主的同一个端口不能同时运行两个微服务。所以，这回我们的微服务将使用宿主机器的50052端口。

利用之前说过的 multi-stage build, 我们创建一个 Dockerfile 来容器化我们的货船微服务:
```
# vessel-service/Dockerfile
FROM golang:1.9.0 as builder

WORKDIR /go/src/github.com/EwanValentine/shippy/vessel-service

COPY . .

RUN go get -u github.com/golang/dep/cmd/dep
RUN dep init && dep ensure
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo .


FROM alpine:latest

RUN apk --no-cache add ca-certificates

RUN mkdir /app
WORKDIR /app
COPY --from=builder /go/src/github.com/EwanValentine/shippy/vessel-service/vessel-service .

CMD ["./vessel-service"]
```
例行公事之后，让我们真正的实现我们的货船服务逻辑吧:
```
// vessel-service/main.go
package main

import (
	"context"
	"errors"
	"fmt"

	pb "github.com/EwanValentine/shippy/vessel-service/proto/vessel"
	"github.com/micro/go-micro"
)

type Repository interface {
	FindAvailable(*pb.Specification) (*pb.Vessel, error)
}

type VesselRepository struct {
	vessels []*pb.Vessel
}

// FindAvailable - 根据Specification，从若干货船中挑选出合适的货船来运送货物
// 如果货物的数量和重量都没有超过一个货船的数量和重量上限，
// 那么我们就返回这个货船
func (repo *VesselRepository) FindAvailable(spec *pb.Specification) (*pb.Vessel, error) {
	for _, vessel := range repo.vessels {
		if spec.Capacity <= vessel.Capacity && spec.MaxWeight <= vessel.MaxWeight {
			return vessel, nil
		}
	}
	return nil, errors.New("No vessel found by that spec")
}

type service struct {
	repo Repository
}

func (s *service) FindAvailable(ctx context.Context, req *pb.Specification, res *pb.Response) error {

	vessel, err := s.repo.FindAvailable(req)
	if err != nil {
		return err
	}

	res.Vessel = vessel
	return nil
}

func main() {
	vessels := []*pb.Vessel{
		&pb.Vessel{Id: "vessel001", Name: "Boaty McBoatface", MaxWeight: 200000, Capacity: 500},
	}
	repo := &VesselRepository{vessels}

	srv := micro.NewService(
		micro.Name("go.micro.srv.vessel"),
		micro.Version("latest"),
	)

	srv.Init()

	pb.RegisterVesselServiceHandler(srv.Server(), &service{repo})

	if err := srv.Run(); err != nil {
		fmt.Println(err)
	}
}

```
啊，太棒了，我们有了一个全新的货船微服务。但如果这个微服务不能从货运微服务那里获得任务，那岂不是浪费精力？所以，现在让我们看一下如果让货运服务和货船服务之间展开通信。我们需要做的就是在货运服务中，想货船服务发起一个请求，寻找合适的货船，然后货船服务返回合适的货船编号给货运服务:
```
// consignment-service/main.go
package main

import (

	"fmt"
	"log"
  
	pb "github.com/EwanValentine/shippy/consignment-service/proto/consignment"
	vesselProto "github.com/EwanValentine/shippy/vessel-service/proto/vessel"
	micro "github.com/micro/go-micro"
	"golang.org/x/net/context"
)

type Repository interface {
	Create(*pb.Consignment) (*pb.Consignment, error)
	GetAll() []*pb.Consignment
}

type ConsignmentRepository struct {
	consignments []*pb.Consignment
}

func (repo *ConsignmentRepository) Create(consignment *pb.Consignment) (*pb.Consignment, error) {
	updated := append(repo.consignments, consignment)
	repo.consignments = updated
	return consignment, nil
}

func (repo *ConsignmentRepository) GetAll() []*pb.Consignment {
	return repo.consignments
}

type service struct {
	repo Repository
  // 请注意，我们在这里记录了一个货船服务的客户端对象
	vesselClient vesselProto.VesselServiceClient
}

func (s *service) CreateConsignment(ctx context.Context, req *pb.Consignment, res *pb.Response) error {

	// 这里，我们通过货船服务的客户端对象，向货船服务发出了一个请求
	vesselResponse, err := s.vesselClient.FindAvailable(context.Background(), &vesselProto.Specification{
		MaxWeight: req.Weight,
		Capacity: int32(len(req.Containers)),
	})
	log.Printf("Found vessel: %s \n", vesselResponse.Vessel.Name)
	if err != nil {
		return err
	}

	req.VesselId = vesselResponse.Vessel.Id

	consignment, err := s.repo.Create(req)
	if err != nil {
		return err
	}

	res.Created = true
	res.Consignment = consignment
	return nil
}

func (s *service) GetConsignments(ctx context.Context, req *pb.GetRequest, res *pb.Response) error {
	consignments := s.repo.GetAll()
	res.Consignments = consignments
	return nil
}

func main() {

	repo := &ConsignmentRepository{}

	srv := micro.NewService(
		micro.Name("consignment"),
		micro.Version("latest"),
	)

  // 我们在这里使用预置的方法生成了一个货船服务的客户端对象
	vesselClient := vesselProto.NewVesselServiceClient("go.micro.srv.vessel", srv.Client())

	srv.Init()

	pb.RegisterShippingServiceHandler(srv.Server(), &service{repo, vesselClient})

	if err := srv.Run(); err != nil {
		fmt.Println(err)
	}
}
```

最后，让我们更新一下我们的 `consignment-cli/consignment.json`，因为我们不再需要将 `vessel_id` 写死了，它将由货船服务实时提供:
```
{
  "description": "This is a test consignment",
  "weight": 55000,
  "containers": [
    { "customer_id": "cust001", "user_id": "user001", "origin": "Manchester, United Kingdom" },
    { "customer_id": "cust002", "user_id": "user001", "origin": "Derby, United Kingdom" },
    { "customer_id": "cust005", "user_id": "user001", "origin": "Sheffield, United Kingdom" }
  ]
}
```

如果你现在在`consignment-cli`中运行`make build && make run`, 你想获得一串已经被创建好的货运任务，每一个任务都有一个对应的 `vessel_id`。

好了，到此为止，我们有了两个互相通信的微服务以及一个命令行工具。在下一篇文章中，我们将介绍如何利用[MongoDB](https://www.mongodb.com/what-is-mongodb)来永久保存我们的货运数据。同时，我们将增加我们的第三个微服务，并学习使用`docker compose`来管理日渐增多的微服务。

你可以访问[这里](https://github.com/EwanValentine/shippy/tree/tutorial-2)来获得项目的所有代码。

如果你觉得这篇文章对你有所帮助，你可以请原作者喝杯咖啡！链接如下：[https://monzo.me/ewanvalentine](https://monzo.me/ewanvalentine)
你也可以在[patreon](https://www.patreon.com/ewanvalentine)上支持原作者！
