-- franchise_status classifies films into three categories based on TMDB collection data:
--   'subsequent' = sequel/later entry in an existing film collection
--   'starter'    = first entry in a collection (an original creative bet, even though it later spawned a series of films)
--   'standalone' = not part of any collection at all
-- When comparing "franchise vs original" films throughout this analysis, 'starter' and 'standalone' are grouped together as "original", since both represent films that were not leaning on an established, already successful entry. 


-- Q1: Franchise share by year 

--total number of films, number of originals and franchise by year. initial pass: reveals some years have very few films, making percentages unreliable
SELECT EXTRACT(YEAR FROM release_date) AS year,
COUNT(title) AS total_films,
COUNT(title)FILTER(WHERE franchise_status='starter' OR franchise_status = 'standalone')AS original,
COUNT(title)FILTER(WHERE franchise_status = 'subsequent')AS franchise 
FROM movies
GROUP BY 1;


--having found uneven data across the years, filter to years with at least 30 films (range 1984-2025), calculate percentage of franchise films per year
SELECT 
EXTRACT(YEAR FROM release_date) AS year, 
COUNT(title) FILTER(WHERE franchise_status = 'subsequent') AS franchise, 
COUNT(title) AS total_films,
ROUND(COUNT(title) FILTER(WHERE franchise_status = 'subsequent')::numeric/COUNT(title)*100, 2) AS franchise_percentage
FROM movies
GROUP BY 1
HAVING COUNT(title) >= 30
ORDER BY 1;


-- Q2: Budget vs revenue/ROI correlation, overall and by franchise status
-- Q2: Budget vs revenue/ROI correlation, overall and by franchise status

-- budget vs revenue correlation: overall, franchise, and original
SELECT 
CORR(budget, revenue) AS revenue_corr_overall,
CORR(budget, revenue) FILTER (WHERE franchise_status = 'subsequent') AS revenue_corr_franchise,
CORR(budget, revenue) FILTER (WHERE franchise_status IN ('standalone', 'starter')) AS revenue_corr_original
FROM movies;

-- budget vs ROI correlation: overall, franchise, and original
SELECT 
CORR(budget, roi) AS roi_corr_overall,
CORR(budget, roi) FILTER (WHERE franchise_status = 'subsequent') AS roi_corr_franchise,
CORR(budget, roi) FILTER (WHERE franchise_status IN ('standalone', 'starter')) AS roi_corr_original
FROM movies;


-- Q3: ROI and rating comparison, subsequent vs standalone+starter

-- average ROI for franchise vs original films
SELECT 
AVG(roi) FILTER(WHERE franchise_status = 'subsequent') AS franchise_roi_avg, 
AVG(roi) FILTER(WHERE franchise_status = 'standalone' OR franchise_status = 'starter') AS original_roi_avg
FROM movies;

-- median ROI for franchise vs original films
SELECT 
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY roi) FILTER (WHERE franchise_status = 'subsequent') AS franchise_roi_median,
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY roi) FILTER (WHERE franchise_status = 'standalone' OR franchise_status = 'starter') AS original_roi_median
FROM movies;

-- rating average for franchise vs original films
SELECT 
AVG(vote_average) FILTER (WHERE franchise_status = 'subsequent') AS franchise_rating_avg, 
AVG(vote_average) FILTER (WHERE franchise_status = 'standalone' OR franchise_status = 'starter') AS original_rating_avg
FROM movies;


-- Q4: ROI outliers (top/bottom 20 and 100)
-- checked the top/bottom 20 films by ROI to identify notable individual examples.
-- checked at 100 to confirm the pattern wasn't the fluke of a small sample. 
-- both sizes show a similar split, showing a genuine pattern.
-- for the top/bottom 20 change LIMIT 100 to LIMIT 20.

-- top 100 best ROI
WITH subquery AS (SELECT title, roi, franchise_status
FROM movies 
ORDER BY roi DESC
LIMIT 100)
SELECT 
COUNT(title) FILTER(WHERE franchise_status = 'starter' OR franchise_status = 'standalone') AS original, 
COUNT(title) FILTER(WHERE franchise_status = 'subsequent') AS franchise
FROM subquery;

-- bottom 100 ROI
WITH subquery AS (SELECT title, roi, franchise_status
FROM movies 
ORDER BY roi 
LIMIT 100)
SELECT 
COUNT(title) FILTER(WHERE franchise_status = 'starter' OR franchise_status = 'standalone') AS original, 
COUNT(title) FILTER(WHERE franchise_status = 'subsequent') AS franchise
FROM subquery;


-- Q5: Genre ROI by franchise status

-- average ROI by genre (original)
SELECT mg.genres, COUNT(mg.title) AS film_count, AVG(m.roi) AS average_roi
FROM movie_genres mg INNER JOIN movies m ON m.id = mg.id
WHERE m.franchise_status = 'standalone' OR m.franchise_status = 'starter'
GROUP BY 1
HAVING COUNT(mg.title) >= 30
ORDER BY 3 DESC;

-- average ROI by genre (franchise)
SELECT mg.genres, COUNT(mg.title) AS film_count, AVG(m.roi) AS average_roi
FROM movie_genres mg INNER JOIN movies m ON m.id = mg.id
WHERE m.franchise_status = 'subsequent'
GROUP BY 1
HAVING COUNT(mg.title) >= 30
ORDER BY 3 DESC;


