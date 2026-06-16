-- ==============================================================================
-- ARCHITECTURE: ENTERPRISE DATA ENGINEERING & TRANSACTIONAL PIPELINES
-- Target Database: Chinook OLTP Benchmark
-- Author: Nikhil Tandon (Data Analyst / Analytics Engineer)
-- Advanced Mechanics: Dynamic SQL Views, Stored Procedures, Error Control Management
-- ==============================================================================

USE Chinook;
GO

-- ------------------------------------------------------------------------------
-- STRUCTURE 1: MULTI-DIMENSIONAL REVENUE ENGINE SUMMARY VIEW
-- OBJECTIVE: Abstract complex joins into an optimized operational reporting view.
-- ------------------------------------------------------------------------------
IF OBJECT_ID('dbo.vw_Enterprise_Executive_Sales_Summary', 'V') IS NOT NULL
    DROP VIEW dbo.vw_Enterprise_Executive_Sales_Summary;
GO

CREATE VIEW dbo.vw_Enterprise_Executive_Sales_Summary AS
SELECT 
    e.EmployeeId AS Representative_ID,
    CONCAT(e.FirstName, ' ', e.LastName) AS Sales_Expert_Full_Name,
    e.Title AS Professional_Corporate_Role,
    COUNT(DISTINCT c.CustomerId) AS Active_Client_Portfolios,
    COUNT(i.InvoiceId) AS Gross_Invoices_Generated,
    ROUND(SUM(i.Total), 2) AS Gross_Financial_Revenue_Attributed,
    ROUND(AVG(i.Total), 2) AS Average_Invoice_Deal_Size
FROM Employee e
LEFT JOIN Customer c ON e.EmployeeId = c.SupportRepId
LEFT JOIN Invoice i  ON c.CustomerId = i.CustomerId
GROUP BY e.EmployeeId, e.FirstName, e.LastName, e.Title;
GO

-- Execution Test Check:
-- SELECT * FROM dbo.vw_Enterprise_Executive_Sales_Summary ORDER BY Gross_Financial_Revenue_Attributed DESC;
-- GO

-- ------------------------------------------------------------------------------
-- STRUCTURE 2: TRANSACTIONAL INVOICE INGESTION PIPELINE (STORED PROCEDURE)
-- OBJECTIVE: Ensure transactional data integrity with multi-table insert and rollback.
-- ------------------------------------------------------------------------------
IF OBJECT_ID('dbo.sp_Ingest_Transactional_Invoice', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_Ingest_Transactional_Invoice;
GO

CREATE PROCEDURE dbo.sp_Ingest_Transactional_Invoice
    @CustomerId INT,
    @BillingAddress NVARCHAR(70),
    @BillingCity NVARCHAR(40),
    @BillingCountry NVARCHAR(40),
    @BillingPostalCode NVARCHAR(10),
    @TrackId INT,
    @UnitPrice NUMERIC(10,2), -- Unit price for the purchased track
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Diagnostic Parameter Validation Checks
    IF NOT EXISTS (SELECT 1 FROM Customer WHERE CustomerId = @CustomerId)
    BEGIN
        RAISERROR('Data Exception Error: Target Customer Profile ID Not Found.', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM Track WHERE TrackId = @TrackId)
    BEGIN
        RAISERROR('Data Exception Error: Catalog Track Stock ID Item Code Not Found.', 16, 1);
        RETURN;
    END

    -- Compute variables
    DECLARE @CalculatedTotal NUMERIC(10,2) = (@UnitPrice * @Quantity);
    DECLARE @NewGeneratedInvoiceId INT;

    -- Initialize Transaction Guard Core Block
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Insert into baseline metadata infrastructure ledger
        INSERT INTO Invoice (CustomerId, InvoiceDate, BillingAddress, BillingCity, BillingCountry, BillingPostalCode, Total)
        VALUES (@CustomerId, GETDATE(), @BillingAddress, @BillingCity, @BillingCountry, @BillingPostalCode, @CalculatedTotal);
        
        -- Capture systemic primary key generated
        SET @NewGeneratedInvoiceId = SCOPE_IDENTITY();

        -- Insert transactional context ledger records
        INSERT INTO InvoiceLine (InvoiceId, TrackId, UnitPrice, Quantity)
        VALUES (@NewGeneratedInvoiceId, @TrackId, @UnitPrice, @Quantity);

        -- Commit changes safely upon comprehensive validation success
        COMMIT TRANSACTION;
        
        PRINT 'Transaction Finalized: Data safely written to core ledgers. Invoice ID: ' + CAST(@NewGeneratedInvoiceId AS VARCHAR(10));
    END TRY
    BEGIN CATCH
        -- Structural failure execution exception handling
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO
