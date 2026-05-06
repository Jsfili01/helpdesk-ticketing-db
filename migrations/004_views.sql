-- =============================================================
-- 004_views.sql
-- Purpose: Defines views that provide simplified access to ticket information
-- Run after: 001_init.sql, 002_seed_data.sql, 003_triggers.sql
-- Team: Julian Chavez, Jordan Sfiligoj, Joshua Torres
-- Course: CPSC 332 – CSUF
-- =============================================================

-- =============================================================
-- SECTION 2: VIEW
-- =============================================================

-- -------------------------------------------------------------
-- VIEW: vw_ticket_dashboard
-- Provides a unified, human-readable summary of every ticket
-- in the system. Joins all related tables so reports and
-- application queries can pull full ticket context without
-- writing repeated multi-table JOINs each time.
--
-- Columns:
--   ticket_id, ticket_title, status, category,
--   submitted_by, submitter_department,
--   assigned_technicians (comma-separated),
--   creation_date, resolution_date, resolution_details
-- -------------------------------------------------------------

CREATE OR REPLACE VIEW vw_ticket_dashboard AS
SELECT
  t.ticket_id,
  t.title                                   AS ticket_title,
  s.status_name                             AS status,
  c.category_name                           AS category,
  eu_emp.name                               AS submitted_by,
  d.department_name                         AS submitter_department,
  STRING_AGG(tech_emp.name, ', '
    ORDER BY tech_emp.name)                 AS assigned_technicians,
  t.creation_date,
  t.resolution_date,
  t.resolution_details
FROM Ticket t
JOIN Status    s       ON s.status_id        = t.status_id
JOIN Category  c       ON c.category_id      = t.category_id
JOIN End_User  eu      ON eu.employee_id     = t.End_User_id
JOIN Employee  eu_emp  ON eu_emp.employee_id = eu.employee_id
JOIN Department d      ON d.department_id    = eu.department_id
LEFT JOIN Assignments  a        ON a.ticket_id       = t.ticket_id
LEFT JOIN Technician   tech     ON tech.employee_id  = a.technician_id
LEFT JOIN Employee     tech_emp ON tech_emp.employee_id = tech.employee_id
GROUP BY
  t.ticket_id, t.title, s.status_name, c.category_name,
  eu_emp.name, d.department_name, t.creation_date,
  t.resolution_date, t.resolution_details;