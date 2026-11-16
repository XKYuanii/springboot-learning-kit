# 任务 10 ~ 集成 Grafana 可视化仪表板

既然我们已经通过 Prometheus 收集了 Spring Boot 应用程序的指标，现在让我们配置 [Grafana](https://grafana.com/)，创建精美、交互式的仪表板来将这些指标可视化。Grafana 是一个功能强大的开源分析与监控平台，擅长从包括 Prometheus 在内的各种数据源构建丰富多样、交互性强的仪表板。

在生产环境中，Grafana 仪表板对于以下方面必不可少：

- **实时监控**：直观展示应用程序的运行健康度与性能表现
- **告警通知**：在发生严重故障时提供可视化的告警与通知
- **历史趋势分析**：追踪指标随时间变化的趋势与规律
- **团队协作**：在开发、运维及架构团队之间共享统一的监控面板
- **商业洞察**：将底层技术指标转化为直观的业务指标与见解
- **SLA 服务级别监控**：确保应用程序稳定达到服务水平协议（SLA）要求

---

## Grafana 如何与 Prometheus 配合工作？

Grafana 作为构建在 Prometheus 之上的数据可视化层。Prometheus 负责收集并持久化时间序列数据，而 Grafana 则使用 PromQL（Prometheus 查询语言）查询这些数据，并通过包含折线图、表格、热力图、单值仪表盘（Gauge/Stat）等丰富可视化图表的自定义面板进行展示。这种强强联合构成了完整的监控解决方案：Prometheus 专注数据采集与存储，Grafana 专注数据呈现与交互。

---

## 步骤 1：在 Docker Compose 中添加 Grafana

更新你的 `compose.yaml` 文件，在 Prometheus 旁边添加 Grafana 服务：

```yaml
  grafana:
    image: grafana/grafana-oss:latest
    container_name: grafana_dashboard
    ports:
      - "3000:3000"   # Grafana Web UI 端口
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_SERVER_DOMAIN=localhost
      - GF_SMTP_ENABLED=false
    volumes:
      - grafana_data:/var/lib/grafana
      - ./grafana/provisioning:/etc/grafana/provisioning
    restart: unless-stopped
    depends_on:
      - prometheus
```

同时在 volumes 部分添加对应的数据卷：

```yaml
volumes:
  prometheus_data:
  grafana_data:  # 添加此行
```

---

## 步骤 2：创建 Grafana 自动化配置（Provisioning）

创建 Grafana provisioning 目录结构，以实现数据源和仪表板的自动化初始化配置：

```bash
  mkdir -p grafana/provisioning/datasources
  mkdir -p grafana/provisioning/dashboards
```

### **数据源配置（Data Source Configuration）**

创建 `grafana/provisioning/datasources/prometheus.yml` 文件：

```yaml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
```

### **仪表板配置（Dashboard Provisioning Configuration）**

创建 `grafana/provisioning/dashboards/dashboards.yml` 文件：

```yaml
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
```

---

## 步骤 3：启动所有服务

现在启动包括新增的 Grafana 在内的所有服务：

```bash
  docker compose up -d
```

这将启动：
- ✅ PostgreSQL 数据库
- ✅ RabbitMQ 消息代理  
- ✅ ActiveMQ 消息代理
- ✅ Prometheus 监控服务
- ✅ **Grafana 仪表板服务**（新增！）

---

## 步骤 4：访问 Grafana 并验证数据源

1. **启动 Spring Boot 应用程序**
2. **访问 Grafana Web 控制台**：
   - 打开浏览器访问：[http://localhost:3000](http://localhost:3000)
   - 登录凭据：
     - **用户名**: `admin`
     - **密码**: `admin`

3. **验证 Prometheus 数据源**：
   - 进入 `Connections > Data Sources`
   - ![img.png](../resources/task10_showingGrafanConnections.png)
   - 你应该能看到 Prometheus 已自动配置并连接正常：
   - ![img.png](../resources/task10_promDataSourceConfig.png)

---

## 步骤 5：创建你的第一个仪表板

### **应用概览仪表板（Application Overview Dashboard）**

**新建仪表板**：
   - 点击左侧边栏的 `+` 图标
   - 选择 `Dashboard`
   - 点击 `Add Visualization`
   - ![img.png](../resources/task10_addVisualization.png)
   - 选择 `Prometheus` 作为数据源

---

**添加 HTTP 请求速率面板（HTTP Request Rate Panel）**：
   ```promql
   sum(rate(http_server_requests_seconds_count[1m])) by (method, status)
   ```
   - ![img_2.png](../resources/task10_httpServerPanel.png)
   - 在右侧属性面板中，将可视化类型设置为 `Time series`
   - 标题（Title）："HTTP Request Rate (req/sec)"
   - ![img.png](../resources/task10_settingVisualType.png)
   - 单位（Unit）："requests/sec"
   - ![img_1.png](../resources/task10_rps_panel.png)

---

**添加平均响应耗时面板（Response Time Panel）**：
   ```promql
   rate(http_server_requests_seconds_sum[1m]) / rate(http_server_requests_seconds_count[1m])
   ```
   - 将可视化类型设置为 `Time series`
   - 标题："Average Response Time"
   - 单位："seconds"

你还可以为每个面板自定义图例（Custom Legends）：
![img.png](../resources/task10_addCustomLegends.png)

效果如下：
![img_1.png](../resources/task10_showingCustomLegendsOnPanel.png)

---

**添加 JVM 堆内存使用率面板（JVM Memory Usage Panel）**：
   ```promql
   (jvm_memory_used_bytes{area="heap"} / jvm_memory_max_bytes{area="heap"}) * 100
   ```
   - 将可视化类型设置为 `Gauge`（仪表盘）
   - 标题："JVM Heap Memory Usage"
   - 单位："percent (0-100)"
   - 设置阈值阈色（Thresholds）：绿色 (0-70)、黄色 (70-85)、红色 (85-100)

---

**添加数据库连接池监控面板（Database Connection Pool Panel）**：
   ```promql
   hikaricp_connections{pool="HikariPool-1"}
   ```
   - 将可视化类型设置为 `Stat`
   - 标题："Active DB Connections"

### **保存仪表板**：
- 点击顶部的 `Save dashboard` 图标
- 填写你喜欢的名称
- 添加标签：`spring-boot`、`monitoring`

此时你的仪表板应该如下所示：
![img.png](../resources/task10_basicDashboards.png)

---

## 步骤 6：为数据库操作添加自定义 @Timed 注解

现在让我们使用 Micrometer 的 `@Timed` 注解为数据库的读（READ）和写（WRITE）操作添加精细的时间统计指标。

### **更新依赖**

确保 `build.gradle` 包含 Micrometer 依赖（通常已包含在 Spring Boot Actuator 中）：

```gradle
implementation 'org.springframework.boot:spring-boot-starter-actuator'
implementation 'io.micrometer:micrometer-registry-prometheus'
```

### **配置 Timer 注册表**

Timer 注册表由 Spring Boot 自动配置，但你可以在 `application.yml` 或 `application.properties` 中进行定制：

```yaml
# application.yml
management:
  metrics:
    enable:
      all: true
    export:
      prometheus:
        enabled: true
    distribution:
      percentiles-histogram:
        http.server.requests: true
        database.read.operations: true
        database.write.operations: true
```

### **创建配置类启用 AOP 切面**

你需要创建一个配置类来启用 `@Timed` 的切面支持。在 `/config` 包下新建 `MetricsConfig.java` 类：

```java
@Configuration
public class MetricsConfig {
    
    @Bean
    public TimedAspect timedAspect(MeterRegistry registry) {
        return new TimedAspect(registry);
    }
}
```

---

## 步骤 8：在业务代码中使用 @Timed 注解

让我们在服务层的方法上添加 `@Timed` 注解来追踪数据库操作的耗时与吞吐量。我们将更新关键服务类以捕获读写操作的指标。

### **更新 OrderService 统计订单保存耗时**

在执行订单保存的方法上添加 `@Timed` 注解：

![img_1.png](../resources/task10_orderServiceSave.png)

### **更新 OrderStatusService 统计订单查询耗时**

为订单状态查询的读操作添加指标统计：

![img.png](../resources/task10_orderStatusGetTimed.png)

### **更新 CustomerService 统计客户详情保存耗时**

为客户信息的保存操作添加耗时统计：

![img.png](../resources/task10_saveCustomerTimed.png)

### **更新 AddressService 统计客户地址保存耗时**

为客户地址保存操作添加耗时统计：

![img.png](../resources/task10_saveAddressTimed.png)

---

## 步骤 9：创建数据库操作专属仪表板

配置好 `@Timed` 注解后，为数据库操作创建一个专属的 Grafana 仪表板：

### **数据库性能 PromQL 查询**

1. **保存订单（Saving Order）**：
- 查询每秒成功保存订单的数量：
   ```promql
   rate(save_new_order_seconds_count{exception="none"}[1m])
   ```
- 若要获取每分钟的订单保存速率，乘以 60：
   ```promql
   rate(save_new_order_seconds_count{exception="none"}[1m]) * 60
   ```

2. **保存客户详情（Saving Customer Details）**：
- 使用以下查询（每分钟速率）：
   ```promql
   rate(save_new_customer_seconds_count{exception="none"}[1m]) * 60
   ```

3. **保存客户地址（Saving Customer Address）**：
- 使用以下查询（每分钟速率）：
   ```promql
   rate(save_new_address_seconds_count{exception="none"}[1m]) * 60
   ```

#### ⭐️ 最终的仪表板效果大致如下：

![img.png](../resources/task10_finalGrafanaDashboard.png)

---

## 步骤 10：使用现成的社区仪表板模板

### **导入社区仪表板**

Grafana 拥有极其庞大的社区仪表板库。以下是针对 Spring Boot 推荐的几个优秀模板：

1. **Spring Boot 2.1 System Monitor**（仪表板 ID: 11378）
2. **JVM (Micrometer)**（仪表板 ID: 4701）
3. **Spring Boot Statistics**（仪表板 ID: 6756）

**导入方法**：
- 点击左侧边栏的 `+` > `Import`
- 输入对应的仪表板 ID
- 选择 Prometheus 作为数据源
- 点击 `Import`

例如，我导入了 Spring Boot 2.1 System Monitor 仪表板（ID: 11378）：
![img_2.png](../resources/task10_springboot2ComDashboard.png)

---

## 步骤 11：仪表板设计的最佳实践

### **仪表板结构组织**

1. **统一时间范围**：默认将仪表板时间范围设为最近 1 小时（Last 1 hour）
2. **分组归类指标**：为应用程序指标、JVM 指标、数据库指标创建不同的 Row 进行折叠与分组
3. **清晰的色彩警示**：绿色代表健康正常，黄色代表预警，红色代表严重故障
4. **添加指标描述**：为每个图表面板添加说明描述，阐明指标的含义与正常基线

### **性能优化技巧**

1. **合理控制查询频率**：根据实际需要设定抓取间隔（5-15 秒），避免给监控服务器过大压力
2. **使用模板变量（Template Variables）**：使仪表板可以在不同环境、不同实例间灵活切换复用
3. **设置合理的自动刷新率**：实时排查时可设为每 30 秒自动刷新，平时可设为 1 分钟或更长

---

## **总结**

将 Grafana 成功集成到 Spring Boot 应用程序后，你已拥有：

- ✅ **实时仪表板**：应用程序整体性能与健康的直观可视化监控
- ✅ **自定义业务指标**：使用 `@Timed` 精准追踪数据库读写操作耗时
- ✅ **全方位告警能力**：主动防御、及时发现系统异常
- ✅ **历史数据回溯**：精准分析性能趋势，从容进行系统容量规划

你的 Spring Boot 应用现在已经具备了企业级的监控可视化体系！📊📈
