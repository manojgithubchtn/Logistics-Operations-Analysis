# Logistics Operations Analytics – Data Analysis Project

## 1. Project Overview

This is an end-to-end data analysis project based on logistics operations. The main purpose of this project is to understand how different areas of a logistics business are performing by analysing operational, financial, fuel, maintenance, and delivery-related data.

The project covers different aspects of logistics operations, such as trips, loads, customers, drivers, trucks, fuel purchases, maintenance activities, delivery performance, and revenue.

I used Python for data exploration and data quality checks, Microsoft SQL Server for database creation and analysis, and Power BI to build an interactive dashboard.

The main goal was to take raw logistics data, organize it properly, analyse it using SQL, and present the results in a way that makes operational performance easier to understand.

## 2. Business Problem

A logistics business generates data from several activities, including customer orders, load assignments, trips, fuel purchases, vehicle maintenance, and delivery events.

Looking at these records separately does not provide a complete picture of how the business is performing.

For example, it may be difficult to understand whether fuel expenditure is increasing, which customers generate more revenue, how reliable deliveries are, or how much vehicles are costing the business through maintenance.

This project brings these different areas together to explore the overall performance of logistics operations and identify useful patterns through data analysis.

## 3. Project Objectives

The main objectives of this project are:

- Explore and understand the available logistics datasets.
- Perform data quality checks using Python.
- Identify missing values, duplicate records, and invalid data.
- Validate primary keys, composite keys, and foreign key relationships.
- Create a relational database using Microsoft SQL Server.
- Establish relationships between the different database tables.
- Analyse overall operational performance and key business metrics.
- Examine revenue and financial performance.
- Understand fuel expenditure and fuel efficiency.
- Analyse delivery performance and reliability.
- Evaluate maintenance expenditure and vehicle downtime.
- Create SQL views to prepare data for Power BI.
- Develop an interactive Power BI dashboard to present the findings.

## 4. Tools and Technologies Used

| Tool / Technology | Purpose |
|---|---|
| Python | Data exploration and quality checks |
| Pandas | Data manipulation and validation |
| Jupyter Notebook | Performing data analysis and validation |
| Microsoft SQL Server | Database creation and data storage |
| SQL | Data analysis, joins, aggregations, CTEs, and views |
| Microsoft Power BI | Dashboard development and visualization |
| GitHub | Project documentation and version control |

## 5. Dataset Description

The project uses multiple CSV files representing different areas of logistics operations.

The datasets are organized into 14 tables:

| Category | Tables |
|---|---|
| Customer Information | customers |
| Route Information | routes |
| Facility Information | facilities |
| Driver Information | drivers |
| Truck Information | trucks |
| Trailer Information | trailers |
| Load Management | loads |
| Trip Management | trips |
| Delivery Tracking | delivery_events |
| Fuel Management | fuel_purchases |
| Vehicle Maintenance | maintenance_records |
| Safety Monitoring | safety_incidents |
| Driver Performance | driver_monthly_metrics |
| Truck Performance | truck_utilization_metrics |

Each table contains information related to a particular part of the logistics business.

The tables are connected through common identifiers such as customer IDs, load IDs, trip IDs, driver IDs, and truck IDs.

The project focuses on the period from January 2022 to December 2024 for the main performance analysis.

## 6. Database Design and Relationships

I created a relational database named `Logistics_operations` using Microsoft SQL Server.

The database contains 14 tables, with primary keys and foreign keys used to establish relationships between the different entities.

Some of the important relationships include:

- A customer can be associated with multiple loads.
- Each load is connected to a customer and a route.
- Trips are connected to loads, drivers, trucks, and trailers.
- Delivery events are connected to loads, trips, and facilities.
- Fuel purchase records are connected to trips, drivers, and trucks.
- Maintenance records are connected to trucks.
- Safety incidents are connected to trips, drivers, and trucks.
- Driver monthly metrics are connected to drivers.
- Truck utilization metrics are connected to trucks.

I also checked the database relationships after creating the constraints to make sure the connections between the tables were properly established.

## 7. Data Exploration and Quality Checks

Before starting the SQL analysis, I used Python and Pandas in Jupyter Notebook to explore the datasets and check their quality.

The following checks were performed:

- **Dataset Overview:** Checked the number of rows, columns, missing values, duplicate records, and unique values in each dataset.
- **Data Types:** Reviewed the data types of different columns.
- **Primary Key Validation:** Checked for missing and duplicate values in primary key columns.
- **Composite Key Validation:** Checked combinations of columns used to identify records in driver and truck monthly metrics.
- **Foreign Key Validation:** Checked whether the IDs in related tables matched the corresponding parent table records.
- **Missing Value Analysis:** Identified missing values in important columns such as driver IDs, truck IDs, and trip IDs.
- **Date Validation:** Checked date columns for missing or invalid date values.
- **Fuel Cost Validation:** Compared recorded fuel costs with calculated costs using gallons purchased and price per gallon.
- **Maintenance Cost Validation:** Compared total maintenance costs with the sum of labour and parts costs.
- **Delivery Punctuality Validation:** Compared the original on-time flags with flags calculated from scheduled and actual delivery times.

I also investigated delivery flag mismatches and tested different time tolerance limits to understand how the on-time classification could change.

