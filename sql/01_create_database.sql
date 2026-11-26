
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


SELECT name AS 資料庫名稱, create_date AS 建立時間
FROM sys.databases
WHERE name = N'CampusSplitDB';
GO
