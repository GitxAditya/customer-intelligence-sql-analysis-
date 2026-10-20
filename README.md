# customer-intelligence-sql-analysis-

## Project Overview
This repository contains an end-to-end SQL data analysis project designed to evaluate the financial health and operational efficiency of a B2B/E-commerce business. 

Using a relational MySQL database (`customer_intelligence_db`), I analyzed data across five core domains: Customer Lifetime Value (CLV), Sales Trends, Product Profitability, Inventory Health, and Marketing Funnel Attribution.

The goal of this project is to go beyond writing SQL queries—it is about **answering critical business questions, identifying data anomalies, and providing actionable strategic recommendations** based on the data.

## Database Schema
The analysis is built on a relational schema (`customer_intelligence_db`) consisting of the following key tables:
- **Customers:** Demographics and geographic data.
- **Orders & Order Items:** Transactional data, quantities, and selling prices.
- **Products:** Catalog details, list prices, and cost of goods sold (COGS).
- **Marketing Campaigns & Customer Campaigns:** Funnel tracking (Sent, Opened, Clicked, Purchased).
- **Payments, Returns, & Reviews:** Post-purchase operational and sentiment data.

## Tech Stack
- **Database:** MySQL
- **IDE:** MySQL Workbench
- **Techniques Used:** Common Table Expressions (CTEs), Window Functions (`ROW_NUMBER`, `RANK`, `LAG`), Aggregations, Subqueries, and Data Integrity Auditing.

## Repository Structure
```text
├── 01_Database_Setup/      # SQL scripts to create the schema and insert data
├── 02_SQL_Queries/         # All analytical queries organized by domain
│   ├── 01_Customer_Analysis/
│   ├── 02_Sales_Trends/
│   ├── 03_Product_Inventory/
│   ├── 04_Marketing_Attribution/
│   └── 05_Executive_Dashboards/
└── 03_Business_Insights/   # Markdown reports detailing findings and recommendations
