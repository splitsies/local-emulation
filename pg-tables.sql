CREATE TABLE "Expense" (
    "id"              VARCHAR(36) PRIMARY KEY,
    "transactionDate" TIMESTAMPTZ NOT NULL,
    "name"            VARCHAR(60) NOT NULL
);

CREATE TABLE "UserExpense" (
    "expenseId"         VARCHAR(36) REFERENCES "Expense" ("id"),
    "userId"            VARCHAR(52) NOT NULL,
    "pendingJoin"       BOOLEAN NOT NULL,
    "requestingUserId"  VARCHAR(36), 
    "createdAt"         TIMESTAMPTZ,
    PRIMARY KEY("expenseId", "userId")
);

CREATE FUNCTION exists_as_child(id VARCHAR(36))
RETURNS boolean AS $$
DECLARE
	rec_count INTEGER;
BEGIN
	SELECT COUNT(*)
	  INTO rec_count
	  FROM "ExpenseGroup"
	 WHERE "childExpenseId" = id;

	RETURN rec_count > 0;
END; 
$$
LANGUAGE plpgsql;

CREATE FUNCTION exists_as_parent(id VARCHAR(36))
RETURNS boolean AS $$
DECLARE
	rec_count INTEGER;
BEGIN
	SELECT COUNT(*)
	  INTO rec_count
	  FROM "ExpenseGroup"
	 WHERE "parentExpenseId" = id;

	RETURN rec_count > 0;
END; 
$$
LANGUAGE plpgsql;

CREATE TABLE "ExpenseGroup" (
    "parentExpenseId" VARCHAR(36) REFERENCES "Expense" ("id") ON DELETE CASCADE,
    "childExpenseId" VARCHAR(36) REFERENCES "Expense" ("id") ON DELETE CASCADE,
    PRIMARY KEY("parentExpenseId", "childExpenseId"),
    CONSTRAINT ck_ids_not_equal CHECK ("parentExpenseId" <> "childExpenseId"),
	CONSTRAINT ck_parent_not_child CHECK (exists_as_child("parentExpenseId") = FALSE),
	CONSTRAINT ck_child_not_parent CHECK (exists_as_parent("childExpenseId") = FALSE),
	CONSTRAINT unq_child_id UNIQUE ("childExpenseId")
);