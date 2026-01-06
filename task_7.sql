--USE DATABASE
use kesavan_db
GO

/*
--- Create a Trigger on the Project Table:
*/

/*
1. Create a trigger named trg_UpdateProjectStatus on the Project table.
Note this needs to Automatically update the Status of a project to 'Completed' when the EndDate is set.
*/


DROP TRIGGER IF EXISTS dbo.trg_update_project_status;

CREATE OR ALTER TRIGGER trg_update_project_status
ON project
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE p
    SET status = CASE 
                    WHEN i.end_date < CAST(GETDATE() AS DATE) THEN 'Completed'
                    ELSE 'In Progress'
                 END
    FROM project p
    INNER JOIN inserted i 
        ON p.project_id = i.project_id;
END
GO

/*
SELECT name, is_instead_of_trigger  
FROM sys.triggers    
WHERE type = 'TR';
*/

---- Check current status before update
SELECT project_id, project_name, end_date, status
FROM project


-- Update end_date 
UPDATE project
SET end_date = '2026-01-06'
WHERE project_id = 16 ;

SELECT * FROM project 


/*
--- Create a Trigger on the Task Table:
*/

/*
1. Create a trigger named trg_AuditTaskChanges on the Task table.
Note this needs to Automatically log changes to the Task table into a TaskAudit table whenever a task is updated.
*/


-- Create TaskAudit table if it doesn't exist
IF OBJECT_ID('dbo.task_audit', 'U') IS NOT NULL
    DROP TABLE dbo.task_audit
    -- Reset so next insert will be 1
    DBCC CHECKIDENT ('task_audit', RESEED, 0);

GO

DROP TABLE IF EXISTS task_audit;
GO

CREATE TABLE task_audit (
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    old_task_id INT NULL,
    new_task_id INT NULL,
    old_task_name VARCHAR(150) NULL,
    new_task_name VARCHAR(150) NULL,
    old_description VARCHAR(255) NULL,
    new_description VARCHAR(255) NULL,
    old_start_date DATE NULL,
    new_start_date DATE NULL,
    old_due_date DATE NULL,
    new_due_date DATE NULL,
    old_priority VARCHAR(150) NULL,
    new_priority VARCHAR(150) NULL,
    old_status VARCHAR(70) NULL,
    new_status VARCHAR(70) NULL,
    changed_by SYSNAME DEFAULT SUSER_SNAME(),
    changed_on DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
    action_type VARCHAR(10) NOT NULL
);
GO


select * from task_audit;
GO

-- drop if already exists 
DROP TRIGGER IF EXISTS dbo.trg_audit_task_changes;



CREATE OR ALTER TRIGGER trg_audit_task_changes
ON dbo.task
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.task_audit (
        old_task_id, new_task_id,
        old_task_name, new_task_name,
        old_description, new_description,
        old_start_date, new_start_date,
        old_due_date, new_due_date,
        old_priority, new_priority,
        old_status, new_status,
        action_type
    )

    SELECT
        NULL, i.task_id,
        NULL, i.task_name,
        NULL, i.description,
        NULL, i.start_date,
        NULL, i.due_date,
        NULL, i.priority,
        NULL, i.status,
        'INSERT'
    FROM inserted i
    LEFT JOIN deleted d ON d.task_id = i.task_id
    WHERE d.task_id IS NULL

    UNION ALL

    SELECT
        d.task_id, i.task_id,
        d.task_name, i.task_name,
        d.description, i.description,
        d.start_date, i.start_date,
        d.due_date, i.due_date,
        d.priority, i.priority,
        d.status, i.status,
        'UPDATE'
    FROM inserted i
    INNER JOIN deleted d ON d.task_id = i.task_id

    UNION ALL

    SELECT
        d.task_id, NULL,
        d.task_name, NULL,
        d.description, NULL,
        d.start_date, NULL,
        d.due_date, NULL,
        d.priority, NULL,
        d.status, NULL,
        'DELETE'
    FROM deleted d
    LEFT JOIN inserted i ON i.task_id = d.task_id
    WHERE i.task_id IS NULL;
END
GO



--DROP task_audit table 
--DROP TABLE task_audit;

--  Check audit log before 
SELECT * FROM task_audit;

-- Test INSERT
INSERT INTO task (task_name, description, start_date, due_date, priority, status, project_id)
VALUES ('New asd Test', 'Testing insert trigger', '2025-04-01', '2026-08-15', 'Low', 'Completed', 1);

SELECT * FROM task

-- Test UPDATE
UPDATE task
SET  description ='testing update trigges'
WHERE task_name = 'New asd Test';

-- Test DELETE
DELETE FROM task
WHERE task_name = 'New  Test';

DELETE FROM task
WHERE task_id = 23

--View audit log
SELECT * FROM task_audit ORDER BY audit_id DESC;

select * from task