These checks helped me understand the structure and reliability of the data before moving forward with the analysis.

## 8. SQL Analysis Performed

After exploring the datasets, I used SQL Server to perform analysis across different areas of logistics operations.

The analysis was divided into the following categories:

### Overall Operations Analysis

- Total trips and loads.
- Total customers, trucks, and drivers.
- Overall revenue.
- Operational date coverage.
- Delivery events crossing into 2025.
- General checks on operational data.

### Revenue and Financial Performance

- Monthly revenue trends.
- Average revenue per load.
- Fuel surcharge and accessorial charge analysis.
- Revenue remaining after deducting the specified charge components.
- Top 10 customers based on revenue.
- Top 10 routes based on revenue.
- Expected base route revenue compared with actual average revenue per load.

### Fuel Expenditure and Efficiency

- Total fuel expenditure.
- Monthly fuel purchase trends.
- Total gallons purchased.
- Average fuel price per gallon.
- Fuel cost per mile.
- Operational miles per gallon (MPG).
- Comparison of fuel purchased with recorded fuel consumption.
- Truck-level fuel expenditure and efficiency.
- Fuel purchase and trip truck assignment validation.

### Delivery Performance and Reliability

- Monthly delivery performance.
- On-time delivery percentage.
- Average delivery delays.
- Delivery detention time.
- Route-wise delivery performance.
- Customer-wise delivery performance.
- Identification of routes and customers with lower on-time performance.
- Validation of original on-time flags against calculated delivery delays.

### Maintenance Performance

- Total maintenance expenditure.
- Labour and parts costs.
- Total maintenance records.
- Number of trucks maintained.
- Monthly maintenance cost trends.
- Average maintenance cost per record.
- Total vehicle downtime.
- Truck-level maintenance expenditure and downtime.
- Validation of maintenance cost calculations.

SQL features used throughout the analysis include joins, aggregate functions, CASE statements, Common Table Expressions (CTEs), date functions, subqueries, and window-related analytical techniques where required.

## 9. SQL Views

I created SQL views to organize frequently used calculations and make it easier to connect the analysis with Power BI.

The following views were created:

| SQL View | Purpose |
|---|---|
| `vw_Dashboard_KPI` | Overall operational and financial KPI values |
| `vw_Dashboard_Monthly_Trends` | Monthly trips, loads, revenue, delivery, fuel, and maintenance trends |
| `vw_Dashboard_Delivery_Routes` | Route-wise delivery performance and revenue |
| `vw_Dashboard_Customer_Performance` | Customer-wise revenue and delivery reliability |
| `vw_Dashboard_Fuel_Performance` | Monthly fuel expenditure and average fuel price |
| `vw_Dashboard_Maintenance_Performance` | Monthly maintenance expenditure and downtime |

These views helped organize the SQL calculations and provided structured data for dashboard reporting.

## 10. Power BI Dashboard

I used Microsoft Power BI to create an interactive dashboard titled **Logistics Operations – Executive Performance Dashboard**.

The dashboard covers the period from January 2022 to December 2024 and includes a year slicer to explore the performance across different years.

The dashboard includes the following KPI cards:

- Total Revenue
- On-Time Delivery %
- Total Fuel Cost
- Total Trips
- Total Maintenance Cost

The visualizations focus on:

- **Monthly Fuel Expenditure vs Average Fuel Price:** Compares monthly fuel spending with changes in average fuel prices.
- **Monthly Maintenance Cost vs Vehicle Downtime:** Shows how maintenance expenditure and vehicle downtime change over time.
- **Route Delivery Efficiency:** Uses a scatter chart to compare average delivery delay with on-time delivery percentage across routes.
- **Top 10 Customers by Customer Revenue:** Highlights the customers contributing the highest revenue.
- **Monthly Revenue Trend:** Shows how revenue changes from month to month.

The dashboard is designed to bring the important operational and financial metrics into one place and make it easier to explore the business performance.

## 11. Key Insights and Areas Explored

Through this project, I explored several important areas that can help understand logistics performance.

- **Revenue Performance:** Monthly revenue trends and customer-wise revenue analysis help identify how revenue is distributed across customers and routes.
- **Fuel Expenditure:** Comparing fuel costs and average fuel prices helps understand changes in fuel spending over time.
- **Fuel Efficiency:** Analysing operational MPG and fuel cost per mile provides a way to compare fuel efficiency across trucks.
- **Delivery Reliability:** On-time delivery percentages, average delays, and detention time help evaluate delivery performance.
- **Route Efficiency:** Comparing route delays with on-time delivery percentages helps identify differences in delivery performance across routes.
- **Maintenance Performance:** Maintenance expenditure and downtime analysis help understand vehicle maintenance activity and its operational impact.
- **Data Quality:** Validating keys, relationships, dates, and financial calculations helps identify data issues that could affect the analysis.

The Power BI dashboard brings some of these findings together through interactive visuals and KPI cards.


This Logistics Operations Analytics project gave me an opportunity to work through a complete data analysis process, starting from raw datasets and ending with an interactive Power BI dashboard.

By combining Python, SQL Server, and Power BI, I was able to explore different areas of logistics operations, perform data quality checks, build a relational database, analyse business performance, and present the results visually.

