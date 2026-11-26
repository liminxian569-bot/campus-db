USE CampusSplitDB;
GO

INSERT INTO Users (student_no, user_name, email) VALUES
(N'B11500001', N'王小明', N'b11500001@example.edu.tw'),
(N'B11500002', N'陳大華', N'b11500002@example.edu.tw'),
(N'B11500003', N'林怡君', N'b11500003@example.edu.tw'),
(N'B11500004', N'張志豪', N'b11500004@example.edu.tw'),
(N'B11500005', N'黃雅婷', N'b11500005@example.edu.tw'),
(N'B11500006', N'劉家宏', N'b11500006@example.edu.tw');
GO

INSERT INTO ExpenseGroups (group_name, group_type) VALUES
(N'實齋 305 室',   N'宿舍'),
(N'吉他社',        N'社團'),
(N'資管二A',      N'班級');
GO

INSERT INTO GroupMembers (group_id, user_id, member_role) VALUES
(1, 1, N'admin'), (1, 2, N'member'), (1, 3, N'member'), (1, 4, N'member'),
(2, 3, N'admin'), (2, 5, N'member'), (2, 6, N'member'),
(3, 1, N'admin'), (3, 2, N'member'), (3, 3, N'member'),
(3, 4, N'member'), (3, 5, N'member'), (3, 6, N'member');
GO

EXEC sp_AddExpenseEqualSplit 1, 1, N'10 月電費',     1200, N'水電', '2026-10-31', N'1,2,3,4';
EXEC sp_AddExpenseEqualSplit 1, 2, N'10 月網路費',    600, N'網路', '2026-10-31', N'1,2,3,4';
EXEC sp_AddExpenseEqualSplit 1, 3, N'衛生紙、洗碗精', 359, N'日用品', '2026-11-03', N'1,2,3,4';
EXEC sp_AddExpenseEqualSplit 1, 1, N'11 月網路費',    600, N'網路', '2026-11-05', N'1,2,3,4';
EXEC sp_AddExpenseEqualSplit 1, 4, N'宵夜鹽酥雞',     420, N'餐飲', '2026-11-12', N'2,3,4';
EXEC sp_AddExpenseEqualSplit 1, 2, N'11 月電費',     1350, N'水電', '2026-11-30', N'1,2,3,4';
EXEC sp_AddExpenseEqualSplit 2, 3, N'吉他弦',         900, N'器材', '2026-11-08', N'3,5,6';
EXEC sp_AddExpenseEqualSplit 2, 5, N'成發場地租借',  3000, N'場地', '2026-11-20', N'3,5,6';
EXEC sp_AddExpenseEqualSplit 3, 1, N'班服',          5940, N'班費', '2026-11-02', N'1,2,3,4,5,6';
EXEC sp_AddExpenseEqualSplit 3, 6, N'期中聚餐訂金',  1000, N'餐飲', '2026-11-15', N'1,2,3,4,5,6';
EXEC sp_AddExpenseEqualSplit 3, 2, N'教授生日卡片',   100, N'其他', '2026-11-18', N'1,2,3,4,5,6';
GO

EXEC sp_AddSettlement 1, 3, 1, 300;
EXEC sp_AddSettlement 3, 4, 1, 990;
GO

SELECT N'Users' AS 資料表, COUNT(*) AS 筆數 FROM Users
UNION ALL SELECT N'ExpenseGroups', COUNT(*) FROM ExpenseGroups
UNION ALL SELECT N'GroupMembers',  COUNT(*) FROM GroupMembers
UNION ALL SELECT N'Expenses',      COUNT(*) FROM Expenses
UNION ALL SELECT N'ExpenseShares', COUNT(*) FROM ExpenseShares
UNION ALL SELECT N'Settlements',   COUNT(*) FROM Settlements;
GO
