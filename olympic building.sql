-- Create the Olympic database
CREATE DATABASE IF NOT EXISTS olympic_history;

-- Select the database to use
USE olympic_history;

-- Drop the old staging table
DROP TABLE IF EXISTS staging_athletes;

-- Create new staging table with VARCHAR for numeric columns
CREATE TABLE staging_athletes (
    ID VARCHAR(20),           
    Name VARCHAR(255),
    Sex VARCHAR(10),
    Age VARCHAR(10),          
    Height VARCHAR(10),       
    Weight VARCHAR(20),       
    Team VARCHAR(255),
    NOC VARCHAR(10),
    Games VARCHAR(50),
    Year INT,                 
    Season VARCHAR(20),
    City VARCHAR(100),
    Sport VARCHAR(100),
    Event VARCHAR(255),
    Medal VARCHAR(20)
    );

-- Check total rows
SELECT COUNT(*) FROM staging_athletes;

-- See the "NA" values
SELECT * FROM staging_athletes 
WHERE Height = 'NA' OR Age = 'NA' OR Weight = 'NA'
LIMIT 10;

-- Count how many NAs in each column
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN Age = 'NA' THEN 1 ELSE 0 END) AS age_na,
    SUM(CASE WHEN Height = 'NA' THEN 1 ELSE 0 END) AS height_na,
    SUM(CASE WHEN Weight = 'NA' THEN 1 ELSE 0 END) AS weight_na
FROM staging_athletes;

-- Convert all 'NA' strings to NULL in staging table
UPDATE staging_athletes
SET 
    Age = NULLIF(Age, 'NA'),
    Height = NULLIF(Height, 'NA'),
    Weight = NULLIF(Weight, 'NA'),
    Medal = NULLIF(Medal, 'NA');
    
-- Find duplicate year combinations with different cities
SELECT Year, Season, City, COUNT(*) AS count
FROM staging_athletes
GROUP BY Year, Season, City
HAVING COUNT(*) > 1;

SELECT Year, Season, COUNT(DISTINCT City) AS city_count, GROUP_CONCAT(DISTINCT City) AS cities
FROM staging_athletes
GROUP BY Year, Season
HAVING COUNT(DISTINCT City) > 1;
    
-- Drop and recreate games table
DROP TABLE IF EXISTS games;

CREATE TABLE games (
    game_id INT AUTO_INCREMENT PRIMARY KEY,
    year INT NOT NULL,
    season VARCHAR(20) NOT NULL,
    city VARCHAR(100) NOT NULL,
    UNIQUE KEY unique_game (year, season)
);

-- Insert with MIN(City) - this will pick Melbourne over Stockholm alphabetically
INSERT INTO games (year, season, city)
SELECT 
    Year, 
    Season, 
    MIN(City) AS city
FROM staging_athletes
GROUP BY Year, Season
ORDER BY Year, Season;

-- Verify
SELECT * FROM games WHERE year = 1956;
SELECT COUNT(*) FROM games;

-- Create sports table
CREATE TABLE sports (
    sport_id INT AUTO_INCREMENT PRIMARY KEY,
    sport_name VARCHAR(100) NOT NULL UNIQUE
);

-- Populate from staging
INSERT INTO sports (sport_name)
SELECT DISTINCT Sport
FROM staging_athletes
ORDER BY Sport;

-- Verify
SELECT * FROM sports ORDER BY sport_name;
SELECT COUNT(*) FROM sports;

-- Create events table
CREATE TABLE events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    event_name VARCHAR(255) NOT NULL,
    sport_id INT NOT NULL,
    FOREIGN KEY (sport_id) REFERENCES sports(sport_id)
);

-- Populate from staging (joining to get sport_id)
INSERT INTO events (event_name, sport_id)
SELECT DISTINCT 
    s.Event,
    sp.sport_id
FROM staging_athletes s
JOIN sports sp ON s.Sport = sp.sport_name
ORDER BY s.Event;

-- Verify
SELECT 
    e.event_id,
    e.event_name,
    s.sport_name
FROM events e
JOIN sports s ON e.sport_id = s.sport_id
LIMIT 20;

SELECT COUNT(*) FROM events;

-- Create athletes table
CREATE TABLE athletes (
    athlete_id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    sex VARCHAR(10),
    height INT,
    weight FLOAT
);

-- Populate from staging
INSERT INTO athletes (athlete_id, name, sex, height, weight)
SELECT DISTINCT
    CAST(ID AS UNSIGNED),
    Name,
    Sex,
    CAST(Height AS UNSIGNED),
    CAST(Weight AS DECIMAL(6,2))
