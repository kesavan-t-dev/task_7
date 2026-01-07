--USE DATABASE
use kesavan_db
GO


                         --- TABLE AND VALUES----
--Drop tables and add values
DROP TABLE task

DROP TABLE project

                        --------PROJECT TABLE------------
--Project Table
CREATE TABLE project
(
	project_id INT IDENTITY(1,1) PRIMARY KEY,
	project_name VARCHAR(150) UNIQUE NOT NULL,
	start_date DATE NOT NULL,
	end_date DATE NOT NULL,
	budget MONEY ,
	status VARCHAR(50) DEFAULT 'Not Started',

	--Constraints for end date field
	    CONSTRAINT CHECK_end_date_After_starts_date 
        CHECK (end_date >= start_date),
)
GO

--Inserting values:
INSERT INTO project (project_name, start_date, end_date, budget, status)
VALUES 
    ('Website Redesign', '2025-01-01', '2025-06-30', 15000.00, 'Completed'),
    ('Mobile App Development', '2025-02-15', '2025-07-15', 25000.00, 'Completed'),
    ('Market Research', '2025-03-01', '2026-05-31', 10000.00, 'In Progress'),
    ('Annual Report Preparation', '2025-04-01', '2025-12-31', 12000.00, 'In Progress')
GO


                        ----------------TASK TABLE-------------------------

-- Create the TASK table
CREATE TABLE task (
    task_id INT IDENTITY(1,1) PRIMARY KEY,
    task_name VARCHAR(150) NOT NULL,
    description VARCHAR(255) NOT NULL,
    start_date DATE NOT NULL,
    due_date DATE NOT NULL,
    CONSTRAINT CHECK_due_date_After_starts_date CHECK (due_date >= start_date),
    priority VARCHAR(150) 
        CONSTRAINT CK_Task_Priority CHECK (priority IN ('Low', 'Medium', 'High')),
    status VARCHAR(70) DEFAULT 'Pending',
    project_id INT FOREIGN KEY REFERENCES project(project_id)
);
GO


--inserting task values
INSERT INTO task (task_name, description, start_date, due_date, priority, status, project_id)
VALUES 
    ('Initial Design', 'Design phase for the new website', '2025-01-02', '2025-02-28', 'High', 'Completed', 1),
    ('UI Development', 'Development of user interface components', '2025-03-01', '2025-05-15', 'Medium', 'In Progress', 1),
    ('Quality Assurance', 'Testing and quality assurance', '2025-05-16', '2025-06-15', 'High', 'Pending', 1),
    ('API Development', 'Developing APIs for the mobile app', '2025-02-16', '2025-04-30', 'Medium', 'Completed', 2),
    ('Beta Testing', 'Conducting beta testing for the mobile app', '2025-05-01', '2025-06-30', 'High', 'In Progress', 2),
    ('Survey Analysis', 'Analyzing market research surveys', '2025-03-02', '2025-04-15', 'Low', 'Completed', 3),
    ('Report Drafting', 'Drafting the final report based on research', '2025-04-16', '2025-05-30', 'Medium', 'Pending', 3),
    ('Financial Statements', 'Preparing financial statements for the annual report', '2025-04-02', '2025-07-15', 'High', 'In Progress', 4),
    ('Final Review', 'Final review and submission of the annual report', '2025-07-16', '2025-12-15', 'High', 'Pending', 4),
    ('Client Feedback Incorporation', 'Incorporating feedback from the client into the project', '2025-02-01', '2025-03-15', 'Medium', 'In Progress', 1),
    ('Launch Preparation', 'Preparing for the official launch of the mobile app', '2025-06-01', '2025-07-01', 'High', 'Pending', 2);
    
  


                        ------- Create a Trigger on the Project Table:-----------------------



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
DROP TRIGGER IF EXISTS dbo.trg_AuditTaskChanges;



CREATE TRIGGER trg_AuditTaskChanges
ON task
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
   IF EXISTS (SELECT 1 FROM inserted)
        AND NOT EXISTS (SELECT 1 FROM deleted)
           BEGIN
           INSERT INTO task_audit
                (old_task_id, new_task_id,
                old_task_name, new_task_name,
                old_description, new_description,
                old_start_date, new_start_date,
                old_due_date, new_due_date,
                old_priority, new_priority,
                old_status, new_status,
                action_type)
                SELECT
                  i.task_id,i.task_id,
                  i.task_name,i.task_name,
                  i.description,i.description,
                  i.start_date,i.start_date,
                  i.due_date,i.due_date,
                  i.priority,i.priority,
                  i.status,i.status,
                   'INSERT'
                  FROM inserted i
                  LEFT JOIN deleted d
                  ON i.task_id = d.task_id
                  WHERE d.task_id IS NULL;
             END
     ELSE IF EXISTS (SELECT 1 FROM inserted)
       AND EXISTS (SELECT 1 FROM deleted)
         BEGIN
              INSERT INTO task_audit
                      (old_task_id, new_task_id,
                old_task_name, new_task_name,
                old_description, new_description,
                old_start_date, new_start_date,
                old_due_date, new_due_date,
                old_priority, new_priority,
                old_status, new_status,
                action_type)
              SELECT
                d.task_id,d.task_id,
                d.task_name,d.task_name,
                d.description,d.description,
                d.start_date,d.start_date,
                d.due_date,d.due_date,
                d.priority,d.priority,
                d.status,d.status,
                'UPDATE'
              FROM deleted d
           INNER JOIN inserted i
              ON d.task_id = i.task_id;
         END
    ELSE IF EXISTS (SELECT 1 FROM deleted)
      AND NOT EXISTS (SELECT 1 FROM inserted)
         BEGIN
            INSERT INTO task_audit
                (old_task_id, new_task_id,
                    old_task_name, new_task_name,
                    old_description, new_description,
                    old_start_date, new_start_date,
                    old_due_date, new_due_date,
                    old_priority, new_priority,
                    old_status, new_status,
                    action_type)
            SELECT
                d.task_id,d.task_id,
                d.task_name,d.task_name,
                d.description,d.description,
                d.start_date,d.start_date,
                d.due_date,d.due_date,
                d.priority,d.priority,
                d.status,d.status,
                'DELETE'
                FROM deleted d
                LEFT JOIN inserted i
                ON d.task_id = i.task_id
                WHERE i.task_id IS NULL;
        END
END
GO



--DROP task_audit table 
--DROP TABLE task_audit;

--  Check audit log before 
SELECT * FROM task_audit;

-- Test INSERT
INSERT INTO task (task_name, description, start_date, due_date, priority, status, project_id)
VALUES ('test sample', 'Testing insert trigger', '2025-04-01', '2026-04-18', 'Low', 'Completed', 1);

SELECT * FROM task

-- Test UPDATE
UPDATE task
SET  description ='testing update trigges'
WHERE task_name = 'test sample';

-- Test DELETE
DELETE FROM task
WHERE task_name = 'test sample';


--View audit log
SELECT * FROM task_audit ORDER BY audit_id DESC;

select * from task
