# Oracle MyBatis Mapper 适配设计

日期：2026-07-26
目标：`xxl-job-admin/src/main/resources/mybatis-mapper/oracle/` 下 7 个 mapper XML 及配套 DDL 在 Oracle 12c+ 下正常运行。

## 1. 范围

- 修改：`mybatis-mapper/oracle/` 下 7 个 XML（XxlJobInfoMapper、XxlJobLogMapper、XxlJobLogGlueMapper、XxlJobLogReportMapper、XxlJobGroupMapper、XxlJobUserMapper、XxlJobRegistryMapper）
- 重写：`doc/db/tables_xxl_job.oracle.sql`（当前内容为 MySQL DDL 原样拷贝，完全不可用）
- 不改动：Java 代码、`application.properties`（mapper 目录激活方式由用户自行处理）
- 前提：Oracle 12c+；ojdbc8 21.5.0.0 已加入 `xxl-job-admin/pom.xml`

## 2. 方案选型

选定方案 A（12c+ 惯用写法、与 MySQL 版最小差异）：

- 分页：`OFFSET ... ROWS FETCH NEXT ... ROWS ONLY` / `FETCH FIRST ... ROWS ONLY`
- 主键：DDL 用显式序列（每表一个 `xxx_seq`），XML insert 用 `<selectKey order="BEFORE">` 取 `NEXTVAL` 回填 id
  （2026-07-26 按用户要求由 IDENTITY 改为序列：全 Oracle 版本/驱动通用；`useGeneratedKeys` 在无 `keyColumn` 时 Oracle 驱动返回 ROWID 而非 id，不可靠）
- upsert：`MERGE INTO`
- 否决方案 B（11g 兼容：ROWNUM 嵌套 + 序列 + selectKey）：用户确认目标 12c+，无需兼容 11g

## 3. XML 逐文件改动

### 3.1 所有文件

- 表别名去掉 `AS`：Oracle 表别名不允许 `AS`（ORA-00933）。如 `FROM xxl_job_info AS t` → `FROM xxl_job_info t`
- 删除 SQL 语句体内结尾的 `;`（Oracle JDBC 会报 ORA-00911/ORA-00933）

### 3.2 分页改写

| 位置 | 现状 | 改为 |
|---|---|---|
| Info pageList / Group pageList / User pageList / Log pageList | `LIMIT #{offset}, #{pagesize}` | `OFFSET #{offset} ROWS FETCH NEXT #{pagesize} ROWS ONLY` |
| Info scheduleJobQuery、Log findClearLogIds（外层）、Log findFailJobLogIds | `LIMIT #{pagesize}` | `FETCH FIRST #{pagesize} ROWS ONLY` |
| Log findClearLogIds 内层子查询、LogGlue removeOld 内层子查询 | `LIMIT 0, #{n}` | `FETCH FIRST #{n} ROWS ONLY` |

所有分页点均已有 `ORDER BY`，满足 OFFSET/FETCH 语法要求。

### 3.3 insert 主键（6 处：Info、Log、LogGlue、LogReport、Group、User）

- 去掉 `useGeneratedKeys="true"`，改为：

```xml
<selectKey resultType="java.lang.Integer" order="BEFORE" keyProperty="id">
    SELECT xxx_seq.NEXTVAL FROM DUAL
</selectKey>
```

  （Log 的 id 为 long，用 `java.lang.Long`；其余 Integer）
- INSERT 列清单加 `id`，VALUES 加 `#{id}`
- registry MERGE 的 WHEN NOT MATCHED 插入端：id 列直接用 `xxl_job_registry_seq.NEXTVAL`
- 序列命名：`xxl_job_info_seq`、`xxl_job_log_seq`、`xxl_job_log_report_seq`、`xxl_job_logglue_seq`、`xxl_job_registry_seq`、`xxl_job_group_seq`、`xxl_job_user_seq`

### 3.4 XxlJobRegistryMapper

