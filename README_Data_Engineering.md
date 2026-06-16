# Chinook-Data-Engineering-Pipeline ⚙️

## 📌 Business Strategy Overview
This repository focuses on moving database systems beyond static queries and into functional data automation. It builds a robust database layer on the **Chinook Relational Model** designed to handle heavy multi-table ingestions, reduce analytics load times, and preserve transaction logic stability.

## 🛠️ Systems Engineering Stack
* **Database Engine:** SQL Server (T-SQL) Core Enterprise Engine
* **Engineering Tools:** Relational constraints, Transaction Control Blocks (`BEGIN TRANSACTION`, `TRY...CATCH`), Materialized Views, and Error Handling.
* **Core Technical Competencies Demonstrated:**
  * Performance Tuning via optimized View abstractions.
  * Safe Transactional Ingestion Procedures built to handle operational stress without silent drops.
  * Strict constraint error handling logic.

## ⚙️ Implemented Production Objects
1. **`dbo.vw_Enterprise_Executive_Sales_Summary`:** A high-performance business view designed to calculate key support representative metrics, including active accounts managed, overall revenue generation, and average deal sizes.
2. **`dbo.sp_Ingest_Transactional_Invoice`:** An enterprise-ready stored procedure built to process complex multi-table inserts (Invoices and Line Items) simultaneously. Features structured validation checks and automated rollback controls to maintain full data integrity.
