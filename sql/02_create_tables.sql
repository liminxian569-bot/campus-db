/* =========================================================
   02_create_tables.sql
   建立 6 張資料表（符合 3NF）
   Users ─< GroupMembers >─ ExpenseGroups      (M:N)
   ExpenseGroups ─< Expenses ─< ExpenseShares   (1:N, 1:N)
   ExpenseGroups ─< Settlements                (1:N)
   ========================================================= */
USE CampusSplitDB;
GO

-- 1. 使用者
CREATE TABLE Users (
    user_id     INT IDENTITY(1,1) PRIMARY KEY,
    student_no  NVARCHAR(20)  NOT NULL UNIQUE,      -- 學號
    user_name   NVARCHAR(50)  NOT NULL,
    email       NVARCHAR(100) NULL,
    created_at  DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);
GO

-- 2. 群組（宿舍／社團／班級）
CREATE TABLE ExpenseGroups (
    group_id    INT IDENTITY(1,1) PRIMARY KEY,
    group_name  NVARCHAR(50)  NOT NULL,
    group_type  NVARCHAR(10)  NOT NULL
        CONSTRAINT CK_ExpenseGroups_Type CHECK (group_type IN (N'宿舍', N'社團', N'班級')),
    created_at  DATETIME2     NOT NULL DEFAULT SYSDATETIME()
);
GO

-- 3. 群組成員（Users 與 ExpenseGroups 的 M:N 關聯表）
CREATE TABLE GroupMembers (
    group_id    INT           NOT NULL,
    user_id     INT           NOT NULL,
    member_role NVARCHAR(10)  NOT NULL DEFAULT N'member'
        CONSTRAINT CK_GroupMembers_Role CHECK (member_role IN (N'admin', N'member')),
    joined_at   DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT PK_GroupMembers PRIMARY KEY (group_id, user_id),
    CONSTRAINT FK_GroupMembers_Group FOREIGN KEY (group_id) REFERENCES ExpenseGroups(group_id),
    CONSTRAINT FK_GroupMembers_User  FOREIGN KEY (user_id)  REFERENCES Users(user_id)
);
GO

-- 4. 支出（付款人必須是該群組成員：複合外鍵指向 GroupMembers）
CREATE TABLE Expenses (
    expense_id    INT IDENTITY(1,1) PRIMARY KEY,
    group_id      INT            NOT NULL,
    payer_id      INT            NOT NULL,
    title         NVARCHAR(100)  NOT NULL,
    amount        DECIMAL(10,2)  NOT NULL CONSTRAINT CK_Expenses_Amount CHECK (amount > 0),
    category      NVARCHAR(20)   NOT NULL DEFAULT N'其他',
    expense_date  DATE           NOT NULL,
    is_recurring  BIT            NOT NULL DEFAULT 0,   -- 期末擴充：週期性帳單
    created_at    DATETIME2      NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Expenses_Member FOREIGN KEY (group_id, payer_id)
        REFERENCES GroupMembers(group_id, user_id)
);
GO

-- 5. 分攤明細（每筆支出每位成員應付多少）
CREATE TABLE ExpenseShares (
    expense_id    INT           NOT NULL,
    user_id       INT           NOT NULL,
    share_amount  DECIMAL(10,2) NOT NULL CONSTRAINT CK_ExpenseShares_Amount CHECK (share_amount >= 0),
    CONSTRAINT PK_ExpenseShares PRIMARY KEY (expense_id, user_id),
    CONSTRAINT FK_ExpenseShares_Expense FOREIGN KEY (expense_id)
        REFERENCES Expenses(expense_id) ON DELETE CASCADE,
    CONSTRAINT FK_ExpenseShares_User FOREIGN KEY (user_id) REFERENCES Users(user_id)
);
GO

-- 6. 還款紀錄（from 付錢給 to）
CREATE TABLE Settlements (
    settlement_id  INT IDENTITY(1,1) PRIMARY KEY,
    group_id       INT           NOT NULL,
    from_user_id   INT           NOT NULL,
    to_user_id     INT           NOT NULL,
    amount         DECIMAL(10,2) NOT NULL CONSTRAINT CK_Settlements_Amount CHECK (amount > 0),
    settled_at     DATETIME2     NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT CK_Settlements_DiffUser CHECK (from_user_id <> to_user_id),
    CONSTRAINT FK_Settlements_From FOREIGN KEY (group_id, from_user_id)
        REFERENCES GroupMembers(group_id, user_id),
    CONSTRAINT FK_Settlements_To FOREIGN KEY (group_id, to_user_id)
        REFERENCES GroupMembers(group_id, user_id)
);
GO

-- 常用查詢的索引
CREATE INDEX IX_Expenses_Group_Date ON Expenses(group_id, expense_date);
CREATE INDEX IX_ExpenseShares_User  ON ExpenseShares(user_id);
GO
