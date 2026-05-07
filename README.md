# IT Helpdesk Ticket Management System

A relational database system for tracking, managing, and resolving IT support requests within an organization, built with PostgreSQL and deployed on Supabase.

**Course:** CPSC 332 - File Structures and Database Systems  
**Institution:** California State University, Fullerton  
**Instructor:** Professor Wuttisasiwat  
**Team:** Julian Chavez, Jordan Sfiligoj, Joshua Torres

---

## Table of Contents

- [System Overview](#system-overview)
- [Schema Design](#schema-design)
- [Business Rules](#business-rules)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Running Migrations](#running-migrations)
- [Example Queries](#example-queries)
- [Team Contributions](#team-contributions)

---

## System Overview

The IT Helpdesk Ticket Management System centralizes all help desk operations for an organization. It allows:

- Employees (End Users) to submit IT support tickets
- IT Technicians to be assigned to and resolve tickets
- Administrators to monitor performance and service efficiency

The system tracks user information, submitted tickets, technician assignments, ticket status lifecycles, and full resolution history. This enables accountability, faster response times, and data-driven IT management.

---

## Schema Design

### Entity Overview

| Table | Type | Description |
|-------|------|-------------|
| `Employee` | Core (Supertype) | Shared attributes for all staff |
| `End_User` | Core (Subtype) | Employees who can submit tickets |
| `Technician` | Core (Subtype) | IT staff who resolve tickets |
| `Admin` | Core (Subtype) | Administrators who monitor the system |
| `Ticket` | Core | Central record of each IT support request |
| `Assignments` | Core (Junction) | M:N bridge between Tickets and Technicians |
| `Department` | Lookup | Organizational units End_Users belong to |
| `Status` | Lookup | Valid ticket statuses (Open, In Progress, Closed) |
| `Category` | Lookup | Issue type classification (Network, Hardware, etc.) |

### Relationships

| Relationship | Cardinality | Notes |
|---|---|---|
| Employee to End_User / Technician / Admin | 1:1 | Disjoint subclass inheritance |
| End_User to Department | N:1 | Each user belongs to one department |
| End_User to Ticket | 1:N | A user may submit many tickets |
| Ticket to Status | N:1 | Each ticket has one status |
| Ticket to Category | N:1 | Each ticket belongs to one category |
| Ticket to Technician | M:N | Resolved via the Assignments junction table |

### ER Diagram

See `/docs/dbdiagram_schema.png` for the full diagram or view it live at the DBDiagram link below.

---

## Business Rules

1. Each employee must have a unique `employee_id`, `email`, and `SSN`
2. Each employee must belong to exactly one subclass: `End_User`, `Technician`, or `Admin`
3. Each `End_User` must belong to exactly one `Department`
4. Only `End_Users` are allowed to submit tickets
5. A ticket must be associated with exactly one `End_User`
6. A ticket can be assigned to multiple technicians via the `Assignments` table
7. A `Technician` must exist before being assigned to a ticket
8. Ticket `status` must be one of `{Open, In Progress, Closed}`
9. A ticket's `resolution_details` can only be set when the ticket is `Closed` (enforced by trigger)
10. `resolution_date` must be later than `creation_date`
11. Employee `DOB` must be a valid past date
12. Duplicate tickets (same user + same title + same timestamp) are not allowed

---

## Repository Structure

```
helpdesk-ticketing-db/
|
|-- docs/
|   |-- Phase 1_ Proposal.pdf      # Original Phase 1 APA proposal
|   |-- dbdiagram_schema.dbml      # DBML schema for dbdiagram.io
|   `-- dbdiagram_schema.png       # ER diagram exported from dbdiagram.io
|
|-- migrations/
|   |-- 001_init.sql               # CREATE TABLE statements, PKs, FKs, constraints, indexes
|   |-- 002_seed_data.sql          # INSERT statements, 5+ rows per table
|   |-- 003_triggers.sql           # Trigger enforcing business rules #9 and #10
|   |-- 004_views.sql              # View providing unified ticket dashboard
|   `-- 005_queries.sql            # SELECT, UPDATE, and DELETE query examples
|
`-- README.md
```

---

## Getting Started

### Prerequisites

- A [Supabase](https://supabase.com) account (free tier works)
- Or any PostgreSQL-compatible cloud DB (Neon, Railway, Render, etc.)

### Cloud Setup (Supabase)

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Navigate to **SQL Editor** in the left sidebar
3. Run the migration files in order (see below)

---

## Running Migrations

Run these files in the Supabase SQL Editor in this exact order:

### Step 1 - Build the Schema
```sql
-- Paste and run the contents of:
migrations/001_init.sql
```
Creates all tables, primary keys, foreign keys, CHECK constraints, and indexes.

### Step 2 - Seed Sample Data
```sql
-- Paste and run the contents of:
migrations/002_seed_data.sql
```
Inserts realistic sample data: 5 departments, 13 employees (5 end users, 5 technicians, 3 admins), 8 tickets, and 9 assignments.

### Step 3 - Create Triggers
```sql
-- Paste and run the contents of:
migrations/003_triggers.sql
```
Creates `trg_enforce_closed_ticket_resolution`, which enforces business rules #9 and #10 on every ticket insert and update.

### Step 4 - Create Views
```sql
-- Paste and run the contents of:
migrations/004_views.sql
```
Creates `vw_ticket_dashboard`, a unified view joining all 9 tables for simplified ticket reporting.

### Step 5 - Run Query Examples
```sql
-- Paste and run the contents of:
migrations/005_queries.sql
```
Demonstrates all CRUD operations: 7 SELECT queries with JOINs, 7 UPDATE queries, and 6 DELETE queries.

---

## Example Queries

### Trigger in Action
```sql
-- This will raise an exception: cannot close a ticket without resolution details
UPDATE Ticket
SET status_id = (SELECT status_id FROM Status WHERE status_name = 'Closed')
WHERE ticket_id = 1;
```

### View - Full Ticket Dashboard
```sql
SELECT * FROM vw_ticket_dashboard ORDER BY creation_date DESC;
```

### Select - Open Tickets with Submitter Info
```sql
SELECT t.ticket_id, t.title, e.name AS submitted_by, e.email, d.department_name
FROM Ticket t
JOIN End_User   eu ON eu.employee_id  = t.End_User_id
JOIN Employee   e  ON e.employee_id   = eu.employee_id
JOIN Department d  ON d.department_id = eu.department_id
JOIN Status     s  ON s.status_id     = t.status_id
WHERE s.status_name = 'Open';
```

---

## Team Contributions

| Team Member | Contributions |
|---|---|
| Julian Chavez | Schema design, `001_init.sql`, business rules |
| Jordan Sfiligoj | Seed data, `002_seed_data.sql`, GitHub setup |
| Joshua Torres | `003_triggers.sql`, `004_views.sql`, `005_queries.sql`, README |

View full commit history: [GitHub Contributors](https://github.com/Jsfili01/helpdesk-ticketing-db/graphs/contributors)

---

## Project Links

| Resource | Link |
|---|---|
| GitHub Repository | https://github.com/Jsfili01/helpdesk-ticketing-db |
| DBDiagram Schema | https://dbdiagram.io/d/dbdiagram_schema-69f9637ac6a36f9c1b045ce7 |
| Cloud Demo Video | *(screen recording link)* |
| Supabase Project | https://etmaozrxnpkqriiazplg.supabase.co |
