---#
---# XXL-JOB v2.4.1
---# Copyright (c) 2015-present, xuxueli.

CREATE TABLE XXL_JOB_INFO
(
    ID NUMBER (20,0) NOT NULL,
    JOB_GROUP NUMBER (20,0) NOT NULL,
    JOB_DESC VARCHAR2 (512) NOT NULL,
    ADD_TIME        DATE,
    UPDATE_TIME     DATE,
    AUTHOR VARCHAR2 (128),
    ALARM_EMAIL VARCHAR2 (512),
    SCHEDULE_TYPE VARCHAR2 (100) DEFAULT 'NONE' NOT NULL,
    SCHEDULE_CONF VARCHAR2 (256),
    MISFIRE_STRATEGY VARCHAR2 (100) DEFAULT 'DO_NOTHING' NOT NULL,
    EXECUTOR_ROUTE_STRATEGY VARCHAR2 (100),
    EXECUTOR_HANDLER VARCHAR2 (512),
    EXECUTOR_PARAM VARCHAR2 (1024),
    EXECUTOR_BLOCK_STRATEGY VARCHAR2 (100),
    EXECUTOR_TIMEOUT NUMBER (20,0) DEFAULT 0 NOT NULL,
    EXECUTOR_FAIL_RETRY_COUNT NUMBER (20,0) DEFAULT 0 NOT NULL,
    GLUE_TYPE VARCHAR2 (100) NOT NULL,
    GLUE_SOURCE CLOB,
    GLUE_REMARK VARCHAR2 (512),
    GLUE_UPDATETIME DATE,
    CHILD_JOBID VARCHAR2 (512),
    TRIGGER_STATUS NUMBER (4,0) DEFAULT 0 NOT NULL,
    TRIGGER_LAST_TIME NUMBER (20,0) DEFAULT 0,
    TRIGGER_NEXT_TIME NUMBER (20,0) DEFAULT 0,
    PRIMARY KEY (ID)
);


CREATE
SEQUENCE SEQ_XXL_JOB_INFO_ID
INCREMENT BY 1
MINVALUE 1 MAXVALUE 9999999999999999999999999999
START
WITH 100
NOCYCLE
CACHE
20
NOORDER;


COMMENT ON COLUMN XXL_JOB_INFO.JOB_GROUP IS '执行器主键ID';
COMMENT ON COLUMN XXL_JOB_INFO.AUTHOR IS '作者';
COMMENT ON COLUMN XXL_JOB_INFO.ALARM_EMAIL IS '报警邮件';
COMMENT ON COLUMN XXL_JOB_INFO.SCHEDULE_TYPE IS '调度类型';
COMMENT ON COLUMN XXL_JOB_INFO.SCHEDULE_CONF IS '调度配置，值含义取决于调度类型';
COMMENT ON COLUMN XXL_JOB_INFO.MISFIRE_STRATEGY IS '调度过期策略';
COMMENT ON COLUMN XXL_JOB_INFO.EXECUTOR_ROUTE_STRATEGY IS '执行器路由策略';
COMMENT ON COLUMN XXL_JOB_INFO.EXECUTOR_HANDLER IS '执行器任务HANDLER';
COMMENT ON COLUMN XXL_JOB_INFO.EXECUTOR_PARAM IS '执行器任务参数';
COMMENT ON COLUMN XXL_JOB_INFO.EXECUTOR_BLOCK_STRATEGY IS '阻塞处理策略';
COMMENT ON COLUMN XXL_JOB_INFO.EXECUTOR_TIMEOUT IS '任务执行超时时间，单位秒';
COMMENT ON COLUMN XXL_JOB_INFO.EXECUTOR_FAIL_RETRY_COUNT IS '失败重试次数';
COMMENT ON COLUMN XXL_JOB_INFO.GLUE_TYPE IS 'GLUE类型';
COMMENT ON COLUMN XXL_JOB_INFO.GLUE_SOURCE IS 'GLUE源代码';
COMMENT ON COLUMN XXL_JOB_INFO.GLUE_UPDATETIME IS 'GLUE更新时间';
COMMENT ON COLUMN XXL_JOB_INFO.CHILD_JOBID IS '子任务ID，多个逗号分隔';
COMMENT ON COLUMN XXL_JOB_INFO.TRIGGER_STATUS IS '调度状态：0-停止，1-运行';
COMMENT ON COLUMN XXL_JOB_INFO.TRIGGER_LAST_TIME IS '上次调度时间';
COMMENT ON COLUMN XXL_JOB_INFO.TRIGGER_NEXT_TIME IS '下次调度时间';



