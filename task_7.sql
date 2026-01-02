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

select * from project

DROP TRIGGER IF EXISTS dbo.trg_update_project_status;

CREATE TRIGGER trg_update_project_status
ON project
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p
    SET statuss = 'Completed'
    FROM project p
    INNER JOIN 
    inserted i ON p.project_id = i.project_id
    WHERE i.end_date <= CAST(GETDATE() AS DATE);
END
GO
/*
SELECT name, is_instead_of_trigger  
FROM sys.triggers    
WHERE type = 'TR';
*/

---- 1. Check current status before update
SELECT project_id, project_name, end_date, statuss
FROM project
WHERE project_id = 2;

-- 2. Update end_date to a past date
UPDATE project
SET end_date = '2025-12-04'
WHERE project_id = 4;

select * from project



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

CREATE TABLE task_audit (
        audit_id INT IDENTITY(1,1) PRIMARY KEY,
        task_id INT,
        old_task_name VARCHAR(150),
        old_status VARCHAR(70),
        changed_by SYSNAME DEFAULT SUSER_SNAME(),
        changed_on DATETIME DEFAULT GETDATE()
    );
GO


select * from task_audit;
GO

-- drop if already exists 
DROP TRIGGER IF EXISTS dbo.trg_audit_task_changes;

--create trigger

CREATE OR ALTER TRIGGER trg_AuditTaskChanges
ON task
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO task_audit (task_id, old_task_name, old_status)
    SELECT 
        d.task_id,
        d.task_name,
        d.statuss
    FROM deleted d
    INNER JOIN inserted i ON d.task_id = i.task_id
    WHERE 
        d.task_name <> i.task_name
        OR d.statuss <> i.statuss; 
END
GO


-- 1. See current audit log 
SELECT * FROM task;

-- 2. Update a task's status 
UPDATE task
SET statuss = 'In progess'
WHERE task_id = 12;

-- 3. Check audit log after update
SELECT * FROM task_audit;

-- 4. Update a task's name 
UPDATE task
SET task_name = ' UX Development'
WHERE task_id = 2;

-- 5. Check audit log again
SELECT * 
FROM task_audit 
ORDER BY 
    audit_id DESC;

select * from task
select * from task_audit