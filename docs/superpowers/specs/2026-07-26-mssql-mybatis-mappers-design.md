# MSSQL MyBatis Mapper 适配设计

日期：2026-07-26
目标：新建 `xxl-job-admin/src/main/resources/mybatis-mapper/mssql/` 下 7 个 mapper XML 及配套 DDL，使 xxl-job-admin 可在 SQL Server 2012+ 下正常运行。

## 1. 范围

- 新建：`mybatis-mapper/mssql/` 7 个 XML（XxlJobInfoMapper、XxlJobLogMapper、XxlJobLogGlueMapper、XxlJobLogReportMapper、XxlJobGroupMapper、XxlJobUserMapper、XxlJobRegistryMapper），从根目录 MySQL 版拷贝后改写
- 新建：`doc/db/tables_xxl_job.mssql.sql`
- 不改动：Java 代码、`application.properties`（mapper 目录激活方式由用户自行处理）
- 前提：SQL Server 2012+；mssql-jdbc 11.2.4.jre8 已在 `xxl-job-admin/pom.xml`

## 2. 方案选型

路线 A：从 MySQL 根目录 mapper 拷贝改写。MSSQL 与 MySQL 共性最大（`AS` 表别名合法、`useGeneratedKeys` + IDENTITY 在 mssql-jdbc 下可靠），差异点最少。
否决路线 B（从 Oracle 版反向改写）：序列/selectKey/去 AS 均需回退，多此一举。

关键决策：

- 分页：`OFFSET ... ROWS FETCH NEXT ... ROWS ONLY`（2012+，需 ORDER BY，各分页点均有）
- 主键：DDL 用 `IDENTITY(100,1)`，XML 保留 `useGeneratedKeys="true" keyProperty="id"`（mssql-jdbc 对 getGeneratedKeys 支持成熟，无 Oracle ROWID 问题）
- upsert：T-SQL `MERGE`（须以分号结尾，mssql-jdbc 可执行）

## 3. XML 改写规则（7 文件通用）

### 3.1 保留不动

- `AS` 表别名：MSSQL 合法，保留
- `<![CDATA[ < ]]>` 等比较写法：通用 SQL，保留

### 3.2 分页

| 位置 | 现状 | 改为 |
|---|---|---|
| Info/Group/User/Log pageList | `LIMIT #{offset}, #{pagesize}` | `OFFSET #{offset} ROWS FETCH NEXT #{pagesize} ROWS ONLY` |
| Info scheduleJobQuery、Log findClearLogIds（外层）、Log findFailJobLogIds | `LIMIT #{pagesize}` | `OFFSET 0 ROWS FETCH NEXT #{pagesize} ROWS ONLY` |
| Log findClearLogIds 内层、LogGlue removeOld 内层 | `LIMIT 0, #{n}` | `OFFSET 0 ROWS FETCH NEXT #{n} ROWS ONLY` |

### 3.3 insert 主键（6 处：Info、Log、LogGlue、LogReport、Group、User）

- 保留 `useGeneratedKeys="true" keyProperty="id"`
- 删除残留的 `LAST_INSERT_ID()` 注释块
- 去掉 INSERT 语句结尾 `;`（风格统一；MSSQL 虽容忍，保持干净）
- DDL 提供 IDENTITY 列，驱动自动回填

### 3.4 XxlJobRegistryMapper

- `DATE_ADD(#{nowTime},INTERVAL -#{timeout} SECOND)`（findDead、findAll 两处）
  → `DATEADD(SECOND, -#{timeout}, #{nowTime})`
- `registrySaveOrUpdate` 的 `INSERT ... ON DUPLICATE KEY UPDATE` 改为：

```sql
MERGE xxl_job_registry AS t
USING (VALUES (#{registryGroup}, #{registryKey}, #{registryValue}))
    AS s (registry_group, registry_key, registry_value)
ON (t.registry_group = s.registry_group AND t.registry_key = s.registry_key AND t.registry_value = s.registry_value)
WHEN MATCHED THEN UPDATE SET t.update_time = #{updateTime}
WHEN NOT MATCHED THEN INSERT (registry_group, registry_key, registry_value, update_time)
    VALUES (#{registryGroup}, #{registryKey}, #{registryValue}, #{updateTime});
```

依赖 DDL 中 `(registry_group, registry_key, registry_value)` 唯一约束。

### 3.5 XxlJobLogMapper

- `findFailJobLogIds`：`WHERE !(...)` → `WHERE NOT (...)`
- `findLostJobIds`：删除结尾 `;`

### 3.6 LIKE 参数（Info、Group、User pageList/pageListCount）

- `CONCAT(CONCAT('%', #{x}), '%')` → `CONCAT('%', #{x}, '%')`（2012+ 支持多参数 CONCAT）

## 4. DDL 脚本 `doc/db/tables_xxl_job.mssql.sql`

- 含 `CREATE DATABASE xxl_job` + `USE xxl_job`，`GO` 分批（脚本人工在 SSMS/sqlcmd 执行）
- 8 张表对齐 MySQL 结构：
  - 主键：`id INT IDENTITY(100,1) PRIMARY KEY`（`xxl_job_log.id` 为 `BIGINT IDENTITY(100,1)`）；100 起避开种子 id=1
  - 类型映射：`datetime` → `DATETIME2`；`int(11)` → `INT`；`bigint(20/13)` → `BIGINT`；`tinyint(4)` → `TINYINT`；`varchar(n)` → `NVARCHAR(n)`；`text`/`mediumtext`（glue_source、trigger_msg、handle_msg、address_list）→ `NVARCHAR(MAX)`
  - 字符串列一律 `NVARCHAR`：种子数据含中文（示例执行器、测试任务1），`VARCHAR` 在非中文排序规则下会乱码
- 索引/唯一约束：
  - `xxl_job_log_report(trigger_day)` UNIQUE
  - `xxl_job_registry(registry_group, registry_key, registry_value)` UNIQUE
  - `xxl_job_user(username)` UNIQUE
  - `xxl_job_lock(lock_name)` PRIMARY KEY
  - `xxl_job_log` 4 个普通索引：trigger_time、handle_code、(job_id, job_group)、job_id
- 种子数据与 MySQL 版一致：示例执行器组（id=1）、测试任务1（id=1）、admin 用户（id=1，密码 md5）、`schedule_lock`；中文字符串加 `N''` 前缀；显式 id 用 `SET IDENTITY_INSERT <table> ON/OFF` 包裹
- 不写表/列注释（MSSQL 需 extended properties，省略保持简洁）

## 5. 验证

- 改后对所有 XML 做良构性校验
- 本机无 SQL Server 实例：T-SQL 按 2012+ 语法人工复核，不做实际执行
- 风险点：MERGE 依赖 registry 三列唯一约束且须分号结尾；IDENTITY_INSERT 须按表单独开关；OFFSET/FETCH 要求 ORDER BY（已确认各分页点具备）

## 6. 交付清单

1. `mybatis-mapper/mssql/XxlJobInfoMapper.xml`
2. `mybatis-mapper/mssql/XxlJobLogMapper.xml`
3. `mybatis-mapper/mssql/XxlJobLogGlueMapper.xml`
4. `mybatis-mapper/mssql/XxlJobLogReportMapper.xml`
5. `mybatis-mapper/mssql/XxlJobGroupMapper.xml`
6. `mybatis-mapper/mssql/XxlJobUserMapper.xml`
7. `mybatis-mapper/mssql/XxlJobRegistryMapper.xml`
8. `doc/db/tables_xxl_job.mssql.sql`
