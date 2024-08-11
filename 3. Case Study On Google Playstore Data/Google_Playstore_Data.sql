USE sql_case_studies;

SELECT * FROM playstore;

TRUNCATE TABLE playstore;

-- infile statement
/*LOAD DATA INFILE "D:/SQL case studies/CS - 2/playstore.csv"
INTO TABLE playstore
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;*/

SELECT COUNT(*) FROM playstore;


/* 1.  You're working as a market analyst for a mobile app development company. 
	Your task is to identify the most promising categories (TOP 5) for launching 
    new free apps based on their average ratings. */
    
SELECT Category, ROUND(AVG(Rating), 2) AS avg_rating
FROM playstore
WHERE Type = 'Free'
GROUP BY Category
ORDER BY avg_rating DESC
LIMIT 5;


/* 2. As a business strategist for a mobile app company, your objective
	is to pinpoint the three categories that generate the most revenue
	from paid apps. This calculation is based on the product of the app
	price and its number of installations. */

SELECT Category, SUM(revenue) AS total_revenue
FROM(    
	SELECT Category, Price * Installs AS revenue
	FROM playstore
	WHERE Type = 'Paid'
    ) t
GROUP BY Category
ORDER BY total_revenue DESC
LIMIT 3;


/* 3. As a data analyst for a gaming company, you're tasked with calculating
	the percentage of games within each category. This information will help
    the company understand the distribution of gaming apps across different
    categories. */
    
-- Solution - 1
SELECT Category, (App_count / (SELECT COUNT(*) FROM playstore) * 100) AS Percentage
FROM
	(SELECT Category, COUNT(*) AS App_count
	FROM playstore
	GROUP BY Category) t
WHERE Category = 'GAME';

-- Solution - 2
SELECT Category, Percentage
FROM 
	(SELECT Category, COUNT(*) AS total_cnt,
	COUNT(*) / SUM(COUNT(*)) OVER(ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED
	 FOLLOWING) * 100 AS Percentage
	FROM playstore
	GROUP BY Category) t
WHERE Category = 'GAME';


/* 4. As a data analyst at a mobile app-focused market research firm
	you’ll recommend whether the company should develop paid or
	free apps for each category based on the ratings of that category */
    
-- Solution - 1
SELECT t1.Category, IF(free_rating > paid_rating, 'Free', 'Paid') AS 'Recommended Type'
FROM
	(SELECT Category, ROUND(AVG(Rating), 2) AS free_rating
	FROM playstore
	WHERE Type =  'Free'
	GROUP BY Category) t1
JOIN
	(SELECT Category, ROUND(AVG(Rating), 2) AS paid_rating
	FROM playstore
	WHERE Type =  'Paid'
	GROUP BY Category)t2
ON t1.Category = t2.Category;


-- Solution - 2
SELECT Category, Type AS Recommended_type
FROM 
	(SELECT Category, Type, AVG(Rating) AS avg_rating,
	RANK() OVER(PARTITION BY Category ORDER BY AVG(Rating)) AS rating_rank
	FROM playstore
	GROUP BY Category, Type) t
WHERE rating_rank = 2;


/* 5. Suppose you're a database administrator your databases have been hacked and 
	hackers are changing price of certain apps on the database, it is taking long for 
    IT team to neutralize the hack, however you as a responsible manager don’t want your
    data to be changed, do some measure where the changes in price can be recorded as
    you can’t stop hackers from making changes. */
    
-- creating table where the update information will be stored.
CREATE TABLE PriceChangeLog (
    App VARCHAR(255),
    Old_Price DECIMAL(10, 2),
    New_Price DECIMAL(10, 2),
    Operation_Type VARCHAR(10),
    Operation_Date TIMESTAMP
);

-- Create a copy of 'playstore' table
create table temp_playstore as
SELECT * FROM playstore;

SELECT * FROM temp_playstore;

-- Track the updates
-- All the  queries in the 'DELIMITER' consider as a single query.
DELIMITER //   
CREATE TRIGGER price_change_update
AFTER UPDATE ON temp_playstore
FOR EACH ROW
BEGIN
    INSERT INTO pricechangelog (App, Old_Price, New_Price, Operation_Type, Operation_Date)
    VALUES (NEW.App, OLD.Price, NEW.Price, 'update', CURRENT_TIMESTAMP);
END
// DELIMITER ;

--         Now Check      --
SET SQL_SAFE_UPDATES = 0;

UPDATE temp_playstore
SET price = 4
WHERE app = 'Infinite Painter';

UPDATE temp_playstore
SET price = 5
WHERE app = 'Sketch - Draw & Paint';

-- check
SELECT * FROM pricechangelog;





/* 6. Your IT team have neutralized the threat. However, hackers have made some changes
	in the prices, but because of your measure you have noted the changes, now you want
    correct data to be inserted into the database again. */
    
-- Step - 1: Drop the trigger.
DROP TRIGGER price_change_update;

-- Step - 2: Update.
UPDATE temp_playstore t1
JOIN pricechangelog t2
ON t1.App = t2.App
SET t1.price = t2.old_price;

-- check
SELECT * FROM temp_playstore
WHERE App = 'Sketch - Draw & Paint';


/* 7. As a data person you are assigned the task of investigating the correlation
	between two numeric factors: app ratings and the quantity of reviews. */
    
SET @mean_rating = (SELECT ROUND(AVG(Rating), 2) FROM Playstore);
SET @mean_reviews = (SELECT ROUND(AVG(Reviews), 2) FROM Playstore);

SELECT ROUND((SUM((Rating - @mean_rating) * (Reviews - @mean_reviews)) / 
SQRT(SUM(POWER((Rating - @mean_rating), 2)) * SUM(POWER((Reviews - @mean_reviews), 2)))), 2)
AS 'correlation between Rating & Reviiews'
FROM playstore


/* 8. Your boss noticed that some rows in genres columns have multiple genres in them,
	which was creating issue when developing the recommender system from the data he/she
    assigned you the task to clean the genres column and make two genres out of it, rows
    that have only one genre will have other column as blank. */

-- function for first part
DELIMITER //
CREATE FUNCTION left_part(genre VARCHAR(100))
RETURNS VARCHAR(100)
DETERMINISTIC
BEGIN
    SET @idx = LOCATE(';', genre);
    SET @ret = IF(@idx > 0, LEFT(genre, @idx-1), genre);
    RETURN @ret;
END
// DELIMITER ;

-- function for second part
DELIMITER //
CREATE FUNCTION right_part(genre VARCHAR(100))
RETURNS VARCHAR(100)
DETERMINISTIC 
BEGIN
   SET @idx = LOCATE(';', genre);
   SET @ret = IF(@idx = 0 , '-', SUBSTRING(genre, @idx+1));
   return @ret;
END
// DELIMITER ;

select App, Genres,
left_part(Genres) AS 'Genre 1',
right_part(Genres) AS 'Genre 2'
FROM playstore;


/* 9. Your senior manager wants to know which apps are not performing as par in their
	particular category, however he is not interested in handling too many files or 
    list for every category and he/she assigned you with a task of creating a dynamic
    tool where he/she can input a category of apps he/she interested in and your tool
	then provides real-time feedback by displaying apps within that category that have
    ratings lower than the average rating for that specific category. */
    
DELIMITER //
CREATE PROCEDURE checking(IN  categ varchar(50))
BEGIN
		SET @avg_rating = (SELECT AVG(Rating) FROM playstore WHERE Category = categ);
        SELECT * FROM playstore WHERE Category=categ AND Rating < @avg_rating;
END
// DELIMITER ;

CALL checking('business')