CREATE TABLE XXL_JOB_LOG
(
    ID NUMBER (20,0) NOT NULL,
    JOB_GROUP NUMBER (20,0) NOT NULL,
    JOB_ID NUMBER (20,0) NOT NULL,
    EXECUTOR_ADDRESS VARCHAR2 (512),
    EXECUTOR_HANDLER VARCHAR2 (512),
    EXECUTOR_PARAM VARCHAR2 (1024),
    EXECUTOR_SHARDING_PARAM VARCHAR2 (40),
    EXECUTOR_FAIL_RETRY_COUNT NUMBER (20,0) DEFAULT 0 NOT NULL,
    TRIGGER_TIME DATE,
    TRIGGER_CODE NUMBER (10,0) NOT NULL,
    TRIGGER_MSG CLOB,
    HANDLE_TIME  DATE,
    HANDLE_CODE NUMBER (10,0) NOT NULL,
    HANDLE_MSG CLOB,
    ALARM_STATUS NUMBER (4,0) DEFAULT 0 NOT NULL,
    PRIMARY KEY (ID)
);

CREATE INDEX IDX_XXL_JOB_LOG_TRIGGER_TIME ON XXL_JOB_LOG (TRIGGER_TIME)
;

CREATE INDEX IDX_XXL_JOB_LOG_HANDLE_CODE ON XXL_JOB_LOG (HANDLE_CODE)
;

CREATE
SEQUENCE SEQ_XXL_JOB_LOG_ID
INCREMENT BY 1
MINVALUE 1 MAXVALUE 9999999999999999999999999999
START
WITH 100
NOCYCLE
CACHE
20
NOORDER;

COMMENT ON COLUMN XXL_JOB_LOG.JOB_GROUP IS '执行器主键ID';
COMMENT ON COLUMN XXL_JOB_LOG.JOB_ID IS '任务，主键ID';
COMMENT ON COLUMN XXL_JOB_LOG.EXECUTOR_ADDRESS IS '执行器地址，本次执行的地址';
COMMENT ON COLUMN XXL_JOB_LOG.EXECUTOR_HANDLER IS '执行器任务HANDLER';
COMMENT ON COLUMN XXL_JOB_LOG.EXECUTOR_PARAM IS '执行器任务参数';
COMMENT ON COLUMN XXL_JOB_LOG.EXECUTOR_SHARDING_PARAM IS '执行器任务分片参数，格式如 1/2';
COMMENT ON COLUMN XXL_JOB_LOG.EXECUTOR_FAIL_RETRY_COUNT IS '失败重试次数';
COMMENT ON COLUMN XXL_JOB_LOG.TRIGGER_TIME IS '调度-时间';
COMMENT ON COLUMN XXL_JOB_LOG.TRIGGER_CODE IS '调度-结果';
COMMENT ON COLUMN XXL_JOB_LOG.TRIGGER_MSG IS '调度-日志';
COMMENT ON COLUMN XXL_JOB_LOG.HANDLE_TIME IS '执行-时间';
COMMENT ON COLUMN XXL_JOB_LOG.HANDLE_CODE IS '执行-状态';
COMMENT ON COLUMN XXL_JOB_LOG.HANDLE_MSG IS '执行-日志';
COMMENT ON COLUMN XXL_JOB_LOG.ALARM_STATUS IS '告警状态：0-默认、1-无需告警、2-告警成功、3-告警失败';


