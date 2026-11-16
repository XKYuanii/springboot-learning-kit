# 任务 1 ~ 项目搭建

本节包含环境配置说明以及如何在本地设备上运行该应用程序。我们来了解一下前置要求以及如何在本地配置该项目。

- **强烈推荐使用 IntelliJ IDEA 来进行此项目的开发。**
- **请阅读 [README](../../README.md) 文件了解前置要求。**

---

**_注意：_** _养成良好的习惯，切勿在代码中硬编码用于测试和生产环境的凭证信息。始终使用环境变量或配置文件来管理敏感信息。随着项目的推进，我们将看到如何配置这些内容。_

---

### **启动数据库与消息中间件**

在项目根目录下执行以下命令：
```bash
  docker compose up -d
```
该命令将拉取 3 个镜像并在你的机器上启动 3 个容器，即 **order_service_db**、**activemq_broker** 和 **rabbitmq_broker**。
这些容器的配置保存在 [compose.yaml](../../compose.yaml) 文件中。该文件定义了使用哪个镜像、暴露哪些端口以及设置哪些环境变量。

---

### 如何验证所有容器已正常运行？
你可以运行以下命令列出机器上的所有活动容器：
```bash
  docker ps
```

---

### **停止运行中的容器**
要停止所有运行中的容器，你可以通过 Docker Desktop UI 操作，也可以在项目根目录下运行以下命令：
```bash
  docker compose down
```

---

### **使用 Liquibase 创建数据库表**

验证数据库容器正常运行后，你需要创建数据库表。只需运行以下命令即可完成：
```bash
  ./gradlew update
```
该命令会触发 Liquibase，它会从 [db.changelog-master.xml](../../src/main/resources/db/changelog/db.changelog-master.xml) 读取变更日志（changelog），并在数据库中创建必要的表。你可以看到该文件包含了对其他 changelog 的引用，每个 changelog 负责创建对应的表。

---

### **查询 PostgreSQL 数据库**

如果你使用的是 IntelliJ IDEA Ultimate，可以使用其内置的数据库工具来查询数据库表。否则，你可以使用 DBeaver 或任何你喜欢的数据库客户端。只需使用以下凭据连接到数据库：
- **数据库名称（Database Name）**: `Order_Service`
- **主机（Host）**: `localhost`
- **端口（Port）**: `5432`
- **用户名（Username）**: `user`
- **密码（Password）**: `password`

在本练习中，我将使用 DBeaver：

![img.png](../resources/dbeaver_setup.png)

你应该能够在 `public` 模式（schema）下查看数据表：

![img.png](../resources/dbeaver_database_view.png)

---

### 运行应用程序
现在你可以运行应用程序了。可以通过不同的方式进行：

**使用 IntelliJ IDEA**：
   - 导航至 [SpringBootLearningKitApplication](../../src/main/java/com/springboot/learning/kit/SpringBootLearningKitApplication.java) 类。
   - 右键点击该类，选择 `Run 'SpringBootLearningKitApplication.main()'`.

**使用命令行**：
   - 导航到项目根目录。
   - 运行以下命令：`./gradlew bootRun`

---

### Spring Boot 配置文件
Spring Boot 使用 `application.properties` 或 `application.yml` 文件将配置外部化，从而轻松管理特定环境的设置（如数据库 URL、端口和特性开关等）。这种方法通过将配置与业务逻辑分离，提升了代码的清晰度与灵活性。配置外部化后，无需修改代码即可轻松在不同环境（dev、test、prod）之间切换。

我们有 [application.properties](../../src/main/resources/application.properties) 文件，应用程序始终会加载该文件，其中包含所有环境通用的公共属性。这种分离方式使你能够隔离特定环境的设置，同时保持共享配置的整洁和集中管理。

此外还有 [application-local.properties](../../src/main/resources/application-local.properties) 文件，用于存放本地环境的属性值。你会看到所有 URL 都指向 `localhost` 等。

然后是 [application-prod.properties](../../src/main/resources/application-prod.properties) 文件，用于存放生产环境的属性值。你会看到所有 URL 都与本地环境不同。

运行应用程序时，我们可以直接向 Spring Boot 传递环境变量，以便为当前环境使用正确的属性文件。

本地开发环境：
```bash
  ./gradlew bootRun -Dspring.profiles.active=local
```
生产环境：
```bash
  ./gradlew bootRun -Dspring.profiles.active=prod
```

