USE CampusSplitDB;
GO

CREATE OR ALTER VIEW vw_MemberBalance
AS
SELECT
    gm.group_id,
    g.group_name,
    gm.user_id,
    u.user_name,
    ISNULL(paid.total, 0)     AS total_paid,
    ISNULL(owed.total, 0)     AS total_owed,
    ISNULL(sent.total, 0)     AS settled_out,
    ISNULL(recv.total, 0)     AS settled_in,
    ISNULL(paid.total, 0) - ISNULL(owed.total, 0)
      + ISNULL(sent.total, 0) - ISNULL(recv.total, 0) AS net_balance
FROM GroupMembers gm
JOIN ExpenseGroups g ON g.group_id = gm.group_id
JOIN Users u         ON u.user_id  = gm.user_id
LEFT JOIN (SELECT group_id, payer_id, SUM(amount) AS total
           FROM Expenses GROUP BY group_id, payer_id) paid
       ON paid.group_id = gm.group_id AND paid.payer_id = gm.user_id
LEFT JOIN (SELECT e.group_id, s.user_id, SUM(s.share_amount) AS total
           FROM ExpenseShares s JOIN Expenses e ON e.expense_id = s.expense_id
           GROUP BY e.group_id, s.user_id) owed
       ON owed.group_id = gm.group_id AND owed.user_id = gm.user_id
LEFT JOIN (SELECT group_id, from_user_id, SUM(amount) AS total
           FROM Settlements GROUP BY group_id, from_user_id) sent
       ON sent.group_id = gm.group_id AND sent.from_user_id = gm.user_id
LEFT JOIN (SELECT group_id, to_user_id, SUM(amount) AS total
           FROM Settlements GROUP BY group_id, to_user_id) recv
       ON recv.group_id = gm.group_id AND recv.to_user_id = gm.user_id;
GO

CREATE OR ALTER PROCEDURE sp_AddExpenseEqualSplit
    @group_id     INT,
    @payer_id     INT,
    @title        NVARCHAR(100),
    @amount       DECIMAL(10,2),
    @category     NVARCHAR(20),
    @expense_date DATE,
    @participants NVARCHAR(400)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @p TABLE (user_id INT PRIMARY KEY);
    INSERT INTO @p (user_id)
    SELECT DISTINCT CAST(LTRIM(RTRIM(value)) AS INT)
    FROM STRING_SPLIT(@participants, ',')
    WHERE LTRIM(RTRIM(value)) <> '';

    DECLARE @n INT = (SELECT COUNT(*) FROM @p);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @n = 0
            THROW 50001, N'至少要有一位分攤成員', 1;

        IF EXISTS (SELECT 1 FROM @p p
                   WHERE NOT EXISTS (SELECT 1 FROM GroupMembers gm
                                     WHERE gm.group_id = @group_id AND gm.user_id = p.user_id))
            THROW 50002, N'分攤成員中有人不屬於此群組', 1;

        INSERT INTO Expenses (group_id, payer_id, title, amount, category, expense_date)
        VALUES (@group_id, @payer_id, @title, @amount, @category, @expense_date);

        DECLARE @expense_id INT = SCOPE_IDENTITY();
        DECLARE @share DECIMAL(10,2) = ROUND(@amount / @n, 2, 1);
        DECLARE @first INT = (SELECT MIN(user_id) FROM @p);

        INSERT INTO ExpenseShares (expense_id, user_id, share_amount)
        SELECT @expense_id, user_id,
               CASE WHEN user_id = @first THEN @amount - @share * (@n - 1) ELSE @share END
        FROM @p;

        COMMIT TRANSACTION;
        SELECT @expense_id AS new_expense_id;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE sp_AddSettlement
    @group_id     INT,
    @from_user_id INT,
    @to_user_id   INT,
    @amount       DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO Settlements (group_id, from_user_id, to_user_id, amount)
    VALUES (@group_id, @from_user_id, @to_user_id, @amount);
END;
GO

CREATE OR ALTER PROCEDURE sp_MonthlyReport
    @group_id INT,
    @year     INT,
    @month    INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @start DATE = DATEFROMPARTS(@year, @month, 1);
    DECLARE @end   DATE = DATEADD(MONTH, 1, @start);

    SELECT category            AS 類別,
           COUNT(*)            AS 筆數,
           SUM(amount)         AS 總金額
    FROM Expenses
    WHERE group_id = @group_id AND expense_date >= @start AND expense_date < @end
    GROUP BY category
    ORDER BY SUM(amount) DESC;

    SELECT u.user_name                         AS 成員,
           ISNULL(p.paid, 0)                   AS 本月代墊,
           ISNULL(o.owed, 0)                   AS 本月應付,
           ISNULL(p.paid, 0) - ISNULL(o.owed, 0) AS 本月差額
    FROM GroupMembers gm
    JOIN Users u ON u.user_id = gm.user_id
    LEFT JOIN (SELECT payer_id, SUM(amount) AS paid
               FROM Expenses
               WHERE group_id = @group_id AND expense_date >= @start AND expense_date < @end
               GROUP BY payer_id) p ON p.payer_id = gm.user_id
    LEFT JOIN (SELECT s.user_id, SUM(s.share_amount) AS owed
               FROM ExpenseShares s JOIN Expenses e ON e.expense_id = s.expense_id
               WHERE e.group_id = @group_id AND e.expense_date >= @start AND e.expense_date < @end
               GROUP BY s.user_id) o ON o.user_id = gm.user_id
    WHERE gm.group_id = @group_id
    ORDER BY 本月差額 DESC;
END;
GO

SELECT name AS 物件名稱,
       CASE type WHEN 'V' THEN N'View' WHEN 'P' THEN N'Stored Procedure' END AS 類型
FROM sys.objects
WHERE type IN ('V', 'P')
ORDER BY type DESC, name;
GO
