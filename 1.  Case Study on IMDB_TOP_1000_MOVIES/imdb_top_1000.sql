USE sql_case_studies;

SELECT * FROM imdb_top_1000;

-- 1. Is there any duplicate row?
SELECT Series_Title AS Duplicate_Series_Title
FROM imdb_top_1000
GROUP BY Series_Title, Director, Released_Year
HAVING COUNT(*) > 1;

-- 2. Find the movie with maximum rating.
-- Solution - 1
SELECT Series_Title AS movie_with_max_rating, IMDB_Rating
FROM imdb_top_1000
WHERE IMDB_Rating = (SELECT MAX(IMDB_Rating) FROM imdb_top_1000);

-- Solution - 2
SELECT Series_Title AS movie_with_max_rating
FROM imdb_top_1000
ORDER BY IMDB_Rating DESC
LIMIT 1;

-- 3. Find the 2nd highest rated movie.
SELECT Series_Title AS movie_with_max_rating
FROM imdb_top_1000
ORDER BY IMDB_Rating DESC
LIMIT 1, 1;

-- 4. Find the movie(s) with maximum gross.
-- Solution - 1
SELECT Series_Title AS movie_with_max_gross
FROM imdb_top_1000
WHERE Gross = (SELECT MAX(Gross) FROM imdb_top_1000);

-- Solution - 2
SELECT Series_Title AS movie_with_max_gross
FROM imdb_top_1000
ORDER BY Gross DESC
LIMIT 1;

-- 5. Which movie(s) earn most with lowest rating?
SELECT Series_Title, IMDB_Rating, Gross
FROM imdb_top_1000
WHERE IMDB_Rating = (SELECT MIN(IMDB_Rating) FROM imdb_top_1000)
ORDER BY Gross DESC
LIMIT 1;

-- 6. Which is the longest movie(s)?
-- Solution - 1
SELECT Series_Title AS 'longest_movie(s)'
FROM imdb_top_1000
WHERE Runtime = (SELECT MAX(Runtime) FROM imdb_top_1000);

-- Solution - 2
SELECT Series_Title AS 'longest_movie(s)'
FROM imdb_top_1000
ORDER BY Runtime DESC
LIMIT 1;

-- 7. Find the top 3 genres by total earning.
SELECT Genre, SUM(Gross) AS Total_Earning
FROM imdb_top_1000
GROUP BY Genre
ORDER BY Total_Earning DESC
LIMIT 3;

-- 8. Find the genre with highest average IMDB rating.
SELECT Genre, AVG(IMDB_Rating) AS Average_Rating
FROM imdb_top_1000
GROUP BY Genre
ORDER BY Average_Rating DESC
LIMIT 1;

-- 9. Find director with most popularity.
SELECT Director AS Most_Popular_Director
FROM imdb_top_1000
GROUP BY Director
ORDER BY SUM(No_of_Votes) DESC
LIMIT 1;

-- 10. Find the most frequent Director.
SELECT Director, COUNT(*) AS Number_of_Movies
FROM imdb_top_1000
GROUP BY Director
ORDER BY Number_of_Movies DESC
LIMIT 1;

-- 11. Find the highest rated movie of each genre.
WITH genre_and_max_rating AS(
	SELECT Genre, MAX(IMDB_Rating) AS max_rating
	FROM imdb_top_1000
	GROUP BY Genre
    )
SELECT Genre, Series_Title, IMDB_Rating
FROM imdb_top_1000
WHERE (Genre, IMDB_Rating) IN
(SELECT * FROM genre_and_max_rating);

-- 12. Find number of movies starting with A for each group.
SELECT Genre, COUNT(*) AS Count
FROM imdb_top_1000
WHERE Series_Title like 'A%'
GROUP BY Genre;

-- 13. Find the most earning actor->director combo.
SELECT Star1, Director, SUM(Gross) AS Earning
FROM imdb_top_1000
GROUP BY Star1, Director
ORDER BY Earning DESC
LIMIT 1;

-- 14. Find the best(in-terms of metascore(avg)) actor->genre combo.
WITH cte AS(
	SELECT Star1, Genre, AVG(Metascore) AS Average_Metascore
	FROM imdb_top_1000
	GROUP BY Star1, Genre
	ORDER BY Average_Metascore DESC
    )
SELECT *
FROM cte
WHERE Average_Metascore = (SELECT MAX(Average_Metascore) FROM cte);

-- 15. Find the maximum movie release year.
SELECT Released_Year, COUNT(*) AS Total_Movie
FROM imdb_top_1000
GROUP BY Released_Year
ORDER BY Total_Movie DESC
LIMIT 1;