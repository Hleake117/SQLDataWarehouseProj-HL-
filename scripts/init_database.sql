/*
========================================================================
Create Database and Shecmas
========================================================================
Script Purpose 
	This script creates a new database named 'DataWarehouse' after checking to see if it already exists.
	If the databse exists, it is dropped and recreated. Additionally, the script sets up three schemas 
	within the database: 'bronze', 'silver', and 'gold'.

Warning:
	Running this script will drop the entire 'DataWarehouse' database if it exists.
	All data in the database wil be permanently deleted. Proceed with caution
	and ensure you have proper backups before running the script.

*/



USE master;
GO


--drop and recreate the 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE DataWarehouse;
END;
GO

--Create the 'DataWarehouse' database
CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

--Create Schemas
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO 
CREATE SCHEMA gold;
GO
