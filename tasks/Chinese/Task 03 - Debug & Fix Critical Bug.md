# 任务 3 ~ 调试并修复严重 Bug

在本任务中，我们将解决应用程序在使用数据库时经常面临的一个严重 Bug。
你在下单时注意到什么异常了吗？如果没有，让我演示给你看。

### **调试应用程序**

启动应用程序，并使用 Bruno 携带相同的请求体多次调用 `/order/submit` 接口。你会发现应用程序每次都返回 200 响应状态码，表明订单已成功提交。这种情况显然不应该发生，因为订单的 `UUID` 应该是唯一的。
因此，如果上游服务尝试使用相同的 `UUID` 提交订单，我们的应用程序应该返回 `409 - Conflict` 错误响应，提示该订单已经存在。

你还应该查看 [order_table.xml](../../src/main/resources/db/changelog/order_table.xml) 文件，了解 `UUID` 列是如何定义的。如下所示的约束确保了 `UUID` 列为主键且始终唯一：

![img.png](../resources/tas3_uuid_xml.png)

你还应该验证 Liquibase 是否正确创建了 `UUID` 列。在 DBeaver 中导航至 `public` 模式下的 `order` 表，展开 `Constraints`（约束）部分。你应该能看到一个名为 `order_pkey` 的约束。双击该约束可以查看其详细信息。`uuid` 列应显示为主键。请确保你的主键与下图相符：

![img.png](../resources/task3_verify_uuid_dbeaver.png)

在数据库中是不可能保存多个具有相同 `UUID` 的订单的。这表明问题出在应用程序代码层面。让我们审查代码找出具体原因。

### **查询数据库**

让我们深入数据库了解到底发生了什么。在此之前，我先分享当前的数据库关系图，帮助你理解各表之间的关联。图表显示 `order` 表与 `customer` 和 `address` 表之间是一对一关系，而与 `order_items` 表之间是一对多关系：

![img.png](../resources/task3_database_diagram.png)

现在获取你在调用 `order/submit` 接口时请求体中使用的 `UUID`。
在 DBeaver 中，右键点击 `Order_Service -> SQL Editor -> New SQL Script` 打开编辑器以运行 SQL 查询。
使用你的 `UUID` 执行以下查询：
```sql
SELECT * FROM public.order WHERE uuid = 1234567;
```

你应该在 `order` 表中看到该 `UUID` 仅对应一条记录。例如：

![img.png](../resources/task3_seeing_single_records.png)

现在，让我们执行更多查询，看看其他表中的记录情况：

```sql
SELECT * FROM public.order_items WHERE order_id = 1234567;
```

![img.png](../resources/task3_multiple_records_for_order_items.png)

你应该在 `order_items` 表中看到相同的 `order_id` 下有多于两条记录。
这表明应用程序确实在尝试向数据库中插入订单。虽然在 `order` 表中它只插入了一条记录，但在 `order_items` 表中却插入了多条记录。

_获取 customer details 和 address 的 ID 并查询这些表，看看是否也能发现多条记录。_

**通过状态 API 进行验证**

如果你调用在上一个任务中实现的 `order/status/{orderId}` 接口，你应该会看到它返回的商品条目比预期多得多：

<img src="../resources/task3_status_wrongresonse.png" alt="img.png" width="250"/>

### **代码调试分析**

现在让我们调试代码看看原因。由于我们一直在提交 `ONLINE` 类型的订单，因此导航至 [OnlineOrderProcessor.java](../../src/main/java/com/springboot/learning/kit/processor/OnlineOrderProcessor.java) 类。该处理器使用了 `AbstractOrderProcessor` 类中的 `saveOrder()` 方法，如方法中的 `this.saveOrder(order)` 所示。

`OrderRequest` 数据被转换为实体对象，然后使用不同的 repository 类保存到数据库中。你应该打开所有实体类并观察它们是如何定义的。你会发现除了 `Order` 类之外，所有类的主键都使用了 `@GeneratedValue(strategy = GenerationType.IDENTITY)` 注解。这是因为我们不希望应用程序自动生成订单的 `UUID`，因为该值是由上游服务传递给我们的。

那么，问题出在哪里？问题在于我们使用了 `JpaRepository` 的 `save()` 方法来保存订单，而该方法只会做两件事：
- 如果实体不存在，它将创建一条新记录。
- 如果实体已经存在，它将更新现有记录。

在生产系统中，有两种方式来处理这种问题：
- 在保存订单之前，先检查数据库中是否已存在该订单。如果存在，则抛出异常。这种方法的缺点是会增加一次额外的数据库查询，可能会拖慢应用程序性能。**该方案在流量不大的生产系统中可行，但随着并发流量增加，这将成为性能瓶颈。**

或者

- 我们在数据库级别解决此问题，如果记录已存在，则让数据库直接拒绝插入操作。**这是更好的方式，因为它不会增加额外的数据库查询开销。对于高并发、大流量应用，这是最佳解决方案。**

### **解决方案**

由于我们希望在实体已存在时抛出异常，因此应该使用 `EntityManager` 类的 `persist()` 方法，而不是 `save()`。如果数据库中已经存在该实体，`persist()` 方法将抛出异常。

在 `OrderService` 类中导入 `jakarta.persistence.EntityManager;`，移除 `OrderRepository` 依赖并注入 `EntityManager` 依赖。将 `orderRepository.save(order)` 替换为 `entityManager.persist(order)`。

