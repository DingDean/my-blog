---
title: "[译]用GoLang实现微服务（三）"
date: 2018-04-08T17:04:26+08:00
lastmod: 2018-04-10T17:04:26+08:00
draft: false
keywords: ["golang", "microservices", "google", "go", "programming", "grpc", "protobuf", "prot", "proto"]
description: "系列文章的第三篇，讲述用Go实现微服务，同时会用到诸如Docker, Kubernetes, CircleCI, go-micro, MongoDB等技术"
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

__*此系列文章介绍如何用GoLang实践微服务, 分十篇。此为其三。*__   
__*原著作者：[Ewan Valentine](https://ewanvalentine.io/)*__   
__*原文连接：[https://ewanvalentine.io/microservices-in-golang-part-3/](https://ewanvalentine.io/microservices-in-golang-part-3/)*__    

~~___初稿___~~ -> ___润色___

在[上一篇文章中](https://blog.dingkewz.com/post/tech/go_ewan_microservices_in_golang_part_2/), 我们了解了[go-micro](https://github.com/micro/go-micro) 以及 [Docker](https://www.docker.com/)的基础。同时引入了我们的第二个微服务，货船服务（vessel-service）。那么在此文中，我们将要了解一下 [docker-compose](https://docs.docker.com/compose/)，并学会用它更好的运行和管理部署在本地的众多微服务。此外，我们还会稍微讲一下几种不同的数据库以及写下我们的第三个微服务！

<!--more-->

# 必要条件

[安装 docker-compose](https://docs.docker.com/compose/install/)

# 选择一个数据库
至今为止，我们从没有真正保存过我们的数据，它们永远存在于内存中，这以为这当我们的微服务重启时，一切数据都会消失。这绝非好事，所以我们需要保存，恢复和搜寻数据的能力，也就是数据库。

微服务的魅力之一就是你可以为每一个微服务提供完全不同的数据库。当然绝大部分人是不会这么做的，毕竟要同时管理好几个不同类型的数据库绝非易事。但是总会存在一个微服务，会让你选择一个不同的数据库来更好的处理它所保有的各种数据。所以给一个微服务使用不一样的数据库完全有其意义。而微服务架构让这种数据库的转变来得异常简单，因为两者本来就是分离的——数据库本身就该是一个微服务，不是吗？

如何为你的微服务选用“正确”的数据库？这问题本身就值得一份完全不同的文章，你可以看看[这一篇](https://www.infoworld.com/article/3236291/database/how-to-choose-a-database-for-your-microservices.html)，所以我们就不在此深入了。尽管如此，但如果你的数据可能不那么严谨，或者一致性不高，那么一个 NoSQL 类型的数据库会是一个好选择。因为这样的数据库对于你能保存的东西及格式非常灵活，并且能完美搭配 JSON 使用。我们将要用 MongoDB 作为我们的数据库选型。选择它的原因无外乎它有高效的性能，广泛的支持以及一个非常棒的在线社区。

如果你的数据在定义上更加完整和严谨，性质上更加关系型的话，选用传统的关系型数据库会更好。在关系型数据库的选择上，也没有什么太多硬性的规定。不过最好仔细研究下你的数据结构，想想你的微服务是读的更多呢，还是写的更多？询问的复杂度几何？试着根据你的回答来寻找合适的数据库吧。而我们呢，将使用 PostgreSQL，因为它高效，且是我熟悉的一种关系型数据库:)。你完全可以使用 MySQL，MariaDB或者其他任何的数据库。

如果你自己不想运维一个数据库的话，亚马逊和谷歌为这些数据库都提供非常好的云端解决方案（推荐）。[compose](https://www.compose.com/)也是一个好方案，它能运行数个不同类型的数据库，并且完全可控的，易拓展，同时它为了优化连接延迟，在云供应商的选择上，它会选择你微服务所使用的云供应商。

Amazon

* RDBMS: [https://aws.amazon.com/rds/](https://aws.amazon.com/rds/)    
* NoSQL: [https://aws.amazon.com/dynamodb/](https://aws.amazon.com/dynamodb/)    

Google

* RDBMS: [https://cloud.google.com/spanner/](https://cloud.google.com/spanner/)
* NoSQL: [https://cloud.google.com/datastore/](https://cloud.google.com/datastore/)

# Docker-Compose

上期我们介绍过 Docker, 它能让我们的微服务运行在一个轻量的，拥有独立运行时和依赖的容器中。但你们大概也感觉到了，为每一个微服务都写一个 Makefile 是在是太麻烦了。让我们看看 docker-compose 是如何解决这个麻烦的！Docker-compose 通过一个 yaml 配置文件就可以让你运行一系列的容器，并且你可以为每一个容器提供它们运行时(runtime)的元数据(metadata)。用 docker-compose 来运行容器类似于使用我们先前使用的 docker 命令。比如我们可以将下面的 docker 命令转换成对应的docker compose 配置文件的内容：

docker 命令:
```bash
$ docker run -p 50052:50051 -e MICRO_SERVER_ADDRESS=:50051 -e MICRO_REGISTRY=mdns vessel-service
```
对应的 docker-compose 配置文件:
```
version: '3.1'

services: 
  vessel-service:
    build: ./vessel-service
    ports:
      - 50052:50051
    environment:
      MICRO_REGISTRY: "mdns"
      MICRO_SERVER_ADDRESS: ":50051"
```
非常简单，不是吗？在你项目的根目录下新建`docker-compose.yaml`：
```yaml
# docker-compose.yaml
version: '3.1'

services:

  consignment-cli:
    build: ./consignment-cli
    environment:
      MICRO_REGISTRY: "mdns"

  consignment-service:
    build: ./consignment-service
    ports:
      - 50051:50051
    environment:
      MICRO_ADDRESS: ":50051"
      MICRO_REGISTRY: "mdns"
      DB_HOST: "datastore:27017"

  vessel-service:
    build: ./vessel-service
    ports:
      - 50052:50051
    environment:
      MICRO_ADDRESS: ":50051"
      MICRO_REGISTRY: "mdns"
```
在这个文件中，我们首先定义了希望使用的 docker-compose 版本——3.1，随后列出了需要运维的微服务。完整的文件内容里会包含一些其他设定，诸如网络和存储(Volume)，但让我们暂时关注与微服务紧密相关的设定上吧。

每个微服务都定义了一个名字，引入了 `build` 的路径，它指向一个存有 Dockerfile 的目录。docker-compose 会使用此路径下的 Dockerfile 来编译一个镜像。你也可以用 `image` 来替代 `build`，只要 `image` 的路径指向一个预编译好的镜像即可（我们以后会使用这种方式）。最后，你再定义你的端口指向和一些环境变量。

你只需要执行 `docker-compose build` 就可以编译完成你的 docker-compose 栈。`docker-compose run` 就可以运行你的微服务，你也可以用 `docker-compose up -d` 可以让你的微服务成为一个后台进程。`docker ps` 会列出你当前运行的所有容器。`docker stop $(docker ps -qa)` 会关闭所有正在运行的容器。

So let's run our stack. You should see lots of output and dockerfile's being built. You may also see an error from our CLI tool, but don't worry about that, it's mostly likely because it's ran prior to our other services. It's simply saying that it can't find them yet.

Let's test it all worked by running our CLI tool. To run it through docker-compose, simply run $ docker-compose run consignment-cli once all of the other containers are running. You should see it run successfully, just as before.

# Entities && Protobufs

至今为止，我们都是把定义好的 protobuf 当作我们的主要数据结构。我们根据他来构建微服务的结构和功能。同时由于 protobuf 对数据的定义非常规范，我们便在数据库中复用了 protobuf 中的数据结构。这仔细想想也是非常神奇的一件事。

但这种做法也有其局限性。有的时候，在 protobuf 中定义的数据结构不能轻易得被整理成合适的数据库结构。比如，又有的时候，protobuf 中数据的类型和数据库中的数据类型不能一一对应。比如我曾经想了非常久的时间，思考对于一个 MongoDB 数据，如何在 `Id string` 和 `Id bson.ObjectId` 类型之间转化。事实上 `bson.ObjectId` 就是一个 `string`，所以两个可以简单互换。我之前还遇到过一个问题，那就是

However this approach does have its down-sides. Sometimes its tricky to marshal the code generated by protobuf into a valid database entity. Sometimes database technologies use custom types which are tricky to translate from the native types generated by protobuf. One problem I spent many many hours thinking about was how I could convert Id string to and from Id bson.ObjectId for Mongodb entities. It turns out that bson.ObjectId, is really just a string anyway, so you can marshal them together. Also, mongodb's id index is stored as _id internally, so you need a way to tie that to your Id string field as you can't really do _Id string. Which means finding a way to define custom tags for your protobuf files. But we'll get to that later.

[许多人反对使用 protobuf 中的数据结构来作为数据库中的数据结构](https://www.reddit.com/r/golang/comments/77yd72/question_do_you_use_protobufs_in_place_of_structs/)。因为这样做的话，你的通信和数据存储之间就有很高的耦合性。

通常来说，最好是在 protobuf 和数据库之间提供一层转换的逻辑。但这样做的话，你有可能会转换两个几乎一摸一样的数据结构，比如:
```golang
func (service *Service) (ctx context.Context, req *proto.User, res *proto.Response) error {
  entity := &models.User{
    Name: req.Name.
    Email: req.Email,
    Password: req.Password, 
  }
  err := service.repo.Create(entity)
  ... 
}
```
乍看下，这也不太麻烦。但如果一个数据结构有好几层嵌套时，你就会发现要转换这层层嵌套的数据结构是有多么心烦。

当然了，到底怎么做还是要取决你自己的喜好。我个人觉得为几乎一样的数据结构提供一层转换的逻辑不太有意义。毕竟 protobuf 中的数据结构定义足够严谨，而且我们的业务都是基于它们的，如果在此之上再另起炉灶，感觉是对 protobuf 优点的浪费。所以我个人会使用protobuf 结构作为我们的数据库结构。如果你有什么想法，[请务必告诉我](mailto:ewan.valentine89@gmail.com)，我很想听听大家的想法。

# 完善货运服务

来完善一下我们的第一个微服务吧。首先，让我们试着整理一下项目结构。至今为止，我们把所有的业务逻辑都放在了 main.go 文件中。虽说我们是在写“微”服务，但也不能不讲究规范。规范因人，因项目而易。
我先讲讲我采取的路线我会在货运服务项目下直接新建三个文件：handler.go, datastore.go 以及 repository.go。这对一个微服务来说已经足够了。
有的开发人员可能会下意识的构建一个在传统的，采用 MVC 架构，功能驱动的项目所常采用的结构，即根据功能创建好几个文件夹，然后在文件夹中创建对应的文件，如下：
```
main.go
models/
  user.go
handlers/
  auth.go 
  user.go
services/
  auth.go 
```
这种方式不是太符合 Golang 项目的风格，尤其不符合小型的 Golang 项目。如果你的 Golang 项目足够复杂， 你应该按照下面的方式来构建项目结构：
```
main.go
users/
  services/
    auth.go
  handlers/
    auth.go
    user.go
  users/
    user.go
containers/
  services/
    manage.go
  models/
    container.go
```
这种情况下，项目结构是领域驱动（domain driven）的，而非功能驱动。

我们的微服务本就该简洁，有明确的单一的关注点。配合上 Golang 所强调的简洁性，我才会将所有的文件放在项目的根目录下，同时给每个文件赋上清晰的，自洽的文件名。[MongoDB 的 Golang 库](https://github.com/go-mgo/mgo)就是这种简洁性的代表。同时[这篇文章](https://rakyll.org/style-packages/)很好的介绍了如何才是一个好的 Golang 项目结构。

另外说一点，因为我们不会将多出来的三个文件当作独立的包引入 main.go 中（熟悉 Golang 的你应该清楚这一点），所以在项目编译的时候我们要告诉 go 此项目需要这另外三个文件。因此，我们将修改对应的 Dockerfile 如下：
```yaml
RUN CGO_ENABLED=0 GOOS=linux go build  -o consignment-service -a -installsuffix cgo main.go repository.go handler.go datastore.go
```

好了，进入正题，首先看一下 repository.go 的代码内容，和往常一样，请仔细阅读代码及注释，确保你理解它们干了什么:
```golang
// consignment-service/repository.go
package main

import (
	pb "github.com/EwanValentine/shippy/consignment-service/proto/consignment"
	"gopkg.in/mgo.v2"
)

const (
	dbName = "shippy"
	consignmentCollection = "consignments"
)

type Repository interface {
	Create(*pb.Consignment) error
	GetAll() ([]*pb.Consignment, error)
	Close()
}

type ConsignmentRepository struct {
	session *mgo.Session
}

// Create a new consignment
func (repo *ConsignmentRepository) Create(consignment *pb.Consignment) error {
	return repo.collection().Insert(consignment)
}

// GetAll consignments
func (repo *ConsignmentRepository) GetAll() ([]*pb.Consignment, error) {
  var consignments []*pb.Consignment
  // Find()通常接受一个询问条件(query)，但我们想要所有的货运任务，所以在这里用nil
  // 然后把找到的所有货运任务通过All()赋值给consignment
  // 另外在mgo中，One可以处理单个结果
  err := repo.collection().Find(nil).All(&consignments)
  return consignments, err
}

// Close closes the database session after each query has ran.
// Mgo creates a 'master' session on start-up, it's then good practice
// to copy a new session for each request that's made. This means that
// each request has its own database session. This is safer and more efficient,
// as under the hood each session has its own database socket and error handling.
// Using one main database socket means requests having to wait for that session.
// I.e this approach avoids locking and allows for requests to be processed concurrently. Nice!
// But... it does mean we need to ensure each session is closed on completion. Otherwise
// you'll likely build up loads of dud connections and hit a connection limit. Not nice!
// （我认为作者这里的描述不太准确，且有点混乱，故放上英文原文。）
// Close()会在所有的询问都结束后关闭数据库会话(session)
// Mgo会在程序启动时创建一个'master'会话
// 一个好习惯就是为每一个数据库请求复制一个新的会话
// 这即更安全也更有效率。
// 因为，在底层，每一个数据库会话都有他自己的数据库socket和错误的处理机制(handling)。
// 让每个请求都只使用同一个数据库socket，这意味着某些请求需要等待socket的使用权。
// 这即排除了锁死的可能，也能更好的并发处理数据库请求。
// 随之而来的是，我们要确保每个会话结束后关闭会话，不然等待我们的就是一大堆无用的连接了！
func (repo *ConsignmentRepository) Close() {
	repo.session.Close()
}

func (repo *ConsignmentRepository) collection() *mgo.Collection {
	return repo.session.DB(dbName).C(consignmentCollection)
}
```

如你所见，repository.go 被用于和 Mongodb 数据库交互。我们还需要业务逻辑来创建数据库会话，即datastore.go:

```golang
// consignment-service/datastore.go
package main

import (
	"gopkg.in/mgo.v2"
)

// CreateSession creates the main session to our mongodb instance
func CreateSession(host string) (*mgo.Session, error) {
	session, err := mgo.Dial(host)
	if err != nil {
		return nil, err
	}

	session.SetMode(mgo.Monotonic, true)

	return session, nil
}
```
直截了当。 好了，现在重构我们的 main.go，删除大部分大部分代码，然后引入 MongoDB 库 mgo:
```golang
// consignment-service/main.go
package main

import (
	"fmt"
	"log"

	pb "github.com/EwanValentine/shippy/consignment-service/proto/consignment"
	vesselProto "github.com/EwanValentine/shippy/vessel-service/proto/vessel"
	"github.com/micro/go-micro"
	"os"
)

const (
	defaultHost = "localhost:27017"
)

func main() {

	// Database host from the environment variables
	host := os.Getenv("DB_HOST")

	if host == "" {
		host = defaultHost
	}

	session, err := CreateSession(host)

	// 确保在main退出前关闭会话
	defer session.Close()

	if err != nil {
		log.Panicf("Could not connect to datastore with host %s - %v", host, err)
	}

	// Create a new service. Optionally include some options here.
	srv := micro.NewService(

		// This name must match the package name given in your protobuf definition
		micro.Name("go.micro.srv.consignment"),
		micro.Version("latest"),
	)

	vesselClient := vesselProto.NewVesselServiceClient("go.micro.srv.vessel", srv.Client())

	// Init will parse the command line flags.
	srv.Init()

	// Register handler
	pb.RegisterShippingServiceHandler(srv.Server(), &service{session, vesselClient})

	// Run the server
	if err := srv.Run(); err != nil {
		fmt.Println(err)
	}
}
```

最后，让我们将 main.go 里实现 gRPC 中的 interface 的代码移到单独的 handler.go 中：
```golang
// consignment-service/handler.go

package main

import (
	"log"
	"golang.org/x/net/context"
	pb "github.com/EwanValentine/shippy/consignment-service/proto/consignment"
	vesselProto "github.com/EwanValentine/shippy/vessel-service/proto/vessel"
)

type service struct {
	vesselClient vesselProto.VesselServiceClient
}

// 请注意session.Clone()，为什么要Clone?
func (s *service) GetRepo() Repository {
    return &ConsignmentRepository{s.session.Clone()}
}

func (s *service) CreateConsignment(ctx context.Context, req *pb.Consignment, res *pb.Response) error {
    repo := s.GetRepo()
    defer repo.Close()
	vesselResponse, err := s.vesselClient.FindAvailable(context.Background(), &vesselProto.Specification{
		MaxWeight: req.Weight,
		Capacity: int32(len(req.Containers)),
	})
	log.Printf("Found vessel: %s \n", vesselResponse.Vessel.Name)
	if err != nil {
		return err
	}

	// We set the VesselId as the vessel we got back from our
	// vessel service
	req.VesselId = vesselResponse.Vessel.Id

	// Save our consignment
	err = repo.Create(req)
	if err != nil {
		return err
	}

	// Return matching the `Response` message we created in our
	// protobuf definition.
	res.Created = true
	res.Consignment = req
	return nil
}

func (s *service) GetConsignments(ctx context.Context, req *pb.GetRequest, res *pb.Response) error {
    repo := s.GetRepo()
    defer repo.Close()
	consignments, err := repo.GetAll()
	if err != nil {
		return err
	}
	res.Consignments = consignments
	return nil
}
```
# Copy vs Clone

有心的你肯定注意到了，在 GetRepo() 函数中，我们每次都使用了 Clone() 函数。这是为什么？

从效果上看，我们在创建了 master 会话之后，其实就没有再真正用过它了，因为在之后的每次数据库请求中，我们都首先使用 Clone 生成了一个新的会话。
虽然我在代码中有过一段与之相关的注释，但我觉得有必要在这仔细讨论下原因。当你每次只使用 master 会话来发起请求时时，在底层，你是在用同一个socket的同一个连接。这意味着你的部分请求会被某个正在进行的请求阻塞，这是对 Golang 强大并发能力的浪费。

为了不阻塞请求，mgo 支持使用 Copy() 或者 Clone() 来复制一个会话，这样你就能并发的处理请求了。Copy 和 Clone 功能尽管差不多，但有其细微且重要的区别。Clone 后的会话将使用和 master 会话相同的 socket，但会使用一个新的连接，这既达到了并发的效果，还减少了新创一个 socket 的开销。这点非常适用于那些快速的写入操作。但某些需要长时间处理的操作，比如复杂的询问，大数据操作等，可能会阻塞其他试图使用此 socket 的 goroutine。而 Copy 则是会生成一个新的socket，相对 Clone, 它的开销就稍微大一点了。

通常情况下，包括我们现在的这个业务场景，使用 Clone 就足够了。

# 货船服务

重构完货运服务，你可以用同样的方法重构货船服务。在此我就不讲具体的内容了，你随时可以参考我的项目[源码](https://github.com/EwanValentine/shippy/tree/tutorial-3)。

除了重构，我们还要为货船服务添加一个新的方法，它将能让我们创建新的货船。照例从 probobuf 开始吧：
```protobuf
syntax = "proto3";

package vessel;

service VesselService {
  rpc FindAvailable(Specification) returns (Response) {}
  rpc Create(Vessel) returns (Response) {}
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
  bool created = 3;
}
```
我们新建了一个 `Create` 方法，它接收 Vessel 并获得 Response。注意，我们在 Response 的结构体中加入了一个布尔值 created。运行`make build`来更新gRPC定义。然后，我们将在 handler.go 和 repository.go 中实现它: 
```golang
// vessel-service/handler.go

func (s *service) GetRepo() Repository {
    return &VesselRepository{s.session.Clone()}
}

func (s *service) Create(ctx context.Context, req *pb.Vessel, res *pb.Response) error {
    repo := s.GetRepo()
    defer repo.Close()
	if err := repo.Create(req); err != nil {
		return err
	}
	res.Vessel = req
	res.Created = true
	return nil
}
```

```golang
// vessel-service/repository.go
func (repo *VesselRepository) Create(vessel *pb.Vessel) error {
	return repo.collection().Insert(vessel)
}
```
很激动不是吗，我们居然可以制造货船了！让我们在 main.go 中使用它来创造一些模拟数据吧，具体的代码参见[此处](https://github.com/EwanValentine/shippy/blob/master/vessel-service/main.go)。

大动干戈了这么会，我们终于让微服务用上了 MongoDB。在试着运行它们之前，记得要修改 docker-compose 以引入 Mongodb 的容器：
```yaml
services: 
  ... 
  datastore:
    image: mongo
    ports:
      - 27017:27017
```
同时还得各自为两个微服务更新一个环境变量: `DB_HOST:datastore:27017`。注意到我们使用`datastore` 而不是 `localhost` 作为数据库的主机名。这是因为 docker-compose 有非常聪明的 DNS 逻辑。做完这么多后，你应该有以下文件内容:
```yaml
version: '3.1'

services:

  consignment-cli:
    build: ./consignment-cli
    environment:
      MICRO_REGISTRY: "mdns"

  consignment-service:
    build: ./consignment-service
    ports:
      - 50051:50051
    environment:
      MICRO_ADDRESS: ":50051"
      MICRO_REGISTRY: "mdns"
      DB_HOST: "datastore:27017"

  vessel-service:
    build: ./vessel-service
    ports:
      - 50052:50051
    environment:
      MICRO_ADDRESS: ":50051"
      MICRO_REGISTRY: "mdns"
      DB_HOST: "datastore:27017"

  datastore:
    image: mongo
    ports:
      - 27017:27017

```
`docker-compose build`然后`docker-compose run`来运行更行后的代码。由于 Docker 缓存的缘故，你有时可能得使用 `--no-cache` 选项来告诉 `docker-compose build` 去重新编译所有的东西。

# User Service

这是我们的第三个微服务。在 docker-compose.yaml 中给引入 Postgres:
```yaml
  ...
  user-service:
    build: ./user-service
    ports:
      - 50053:50051
    environment:
      MICRO_ADDRESS: ":50051"
      MICRO_REGISTRY: "mdns"

  ...
  database:
    image: postgres
    ports:
      - 5432:5432
```
在项目的根目录下创建 `user-service` 文件夹，和以前两个微服务一样，创建下面几个文件: handler.go, main.go, repository.go, database.go, Dockerfile, Makefile，然后在proto文件夹下创建 `/user/user.proto`。`user.proto`内容如下：
```golang
syntax = "proto3";

package go.micro.srv.user;

service UserService {
    rpc Create(User) returns (Response) {}
    rpc Get(User) returns (Response) {}
    rpc GetAll(Request) returns (Response) {}
    rpc Auth(User) returns (Token) {}
    rpc ValidateToken(Token) returns (Token) {}
}

message User {
    string id = 1;
    string name = 2;
    string company = 3;
    string email = 4;
    string password = 5;
}

message Request {}

message Response {
    User user = 1;
    repeated User users = 2;
    repeated Error errors = 3;
}

message Token {
    string token = 1;
    bool valid = 2;
    repeated Error errors = 3;
}

message Error {
    int32 code = 1;
    string description = 2;
}
```
确保你像之前的几个微服务一样创建了 Makefile, 那么你现在应该 `make build` 来生成 gRPC 代码了。当然了， 我们要实现其中的方法。在本文里，我只实现部分方法。任何有关验证和JWT的部分都会放在下一篇文章里介绍。你的 handler.go 应该如下:
```golang
// user-service/handler.go
package main

import (
	"golang.org/x/net/context"
	pb "github.com/EwanValentine/shippy/user-service/proto/user"
)

type service struct {
	repo Repository
	tokenService Authable
}

func (srv *service) Get(ctx context.Context, req *pb.User, res *pb.Response) error {
	user, err := srv.repo.Get(req.Id)
	if err != nil {
		return err
	}
	res.User = user
	return nil
}

func (srv *service) GetAll(ctx context.Context, req *pb.Request, res *pb.Response) error {
	users, err := srv.repo.GetAll()
	if err != nil {
		return err
	}
	res.Users = users
	return nil
}

func (srv *service) Auth(ctx context.Context, req *pb.User, res *pb.Token) error {
	user, err := srv.repo.GetByEmailAndPassword(req)
	if err != nil {
		return err
	}
	res.Token = "testingabc"
	return nil
}

func (srv *service) Create(ctx context.Context, req *pb.User, res *pb.Response) error {
	if err := srv.repo.Create(req); err != nil {
		return err
	}
	res.User = req
	return nil
}

func (srv *service) ValidateToken(ctx context.Context, req *pb.Token, res *pb.Token) error {
	return nil
}
```
而你的 repository.go 应该为:
```golang
// user-service/repository.go
package main

import (
	pb "github.com/EwanValentine/shippy/user-service/proto/user"
	"github.com/jinzhu/gorm"
)

type Repository interface {
	GetAll() ([]*pb.User, error)
	Get(id string) (*pb.User, error)
	Create(user *pb.User) error
	GetByEmailAndPassword(user *pb.User) (*pb.User, error)
}

type UserRepository struct {
	db *gorm.DB
}

func (repo *UserRepository) GetAll() ([]*pb.User, error) {
	var users []*pb.User
	if err := repo.db.Find(&users).Error; err != nil {
		return nil, err
	}
	return users, nil
}

func (repo *UserRepository) Get(id string) (*pb.User, error) {
	var user *pb.User
	user.Id = id
	if err := repo.db.First(&user).Error; err != nil {
		return nil, err
	}
	return user, nil
}

func (repo *UserRepository) GetByEmailAndPassword(user *pb.User) (*pb.User, error) {
	if err := repo.db.First(&user).Error; err != nil {
		return nil, err
	}
	return user, nil
}

func (repo *UserRepository) Create(user *pb.User) error {
	if err := repo.db.Create(user).Error; err != nil {
		return err
	}
}
```
我们需要修改 ORM 的行为，从而在创建ORM时生成一个[UUID](https://en.wikipedia.org/wiki/Universally_unique_identifier)，而不是一个整型ID。如果你不知道的话，UUID 是随机生成的一个集合，其元素都是用'-'串联的字符串，被用于当作ID或者主要标识。他比递增的ID更加安全，因为他能防止别人猜到或者追踪到你的API端点。MongoDB 本身使用了此技术的一个变种，但是我们必须自己告诉 Postgres 去使用 UUID。于是，在 `user-service/proto/user`下新建 `extension.go`，内容如下：
```golang
package go_micro_srv_user

import (
	"github.com/jinzhu/gorm"
	"github.com/satori/go.uuid"
)

func (model *User) BeforeCreate(scope *gorm.Scope) error {
	uuid := uuid.NewV4()
	return scope.SetColumn("Id", uuid.String())
}
```
这深入到了 GORM 的[时间生命周期](http://jinzhu.me/gorm/callbacks.html)之中，在每个实例创建之前为其生成一个UUID作为ID列。

你可能会注意到，不像使用 MongoDB 的微服务，我们在这里不需要处理任何关于连接的操作。原生的 SQL/postgres 驱动有着不一样的行为模式，所以我们这回不需要去管这些事情。现在让我们稍微了解下用到的 `gorm` 库。

# Gorm = Go + ORM

[Gorm](http://jinzhu.me/gorm/)是个相当轻量的对象关系映射(Object-Relational Mapping)，很适合 Postgres, MySQL 或者 Sqlite等数据库。它让你轻松的生成，使用和管理你的数据库格式变化。

纵然简单，但你不一定要用任何形式的 ORM，毕竟我们在实现微服务，它的数据结构应该更加简单，没有那么多复杂性。

我们需要测试一下能否创建用户，所以让我们创建另一个命令行工具。在项目根目录下创建`user-cli`目录，并生成 `cli.go`如下：
```golang
package main

import (
	"log"
	"os"

	pb "github.com/EwanValentine/shippy/user-service/proto/user"
	microclient "github.com/micro/go-micro/client"
	"github.com/micro/go-micro/cmd"
	"golang.org/x/net/context"
	"github.com/micro/cli"
	"github.com/micro/go-micro"
)


func main() {

	cmd.Init()

	// Create new greeter client
	client := pb.NewUserServiceClient("go.micro.srv.user", microclient.DefaultClient)
    
    // Define our flags
	service := micro.NewService(
		micro.Flags(
			cli.StringFlag{
				Name:  "name",
				Usage: "You full name",
			},
			cli.StringFlag{
				Name:  "email",
				Usage: "Your email",
			},
			cli.StringFlag{
				Name:  "password",
				Usage: "Your password",
			},
			cli.StringFlag{
				Name: "company",
				Usage: "Your company",
			},
		),
	)
    
    // Start as service
	service.Init(

		micro.Action(func(c *cli.Context) {

			name := c.String("name")
			email := c.String("email")
			password := c.String("password")
			company := c.String("company")

            // Call our user service
			r, err := client.Create(context.TODO(), &pb.User{
				Name: name,
				Email: email,
				Password: password,
				Company: company,
			})
			if err != nil {
				log.Fatalf("Could not create: %v", err)
			}
			log.Printf("Created: %s", r.User.Id)

			getAll, err := client.GetAll(context.Background(), &pb.Request{})
			if err != nil {
				log.Fatalf("Could not list users: %v", err)
			}
			for _, v := range getAll.Users {
				log.Println(v)
			}

			os.Exit(0)
		}),
	)

	// Run the server
	if err := service.Run(); err != nil {
		log.Println(err)
	}
}
```
运行
```bash
$ docker-compose run user-cli command \
  --name="Ewan Valentine" \
  --email="ewan.valentine89@gmail.com" \
  --password="Testing123" \
  --company="BBC"
```
你就应该能看到被创建的用户了！

可以看到创建的流程一点都不安全，因为我们是明文保存的密码。在下一文章中，我们就聊聊如何在微服务中实现认证和JWT。

太好了，我们这回多了一个新的微服务和命令行工具，同时还使用了两种数据库技术来保存我们的数据。如果你觉得这节东西讲得太快且太多，我报以诚挚的歉意。如果你有任何问题，欢迎给我[发邮件](mailto:ewan.valentine89@gmail.com)！

如果你觉得这篇文章对你有所帮助，你可以请原作者喝杯咖啡！链接如下：[https://monzo.me/ewanvalentine](https://monzo.me/ewanvalentine)
你也可以在[patreon](https://www.patreon.com/ewanvalentine)上支持原作者！

我们下回见！
