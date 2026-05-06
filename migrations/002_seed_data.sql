-- =============================================================
-- 002_seed_data.sql
-- Purpose: Seed sample data for IT Helpdesk Ticket Management System
-- Run after: 001_init.sql
-- Team: Julian Chavez, Jordan Sfiligoj, Joshua Torres
-- Course: CPSC 332 – CSUF
-- =============================================================
-- Note: Insert order follows FK dependencies:
--   Department -> Employee -> End_User / Technician / Admin
--   -> Status -> Category -> Ticket -> Assignments
-- =============================================================

-- -------------------------------------------------------------
-- DEPARTMENT (5 rows)
-- -------------------------------------------------------------
INSERT INTO Department (department_name, building_location) VALUES
('Finance',                'Building A'),
('Human Resources',        'Building B'),
('Facilities',             'Building C'),
('Admissions',             'Building D'),
('Information Technology', 'Building E');

-- -------------------------------------------------------------
-- EMPLOYEE (13 rows: 5 End_Users + 5 Technicians + 3 Admins)
-- -------------------------------------------------------------
INSERT INTO Employee (name, SSN, DOB, email, address) VALUES
-- End Users (will get employee_id 1-5)
('Ava Chen',        '111-22-3331', '1995-03-14', 'ava.chen@csuf.edu',        '100 Main St, Fullerton CA'),
('Miguel Torres',   '111-22-3332', '1990-07-22', 'miguel.torres@csuf.edu',   '200 Elm St, Anaheim CA'),
('Sana Patel',      '111-22-3333', '1998-11-05', 'sana.patel@csuf.edu',      '300 Oak Ave, Brea CA'),
('Derek Williams',  '111-22-3334', '1987-01-30', 'derek.williams@csuf.edu',  '400 Pine Rd, Placentia CA'),
('Lena Park',       '111-22-3335', '2000-06-18', 'lena.park@csuf.edu',       '500 Cedar Blvd, Orange CA'),
-- Technicians (will get employee_id 6-10)
('Jordan Lee',      '222-33-4441', '1993-09-10', 'jordan.lee@it.csuf.edu',   '101 Tech Ln, Fullerton CA'),
('Riley Nguyen',    '222-33-4442', '1989-04-25', 'riley.nguyen@it.csuf.edu', '202 Circuit Ave, Anaheim CA'),
('Casey Kim',       '222-33-4443', '1996-12-03', 'casey.kim@it.csuf.edu',    '303 Server St, Brea CA'),
('Morgan Davis',    '222-33-4444', '1991-08-17', 'morgan.davis@it.csuf.edu', '404 Network Rd, Placentia CA'),
('Taylor Brooks',   '222-33-4445', '1994-02-28', 'taylor.brooks@it.csuf.edu','505 Byte Blvd, Orange CA'),
-- Admins (will get employee_id 11-13)
('Alex Johnson',    '333-44-5551', '1985-05-20', 'alex.johnson@it.csuf.edu', '600 Admin Dr, Fullerton CA'),
('Sam Rivera',      '333-44-5552', '1982-10-11', 'sam.rivera@it.csuf.edu',   '700 Control St, Anaheim CA'),
('Jamie Wu',        '333-44-5553', '1979-03-07', 'jamie.wu@it.csuf.edu',     '800 Manage Ave, Brea CA');

-- -------------------------------------------------------------
-- END_USER (5 rows — mapped to employee_id 1-5)
-- -------------------------------------------------------------
INSERT INTO End_User (employee_id, department_id) VALUES
(1, 1),   -- Ava Chen       -> Finance
(2, 3),   -- Miguel Torres  -> Facilities
(3, 4),   -- Sana Patel     -> Admissions
(4, 2),   -- Derek Williams -> Human Resources
(5, 1);   -- Lena Park      -> Finance

-- -------------------------------------------------------------
-- TECHNICIAN (5 rows — mapped to employee_id 6-10)
-- -------------------------------------------------------------
INSERT INTO Technician (employee_id, skill_level) VALUES
(6,  'Senior'),
(7,  'Mid-Level'),
(8,  'Junior'),
(9,  'Senior'),
(10, 'Mid-Level');

