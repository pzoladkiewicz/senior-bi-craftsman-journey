USE SupplyChainDB;
GO

-- DROP PROCEDURE IF EXISTS dwh.sp_PopulateDateDimmension;
-- EXEC dwh.sp_PopulateDateDimmension


CREATE PROCEDURE dwh.sp_PopulateDateDimmension
    @StartDate DATE = '2015-01-01',
    @EndDate DATE = '2025-12-31'
AS
BEGIN
    SET NOCOUNT ON;

    --TRUNCATE TABLE dwh.D_Date;

    DECLARE @d DATE = @StartDate;

    WHILE @d <= @EndDate
    BEGIN
        INSERT INTO D_Date
        (
             DateKey
            ,Date
            ,Year
            ,Quarter
            ,Month
            ,WeekOfYear
            ,DayOfMonth
            ,DayOfWeek
            ,DayOfYear
            ,IsWeekend
            ,IsHoliday
            ,FiscalYear
            ,FiscalQuarter
        )
        VALUES
        (
             CAST(CONVERT(char(8), @d , 112) AS INT)
            ,@d
            ,YEAR(@d)
            ,DATEPART(QUARTER, @d)
            ,MONTH(@d)
            ,DATEPART(WEEK, @d)
            ,DAY(@d)
            ,DATEPART(WEEKDAY, @d)
            ,DATEPART(DAYOFYEAR, @d)
            ,CASE WHEN DATEPART(WEEKDAY, @d) IN (1, 7) THEN 1 ELSE 0 END
            ,0  -- Placeholder for IsHoliday, can be updated later with actual holiday data
            ,YEAR(@d)
            ,DATEPART(QUARTER, @d)

        );

        SET @d = DATEADD(DAY, 1, @d);
    END

END;