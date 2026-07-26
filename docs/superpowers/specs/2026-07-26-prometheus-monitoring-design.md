# XXL-JOB Admin Prometheus 监控设计

日期：2026-07-26
分支：2.5.0.a

## 目标

为 xxl-job-admin（调度中心）开启 Prometheus 监控，暴露标准 Micrometer 指标端点，供 Prometheus 抓取。

## 范围

- 仅 `xxl-job-admin` 模块。
- 不含 executor 样例、不含自定义业务指标（任务触发次数、调度延迟等埋点）。
- 不含 Prometheus 服务端配置（prometheus.yml、Grafana 面板属运维侧）。

## 背景

- Spring Boot 2.7.18，Java 8。
- admin 已有 `spring-boot-starter-actuator`，配置了 `management.server.base-path=/actuator`。
- admin 登录拦截器（`WebMvcConfig`）作用于 DispatcherServlet，管不到 actuator 端点（独立 HandlerMapping），同端口暴露等于无鉴权，故采用独立管理端口隔离。

## 方案（纯配置，零 Java 代码）

### 1. 依赖

`xxl-job-admin/pom.xml` 添加：

```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

版本由 spring-boot-dependencies 2.7.18 BOM 管理（micrometer 1.9.x），不显式指定。

### 2. 配置

`xxl-job-admin/src/main/resources/application.properties` 现有 actuator 段改为：

```properties
### actuator
management.server.port=18080
management.endpoints.web.exposure.include=health,info,prometheus
management.health.mail.enabled=false
management.metrics.tags.application=xxl-job-admin
```

注意：不设 `management.server.base-path`。独立管理端口下该属性同时成为子上下文
context-path 和端点 base path，会产生 `/actuator/actuator` 双前缀（实测确认）。
端点默认 base path 即 `/actuator`，URL 不变。

效果：

- 主服务端口 8080（context-path `/xxl-job-admin`）不变。
- 管理端口 18080，仅暴露 `health`、`info`、`prometheus` 三个端点。
- 抓取地址：`http://<host>:18080/actuator/prometheus`。
- 所有指标带 `application="xxl-job-admin"` 标签，多实例部署可区分。
- 8080 端口无 actuator 端点，访问对应路径被登录拦截器拦截（302），业务端口与管理端口隔离。
- 管理子上下文会继承主上下文注册的拦截器（parent context 的 `WebMvcConfigurer` 对子上下文可见），
  且路径排除在子上下文不生效。`PermissionInterceptor` 按 handler 类型放行：
  bean 类名以 `org.springframework.boot.actuate` 开头直接通过。

### 3. 指标内容

Spring Boot Actuator 自动装配，无需代码：

- JVM：内存、GC、线程、类加载
- Tomcat：会话、线程池、请求
- HTTP 请求：`http.server.requests`（uri、status、耗时）
- HikariCP：连接池活跃/空闲/等待
- logback：各级别日志事件数

## 错误处理

纯配置方案无运行时错误处理逻辑。配置错误（如端口占用）在启动期由 Spring Boot 直接报错暴露。

## 验证方式

项目 `maven.test.skip=true`，无测试基建，采用手工验证：

1. 启动 xxl-job-admin。
2. `curl http://localhost:18080/actuator/prometheus` 返回 Prometheus 文本格式指标（含 `jvm_memory_used_bytes` 等）。
3. `curl http://localhost:18080/actuator/health` 返回 `{"status":"UP"}`。
4. `curl http://localhost:8080/xxl-job-admin/actuator/prometheus` 返回 404，确认主端口隔离生效。

## 风险与注意事项

- 18080 端口需防火墙/安全组限制为内网可达，端点无鉴权。
- admin 打包为可执行 jar 时该依赖自动打入，无额外部署变更。
- 未来如需业务指标（任务触发/成功/失败计数、调度延迟），在 `XxlJobScheduler` / 调度日志组件埋点，另行设计。