当 Spring Boot 应用启动时，你可以在第二行日志中看到所选的 profile：
```text
[SpringBootLearningKit] [           main] c.s.l.k.SpringBootLearningKitApplication : Starting SpringBootLearningKitApplication using Java 17.0.13 with PID 61942
[SpringBootLearningKit] [           main] c.s.l.k.SpringBootLearningKitApplication : The following 1 profile is active: "local"
[SpringBootLearningKit] [           main] .s.b.d.c.l.DockerComposeLifecycleManager : Using Docker Compose file springboot-learning-kit/compose.yaml
[SpringBootLearningKit] [           main] .s.b.d.c.l.DockerComposeLifecycleManager : There are already Docker Compose services running, skipping startup
```

**⚠️ 注意：**
在此项目中，`application.properties` 中已将 `local` profile 设置为默认值。这意味着如果你在运行应用程序时未指定任何 profile，它将始终回退到 `local` profile。

![img.png](../resources/task1_showing_default_profile.png)

---

### **验证应用程序运行健康**

将 [Bruno Collection](../../docs/SpringBoot%20Learning%20Kit%20-%20APIs) 导入到你的 Bruno API 客户端中。你可以参考[这里](https://docs.usebruno.com/get-started/import-export-data/import-collections)的说明。

现在，你可以调用健康检查（HealthCheck）API 来验证应用程序是否已启动并运行。你应该会收到如下响应：

![img.png](../resources/healthCheck_response.png)

✅ 这表明应用程序已成功连接到数据库和消息代理。

### **消息代理管理控制台（UI）**

#### **RabbitMQ**

你可以使用以下凭据访问 RabbitMQ 管理控制台：[http://localhost:15672](http://localhost:15672)
- **用户名**: `user`
- **密码**: `password`

你可以在界面上看到一个队列（queue）和一个死信队列（dlq）。点击队列还可以查看活跃的消费者（Spring Boot 应用程序）。

![img.png](../resources/rabbitmq_intro_pic.png)

#### **ActiveMQ**
你可以使用以下凭据访问 ActiveMQ 管理控制台：[http://localhost:8161/admin/queues.jsp](http://localhost:8161/admin/queues.jsp)
- **用户名**: `admin`
- **密码**: `admin`

你可以在界面上看到一个队列和一个死信队列。在 "No. of Consumers" 列下应该能看到 1 个活跃消费者。

![img.png](../resources/activemq_ui_intro.png)

---

### **实用的 IntelliJ 插件推荐**
- **Lombok**：确保在 IntelliJ 中安装了 Lombok 插件。这将支持 getter、setter 和其他注解的代码自动生成。
- **Pretty JSON Log**：在 IntelliJ 中运行应用程序时，该插件以易读的格式展示 JSON 格式的日志。
- **Rainbow Brackets**：该插件为括号添加彩虹颜色，使阅读嵌套代码更加容易。
- **SonarQube For IDE**：该插件在你编写代码时提供代码质量和安全问题的实时反馈。
- **Mermaid**：该插件允许你使用简单的类似 Markdown 的语法创建图表和流程图。你可以用它来可视化数据库表结构或任何其他图表。

### **IntelliJ 常用快捷键**

IntelliJ 提供了丰富的功能让你的开发体验更流畅。以下是一些实用提示：
- **全局搜索（Find in Project）**：使用 `Ctrl + Shift + F` (Windows/Linux) 或 `Cmd + Shift + F` (Mac) 在整个项目中搜索文本。
- **代码格式化（Code Formatting）**：使用 `Ctrl + Alt + L` (Windows/Linux) 或 `Cmd + Option + L` (Mac) 格式化代码。
- **重构（Refactoring）**：使用 `Shift + F6` 重命名变量或方法，并自动更新所有引用。
- **版本控制（Version Control）**：如果你使用 Git，IntelliJ 拥有内置的版本控制支持。你可以直接在 IDE 中提交更改、查看历史记录并解决合并冲突。
- **终端（Terminal）**：IntelliJ 拥有内置终端，让你无需离开 IDE 即可运行 shell 命令。点击窗口底部的 `Terminal` 标签即可访问。

---

### 任务完成
现在你已经拥有一个完全正常运行的 Spring Boot 应用程序，并已配置好 PostgreSQL 和 RabbitMQ/ActiveMQ。如果你愿意，现在就可以开始探索 API 和消息队列功能了。