CREATE TABLE XXL_JOB_LOG_REPORT
(
    ID NUMBER (20,0) NOT NULL,
    TRIGGER_DAY DATE,
    RUNNING_COUNT NUMBER (20,0) DEFAULT 0 NOT NULL,
    SUC_COUNT NUMBER (20,0) DEFAULT 0 NOT NULL,
    FAIL_COUNT NUMBER (20,0) DEFAULT 0 NOT NULL,
    UPDATE_TIME DATE,
    PRIMARY KEY (ID)
);

CREATE INDEX IDX_XXL_JOB_LOG_REPORT_TRIGGER_DAY ON XXL_JOB_LOG_REPORT (TRIGGER_DAY)
;

CREATE
SEQUENCE SEQ_XXL_JOB_LOG_REPORT_ID
INCREMENT BY 1
MINVALUE 1 MAXVALUE 9999999999999999999999999999
START
WITH 100
NOCYCLE
CACHE
20
NOORDER;

COMMENT ON COLUMN XXL_JOB_LOG_REPORT.TRIGGER_DAY IS '调度-时间';
COMMENT ON COLUMN XXL_JOB_LOG_REPORT.RUNNING_COUNT IS '运行中-日志数量';
COMMENT ON COLUMN XXL_JOB_LOG_REPORT.SUC_COUNT IS '执行成功-日志数量';
COMMENT ON COLUMN XXL_JOB_LOG_REPORT.FAIL_COUNT IS '执行失败-日志数量';

CREATE TABLE XXL_JOB_LOGGLUE
(
    ID NUMBER (20,0) NOT NULL,
    JOB_ID NUMBER (20,0) NOT NULL,
    GLUE_TYPE VARCHAR2 (100),
    GLUE_SOURCE CLOB,
    GLUE_REMARK VARCHAR2 (256) NOT NULL,
    ADD_TIME    DATE,
    UPDATE_TIME DATE,
    PRIMARY KEY (ID)
);


CREATE
SEQUENCE SEQ_XXL_JOB_LOGGLUE_ID
INCREMENT BY 1
MINVALUE 1 MAXVALUE 9999999999999999999999999999
START
WITH 100
NOCYCLE
CACHE
20
NOORDER;

COMMENT ON COLUMN XXL_JOB_LOGGLUE.JOB_ID IS '任务，主键ID';
COMMENT ON COLUMN XXL_JOB_LOGGLUE.GLUE_TYPE IS 'GLUE类型';
COMMENT ON COLUMN XXL_JOB_LOGGLUE.GLUE_SOURCE IS 'GLUE源代码';
COMMENT ON COLUMN XXL_JOB_LOGGLUE.GLUE_REMARK IS 'GLUE备注';

CREATE TABLE XXL_JOB_REGISTRY
(
    ID NUMBER (20,0) NOT NULL,
    REGISTRY_GROUP VARCHAR2 (100) NOT NULL,
    REGISTRY_KEY VARCHAR2 (512) NOT NULL,
    REGISTRY_VALUE VARCHAR2 (512) NOT NULL,
    UPDATE_TIME DATE,
    PRIMARY KEY (ID)
);

CREATE INDEX IDX_XXL_JOB_REGISTRY_G_K_V ON XXL_JOB_REGISTRY (REGISTRY_GROUP, REGISTRY_KEY, REGISTRY_VALUE)
;

CREATE
SEQUENCE SEQ_XXL_JOB_REGISTRY_ID
INCREMENT BY 1
MINVALUE 1 MAXVALUE 9999999999999999999999999999
START
WITH 100
NOCYCLE
CACHE
20
NOORDER;

CREATE TABLE XXL_JOB_GROUP
(
    ID NUMBER (20,0) NOT NULL,
    APP_NAME VARCHAR2 (128) NOT NULL,
    TITLE VARCHAR2 (128) NOT NULL,
    ADDRESS_TYPE NUMBER (4,0) DEFAULT 0 NOT NULL,
    ADDRESS_LIST VARCHAR2 (4000),
    UPDATE_TIME DATE,
    PRIMARY KEY (ID)
);

CREATE
SEQUENCE SEQ_XXL_JOB_GROUP_ID
INCREMENT BY 1
MINVALUE 1 MAXVALUE 9999999999999999999999999999
START
WITH 100
NOCYCLE
CACHE
20
NOORDER;

