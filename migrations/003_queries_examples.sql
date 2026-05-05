-- =============================================================
-- 003_queries_examples.sql
-- Purpose: Trigger, View, and CRUD query examples for the
--          IT Helpdesk Ticket Management System
-- Run after: 001_init.sql, 002_seed_data.sql
-- Team: Julian Chavez, Jordan Sfiligoj, Joshua Torres
-- Course: CPSC 332 – CSUF
-- =============================================================


-- =============================================================
-- SECTION 1: TRIGGER
-- =============================================================

-- -------------------------------------------------------------
-- TRIGGER: trg_enforce_closed_ticket_resolution
-- Business Rule #9: Resolution details can only exist when
-- a ticket is marked as Closed.
-- Business Rule #10: resolution_date must be after creation_date.
--
-- Fires BEFORE any INSERT or UPDATE on Ticket.
-- Rule 1: If status is Closed, resolution_details must NOT be
--         NULL. A ticket cannot be closed without an explanation.
-- Rule 2: If status is Closed and resolution_date is missing,
--         it is automatically set to NOW().
-- Rule 3: If status is Open or In Progress, resolution_details
--         and resolution_date are cleared to NULL to prevent
--         orphaned resolution data.
-- -------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_enforce_closed_ticket_resolution()
RETURNS TRIGGER AS $$
DECLARE
  v_status_name VARCHAR(20);
BEGIN
  -- Look up the status name for the incoming status_id
  SELECT status_name INTO v_status_name
  FROM Status
  WHERE status_id = NEW.status_id;

  IF v_status_name = 'Closed' THEN

    -- Rule 1: Cannot close a ticket without resolution details
    IF NEW.resolution_details IS NULL OR TRIM(NEW.resolution_details) = '' THEN
      RAISE EXCEPTION
        'Business Rule Violation: A ticket cannot be closed without resolution_details.';
    END IF;

    -- Rule 2: Auto-set resolution_date if caller did not provide it
    IF NEW.resolution_date IS NULL THEN
      NEW.resolution_date := NOW();
    END IF;

  ELSE

    -- Rule 3: Open and In Progress tickets must not carry resolution data
    NEW.resolution_details := NULL;
    NEW.resolution_date     := NULL;

  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_enforce_closed_ticket_resolution
BEFORE INSERT OR UPDATE ON Ticket
FOR EACH ROW
EXECUTE FUNCTION fn_enforce_closed_ticket_resolution();


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


-- =============================================================
-- SECTION 3: READ (SELECT) QUERIES
-- =============================================================

-- -------------------------------------------------------------
-- READ 1: Full ticket dashboard
-- Show all tickets with status, category, submitter, department,
-- and assigned technician(s) using the vw_ticket_dashboard view.
-- -------------------------------------------------------------
SELECT
  ticket_id,
  ticket_title,
  status,
  category,
  submitted_by,
  submitter_department,
  COALESCE(assigned_technicians, 'Unassigned') AS assigned_technicians,
  creation_date
FROM vw_ticket_dashboard
ORDER BY creation_date DESC;


-- -------------------------------------------------------------
-- READ 2: All Open tickets with submitter contact info
-- Useful for the helpdesk triage queue.
-- -------------------------------------------------------------
SELECT
  t.ticket_id,
  t.title,
  t.creation_date,
  e.name   AS submitted_by,
  e.email  AS contact_email,
  d.department_name
FROM Ticket     t
JOIN End_User   eu ON eu.employee_id  = t.End_User_id
JOIN Employee   e  ON e.employee_id   = eu.employee_id
JOIN Department d  ON d.department_id = eu.department_id
JOIN Status     s  ON s.status_id     = t.status_id
WHERE s.status_name = 'Open'
ORDER BY t.creation_date ASC;


-- -------------------------------------------------------------
-- READ 3: Technician workload
-- Count of active (non-Closed) tickets per technician.
-- Uses CASE WHEN inside COUNT so closed tickets are excluded
-- without dropping technicians who only have closed tickets.
-- Helps managers spot overloaded staff.
-- -------------------------------------------------------------
SELECT
  e.name             AS technician_name,
  tech.skill_level,
  COUNT(
        CASE WHEN s.status_name <> 'Closed' THEN a.ticket_id END
  ) AS active_ticket_count
FROM Technician  tech
JOIN Employee    e   ON e.employee_id    = tech.employee_id
LEFT JOIN Assignments a ON a.technician_id = tech.employee_id
LEFT JOIN Ticket      t ON t.ticket_id     = a.ticket_id
LEFT JOIN Status      s ON s.status_id     = t.status_id
GROUP BY e.name, tech.skill_level
ORDER BY active_ticket_count DESC;


-- -------------------------------------------------------------
-- READ 4: Closed tickets with turnaround time
-- Shows resolution details and how many days each ticket took
-- to resolve. Useful for measuring IT team performance.
-- -------------------------------------------------------------
SELECT
  t.ticket_id,
  t.title,
  e.name             AS resolved_for,
  t.creation_date,
  t.resolution_date,
  t.resolution_details,
  EXTRACT(DAY FROM (t.resolution_date - t.creation_date)) AS days_to_resolve
FROM Ticket   t
JOIN Status   s  ON s.status_id    = t.status_id
JOIN End_User eu ON eu.employee_id = t.End_User_id
JOIN Employee e  ON e.employee_id  = eu.employee_id
WHERE s.status_name = 'Closed'
ORDER BY days_to_resolve ASC;


-- -------------------------------------------------------------
-- READ 5: Ticket count by category
-- Shows which issue types are most common across the organization.
-- -------------------------------------------------------------
SELECT
  c.category_name,
  COUNT(t.ticket_id) AS total_tickets