-- -------------------------------------------------------------
-- ADMIN (3 rows — mapped to employee_id 11-13)
-- -------------------------------------------------------------
INSERT INTO Admin (employee_id, admin_level) VALUES
(11, 'Super Admin'),
(12, 'Department Admin'),
(13, 'Department Admin');

-- -------------------------------------------------------------
-- STATUS ( 3 rows only - CHECK constraints in 001_init.sql restricts
--valid values to exactly: 'Open', 'In Progress', 'Closed'. 
-- A 4th or 5th row would violate the schema by design.)
-- -------------------------------------------------------------
INSERT INTO Status (status_name) VALUES
('Open'),
('In Progress'),
('Closed');

-- -------------------------------------------------------------
-- CATEGORY (5 rows)
-- -------------------------------------------------------------
INSERT INTO Category (category_name) VALUES
('Network'),
('Hardware'),
('Software'),
('Account Access'),
('Other');

-- -------------------------------------------------------------
-- TICKET (8 rows)
-- Note: Closed tickets need resolution_details AND resolution_date
--       Open/In Progress tickets must leave those NULL
-- -------------------------------------------------------------
INSERT INTO Ticket (title, description, creation_date, resolution_details, resolution_date, status_id, category_id, End_User_id) VALUES

-- Open tickets (status_id = 1)
('Wi-Fi drops every 5 minutes',
 'Laptop disconnects from campus Wi-Fi repeatedly near the library.',
 NOW() - INTERVAL '3 days', NULL, NULL, 1, 1, 1),

('Request software install: Zoom',
 'Requesting Zoom installation on staff workstation.',
 NOW() - INTERVAL '1 day', NULL, NULL, 1, 3, 3),

('Keyboard not responding',
 'USB keyboard stopped working after a system update.',
 NOW() - INTERVAL '2 days', NULL, NULL, 1, 2, 5),

-- In Progress tickets (status_id = 2)
('Printer jam in Building A',
 'Office printer shows error code E13 and jams repeatedly.',
 NOW() - INTERVAL '5 days', NULL, NULL, 2, 2, 2),

('Cannot access shared drive',
 'Permission denied error when opening the shared Finance drive.',
 NOW() - INTERVAL '4 days', NULL, NULL, 2, 4, 4),

-- Closed tickets (status_id = 3) must have resolution_details and resolution_date
('Email account locked out',
 'User locked out of CSUF email after too many failed login attempts.',
 NOW() - INTERVAL '10 days',
 'Reset account credentials and re-enabled MFA. User confirmed access restored.',
 NOW() - INTERVAL '9 days', 3, 4, 1),

('Monitor flickering on startup',
 'External monitor flickers for 30 seconds on startup.',
 NOW() - INTERVAL '7 days',
 'Replaced HDMI cable. Issue resolved after cable swap.',
 NOW() - INTERVAL '6 days', 3, 2, 3),

('VPN connection failing off-campus',
 'Unable to connect to campus VPN from home network.',
 NOW() - INTERVAL '14 days',
 'Updated VPN client and reconfigured network profile. Confirmed working.',
 NOW() - INTERVAL '12 days', 3, 1, 2);

-- -------------------------------------------------------------
-- ASSIGNMENTS (9 rows)
-- Note: ticket 4 has two technicians assigned (BR #6)
-- -------------------------------------------------------------
INSERT INTO Assignments (ticket_id, technician_id) VALUES
(1, 7),   -- Wi-Fi issue          -> Riley Nguyen
(2, 8),   -- Zoom install         -> Casey Kim
(3, 10),  -- Keyboard             -> Taylor Brooks
(4, 6),   -- Printer jam          -> Jordan Lee
(4, 9),   -- Printer jam also     -> Morgan Davis (multiple techs!)
(5, 7),   -- Shared drive         -> Riley Nguyen
(6, 9),   -- Email lockout        -> Morgan Davis
(7, 6),   -- Monitor flicker      -> Jordan Lee
(8, 10);  -- VPN issue            -> Taylor Brooks


