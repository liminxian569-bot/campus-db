/* =========================================================
   01_create_database.sql
   建立「校園共同支出與分帳管理系統」資料庫
   執行環境：SQL Server 2019 + SSMS
   注意：會刪除同名舊資料庫，重新建立
   ========================================================= */
USE master;
GO

IF DB_ID(N'CampusSplitDB') IS NOT NULL
BEGIN
    ALTER DATABASE CampusSplitDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CampusSplitDB;
END
GO

CREATE DATABASE CampusSplitDB;
GO

USE CampusSplitDB;
GO

-- 確認：資料庫已建立
SELECT name AS 資料庫名稱, create_date AS 建立時間
FROM sys.databases
WHERE name = N'CampusSplitDB';
GO