FROM staging_athletes
ORDER BY CAST(ID AS UNSIGNED);

-- Verify
SELECT * FROM athletes LIMIT 20;
SELECT COUNT(*) FROM athletes;

-- Check data quality
SELECT 
    COUNT(*) AS total_athletes,
    SUM(CASE WHEN height IS NULL THEN 1 ELSE 0 END) AS missing_height,
    SUM(CASE WHEN weight IS NULL THEN 1 ELSE 0 END) AS missing_weight,
    ROUND(AVG(height), 1) AS avg_height_cm,
    ROUND(AVG(weight), 1) AS avg_weight_kg
FROM athletes;

-- See all your tables
SHOW TABLES;

-- Row count summary
SELECT 'countries' AS table_name, COUNT(*) AS row_count FROM countries
UNION ALL
SELECT 'games', COUNT(*) FROM games
UNION ALL
SELECT 'sports', COUNT(*) FROM sports
UNION ALL
SELECT 'events', COUNT(*) FROM events
UNION ALL
SELECT 'athletes', COUNT(*) FROM athletes
UNION ALL
SELECT 'staging_athletes', COUNT(*) FROM staging_athletes;

-- Create countries reference table
CREATE TABLE countries (
    NOC VARCHAR(10) PRIMARY KEY,
    region VARCHAR(255) NOT NULL,
    notes TEXT
);

-- Find missing NOC codes
SELECT DISTINCT s.NOC, s.Team
FROM staging_athletes s
LEFT JOIN countries c ON s.NOC = c.NOC
WHERE c.NOC IS NULL;

SELECT s.NOC, GROUP_CONCAT(DISTINCT s.Team) AS team_names, COUNT(DISTINCT s.Team) AS name_count
FROM staging_athletes s
LEFT JOIN countries c ON s.NOC = c.NOC
WHERE c.NOC IS NULL
GROUP BY s.NOC
HAVING COUNT(DISTINCT s.Team) > 1;

-- Insert missing NOCs
INSERT INTO countries (NOC, region, notes)
SELECT DISTINCT 
    s.NOC, 
    MIN(s.Team) AS region,  -- Pick one team name (first alphabetically)
    'Added from staging data'
FROM staging_athletes s
LEFT JOIN countries c ON s.NOC = c.NOC
WHERE c.NOC IS NULL
GROUP BY s.NOC;

SELECT * FROM countries WHERE notes = 'Added from staging data';

-- Create participations table
CREATE TABLE participations (
    participation_id INT AUTO_INCREMENT PRIMARY KEY,
    athlete_id INT NOT NULL,
    game_id INT NOT NULL,
    event_id INT NOT NULL,
    NOC VARCHAR(10) NOT NULL,
    age INT,
    medal VARCHAR(20),
    FOREIGN KEY (athlete_id) REFERENCES athletes(athlete_id),
    FOREIGN KEY (game_id) REFERENCES games(game_id),
    FOREIGN KEY (event_id) REFERENCES events(event_id),
    FOREIGN KEY (NOC) REFERENCES countries(NOC),
    CHECK (medal IS NULL OR medal IN ('Gold', 'Silver', 'Bronze'))
);

-- Populate participations from staging
INSERT INTO participations (athlete_id, game_id, event_id, NOC, age, medal)
SELECT 
    CAST(s.ID AS UNSIGNED) AS athlete_id,
    g.game_id,
    e.event_id,
    s.NOC,
    CAST(s.Age AS UNSIGNED) AS age,
    s.Medal
FROM staging_athletes s
JOIN games g ON s.Year = g.year AND s.Season = g.season
JOIN events e ON s.Event = e.event_name
ORDER BY s.ID, g.year;

SELECT COUNT(*) FROM participations;

SELECT 
    p.participation_id,
    a.name,
    c.region AS country,
    g.year,
    g.season,
    g.city,
    sp.sport_name,
    e.event_name,
    p.age,
    p.medal
FROM participations p
JOIN athletes a ON p.athlete_id = a.athlete_id
JOIN countries c ON p.NOC = c.NOC
JOIN games g ON p.game_id = g.game_id
JOIN events e ON p.event_id = e.event_id
JOIN sports sp ON e.sport_id = sp.sport_id
ORDER BY year desc
LIMIT 20;

SELECT 
    medal,
    COUNT(*) AS count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM participations), 2) AS percentage
FROM participations
GROUP BY medal
ORDER BY count DESC;