- `DATE_ADD(#{nowTime},INTERVAL -#{timeout} SECOND)`（findDead、findAll 两处）
  → `#{nowTime} - NUMTODSINTERVAL(#{timeout}, 'SECOND')`
- `registrySaveOrUpdate` 的 `INSERT ... ON DUPLICATE KEY UPDATE` 改为：

```sql
MERGE INTO xxl_job_registry t
USING dual ON (t.registry_group = #{registryGroup}
               AND t.registry_key = #{registryKey}
               AND t.registry_value = #{registryValue})
WHEN MATCHED THEN UPDATE SET t.update_time = #{updateTime}
WHEN NOT MATCHED THEN INSERT (registry_group, registry_key, registry_value, update_time)
    VALUES (#{registryGroup}, #{registryKey}, #{registryValue}, #{updateTime})
```

依赖 DDL 中 `(registry_group, registry_key, registry_value)` 唯一约束。

### 3.5 XxlJobLogMapper

- `findFailJobLogIds`：`WHERE !(...)` → `WHERE NOT (...)`（`!` 为 MySQL 方言）
- `findLostJobIds`：删除结尾 `;`

## 4. DDL 脚本 `doc/db/tables_xxl_job.oracle.sql`（重写）

8 张表（xxl_job_info、xxl_job_log、xxl_job_log_report、xxl_job_logglue、xxl_job_registry、xxl_job_group、xxl_job_user、xxl_job_lock），对齐 MySQL 结构：

- 主键：`id NUMBER(x) NOT NULL PRIMARY KEY`，不配自增；另建 7 个序列（见 3.3），均 `START WITH 100`，避开种子数据显式 id=1
- 类型映射：`datetime` → `TIMESTAMP`；`int(11)` → `NUMBER(10)`；`bigint(20/13)` → `NUMBER(19)`；`tinyint(4)` → `NUMBER(3)`；`varchar(n)` → `VARCHAR2(n)`；`text`/`mediumtext`（glue_source、trigger_msg、handle_msg、address_list）→ `CLOB`
- 索引/唯一约束：
  - `xxl_job_log_report(trigger_day)` UNIQUE
  - `xxl_job_registry(registry_group, registry_key, registry_value)` UNIQUE
  - `xxl_job_user(username)` UNIQUE
  - `xxl_job_lock(lock_name)` PRIMARY KEY
  - `xxl_job_log` 4 个普通索引：trigger_time、handle_code、(job_id, job_group)、job_id
- 种子数据与 MySQL 版一致：示例执行器组（id=1）、测试任务1（id=1）、admin 用户（id=1，密码 md5）、`schedule_lock`；日期用 `TIMESTAMP '2018-11-03 22:21:31'` 字面量；显式 id=1 与序列（100 起）无冲突
- 注释用 `--`；不含 `CREATE DATABASE`/`USE`/`SET NAMES`/表级 `COMMENT` 子句；列注释默认省略，保持脚本简洁

注：现有 `xxl_job_log_report` DDL 含 `update_time` 列而 mapper 未映射，保留该列（与 MySQL 一致，无副作用）。

## 5. 验证

- 改后对所有 XML 做良构性校验（解析 DTD/标签）
- 本机无 Oracle 实例：SQL 按 Oracle 12c 语法人工复核，不做实际执行
- 风险点：MERGE INTO 依赖 registry 三列唯一约束；序列须在应用启动前创建（DDL 已含）

## 6. 交付清单

1. `mybatis-mapper/oracle/XxlJobInfoMapper.xml`
2. `mybatis-mapper/oracle/XxlJobLogMapper.xml`
3. `mybatis-mapper/oracle/XxlJobLogGlueMapper.xml`
4. `mybatis-mapper/oracle/XxlJobLogReportMapper.xml`
5. `mybatis-mapper/oracle/XxlJobGroupMapper.xml`
6. `mybatis-mapper/oracle/XxlJobUserMapper.xml`
7. `mybatis-mapper/oracle/XxlJobRegistryMapper.xml`
8. `doc/db/tables_xxl_job.oracle.sql`（重写）
