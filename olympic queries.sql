-- 1. Total medals awarded in Summer Olympics (by country)
SELECT 
    c.region AS country,
    COUNT(p.medal) AS total_summer_medals,
    SUM(CASE WHEN p.medal = 'Gold' THEN 1 ELSE 0 END) AS gold,
    SUM(CASE WHEN p.medal = 'Silver' THEN 1 ELSE 0 END) AS silver,
    SUM(CASE WHEN p.medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze
FROM participations p
JOIN countries c ON p.NOC = c.NOC
JOIN games g ON p.game_id = g.game_id
WHERE p.medal IS NOT NULL 
  AND g.season = 'Summer'
GROUP BY c.region
ORDER BY total_summer_medals DESC
LIMIT 20;

-- 2. Total medals awarded in Winter Olympics (by country)
SELECT 
    c.region AS country,
    COUNT(p.medal) AS total_winter_medals,
    SUM(CASE WHEN p.medal = 'Gold' THEN 1 ELSE 0 END) AS gold,
    SUM(CASE WHEN p.medal = 'Silver' THEN 1 ELSE 0 END) AS silver,
    SUM(CASE WHEN p.medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze
FROM participations p
JOIN countries c ON p.NOC = c.NOC
JOIN games g ON p.game_id = g.game_id
WHERE p.medal IS NOT NULL 
  AND g.season = 'Winter'
GROUP BY c.region
ORDER BY total_winter_medals DESC
LIMIT 20;

-- 3. Top 10 athletes by total medal count
SELECT 
    a.name,
    c.region AS country,
    COUNT(p.medal) AS total_medals,
    SUM(CASE WHEN p.medal = 'Gold' THEN 1 ELSE 0 END) AS gold,
    SUM(CASE WHEN p.medal = 'Silver' THEN 1 ELSE 0 END) AS silver,
    SUM(CASE WHEN p.medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze
FROM participations p
JOIN athletes a ON p.athlete_id = a.athlete_id
JOIN countries c ON p.NOC = c.NOC
WHERE p.medal IS NOT NULL
GROUP BY a.name, c.region
ORDER BY total_medals DESC, gold DESC
LIMIT 10;

-- 4. Average age of gold medal winners by sport
SELECT 
    s.sport_name,
    ROUND(AVG(p.age), 1) AS avg_gold_medalist_age,
    COUNT(p.medal) AS gold_medals,
    MIN(p.age) AS youngest_gold,
    MAX(p.age) AS oldest_gold
FROM participations p
JOIN events e ON p.event_id = e.event_id
JOIN sports s ON e.sport_id = s.sport_id
WHERE p.medal = 'Gold' AND p.age IS NOT NULL
GROUP BY s.sport_name
ORDER BY avg_gold_medalist_age DESC;

-- 5. Average height by sport
SELECT 
    s.sport_name,
    ROUND(AVG(a.height_cm), 1) AS avg_height_cm,
    COUNT(DISTINCT a.athlete_id) AS athlete_count,
    MIN(a.height_cm) AS min_height,
    MAX(a.height_cm) AS max_height
FROM participations p
JOIN athletes a ON p.athlete_id = a.athlete_id
JOIN events e ON p.event_id = e.event_id
JOIN sports s ON e.sport_id = s.sport_id
WHERE a.height_cm IS NOT NULL
GROUP BY s.sport_name
HAVING COUNT(DISTINCT a.athlete_id) >= 100
ORDER BY avg_height_cm DESC;

-- 6. USA Basketball Performance Over Time
SELECT 
    g.year,
    g.season,
    g.city,
    COUNT(p.medal) AS medals_won,
    SUM(CASE WHEN p.medal = 'Gold' THEN 1 ELSE 0 END) AS gold_medals
FROM participations p
JOIN games g ON p.game_id = g.game_id
JOIN events e ON p.event_id = e.event_id
JOIN sports s ON e.sport_id = s.sport_id
WHERE p.NOC = 'USA' 
  AND s.sport_name = 'Basketball'
  AND p.medal IS NOT NULL
GROUP BY g.year, g.season, g.city
ORDER BY g.year;

-- 7. Find the youngest and oldest medal winners in each sport
SELECT 
    s.sport_name,
    MIN(p.age) AS youngest_medalist_age,
    MAX(p.age) AS oldest_medalist_age,
    MAX(p.age) - MIN(p.age) AS age_range,
    ROUND(AVG(p.age), 1) AS avg_medalist_age
FROM participations p
JOIN events e ON p.event_id = e.event_id
JOIN sports s ON e.sport_id = s.sport_id
WHERE p.medal IS NOT NULL AND p.age IS NOT NULL
GROUP BY s.sport_name
ORDER BY age_range DESC;

-- 8. Find the 10 tallest athletes
SELECT name, height_cm, sex
FROM athletes
WHERE height_cm IS NOT NULL
ORDER BY height_cm DESC
LIMIT 10;

-- 9. List all gold medal winners
SELECT 
    a.name,
    g.year,
    s.sport_name,
    e.event_name
FROM participations p
JOIN athletes a ON p.athlete_id = a.athlete_id
JOIN games g ON p.game_id = g.game_id
JOIN events e ON p.event_id = e.event_id
JOIN sports s ON e.sport_id = s.sport_id
WHERE p.medal = 'Gold'
ORDER BY g.year DESC
LIMIT 50;

-- 10. Countries that have won medals in at least 10 different Olympic games
SELECT 
    c.region AS country,
    COUNT(DISTINCT g.game_id) AS olympics_with_medals,
    COUNT(p.medal) AS total_medals,
    MIN(g.year) AS first_medal_year,
    MAX(g.year) AS most_recent_medal_year,
    ROUND(COUNT(p.medal) * 1.0 / COUNT(DISTINCT g.game_id), 1) AS avg_medals_per_olympics
FROM participations p
JOIN countries c ON p.NOC = c.NOC
JOIN games g ON p.game_id = g.game_id
WHERE p.medal IS NOT NULL
GROUP BY c.region
HAVING COUNT(DISTINCT g.game_id) >= 10
ORDER BY olympics_with_medals DESC, total_medals DESC;


-- INSERT STATEMENTS

-- 1. Add Future Games
INSERT INTO games (year, season, city)
VALUES 
    (2018, 'Winter', 'PyeongChang'),
    (2020, 'Summer', 'Tokyo');
    
-- 2. Insert a new athlete
INSERT INTO athletes (athlete_id, name, sex, height, weight)
VALUES 
    ((SELECT MAX(athlete_id) + 1 FROM athletes AS a), 'Max Lee', 'M', 188, 85.0),
	((SELECT MAX(athlete_id) + 1 FROM athletes AS a), 'Jamie Darnold', 'F', 175, 68.5);
    
-- 3. Insert a new sport
INSERT INTO sports (sport_name)
VALUES ('Esports');

-- 4. Insert a new event for Basketball (sport_id = 5, for example)
INSERT INTO events (event_name, sport_id)
VALUES ('Basketball 3x3 Mixed', 5);

-- 5. Insert a participation with a medal
INSERT INTO participations (athlete_id, game_id, event_id, NOC, age, medal)
VALUES (135573, 1, 1, 'USA', 28, 'Gold');
    
-- UPDATE STATEMENTS

-- 1. Update weight for a specific athlete
UPDATE athletes
SET weight_kg = 72.5
WHERE name = 'Max Lee';

-- 2. Update a country's region name
UPDATE countries
SET region = 'United States of America'
WHERE NOC = 'USA';

-- 3. Correct a city name
UPDATE games
SET city = 'Saint Louis'
WHERE year = 1904 AND season = 'Summer';

-- 4. Correct a medal type
UPDATE participations
SET medal = 'Gold'
WHERE participation_id = 100;

-- 5. Rename a sport
UPDATE sports
SET sport_name = 'Track and Field'
WHERE sport_name = 'Athletics';

-- 6. Correct age for a specific participation record
UPDATE participations
SET age = 26
WHERE participation_id = 500;

-- 7. Add historical notes to a country record
UPDATE countries
SET notes = 'Competed as West Germany before reunification'
WHERE NOC = 'FRG';

-- 8. Standardize all event names containing "Men's"
UPDATE events
SET event_name = REPLACE(event_name, "Men's", 'Mens')
WHERE event_name LIKE "%Men's%";

-- 9. Standardize all variations of Beijing
UPDATE games
SET city = 'Beijing'
WHERE city IN ('Peking', 'Beijing', 'Bejing');

-- 10. Correct season if it was entered wrong
UPDATE games
SET season = 'Winter'
WHERE year = 1924 AND season = 'Summer' AND city = 'Chamonix';


