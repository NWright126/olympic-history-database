# Olympic History Database

A relational MySQL database built from 120 years of Olympic Games data, covering every athlete and event from 1896 to 2016.

## Project Overview

This project transforms a raw 271,000+ record CSV dataset into a fully normalized relational database with analytical queries surfacing trends in medal distribution, athlete demographics, and country performance across Olympic history.

Built as a semester-long database systems project (IS 4420, University of Utah — Fall 2025), it covers the complete database development lifecycle: data modeling, ETL, SQL development, and user access management.

## Dataset

[120 Years of Olympic History: Athletes and Results](https://www.kaggle.com/datasets/heesoo37/120-years-of-olympic-history-athletes-and-results) — Kaggle

- 271,000+ participation records
- Every Olympic Games from Athens 1896 to Rio 2016
- Athlete bios (age, height, weight, gender, nationality) and medal results

## Database Design

- 6 normalized tables with enforced primary and foreign key constraints
- Designed to eliminate redundancy and maintain referential integrity across athletes, events, games, countries, and participation records
- ERD created prior to implementation to map complex many-to-many relationships

## ETL Process

- Imported raw CSV into a staging table using VARCHAR types to handle inconsistent formatting
- Converted `NA` string values to proper `NULL` and cast numeric columns to correct data types
- Populated dimension tables via clean `INSERT` statements from the staging table
- Preserved original `athlete_id` structure using `MAX(athlete_id) + 1` for new inserts to maintain referential integrity

## Key Findings

- **US leads all-time** with 4,000+ total medals; Winter Games show more concentrated distribution among northern European countries
- **Michael Phelps** holds the individual record with 28 total medals — 10 more than the next closest athlete (Larisa Latynina, 18)
- **Age varies significantly by sport** — art competitions and alpinism average gold medalist ages of 41 and 39 respectively; sailing has the widest medalist age range at 57 years
- **Medal distribution** reveals meaningful differences in country dominance across Summer vs. Winter Games

## SQL Features Used

- Multi-table JOINs
- Aggregate functions and GROUP BY
- Subqueries
- Window functions
- Role-based user access control (analyst, data entry, and DBA admin privilege tiers)

## Skills Demonstrated

`MySQL` `ETL` `Data Cleaning` `Database Normalization` `ERD Design` `Analytical SQL` `User Privilege Management`
