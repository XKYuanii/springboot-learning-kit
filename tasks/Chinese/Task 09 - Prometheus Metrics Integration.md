# 任务 9 ~ 集成 Prometheus 指标监控

让我们来看看如何使用 Prometheus 暴露应用程序的各项监控指标。[Prometheus](https://prometheus.io/) 是一个开源的系统监控与告警工具套件，专为可靠性与可扩展性而设计。它使我们能够实时监控应用程序的性能与运行健康状态。在生产级应用中，监控指标对以下方面至关重要：

- **性能监控**：追踪响应时间、错误率与系统吞吐量
- **资源利用率**：监控 CPU、内存及数据库连接池使用情况
- **告警机制**：针对高错误率或响应延迟等严重问题配置告警
- **故障排查**：迅速定位性能瓶颈与异常环节
- **容量规划**：分析资源消耗趋势以规划未来的扩容需求
- **SLA 合规**：确保应用程序持续满足约定的性能服务水平协议（SLA）

---

## Prometheus 是如何工作的？

Prometheus 通过以特定时间间隔从配置的目标（Targets）拉取（Scrape）指标，将其保存在时间序列数据库（TSDB）中，并提供强大的查询语言（PromQL）进行数据分析。Prometheus 采用**拉模式（Pull Model）**，定期从目标暴露的 HTTP 端点抓取指标。这与应用程序主动向中央服务器推送指标的推模式（Push-based）截然不同。Prometheus 具备高可靠性与强扩展性，无论是小型微服务还是大型分布式系统均十分适用。

---

## 步骤 1：Docker Compose 配置

你需要更新 `docker-compose.yml`（或 `compose.yaml`）文件以引入 Prometheus 服务。以下是需要添加的配置内容：

```yaml
prometheus:
  image: prom/prometheus:latest
  container_name: prometheus_monitoring
  ports:
    - "9090:9090"   # Prometheus Web UI 端口
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml:ro
    - prometheus_data:/prometheus
  command:
    - '--config.file=/etc/prometheus/prometheus.yml'
    - '--storage.tsdb.path=/prometheus'
    - '--web.console.libraries=/etc/prometheus/console_libraries'
    - '--web.console.templates=/etc/prometheus/consoles'
    - '--storage.tsdb.retention.time=200h'
    - '--web.enable-lifecycle'
  restart: unless-stopped

volumes:
  prometheus_data:
```

---

## 步骤 2：Prometheus 配置文件

在上面的 docker compose 配置中，可以看到我们通过 `--config.file` 命令参数指示 Prometheus 使用特定的 `yml` 配置文件。现在我们在项目根目录下创建 `prometheus.yml` 配置文件，用于定义 Prometheus 如何从我们的 Spring Boot 应用程序抓取指标：

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'spring-boot-app'
    metrics_path: 'OrderService/actuator/prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['host.docker.internal:8080']
    scrape_timeout: 3s
```

### **抓取配置详解**

**全局配置（Global Settings）：**
- **scrape_interval**：默认每隔 15 秒采集一次指标
- **evaluation_interval**：每隔 15 秒评估一次告警规则

**目标任务（Target Jobs）：**

1. **Prometheus 自身监控**（`prometheus` 任务）：
   - 监控 Prometheus 服务自身的运行指标
   - 目标地址：`localhost:9090`
   - 使用默认指标路径（`/metrics`）

2. **Spring Boot 应用程序**（`spring-boot-app` 任务）：
   - **metrics_path**：`OrderService/actuator/prometheus`（Spring Boot Actuator 指标端点）
   - **targets**：`host.docker.internal:8080`（允许 Docker 容器内部访问宿主机上的服务）
   - **scrape_interval**：5 秒（比默认抓取更频繁，以便进行实时监控）
   - **scrape_timeout**：3 秒，防止抓取请求长时间挂起超时

---

## 步骤 3：启动服务

现在你可以启动包括 Prometheus 在内的所有服务：

```bash
  docker compose up -d
```

这将依次启动：
- ✅ PostgreSQL 数据库
- ✅ RabbitMQ 消息代理  
- ✅ ActiveMQ 消息代理
- ✅ **Prometheus 监控服务**（新增！）

## 步骤 4：验证 Prometheus 环境

1. **启动 Spring Boot 应用程序**：
   ```bash
   ./gradlew bootRun
   ```

2. **访问 Prometheus Web 控制台**：
   - 打开浏览器访问：[http://localhost:9090](http://localhost:9090)
   - 你应该能看到 Prometheus 的仪表板界面：
   - ![img.png](../resources/task9_promDashboard.png)

3. **检查抓取目标（Targets）**：
   - 在 Prometheus UI 顶部导航至 `Status > Targets`
   - 你应该能看到 `prometheus` 和 `spring-boot-app` 两个抓取目标
   - 两者的状态均应显示为绿色的 "UP"
   - ![img.png](../resources/task9_prometheusTargets.png)

4. **查询指标**：
   - 在 Prometheus 查询输入框中，尝试搜索并执行以下指标查询：
     - `jvm_memory_used_bytes`（JVM 内存已使用量）
     - `http_server_requests_seconds_count`（HTTP 请求总次数）
     - `system_cpu_usage`（系统 CPU 使用率）

这可以验证 Prometheus 正在成功抓取 Spring Boot 应用程序暴露的度量数据：
![img.png](../resources/task9_promJVMMetrics.png)

---

## 步骤 5：理解各项指标

你的 Spring Boot 应用程序通过 `/actuator/prometheus` 端点自动暴露数十个非常有价值的监控指标：

### **核心指标分类**

**📈 应用程序指标：**
- `http_server_requests_*`：HTTP 请求指标（请求次数、响应耗时、状态码分布）
- `jvm_*`：JVM 内存堆栈、垃圾回收（GC）、线程状态指标
- `system_*`：系统 CPU、内存及磁盘利用率
- `tomcat_*`：内嵌 Tomcat 服务器连接与请求指标

**🗄️ 数据库指标：**
- `hikaricp_*`：HikariCP 数据库连接池指标（活跃连接数、空闲连接数、等待时长）
- `jdbc_*`：数据库连接与 JDBC 查询执行指标

**📨 消息队列指标：**
- `rabbitmq_*`：RabbitMQ 连接与队列消息状态指标
- `jms_*`：JMS / ActiveMQ 消息消费与处理指标

---

### **推荐尝试的 PromQL 示例查询**

点击 Prometheus 控制台界面的 "Graph" 选项卡，输入以下查询语句查看数据可视化图表：

```promql
# 所有 HTTP 请求的平均响应耗时（秒）
rate(http_server_requests_seconds_sum[5m]) / rate(http_server_requests_seconds_count[5m])

# 每秒请求数（RPS 吞吐量）
rate(http_server_requests_seconds_count[1m])

# JVM 内存使用率百分比
(jvm_memory_used_bytes / jvm_memory_max_bytes) * 100

# 系统 CPU 使用率百分比
system_cpu_usage * 100
```

---

## 🚀 **后续步骤**

- 进一步深入学习 Prometheus 查询语言（PromQL）
- 配置 Grafana 打造现代化的高级仪表板（参见 [Task 10](./Task%2010%20-%20Grafana%20Integration.md)）
- 为关键业务指标配置告警规则
- 使用 Micrometer 在业务代码中添加自定义监控指标

现在你的应用程序已经完整集成了 Prometheus 监控体系！📊
