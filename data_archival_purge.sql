-- Step 1: Create Archive Tables
CREATE TABLE orders_archive AS SELECT * FROM orders WHERE 1=0;
CREATE TABLE audit_logs_archive AS SELECT * FROM audit_logs WHERE 1=0;
CREATE TABLE customer_transactions_archive AS SELECT * FROM customer_transactions WHERE 1=0;

-- Step 2: PL/SQL Procedure to Archive Data
CREATE OR REPLACE PROCEDURE archive_old_data AS
BEGIN
    INSERT INTO orders_archive
    SELECT * FROM orders WHERE order_date < SYSDATE - 90;
    
    INSERT INTO audit_logs_archive
    SELECT * FROM audit_logs WHERE log_date < SYSDATE - 90;
    
    INSERT INTO customer_transactions_archive
    SELECT * FROM customer_transactions WHERE transaction_date < SYSDATE - 90;
    
    COMMIT;
END;
/

-- Step 3: PL/SQL Procedure to Purge Old Data
CREATE OR REPLACE PROCEDURE purge_old_data AS
BEGIN
    DELETE FROM orders WHERE order_date < SYSDATE - 180;
    DELETE FROM audit_logs WHERE log_date < SYSDATE - 180;
    DELETE FROM customer_transactions WHERE transaction_date < SYSDATE - 180;
    
    COMMIT;
END;
/

-- Step 4: Schedule the Archival & Purging Jobs
BEGIN
    -- Schedule Archival Job (Runs Daily)
    DBMS_SCHEDULER.create_job (
        job_name        => 'DATA_ARCHIVAL_JOB',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN archive_old_data; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; INTERVAL=1',
        enabled         => TRUE
    );

    -- Schedule Purging Job (Runs Daily)
    DBMS_SCHEDULER.create_job (
        job_name        => 'DATA_PURGING_JOB',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'BEGIN purge_old_data; END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; INTERVAL=1',
        enabled         => TRUE
    );
END;
/

-- Step 5: Generate Reports on Archived Data
SELECT table_name, COUNT(*) AS archived_records
FROM user_tables
WHERE table_name LIKE '%ARCHIVE%'
GROUP BY table_name;