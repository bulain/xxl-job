--
-- XXL-JOB
-- Copyright (c) 2015-present, xuxueli.
-- Oracle 12c+
--

CREATE TABLE xxl_job_info
(
    id                        NUMBER(10) NOT NULL,
    job_group                 NUMBER(10) NOT NULL,
    job_desc                  VARCHAR2(255) NOT NULL,
    add_time                  TIMESTAMP DEFAULT NULL,
    update_time               TIMESTAMP DEFAULT NULL,
    author                    VARCHAR2(64) DEFAULT NULL,
    alarm_email               VARCHAR2(255) DEFAULT NULL,
    schedule_type             VARCHAR2(50) DEFAULT 'NONE' NOT NULL,
    schedule_conf             VARCHAR2(128) DEFAULT NULL,
    misfire_strategy          VARCHAR2(50) DEFAULT 'DO_NOTHING' NOT NULL,
    executor_route_strategy   VARCHAR2(50) DEFAULT NULL,
    executor_handler          VARCHAR2(255) DEFAULT NULL,
    executor_param            VARCHAR2(512) DEFAULT NULL,
    executor_block_strategy   VARCHAR2(50) DEFAULT NULL,
    executor_timeout          NUMBER(10) DEFAULT 0 NOT NULL,
    executor_fail_retry_count NUMBER(10) DEFAULT 0 NOT NULL,
    glue_type                 VARCHAR2(50) NOT NULL,
    glue_source               CLOB,
    glue_remark               VARCHAR2(128) DEFAULT NULL,
    glue_updatetime           TIMESTAMP DEFAULT NULL,
    child_jobid               VARCHAR2(255) DEFAULT NULL,
    trigger_status            NUMBER(3) DEFAULT 0 NOT NULL,
    trigger_last_time         NUMBER(19) DEFAULT 0 NOT NULL,
    trigger_next_time         NUMBER(19) DEFAULT 0 NOT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE xxl_job_log
(
    id                        NUMBER(19) NOT NULL,
    job_group                 NUMBER(10) NOT NULL,
    job_id                    NUMBER(10) NOT NULL,
    executor_address          VARCHAR2(255) DEFAULT NULL,
    executor_handler          VARCHAR2(255) DEFAULT NULL,
    executor_param            VARCHAR2(512) DEFAULT NULL,
    executor_sharding_param   VARCHAR2(20) DEFAULT NULL,
    executor_fail_retry_count NUMBER(10) DEFAULT 0 NOT NULL,
    trigger_time              TIMESTAMP DEFAULT NULL,
    trigger_code              NUMBER(10) NOT NULL,
    trigger_msg               CLOB,
    handle_time               TIMESTAMP DEFAULT NULL,
    handle_code               NUMBER(10) NOT NULL,
    handle_msg                CLOB,
    alarm_status              NUMBER(3) DEFAULT 0 NOT NULL,
    PRIMARY KEY (id)
);

CREATE INDEX i_trigger_time ON xxl_job_log (trigger_time);
CREATE INDEX i_handle_code ON xxl_job_log (handle_code);
CREATE INDEX i_jobid_jobgroup ON xxl_job_log (job_id, job_group);
CREATE INDEX i_job_id ON xxl_job_log (job_id);

CREATE TABLE xxl_job_log_report
(
    id            NUMBER(10) NOT NULL,
    trigger_day   TIMESTAMP DEFAULT NULL,
    running_count NUMBER(10) DEFAULT 0 NOT NULL,
    suc_count     NUMBER(10) DEFAULT 0 NOT NULL,
    fail_count    NUMBER(10) DEFAULT 0 NOT NULL,
    update_time   TIMESTAMP DEFAULT NULL,
    PRIMARY KEY (id),
    CONSTRAINT i_trigger_day UNIQUE (trigger_day)
);

CREATE TABLE xxl_job_logglue
(
    id          NUMBER(10) NOT NULL,
    job_id      NUMBER(10) NOT NULL,
    glue_type   VARCHAR2(50) DEFAULT NULL,
    glue_source CLOB,
    glue_remark VARCHAR2(128) NOT NULL,
    add_time    TIMESTAMP DEFAULT NULL,
    update_time TIMESTAMP DEFAULT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE xxl_job_registry
(
    id             NUMBER(10) NOT NULL,
    registry_group VARCHAR2(50) NOT NULL,
    registry_key   VARCHAR2(255) NOT NULL,
    registry_value VARCHAR2(255) NOT NULL,
    update_time    TIMESTAMP DEFAULT NULL,
    PRIMARY KEY (id),
    CONSTRAINT i_g_k_v UNIQUE (registry_group, registry_key, registry_value)
);

CREATE TABLE xxl_job_group
(
    id           NUMBER(10) NOT NULL,
    app_name     VARCHAR2(64) NOT NULL,
    title        VARCHAR2(12) NOT NULL,
    address_type NUMBER(3) DEFAULT 0 NOT NULL,
    address_list CLOB,
    update_time  TIMESTAMP DEFAULT NULL,
    PRIMARY KEY (id)
);

CREATE TABLE xxl_job_user
(
    id         NUMBER(10) NOT NULL,
    username   VARCHAR2(50) NOT NULL,
    password   VARCHAR2(50) NOT NULL,
    role       NUMBER(3) NOT NULL,
    permission VARCHAR2(255) DEFAULT NULL,
    PRIMARY KEY (id),
    CONSTRAINT i_username UNIQUE (username)
);

CREATE TABLE xxl_job_lock
(
    lock_name VARCHAR2(50) NOT NULL,
    PRIMARY KEY (lock_name)
);


-- ------------------------------- sequences -------------------------------
-- START WITH 100：避开种子数据显式 id=1

CREATE SEQUENCE xxl_job_info_seq START WITH 100;
CREATE SEQUENCE xxl_job_log_seq START WITH 100;
CREATE SEQUENCE xxl_job_log_report_seq START WITH 100;
CREATE SEQUENCE xxl_job_logglue_seq START WITH 100;
CREATE SEQUENCE xxl_job_registry_seq START WITH 100;
CREATE SEQUENCE xxl_job_group_seq START WITH 100;
CREATE SEQUENCE xxl_job_user_seq START WITH 100;


-- ------------------------------- init data -------------------------------

INSERT INTO xxl_job_group (id, app_name, title, address_type, address_list, update_time)
VALUES (1, 'xxl-job-executor-sample', '示例执行器', 0, NULL, TIMESTAMP '2018-11-03 22:21:31');

INSERT INTO xxl_job_info (id, job_group, job_desc, add_time, update_time, author, alarm_email,
                          schedule_type, schedule_conf, misfire_strategy, executor_route_strategy,
                          executor_handler, executor_param, executor_block_strategy, executor_timeout,
                          executor_fail_retry_count, glue_type, glue_source, glue_remark, glue_updatetime,
                          child_jobid)
VALUES (1, 1, '测试任务1', TIMESTAMP '2018-11-03 22:21:31', TIMESTAMP '2018-11-03 22:21:31', 'XXL', '',
        'CRON', '0 0 0 * * ? *',
        'DO_NOTHING', 'FIRST', 'demoJobHandler', '', 'SERIAL_EXECUTION', 0, 0, 'BEAN', '', 'GLUE代码初始化',
        TIMESTAMP '2018-11-03 22:21:31', '');

INSERT INTO xxl_job_user (id, username, password, role, permission)
VALUES (1, 'admin', 'e10adc3949ba59abbe56e057f20f883e', 1, NULL);

INSERT INTO xxl_job_lock (lock_name)
VALUES ('schedule_lock');

COMMIT;
