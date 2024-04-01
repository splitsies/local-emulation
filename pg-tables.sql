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