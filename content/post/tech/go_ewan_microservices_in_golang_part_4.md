---
title: "[译]用GoLang实现微服务（四）"
date: 2018-04-17T18:11:32+08:00
lastmod: 2018-05-14T18:11:32+08:00
draft: false
keywords: ["golang", "microservices", "google", "go", "programming", "grpc", "protobuf", "prot", "proto"]
description: "系列文章的第四篇，讲述用Go实现微服务，同时会用到诸如Docker, Kubernetes, CircleCI, go-micro, MongoDB等技术"
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

__*此系列文章介绍如何用GoLang实践微服务, 分十篇。此为其四。*__   
__*原著作者：[Ewan Valentine](https://ewanvalentine.io/)*__   
__*原文连接：[https://ewanvalentine.io/microservices-in-golang-part-3/](https://ewanvalentine.io/microservices-in-golang-part-4/)*__    
__*友情提示：系列文章的后五篇翻译请移步至[wuYin's blog](https://wuyin.io)*__

~~___初稿___~~ -> ___润色___

在[上一篇文章中](https://blog.dingkewz.com/post/tech/go_ewan_microservices_in_golang_part_3/), 我们创建用户(User)服务，并且引入了数据库来保存数据。这回，我们希望用户微服务能安全的保存用户密码，并且有完整的机制来验证用户，从而在我们的几个微服务之间分发安全秘钥以互相沟通。

请特别注意，我重构了项目结构，现在每个微服务都是一个单独的仓库，不再共处于一个父目录之下了。这样做更方便于代码的部署。你们大概记得，我一开始是想把所有微服务都放在一个仓库下的，但后来发现这样做使我很难管理 Go 项目的依赖，总是遇到一些冲突。随着每个项目的独立，我有必要讲讲如何测试，运行和部署一个个微服务。与此同时，由于各个微服务的独立，我们目前也不能使用 docker-compose 了，但这对我们的影响暂时不大。如果你对此有什么好的建议，欢迎给我[写邮件](mailto:ewan.valentine89@gmail.com)。

此外，你需要手动运行数据库了，就像下面这样:
```bash
$ docker run -d -p 5432:5432 postgres
$ docker run -d -p 27017:27017 mongo
```

独立出来的项目代码链接如下:

* [https://github.com/EwanValentine/shippy-consignment-service](https://github.com/EwanValentine/shippy-consignment-service)
* [https://github.com/EwanValentine/shippy-user-service](https://github.com/EwanValentine/shippy-user-service)
* [https://github.com/EwanValentine/shippy-vessel-service](https://github.com/EwanValentine/shippy-vessel-service)
* [https://github.com/EwanValentine/shippy-user-cli](https://github.com/EwanValentine/shippy-user-cli)
* [https://github.com/EwanValentine/shippy-consignment-cli](https://github.com/EwanValentine/shippy-consignment-cli)

<!--more-->

# 保存用户密码

首先，我们要更新用户微服务的句柄，从而将用户的密码以哈希值的形式保存下来。你可能会想这不是废话吗，当然不能存明文！但即使如此强调，但还是有项目明文存储密码啊！
```golang
// shippy-user-service/handler.go
... 
func (srv *service) Auth(ctx context.Context, req *pb.User, res *pb.Token) error {
	log.Println("Logging in with:", req.Email, req.Password)
	user, err := srv.repo.GetByEmail(req.Email)
	log.Println(user)
	if err != nil {
		return err
	}

	// Compares our given password against the hashed password
	// stored in the database
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		return err
	}

	token, err := srv.tokenService.Encode(user)
	if err != nil {
		return err
	}
	res.Token = token
	return nil
}

func (srv *service) Create(ctx context.Context, req *pb.User, res *pb.Response) error {

	// Generates a hashed version of our password
	hashedPass, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	req.Password = string(hashedPass)
	if err := srv.repo.Create(req); err != nil {
		return err
	}
	res.User = req
	return nil
}
```
如你所见，我们在创建新用户之前，会先将其密码哈希化，并以此哈希值作为其实际密码。除此之外，在认证的时候，我们是以此哈希值做匹配的。

至此，我们可以确信的通过数据库比对用户。我们需要一个机制来在各个服务和用户界面随时随地的使用此能力。虽然有很多解决方案，但我所知最简单的一个方案就是使用[JWT](https://jwt.io/)。

在我们继续之前，请务必查看一下 Dockerfile 和 Makefile 文件的些许变化。新的 Git 项目结构意味着新的依赖引入语句。

# JWT
[JWT](https://jwt.io/) 代表 JSON Web Token，是一个分布式的安全协议。和Oauth相似，协议使用算法为一个用户生成唯一的哈希值，然后使用此哈希值来比对用户。不仅如此，此哈希值包含了用户的元信息，因此，它也可以成为另一个 Token 的一部分。让我们看一个具体的 JWT 例子：
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ
```
此 Token 被 `.` 分割成三个部分。每个部分都有其重要性。第一部分包含了用于描述 Token 自身的元数据，包括其类型，所用的算法。客户端将以此信息来解析它。第二个部分包含了用户自定义的元数据，可以是用户的细节信息，一个过期时间，或者任何你想得到的信息。最后一个部分是验证签名，我们能用它验证此 Token 在传输的过程中未被修改。

当然了，JWT有其缺点和风险，[这篇文章](http://cryto.net/~joepie91/blog/2016/06/13/stop-using-jwt-for-sessions/)对此做了非常好的总结。我也建议你读一下[这篇文章](https://www.owasp.org/index.php/JSON_Web_Token_(JWT)_Cheat_Sheet_for_Java)来学习确保安全性的最佳实践。

说到安全性的最佳实践，有一点我想特别强调一下，那就是在生成 Token 时使用用户的 IP 地址。这能防止另一个人在盗取你的 Token 后在另一个设备上使用。同时请确保你使用Https，它的加密信道可以有效防止中间人攻击。

我们可以将用于生成 JWT 的众多算法大致分为两个类别，即对称和非对称。对称算法就像我们现在用的，加密和解密使用的是同一个秘钥。非对称算法则使用公钥和私钥进行验证。非对称算法非常适合于在多个服务间进行认证。

下面的两个链接将提供更多的资源:

* [Autho](https://auth0.com/blog/json-web-token-signing-algorithms-overview/)
* [RFC spec for algorithms](https://tools.ietf.org/html/rfc7518#section-3)

既然我们已经大致了解了 JWT，那是时候在 token_service.go 中小试牛刀了。我们将使用 `github.com/dgrijalva/jwt-go` 来帮助我们实现 JWT，这个库同时还有很多非常棒的实例可供我们参考。

```golang
// shippy-user-service/token_service.go
package main

import (
    "time"

    pb "github.com/EwanValentine/shippy-user-service/proto/user"
    "github.com/dgrijalva/jwt-go"
    )

var (

    // 定义一个安全秘钥，它将用于生成我们的token
    // 在您实际的使用中，请务必使用一个更安全的方法来
    // 生成此安全秘钥，比如 md5。
    key = []byte("mySuperSecretKeyLol")
    )

// CustomClaims 是一个自定义的元数据，它的哈希值会被当作JWT的第二部分
type CustomClaims struct {
  User *pb.User
    jwt.StandardClaims
}

type Authable interface {
  Decode(token string) (*CustomClaims, error)
    Encode(user *pb.User) (string, error)
}

type TokenService struct {
  repo Repository
}

// 将一个 token 字符串解码成 token 对象
func (srv *TokenService) Decode(tokenString string) (*CustomClaims, error) {

  // 解析 token
  token, err := jwt.ParseWithClaims(tokenString, &CustomClaims{}, func(token *jwt.Token) (interface{}, error) {
      return key, nil
      })

  // 验证 token 并且返回自定义的 claims
  if claims, ok := token.Claims.(*CustomClaims); ok && token.Valid {
    return claims, nil
  } else {
    return nil, err
  }
}

// 将一个 claim 编程成一个 JWT
func (srv *TokenService) Encode(user *pb.User) (string, error) {

expireToken := time.Now().Add(time.Hour * 72).Unix()
  // 生成 claims
  claims := CustomClaims{
   user,
     jwt.StandardClaims{
  ExpiresAt: expireToken,
  Issuer:    "go.micro.srv.user",
     },
  }

  // 生成 token
  token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

  // 返回签名后的 token 
  return token.SignedString(key)
}
```
一如既往，我把许多的细节都写在了代码注释中。总的来说，Decode 接受一个字符串 token，将其解析成 token 对象，随之认证，最后如果认证通过，则返回 claim。我们可以使用这 claim 中包含的用户元数据来认证用户。

Encode 恰好与 Decode 相反，它接收你自定义的元数据，将其哈希成一个JWT，并返回它。

请注意我们在文件开头定义了一个 'key' 变量，这是我们的安全秘钥，请在生产环境中务必使用更为安全的方法生成此安全秘钥！

恭喜，我们现在有了一个微服务可以用于认证 token。

让我们再更新一下 user-cli 吧。在这一版代码中，我将其精简成了一个单纯的脚本，不接收任何参数，且只返回一个固定的token。但这是暂时的，在以后我会来优化此脚本。我们就暂时使用它来做测试之用吧！
```golang
// shippy-user-cli/cli.go
package main

import (
	"log"
	"os"

	pb "github.com/EwanValentine/shippy-user-service/proto/user"
	micro "github.com/micro/go-micro"
	microclient "github.com/micro/go-micro/client"
	"golang.org/x/net/context"
)

func main() {

	srv := micro.NewService(

		micro.Name("go.micro.srv.user-cli"),
		micro.Version("latest"),
	)

	// Init will parse the command line flags.
	srv.Init()

	client := pb.NewUserServiceClient("go.micro.srv.user", microclient.DefaultClient)

	name := "Ewan Valentine"
	email := "ewan.valentine89@gmail.com"
	password := "test123"
	company := "BBC"

	r, err := client.Create(context.TODO(), &pb.User{
		Name:     name,
		Email:    email,
		Password: password,
		Company:  company,
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

	authResponse, err := client.Auth(context.TODO(), &pb.User{
		Email:    email,
		Password: password,
	})

	if err != nil {
		log.Fatalf("Could not authenticate user: %s error: %v\n", email, err)
	}

	log.Printf("Your access token is: %s \n", authResponse.Token)

	// let's just exit because
	os.Exit(0)
}
```
你瞧，代码中我们写死了几个变量(name, email, password, company)，请用你认为合适的值替换它们，并运行`make build & make run`，你应该获得一个 token。请保存好这个 token, 你很快就会用到它的！

现在让我们更新 consignment-cli, 从而让它接受一个字符串token，并将其传入我们 consignment-service 的上下文中。
```golang
// shippy-consignment-cli/cli.go
...
func main() {

  cmd.Init()

    // Create new greeter client
    client := pb.NewShippingServiceClient("go.micro.srv.consignment", microclient.DefaultClient)

    // Contact the server and print out its response.
    file := defaultFilename
    var token string
    log.Println(os.Args)

    if len(os.Args) < 3 {
      log.Fatal(errors.New("Not enough arguments, expecing file and token."))
    }

  file = os.Args[1]
    token = os.Args[2]

    consignment, err := parseFile(file)

    if err != nil {
      log.Fatalf("Could not parse file: %v", err)
    }

  // 创建一个包含自定义token 的上下文
  // 这个上下文会在我们调用consignment-service时被传入
  ctx := metadata.NewContext(context.Background(), map[string]string{
  "token": token,
  })

   // First call using our tokenised context
   r, err := client.CreateConsignment(ctx, consignment)
     if err != nil {
       log.Fatalf("Could not create: %v", err)
     }
   log.Printf("Created: %t", r.Created)

     // Second call
     getAll, err := client.GetConsignments(ctx, &pb.GetRequest{})
     if err != nil {
       log.Fatalf("Could not list consignments: %v", err)
     }
   for _, v := range getAll.Consignments {
     log.Println(v)
   }
}
```
现在，consignment-service 需要监听任何使用token 请求，并将其传入 user-service：
```golang
// shippy-consignment-service/main.go
func main() {
  ... 
    // Create a new service. Optionally include some options here.
    srv := micro.NewService(

        // This name must match the package name given in your protobuf definition
        micro.Name("go.micro.srv.consignment"),
        micro.Version("latest"),
        // Our auth middleware
        micro.WrapHandler(AuthWrapper),
        )
    ...
}

... 

// AuthWrapper 是一个高阶函数，它接受一个函数A，且返回一个函数B。其返回值函数接受三个参数：
// context, request 以及 response interface.
// Token 值提取于consignment-ci中定义的上下文。我们将使用 user-service 认证这个 token.
// 如果认证通过，那么函数A会被执行，否则将返回错误。
func AuthWrapper(fn server.HandlerFunc) server.HandlerFunc {
  return func(ctx context.Context, req server.Request, resp interface{}) error {
    meta, ok := metadata.FromContext(ctx)
    if !ok {
      return errors.New("no auth meta-data found in request")
    }

    // Note this is now uppercase (not entirely sure why this is...)
    token := meta["Token"]
    log.Println("Authenticating with token: ", token)

    // Auth here
    authClient := userService.NewUserServiceClient("go.micro.srv.user", client.DefaultClient)
    _, err := authClient.ValidateToken(context.Background(), &userService.Token{
      Token: token,
      })
    if err != nil {
      return err
    }
    err = fn(ctx, req, resp)
    return err
  }
}
```
让我们使用一下 consignment-cli吧。步入我们全新的 shippy-consignmnt-cli 文件夹并运行 `make build` 来构建一个全新的 docker 镜像:
```bash
$ make build
$ docker run --net="host" \
 -e MICRO_REGISTRY=mdns \
      consignment-cli consignment.json \
      <TOKEN_HERE>
```
请注意我们使用了 `--net="host"` 来运行我们的 docker 镜像。它让 docker 运行在我们的本地网络，即 127.0.0.1 或者 localhost，而不是一个 docker 的内部网络。如此，你便不需要进行端口的映射了，即你只需要指定 `-p 8080` 而非 `-p 8080:8080`。你可以在这里参考 [docker 网络的更多细节](https://docs.docker.com/engine/userguide/networking/)。

如果你执行了上述命令，你将看到一个新的consignment被创建出来。 试着从安全秘钥中删除几个字符，再运行上述命令，不出意外，你将收获一个错误。

好了，我们终于创建了一个 JWT 服务以及一个用于认证 JWT 秘钥的中间层来认证我们的用户。如果你不想使用 go-micro，而是使用原生的 grpc, 你需要将你的中间件改成下面的样子:
```golang
func main() {
    ... 
    myServer := grpc.NewServer(
        grpc.UnaryInterceptor(grpc_middleware.ChainUnaryServer(AuthInterceptor),
    )
    ... 
}

func AuthInterceptor(ctx context.Context, req interface{}, info *grpc.UnaryServerInfo, handler grpc.UnaryHandler) (interface{}, error) {

    // Set up a connection to the server.
    conn, err := grpc.Dial(authAddress, grpc.WithInsecure())
    if err != nil {
        log.Fatalf("did not connect: %v", err)
    }
    defer conn.Close()
    c := pb.NewAuthClient(conn)
    r, err := c.ValidateToken(ctx, &pb.ValidateToken{Token: token})

    if err != nil {
	    log.Fatalf("could not authenticate: %v", err)
    }

    return handler(ctx, req)
}
```
上面的代码并不能很好的运行在本地网络。但我们并不需要在本地运行每一个微服务。微服务之间需要相互独立，且每个都能在隔离的环境中被测试。具体到当前的例子，我们可能不希望运行 auth-service。我认为在代码中能暂时关闭或开启某项服务是一个好点子。

比如我在 user-service 中使用了一个控制变量`DISABLE_AUTH`来控制是否使用 auth-service。
```golang
// shippy-user-service/main.go
...
func AuthWrapper(fn server.HandlerFunc) server.HandlerFunc {
	return func(ctx context.Context, req server.Request, resp interface{}) error {
        // This skips our auth check if DISABLE_AUTH is set to true
		if os.Getenv("DISABLE_AUTH") == "true" {
			return fn(ctx, req, resp)
		}
		...
	}
}
```
我们可以在 Makefile 中定义这个控制变量:
```golang
// shippy-user-service/Makefile
...
run:
	docker run -d --net="host" \
		-p 50052 \
		-e MICRO_SERVER_ADDRESS=:50052 \
		-e MICRO_REGISTRY=mdns \
		-e DISABLE_AUTH=true \
		consignment-service
```
这个方法能让你的一些微服务在本地运行与测试。当然了，有很多实现此功能的方法，我个人认为上面的方法是最简单的。同时，如果你对如何让一个单一仓库在本地运行有任何建议，请务必告诉我，不胜感激！

任何漏洞，错误或者反馈，欢迎你通过邮件[告诉我](mailto: ewan.valentine89@gmail.com)。

如果你觉得这篇文章对你有所帮助，你可以请原作者喝杯咖啡！链接如下：[https://monzo.me/ewanvalentine](https://monzo.me/ewanvalentine)
你也可以在[patreon](https://www.patreon.com/ewanvalentine)上支持原作者！
