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
    task_name VARCHAR(150),
    descriptions VARCHAR(255),
    starts_date DATE,
    due_date DATE,
    prioritys VARCHAR(150),
    statuss VARCHAR(70),
    action_type VARCHAR(10), 
    changed_by SYSNAME DEFAULT SUSER_SNAME(),
    changed_on DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()

    );
GO

select * from task_audit;
GO

-- drop if already exists 
DROP TRIGGER IF EXISTS dbo.trg_audit_task_changes;

--create trigger
CREATE OR ALTER TRIGGER trg_AuditTaskChanges
ON task
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO task_audit (task_id, task_name, descriptions, starts_date, due_date, prioritys, statuss, action_type)
    SELECT 
        i.task_id, i.task_name, i.descriptions, i.starts_date, i.due_date, i.prioritys, i.statuss, 'INSERT'
    FROM inserted i
    LEFT JOIN deleted d ON i.task_id = d.task_id
    WHERE d.task_id IS NULL; 

    INSERT INTO task_audit (task_id, task_name, descriptions, starts_date, due_date, prioritys, statuss, action_type)
    SELECT 
        d.task_id, d.task_name, d.descriptions, d.starts_date, d.due_date, d.prioritys, d.statuss, 'UPDATE'
    FROM deleted d
    INNER JOIN inserted i ON d.task_id = i.task_id;

    INSERT INTO task_audit (task_id, task_name, descriptions, starts_date, due_date, prioritys, statuss, action_type)
    SELECT 
        d.task_id, d.task_name, d.descriptions, d.starts_date, d.due_date, d.prioritys, d.statuss, 'DELETE'
    FROM deleted d
    LEFT JOIN inserted i ON d.task_id = i.task_id
    WHERE i.task_id IS NULL; 
END
GO

-- 1. Check audit log before 
SELECT * FROM task_audit;

-- 2. Test INSERT
INSERT INTO task (task_name, descriptions, starts_date, due_date, prioritys, statuss, project_id)
VALUES ('New Audit Test', 'Testing insert trigger', '2025-08-01', '2025-08-15', 'High', 'Pending', 1);

-- 3. Test UPDATE
UPDATE task
SET statuss = 'Completed'
WHERE task_name = 'New Audit Test';

-- 4. Test DELETE
DELETE FROM task
WHERE task_name = 'New Audit Test';

-- 5. View audit log
SELECT * FROM task_audit ORDER BY audit_id DESC;
select * from task
