== DATABASE CREATION====
IF DB_ID('SupplyChainAnalytics') IS NULL
BEGIN
    CREATE DATABASE SupplyChainAnalytics;
END
GO

USE SupplyChainAnalytics;
GO
