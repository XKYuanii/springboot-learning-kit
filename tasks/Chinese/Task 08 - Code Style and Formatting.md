# 任务 8 ~ 代码风格与格式化规范

现在我们将关注代码风格和格式化。这是编写整洁、可维护代码的重要一环。在团队协作中，遵循统一的代码风格规范至关重要，以确保每个人都能轻松阅读和理解代码。
来自不同背景和经验的开发者可能有不同的个人偏好，因此达成共识尤为重要。

以下是一些业界常见的代码风格规范：

### **Google Java 风格指南（Google Java Style Guide）**
- **概述**：Google 在其所有 Java 项目中推行的综合性风格指南。
- **核心特性**：2 空格缩进、单行 100 字符限制、特定的命名约定。
- **适用场景**：偏好紧凑、易读且格式规则严格的团队。
- **推荐时机**：项目重视一致性与规范性胜过个人代码偏好时。
- **链接**：[Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)

### **Palantir Java 风格指南（Palantir Java Style Guide）**
- **概述**：一种现代化且有明确主见（opinionated）的格式化方案，优先考虑代码可读性与可维护性。
- **核心特性**：4 空格缩进、单行 120 字符限制、自动组织 Import 导入语句。
- **适用场景**：希望极简配置且拥有卓越开箱即用体验的团队。
- **推荐时机**：偏好更宽松的行宽限制，不想花时间反复调整格式化规则。
- **链接**：[Palantir Java Style Guide](https://github.com/palantir/palantir-java-format)

### **Eclipse Java 格式化器（Eclipse Java Formatter）**
- **概述**：Eclipse IDE 默认的格式化器，具备极高的可定制性。
- **核心特性**：高度可配置的缩进、换行和空格规则。
- **适用场景**：已经在使用 Eclipse IDE 的团队，或需要深度定制格式化细节的项目。
- **推荐时机**：团队拥有非常特殊的格式化要求，需要精细化微调。
- **链接**：[Eclipse Formatter](https://github.com/diffplug/spotless/tree/main/plugin-gradle#eclipse-java-formatter)

### **Oracle Java 编码规范（Oracle Java Code Conventions）**
- **概述**：最初由 Sun/Oracle 发布的经典 Java 编码标准。
- **核心特性**：传统的 Java 格式，4 空格缩进，单行 80 字符。
- **适用场景**：遗留系统项目或偏好保守、经受时间考验规范的团队。
- **推荐时机**：维护老旧代码库或处于要求严格遵循 Oracle 标准的环境。
- **链接**：[Oracle Java Code Conventions](https://www.oracle.com/java/technologies/javase/codeconventions-contents.html)

---

## 该选择哪种风格指南？

选择哪种风格指南取决于团队的偏好与项目的具体需求。多年来我接触过各种格式化工具，它们各有千秋。Google 的 Java 风格指南在业内使用最广泛，但其 100 字符的行宽限制较为严格，经常导致方法调用中间断行。这会占用过多垂直空间，降低阅读流畅度。

此外，Google 规范中 2 空格的缩进有时会略显拥挤，尤其是在较为复杂的代码结构中。我个人不是 2 空格缩进的拥趸。

**我的推荐**：在本项目中我将采用 **⭐️ Palantir Java Format**，理由如下：
- 与 Spotless 结合时配置极简
- 允许 120 字符行宽，相比 80 或 100 字符更具可读性
- 采用 4 空格缩进，视觉体验更加舒适
- 产出整洁美观、赏心悦目的代码
- 拥有出色的 IDE 集成体验

---

## Spotless

Spotless 是一个能够帮助你按照指定风格指南自动格式化代码的工具。它可以集成到项目的构建流程中，在执行构建时自动格式化代码。这样能确保你的代码始终格式规范，而无需手动逐一调整。你可以在 [Gradle 插件官网](https://plugins.gradle.org/plugin/com.diffplug.gradle.spotless) 查看 Spotless 的最新版本。

要使用 Spotless，只需将其添加到 `build.gradle` 文件中。配置示例如下：

```groovy
plugins {
    id 'java'
    id 'com.diffplug.spotless' version '7.0.4'
}

// 其他属性与依赖配置
// ........................................

spotless {
    java {
        palantirJavaFormat()
        // 若使用 Google 风格指南，可替换为 googleJavaFormat()
    }
}
```

将 Spotless 添加到项目后，运行以下命令即可格式化代码：

```bash
  ./gradlew spotlessApply
```

### 自动化 Spotless 执行

你可以通过在 `build.gradle` 文件中添加任务依赖来自动化格式化过程，使 Spotless 在项目构建前自动运行。
这样每次运行 `build` 任务时，Spotless 都会在构建开始前自动格式化所有代码。

配置示例如下：

```groovy
tasks.named('build') {
    dependsOn 'spotlessApply'
}
```

现在如果你运行 `build` 任务，它将在构建项目之前自动完成代码格式化：

```bash
  ./gradlew build
```

此时项目中的所有文件均已按照 Palantir 风格指南完成格式化，可以随时提交到代码仓库。