此时 `OrderService` 类中的 save 方法应该如下所示：

![img.png](../resources/task3_implementing_entityManager.png)

### **测试修复效果**

现在重启应用程序，再次使用相同的 `UUID` 下单。你应该会收到如下所示的错误响应：

![img_1.png](../resources/task3_error_after_doingfix.png)

出现该错误的原因是 `EntityManager.persist()` 需要一个活跃的事务，但当前线程上没有可用事务。在 Spring 中，事务是通过代理（Proxy）生效的。如果你在同一个类内部调用带有 `@Transactional` 的方法，或者通过 `super.method()` 调用，代理会被绕过，事务根本不会启动，从而导致此错误。你可以阅读 [Spring 官方文档](https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/annotations.html) 了解更多细节。

我们在使用多态时，`OnlineOrderProcessor` 直接调用了父类 `AbstractOrderProcessor` 中带有 `@Transactional` 的方法，此调用绕过了 Spring 代理，导致事务未能正确应用。

**使用 @Transactional 的原因**

对于不清楚我们为何使用 `@Transactional` 注解的同学，补充一些背景知识：当你处理一个业务事件时，可能涉及对数据库的多张表进行多次更新操作。你希望仅在所有操作都成功时才将更改全部提交保存到数据库；如果其中任何一个操作失败，你希望回滚对数据库所做的所有更改。

例如，此应用程序在处理新订单时会对以下数据表执行写入（WRITE）操作：
- customer_details
- customer_address
- orders
- order_items

如果应用程序在向 `order_items` 表插入数据时失败，我们希望回滚先前对前面几张表执行的所有写入操作。这就是 `@Transactional` 注解的作用。它指示 Spring 在执行方法前开启一个事务，并在方法成功执行完毕后提交事务。如果发生任何异常，Spring 将回滚对数据库所做的所有更改。

**解决我们的问题**

我们可以移除 `AbstractOrderProcessor` 类中 `saveOrder()` 方法上的 `@Transactional` 注解，将其添加到 `OrderProcessingService` 类的 `processNewOrder()` 方法上。这将在最合适的顶层设置事务边界，并将整个订单处理完整地包裹在一个事务中。现在在我们的下单流程中应该仅有一个 `@Transactional` 注解。

让我们重启应用程序，再次使用相同的 `UUID` 下单。你应该会收到 `500` 错误响应，这正是我们想要的结果！

![img_1.png](../resources/task3_duplicate_key_error.png)

### **改进重复订单的错误处理**

现在，当提交重复订单时，应用程序会抛出错误。但该错误信息不应该暴露给最终用户。在生产系统中，我们应该始终向最终用户返回简明扼要且有意义的错误信息，同时隐藏底层的技术实现细节。

我们可以通过创建一个自定义异常类来实现这一点，就像在上一个任务中为 `OrderNotFoundException` 所做的那样。
创建好自定义异常类后，导航到 `OrderService` 类。使用 try-catch 块包裹 `entityManager.persist()` 方法。如果抛出异常，我们可以转而抛出自定义异常类。

此时你的 save 方法可能看起来像这样：

![img.png](../resources/task3_save_method_withTryCatch.png)

但这种实现存在一个问题：你的 `catch` 块捕获了 `entityManager.persist()` 方法抛出的所有异常。这意味着即使发生的异常与重复订单无关，我们的代码也始终会抛出 `DuplicateOrderException`。这并不是良好实践，因为它可能导致误导并增加调试难度。

我们应该仅捕获因重复下单而抛出的特定异常。但是如何确定到底要捕获哪个具体异常呢？我们可以通过打印完整的异常堆栈信息来确认。

在 `order/submit` 接口的 catch 块中添加 `log.error("Error while placing order", e)`。这将打印完整的异常堆栈信息。你应该能在堆栈顶端看到 `org.hibernate.exception.ConstraintViolationException`。这就是提交重复订单时所抛出的异常。

现在你的代码应该如下所示：

![img.png](../resources/task3_entitymanager_withoutflush.png)

如果你再次使用相同的请求体调用 `order/submit` 接口，你会发现即使我们编写了处理重复订单的逻辑，依然会看到与之前相同的错误响应。这是因为在 persist 订单后，我们没有刷新（flush）实体管理器。`flush()` 方法用于将持久化上下文同步到底层数据库中。
这意味着在调用 `flush()` 方法之前，对实体管理器所做的更改并没有真正写入数据库。因此，我们需要在 persist 订单后调用 `flush()` 方法。这将确保实体管理器的变更写入数据库，并在订单已存在时即刻抛出异常。

最终代码应该如下所示：

`OrderService`：

![img.png](../resources/task3_entitymanager_with_flush.png)

`OrderController`：

![img.png](../resources/task3_final_controller_code.png)

重启应用程序，再次使用相同的 `UUID` 提交订单。你应该会收到 `409` 冲突错误响应：

![img.png](../resources/task3_conflict_response_final.png)

### **总结**

希望本任务能让你深入了解如何在应用程序中排查此类错误，以及我们可以选择哪些解决思路。在实施解决方案之前，我们应该始终评估每种方法的优缺点。短期快速的修复方案并不总是长期维度的最佳方案。
