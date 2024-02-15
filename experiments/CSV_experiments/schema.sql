CREATE TABLE IF NOT EXISTS "bills" (
  "bill_id" INT,
  "session_id" INT,
  "bill_number" TEXT,
  "status" INT,
  "status_desc" TEXT,
  "status_date" TEXT,
  "title" TEXT,
  "description" TEXT,
  "committee_id" INT,
  "committee" TEXT,
  "last_action_date" TEXT,
  "last_action" TEXT,
  "url" TEXT,
  "state_link" TEXT
);
CREATE TABLE IF NOT EXISTS "history" (
  "bill_id" INT,
  "date" TEXT,
  "chamber" TEXT,
  "sequence" INT,
  "action" TEXT
);

