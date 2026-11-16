# 任务 11 ~ 应用程序负载压测

既然我们已经通过 Prometheus 和 Grafana 建立了监控和可视化体系，现在是时候验证我们的应用程序在各种负载条件下的性能表现了。负载测试是一项至关重要的实践，它有助于确保我们的 Spring Boot 应用程序能够承受预期的流量规模，并在潜在的性能瓶颈影响生产用户之前将其识别出来。

[Apache JMeter](https://jmeter.apache.org/) 是一款功能强大、开源的负载测试工具，能够在服务器、网络或对象上模拟高并发高负载，以测试其承受能力并分析在不同负载类型下的整体性能表现。JMeter 凭借其灵活性、丰富的协议支持和完善的测试报告功能，在行业内得到了极其广泛的应用。

在生产环境中，负载压测对于以下方面不可或缺：

- **性能验证**：确保应用程序在预期负载下满足性能要求
- **容量规划**：确定最大用户承载量与最佳资源分配策略
- **瓶颈识别**：在真实用户受影响之前发现潜在的性能瓶颈
- **回归测试**：验证新的代码改动不会导致系统性能劣化
- **基础设施选型**：为部署基础设施匹配合理规模，实现成本最优化
- **压力极限测试**：探究应用程序在濒临崩溃临界点时的极限行为

---

## 业界主流的负载测试工具

### 常用压测工具概览：

1. **Apache JMeter**：开源、基于 Java、支持 GUI 可视化与命令行无界面模式
2. **Gatling**：高性能、基于 Scala/Java、对 CI/CD 流水线集成非常友好
3. **Artillery**：现代、基于 Node.js、云原生架构负载测试
4. **K6**：以开发者为中心、基于 JavaScript/Go、提供卓越的开发体验
5. **LoadRunner**：企业级商用方案，拥有最广泛的协议支持（商业收费）
6. **Locust**：基于 Python、支持分布式测试、非常易于脚本化编写
7. **NBomber**：基于 .NET 的响应式负载测试框架
8. **WebLOAD**：具备高级分析功能的企业级解决方案（商业收费）

### 为什么本教程选择 JMeter：

- **完全免费**：100% 开源且零授权成本
- **功能完备的 GUI 界面**：直观易用的测试计划（Test Plan）可视化创建界面
- **广泛的协议支持**：HTTP、HTTPS、SOAP、REST、FTP、JDBC 数据库直连等
- **强大的扩展性**：拥有成熟的插件生态系统，支持自定义脚本扩展

---

## 步骤 1：安装 Apache JMeter

### **macOS 安装**

#### 使用 Homebrew（推荐）
```bash
# 如果尚未安装 Homebrew，请先安装
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装 JMeter
brew install jmeter
```

### **Windows 安装**

请参考此教程了解如何在 Windows 上安装 JMeter：[JMeter Windows 安装指南](https://www.simplilearn.com/tutorials/jmeter-tutorial/jmeter-installation)。

⚠️ _下载官方二进制压缩包（zip），解压后运行 `bin/jmeter.bat` 即可启动，非常简单方便。_

### **Linux (Ubuntu/Debian) 安装**

#### 方式 1：使用包管理器
参考指南：[Linux JMeter 安装指南](https://dev.to/hitjethva/how-to-install-apache-jmeter-on-ubuntu-20-04-2di9)。

#### 方式 2：使用 Snap
```bash
  sudo snap install jmeter
```

### **验证安装**
```bash
    # 检查 JMeter 版本
    jmeter --version
    
    # 终端输出大致如下：
    # Copyright (c) 1999-2023 The Apache Software Foundation
    # Version 5.6.2
```

### **启动 JMeter GUI**

```bash
  jmeter
```

启动 JMeter GUI 后，界面大致如下：
![img.png](../resources/task11_launchingJmeter.png)

---

## 步骤 2：理解 JMeter 核心组件

### **JMeter 关键概念：**

1. **Test Plan（测试计划）**：所有测试组件的最顶层根容器
2. **Thread Group（线程组）**：模拟并发用户，定义施压负载模型
3. **Samplers（取样器）**：负责执行实际的网络请求（HTTP、FTP、JDBC 等）
4. **Listeners（监听器）**：收集、统计并展示测试结果
5. **Timers（定时器）**：控制请求之间的思考时间（Think Time）与节奏
6. **Assertions（断言）**：校验响应内容、状态码是否符合预期
7. **Configuration Elements（配置元件）**：设置通用变量、请求头及默认参数
8. **Pre/Post Processors（前置/后置处理器）**：在请求发出前或响应返回后对数据进行加工提取

---

## 步骤 3：创建你的第一个负载测试计划

### **启动你的 Spring Boot 应用程序**

首先，确保你的 **Spring Boot 应用程序处于运行状态！**

### **步骤 3.1：创建测试计划**

1. JMeter 启动时会自带一个默认的 Test Plan。
2. 右键点击 "Test Plan" → Add → Threads (Users) → Thread Group。
3. 将其重命名为 "Order Service Load Test"。

### **步骤 3.2：配置线程组（Thread Group）**

在线程组中配置以下参数：

- **Number of Threads (users)（并发用户数）**: 10
- **Ramp-up period (seconds)（加压爬坡时间）**: 10
- **Loop Count（循环次数）**: 5

此配置的含义是：
- 模拟 10 个并发用户
- 在 10 秒内逐步将负载拉升至 10 个并发线程
- 每个线程循环执行测试 5 次

### **步骤 3.3：添加 HTTP 请求取样器（HTTP Request Sampler）**

1. 右键点击 Thread Group → Add → Sampler → HTTP Request。
2. 配置 HTTP 请求属性：
   - **Name**: `Place New Orders`
   - **Server Name or IP**: `localhost`
   - **Port Number**: `8080`
   - **HTTP Request Method**: `POST`
   - **Path**: `OrderService/order/submit`
   - **Body Data**:
```json
{
   "uuid": "${__time(,)}${__Random(100,999)}",
   "orderType": "ONLINE",
   "customerDetails": {
      "name": "John Doe",
      "email": "john.doe@email.com",
      "phone": "+1234567890"
   },
   "customerAddress": {
      "street": "123 Main St",
      "city": "New York",
      "state": "NY",
      "zipCode": "10001",
      "country": "USA"
   },
   "orderItems": [
      {
         "productId": 1,
         "quantity": 2,
         "pricePerUnit": 29.99
      },
      {
         "productId": 2,
         "quantity": 1,
         "pricePerUnit": 49.99
      }
   ],
   "orderAmount": 109.97,
   "currency": "USD"
}
```

**提示** ⚠️ 你可以看到我使用了 JMeter 内置函数 `${__time(,)}${__Random(100,999)}` 来为每个订单动态生成唯一的 UUID。这确保了每个请求都是独立唯一的，避免因主键重复导致冲突。

HTTP 请求配置应如下所示：
![img.png](../resources/task11_jmeter_httpConfig.png)

### **步骤 3.4：添加 HTTP 信息头管理器（HTTP Header Manager）**

1. 右键点击 Thread Group → Add → Config Element → HTTP Header Manager。
2. 添加以下请求头：
   - **Name**: `Content-Type`, **Value**: `application/json`
   - **Name**: `Accept`, **Value**: `text/plain`

### **步骤 3.5：添加结果监听器（Listeners）**

1. 右键点击 Thread Group → Add → Listener → View Results Tree（查看结果树）
2. 右键点击 Thread Group → Add → Listener → Summary Report（汇总报告）
3. 右键点击 Thread Group → Add → Listener → Graph Results（图形结果）

你的测试计划目录树结构应该如下：

```
Test Plan
└── Order Service Load Test (Thread Group)
    ├── HTTP Header Manager
    ├── Place New Orders (HTTP Request)
    ├── View Results Tree
    ├── Summary Report
    └── Graph Results
```

---

### **步骤 3.6：添加响应断言（Response Assertions）**

1. 右键点击 "Place New Orders" → Add → Assertions → Response Assertion。
2. 配置参数：
   - **Field to Test**: Response Code
   - **Pattern Matching Rules**: Equals
   - **Patterns to Test**: 200

你的配置应该如下所示：
![img.png](../resources/task11_assertionsJmeter.png)

### **步骤 3.7：添加思考时间（Think Time）**

1. 右键点击 Thread Group → Add → Timer → Constant Timer（固定定时器）。
2. 设置 **Thread Delay**: 1000（毫秒）。

这模拟了真实用户在发起请求之间停顿 1 秒的行为。

---

## 步骤 5：执行负载测试

### **GUI 界面模式（仅用于开发与调试）**

1. 点击工具栏上的绿色启动按钮（🟢）。
2. 在各个 Listener 监听器中实时观察测试结果。
3. 分析响应耗时、系统吞吐量和错误情况。

测试运行时，你可以在 "View Results Tree" 和 "Summary Report" 中查看实时输出：
![img.png](../resources/task11_treeResultsGUI.png)

### **命令行非 GUI 模式（适用于 CI/CD 与正式测试）**

为了在更高并发负载下获得更高的测试准确性和更低的自身资源消耗，请在非 GUI 模式下运行 JMeter：

前往项目的 `docs/Jmeter Scripts` 目录。我在那里放置了一个名为 `Order_Placement_Script.jmx` 的 JMeter 脚本文件供你压测使用。运行以下命令执行非 GUI 模式压测：

```bash
# 执行压测并生成 HTML 报告
jmeter -n -t Order_Placement_Script.jmx -l results.jtl -e -o report-output/

# 参数说明：
# -n: 非 GUI 模式 (Non-GUI)
# -t: 测试计划文件 (.jmx)
# -l: 结果输出日志文件 (.jtl)
# -e: 在测试结束后自动生成 HTML 聚合报告
# -o: HTML 报告的输出文件夹路径
```

### **步骤 5.1：解读压测结果**

该脚本将持续运行 2 分钟，模拟大约 500 名并发用户下单。测试完成后，你可以在 `docs/Jmeter Scripts/report-output/` 目录下打开 `index.html` 查看生成的 HTML 图表报告。

#### 核心监控指标：

1. **响应时间（Response Time）**：请求耗时
   - **Average**：整体平均响应耗时
   - **90th Percentile（90% 分位）**：90% 的请求在此时间内完成
   - **95th/99th Percentile（长尾分位）**：用于识别离群长尾延迟
2. **吞吐量（Throughput / TPS）**：每秒处理的请求数
   - 吞吐量指标越大代表性能越好
   - 在稳定的持续压力下应保持平稳
3. **错误率（Error Rate）**：失败请求所占的百分比
   - 在正常承载范围内应保持为 0%
   - 错误率上升通常意味着系统已触及容量瓶颈
4. **资源利用率（Resource Utilization）**：通过 Grafana 配合监控
   - **CPU 使用率**：长期持续使用率不宜超过 80%
   - **内存**：关注垃圾回收是否健康，排查潜在内存泄漏
   - **数据库连接**：监控 HikariCP 连接池是否耗尽

在我本机的实际压测过程中，我观察到由于本地硬件资源有限，应用程序难以维持与消息代理的密集连接，导致约 68% 的请求出现失败。在本地单机极限压测下，这是非常典型的瓶颈表现：

![img.png](../resources/task11_68failures.png)

### 检查消息代理状态

进入 ActiveMQ 或 RabbitMQ 管理控制台查看消息代理的状态。由于我连续执行了多次高并发压测，你可以看到队列中堆积了约 31.8 万条待处理消息：

![img.png](../resources/task11_rabbitmq318kmessages.png)

---

## 步骤 6：压测与监控联动分析

### **结合 Grafana 仪表板协同观察**

在执行负载测试时：

1. 打开你的 Grafana 仪表板（http://localhost:3000）
2. 在压测期间实时监控各项指标
3. 观察不同指标之间的关联反应：
   - JMeter 施压波形 → 应用程序响应耗时变化
   - 请求并发量增加 → CPU / 内存消耗激增
   - 错误率攀升 → 数据库连接池耗尽

在 Grafana 仪表板中，你应该能清楚看到压测开始时订单下单速率的陡增尖峰：
![img.png](../resources/task11_dashboard_duringLoadTest.png)

你还可以看到活动数据库连接数（Active Database Connections）在压测期间瞬间被打满，这符合预期，因为我们正在模拟大量用户并发写入数据。这充分展示了系统在重压下的行为模式：

![img.png](../resources/task11_maxDBConnections.png)

### **负载测试最佳实践**

1. **循序渐进（Start Small）**：先从低并发开始，逐步增加压力阶梯
2. **场景真实（Realistic Scenarios）**：尽量使用贴合生产实际的数据模型与用户行为路径
3. **全局监控（Monitor Everything）**：全方位兼顾 CPU、内存、数据库、磁盘 I/O 及网络带宽
4. **覆盖不同压测模型**：
   - **恒定负载测试（Constant Load）**：保持稳定用户数，观察基线性能
   - **突增脉冲测试（Spike Testing）**：瞬间大幅激增流量，观察系统弹性
   - **压力极限测试（Stress Testing）**：持续加压直至系统崩溃，摸清承载上限
   - **稳定性浸泡测试（Endurance/Soak Testing）**：长时间中高负荷运行，排查内存泄漏与连接泄露
5. **环境对齐**：尽可能在配置接近生产环境的隔离测试环境中执行

---

## 结论

使用 JMeter 进行负载测试能够为应用程序的性能特征提供关键洞察。通过将 JMeter 压力测试与 Prometheus 性能指标和 Grafana 可视化深度结合，你构建起了一个全方位的性能监控与调优生态系统，确保你的 Spring Boot 应用能够从容应对生产级别的流量挑战。

应该将定期负载测试整合到日常开发工作流中，从而尽早捕获性能衰退，确保应用架构能够伴随业务增长稳健扩展。

**后续探索：**
- 尝试不同的加压曲线模型与复杂用户链路场景
- 在 CI/CD 流水线中引入自动化性能回归测试
- 根据项目特殊协议编写自定义 JMeter 插件
- 探索针对更大规模并发的 JMeter 分布式集群压测模式