FROM Category c
LEFT JOIN Ticket t ON t.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_tickets DESC;


-- -------------------------------------------------------------
-- READ 6: Technicians with no ticket assignments
-- Identifies available staff who can take on new tickets.
-- -------------------------------------------------------------
SELECT
  e.employee_id,
  e.name,
  e.email,
  tech.skill_level
FROM Technician tech
JOIN Employee   e  ON e.employee_id = tech.employee_id
WHERE NOT EXISTS (
  SELECT 1
  FROM Assignments a
  WHERE a.technician_id = tech.employee_id
);


-- -------------------------------------------------------------
-- READ 7: Tickets submitted per department
-- Helps identify which departments generate the most IT requests.
-- -------------------------------------------------------------
SELECT
  d.department_name,
  d.building_location,
  COUNT(t.ticket_id) AS tickets_submitted
FROM Department d
JOIN End_User   eu ON eu.department_id = d.department_id
JOIN Ticket     t  ON t.End_User_id   = eu.employee_id
GROUP BY d.department_name, d.building_location
ORDER BY tickets_submitted DESC;


-- =============================================================
-- SECTION 4: UPDATE QUERIES
-- =============================================================

-- -------------------------------------------------------------
-- UPDATE 1: Move ticket #1 from Open to In Progress
-- A technician has started investigating the Wi-Fi issue.
-- -------------------------------------------------------------
UPDATE Ticket
SET status_id = (SELECT status_id FROM Status WHERE status_name = 'In Progress')
WHERE ticket_id = 1;


-- -------------------------------------------------------------
-- UPDATE 2: Close ticket #2 (Zoom install request)
-- Provide resolution details; the trigger auto-fills resolution_date.
-- -------------------------------------------------------------
UPDATE Ticket
SET
  status_id          = (SELECT status_id FROM Status WHERE status_name = 'Closed'),
  resolution_details = 'Zoom installed successfully on user workstation. Verified with test call.'
WHERE ticket_id = 2;


-- -------------------------------------------------------------
-- UPDATE 3: Close ticket #3 (Keyboard not responding)
-- Provide both resolution details and an explicit resolution_date.
-- -------------------------------------------------------------
UPDATE Ticket
SET
  status_id          = (SELECT status_id FROM Status WHERE status_name = 'Closed'),
  resolution_details = 'Replaced faulty USB hub. Keyboard now functional.',
  resolution_date    = NOW()
WHERE ticket_id = 3;


-- -------------------------------------------------------------
-- UPDATE 4: Promote technician Casey Kim (employee_id = 8)
-- Skill level upgraded from Junior to Mid-Level after review.
-- -------------------------------------------------------------
UPDATE Technician
SET skill_level = 'Mid-Level'
WHERE employee_id = 8;


-- -------------------------------------------------------------
-- UPDATE 5: Correct Ava Chen's email after a domain migration
-- -------------------------------------------------------------
UPDATE Employee
SET email = 'ava.chen@titan.csuf.edu'
WHERE employee_id = 1;


-- -------------------------------------------------------------
-- UPDATE 6: Relocate the Finance department to a new building
-- -------------------------------------------------------------
UPDATE Department
SET building_location = 'Building F'
WHERE department_name = 'Finance';


-- -------------------------------------------------------------
-- UPDATE 7: Reassign ticket #5 (Shared Drive access)
-- Riley Nguyen (employee_id = 7) is replaced by Jordan Lee (6)
-- because Riley is at capacity.
-- -------------------------------------------------------------
UPDATE Assignments
SET technician_id = 6
WHERE ticket_id     = 5
  AND technician_id = 7;


-- =============================================================
-- SECTION 5: DELETE QUERIES
-- =============================================================

-- -------------------------------------------------------------
-- DELETE 1: Remove Taylor Brooks (employee_id = 10) from ticket #3
-- Ticket is closed and the assignment record is no longer needed.
-- -------------------------------------------------------------
DELETE FROM Assignments
WHERE ticket_id     = 3
  AND technician_id = 10;


-- -------------------------------------------------------------
-- DELETE 2: Remove all assignments tied to ticket #8 (VPN issue)
-- Ticket is fully closed and archived.
-- -------------------------------------------------------------
DELETE FROM Assignments
WHERE ticket_id = 8;


-- -------------------------------------------------------------
-- DELETE 3: Delete ticket #7 (Monitor flickering)
-- Confirmed duplicate of a previously resolved incident.
-- -------------------------------------------------------------
DELETE FROM Ticket
WHERE ticket_id = 7;


-- -------------------------------------------------------------
-- DELETE 4: Delete all Closed tickets older than 30 days
-- Keeps the active ticket backlog clean and relevant.
-- -------------------------------------------------------------
DELETE FROM Ticket
WHERE status_id = (SELECT status_id FROM Status WHERE status_name = 'Closed')
  AND resolution_date < NOW() - INTERVAL '30 days';


-- -------------------------------------------------------------
-- DELETE 5: Remove the Other category if no tickets reference it
-- Safe cleanup of unused lookup values.
-- -------------------------------------------------------------
DELETE FROM Category
WHERE category_name = 'Other'
  AND NOT EXISTS (
    SELECT 1 FROM Ticket t WHERE t.category_id = Category.category_id
  );


-- -------------------------------------------------------------
-- DELETE 6: Remove a terminated employee (employee_id = 13)
-- ON DELETE CASCADE handles the Admin subtype row automatically.
-- -------------------------------------------------------------
DELETE FROM Employee
WHERE employee_id = 13;
