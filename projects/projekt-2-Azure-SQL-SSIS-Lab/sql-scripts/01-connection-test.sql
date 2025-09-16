use AdventureWorksLT
GO

-- DB szczegó³y
SELECT 
     DB_NAME() as DatabaseName
    ,SYSTEM_USER as CurrentUser
    ,GETDATE() as CurrentDateTime;

-- SprawdŸ tabele AdventureWorksLT
SELECT
	 TABLE_SCHEMA
	,TABLE_NAME
	,TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
ORDER BY
	 TABLE_SCHEMA
	,TABLE_NAME;
