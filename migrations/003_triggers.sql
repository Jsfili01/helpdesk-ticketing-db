-- =============================================================
-- 003_triggers.sql
-- Purpose: Triggers that enforce important ticket rules
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