COMMENT ON COLUMN XXL_JOB_GROUP.APP_NAME IS '执行器APPNAME';
COMMENT ON COLUMN XXL_JOB_GROUP.TITLE IS '执行器名称';
COMMENT ON COLUMN XXL_JOB_GROUP.ADDRESS_TYPE IS '执行器地址类型：0=自动注册、1=手动录入';
COMMENT ON COLUMN XXL_JOB_GROUP.ADDRESS_LIST IS '执行器地址列表，多地址逗号分隔';


CREATE TABLE XXL_JOB_USER
(
    ID NUMBER (20,0) NOT NULL,
    USERNAME VARCHAR2 (100) NOT NULL,
    PASSWORD VARCHAR2 (600) NOT NULL,
    ROLE NUMBER (4,0) NOT NULL,
    PERMISSION VARCHAR2 (512),
    PRIMARY KEY (ID)
);

CREATE UNIQUE INDEX IDX_XXL_JOB_USER_USERNAME ON XXL_JOB_USER (USERNAME)
;

CREATE
SEQUENCE SEQ_XXL_JOB_USER_ID
INCREMENT BY 1
MINVALUE 1 MAXVALUE 9999999999999999999999999999
START
WITH 100
NOCYCLE
CACHE
20
NOORDER;

COMMENT ON COLUMN XXL_JOB_USER.USERNAME IS '账号';
COMMENT ON COLUMN XXL_JOB_USER.PASSWORD IS '密码';
COMMENT ON COLUMN XXL_JOB_USER.ROLE IS '角色：0-普通用户、1-管理员';
COMMENT ON COLUMN XXL_JOB_USER.PERMISSION IS '权限：执行器ID列表，多个逗号分割';


CREATE TABLE XXL_JOB_LOCK
(
    LOCK_NAME VARCHAR2 (100) NOT NULL,
    PRIMARY KEY (LOCK_NAME)
);

COMMENT ON COLUMN XXL_JOB_LOCK.LOCK_NAME IS '锁名称';

INSERT INTO XXL_JOB_GROUP(ID, APP_NAME, TITLE, ADDRESS_TYPE, ADDRESS_LIST, UPDATE_TIME)
VALUES (1, 'xxl-job-executor-sample', '示例执行器', 0, NULL, to_date('2018-11-03 22:21:31', 'yyyy-MM-dd hh24:mi:ss'));

INSERT INTO XXL_JOB_INFO(ID, JOB_GROUP, JOB_DESC,
                           ADD_TIME, UPDATE_TIME,
                           AUTHOR, ALARM_EMAIL,
                           SCHEDULE_TYPE, SCHEDULE_CONF,
                           MISFIRE_STRATEGY, EXECUTOR_ROUTE_STRATEGY,
                           EXECUTOR_HANDLER, EXECUTOR_PARAM,
                           EXECUTOR_BLOCK_STRATEGY,
                           EXECUTOR_TIMEOUT, EXECUTOR_FAIL_RETRY_COUNT,
                           GLUE_TYPE, GLUE_SOURCE, GLUE_REMARK,
                           GLUE_UPDATETIME,
                           CHILD_JOBID)
VALUES (1, 1, '测试任务1',
        to_date('2018-11-03 22:21:31', 'yyyy-MM-dd hh24:mi:ss'),
        to_date('2018-11-03 22:21:31', 'yyyy-MM-dd hh24:mi:ss'),
        'XXL', '',
        'CRON', '0 0 0 * * ? *',
        'DO_NOTHING', 'FIRST',
        'demoJobHandler', '',
        'SERIAL_EXECUTION', 0, 0,
        'BEAN', '', 'GLUE代码初始化',
        to_date('2018-11-03 22:21:31', 'yyyy-MM-dd hh24:mi:ss'),
        '');

INSERT INTO XXL_JOB_USER(ID, USERNAME, PASSWORD, ROLE, PERMISSION)
VALUES (1, 'admin', 'e10adc3949ba59abbe56e057f20f883e', 1, NULL);

INSERT INTO XXL_JOB_LOCK (LOCK_NAME)
VALUES ('schedule_lock');

COMMIT;
