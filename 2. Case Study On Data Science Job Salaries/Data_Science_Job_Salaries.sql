USE sql_case_studies;

SELECT * FROM salaries;

/* 1. You're a Compensation analyst employed by a multinational corporation.
	Your Assignment is to Pinpoint Countries who give work fully remotely, for the 
    title 'managers’ Paying salaries Exceeding $90,000 USD. */
    
SELECT DISTINCT(company_location)
FROM salaries
WHERE remote_ratio = 100
AND job_title LIKE '%Manager%'
AND salary_in_usd > 90000;


/* 2. AS a remote work advocate Working for a progressive HR tech startup who place
	their freshers’ clients IN large tech firms. you're tasked WITH Identifying top 5 
    Country Having greatest count of large (company size) number of companies. */
    
SELECT DISTINCT(company_location), COUNT(*) AS total_large_company
FROM salaries
WHERE experience_level = 'EN'
AND company_size = 'L'
GROUP BY company_location
ORDER BY total_large_company DESC
LIMIT 5;


/* 3. Picture yourself AS a data scientist Working for a workforce management platform.
	Your objective is to calculate the percentage of employees. Who enjoy fully remote
    roles WITH salaries Exceeding $100,000 USD, Shedding light ON the attractiveness of
    high-paying remote positions IN today's job market. */
    
SELECT COUNT(*) / (SELECT COUNT(*) FROM salaries WHERE salary_in_usd > 100000) * 100
AS percentage
FROM salaries
WHERE remote_ratio = 100
AND salary_in_usd > 100000;


/* 4. As a market researcher, your job is to Investigate the job market for a company 
	that analyzes workforce data. Your task is to know how many people were employed in
    different types of companies AS per their size in 2021. */

SELECT company_size, COUNT(*) AS total_employee
FROM salaries
WHERE work_year = 2021
GROUP BY company_size;


/* 5. Imagine you're a data analyst Working for a global recruitment agency. Your Task
	is to identify the Locations where entry-level average salaries exceed the average
    salary for that job title IN market for entry level, helping your agency guide 
    candidates towards lucrative opportunities. */

-- Solution :- 1
WITH avg_per_job_title AS(    
	SELECT job_title, AVG(salary_in_usd) AS average_salary1
	FROM salaries
	WHERE experience_level = 'EN'
	GROUP BY job_title
    ),
avg_per_location AS(
	SELECT company_location, job_title, AVG(salary_in_usd) AS average_salary2
    FROM salaries
	WHERE experience_level = 'EN'
	GROUP BY company_location, job_title
    )
    
SELECT DISTINCT(company_location) AS Locations
FROM avg_per_location t1
WHERE average_salary2 > (SELECT average_salary1 FROM avg_per_job_title t2
						WHERE t1.job_title = t2.job_title);
                        

-- Solution :- 2
WITH avg_per_job_title AS(    
	SELECT job_title, AVG(salary_in_usd) AS average_salary1
	FROM salaries
	WHERE experience_level = 'EN'
	GROUP BY job_title
    ),
avg_per_location AS(
	SELECT company_location, job_title, AVG(salary_in_usd) AS average_salary2
    FROM salaries
	WHERE experience_level = 'EN'
	GROUP BY company_location, job_title
    )
    
SELECT DISTINCT(company_location) AS Locations
FROM avg_per_job_title t1 JOIN avg_per_location t2
ON t1.job_title = t2.job_title
WHERE average_salary2 > average_salary1;


/* 6. You've been hired by a big HR Consultancy to look at how much people get paid IN
	different Countries. Your job is to Find out for each job title which Country pays 
    the maximum average salary. This helps you to place your candidates IN those 
    countries. */

-- Solution :- 1
WITH avg_salary AS(
	SELECT company_location, job_title, AVG(salary_in_usd) AS avg_salary
	FROM salaries
	GROUP BY company_location, job_title
    )
    
SELECT company_location, job_title
FROM avg_salary t1
WHERE t1.avg_salary = (SELECT MAX(avg_salary)
						FROM avg_salary t2
                        WHERE t2.job_title = t1.job_title);
                        
-- Solution :- 2
SELECT company_location, job_title FROM
(SELECT company_location, job_title, AVG(salary_in_usd) AS avg_salary,
RANK() OVER(PARTITION BY job_title ORDER BY AVG(salary_in_usd) DESC) AS country_rank
FROM salaries
GROUP BY company_location, job_title) temp
WHERE country_rank = 1;


/* 7. AS a data-driven Business consultant, you've been hired by a multinational 
	corporation to analyze salary trends across different company Locations. Your goal 
    is to Pinpoint Locations WHERE the average salary Has consistently Increased over 
    the Past few years (Countries WHERE data is available for 3 years Only(present year 
    and past two years) providing Insights into Locations experiencing Sustained salary 
    growth. */

-- Solution:- 1
WITH cte1 AS (
	SELECT company_location, work_year, AVG(salary_in_usd) AS avg_salary
	FROM salaries
	WHERE work_year >= YEAR(CURRENT_DATE()) - 2
	GROUP BY company_location, work_year
	ORDER BY company_location ASC, work_year DESC
    ),

cte2 AS(
	SELECT *
	FROM cte1
	WHERE company_location IN 
		(SELECT company_location
		FROM cte1
		GROUP BY company_location
		HAVING COUNT(company_location) = 3)
	),
 
cte3 AS(
	SELECT *,
	LEAD(avg_salary) OVER(PARTITION BY company_location) AS last_avg_salary
	FROM cte2
    ),

cte4 AS(    
	SELECT *,
	LEAD(last_avg_salary) OVER(PARTITION BY company_location) AS second_last_avg_salary
	FROM cte3
    )
    
SELECT company_location
FROM cte4
WHERE last_avg_salary IS NOT NULL
AND second_last_avg_salary IS NOT NULL
AND avg_salary > last_avg_salary
AND last_avg_salary > second_last_avg_salary;

-- Solution:- 2  (creating pivot table)
WITH cte1 AS (
	SELECT company_location, work_year, AVG(salary_in_usd) AS avg_salary
	FROM salaries
	WHERE work_year >= YEAR(CURRENT_DATE()) - 2
	GROUP BY company_location, work_year
	ORDER BY company_location ASC, work_year DESC
    ),

cte2 AS(
	SELECT *
	FROM cte1
	WHERE company_location IN 
		(SELECT company_location
		FROM cte1
		GROUP BY company_location
		HAVING COUNT(company_location) = 3)
	)

SELECT company_location
FROM(
	SELECT company_location,
	MAX(CASE WHEN work_year = YEAR(CURRENT_DATE) THEN avg_salary END) AS current_year_avg,
	MAX(CASE WHEN work_year = YEAR(CURRENT_DATE) - 1 THEN avg_salary END) AS last_year_avg,
	MAX(CASE WHEN work_year = YEAR(CURRENT_DATE) - 2 THEN avg_salary END) AS second_last_year_avg
	FROM cte2
	GROUP BY company_location
	HAVING current_year_avg > last_year_avg
	AND last_year_avg > second_last_year_avg
) t;

/* 8. Picture yourself AS a workforce strategist employed by a global HR tech startup. 
	Your Mission is to Determine the percentage of fully remote work for each experience
    level IN 2021 and compare it WITH the corresponding figures for 2024, Highlighting 
    any significant Increases or decreases IN remote work Adoption over the years. */

WITH percentage_of_2021 AS(
	SELECT t1.experience_level, ROUND((total_remote / total * 100), 2) AS percentage FROM
		(SELECT experience_level, COUNT(*) AS total 
		FROM salaries
		WHERE work_year = 2021
		GROUP BY experience_level) t1
	JOIN
		(SELECT experience_level, COUNT(*) AS total_remote
		FROM salaries
		WHERE work_year = 2021 AND remote_ratio = 100
		GROUP BY experience_level) t2
	ON t1.experience_level = t2.experience_level
    ),
    
percentage_of_2024 AS(
	SELECT t1.experience_level, ROUND((total_remote / total * 100), 2) AS percentage FROM
		(SELECT experience_level, COUNT(*) AS total 
		FROM salaries
		WHERE work_year = 2024
		GROUP BY experience_level) t1
	JOIN
		(SELECT experience_level, COUNT(*) AS total_remote
		FROM salaries
		WHERE work_year = 2024 AND remote_ratio = 100
		GROUP BY experience_level) t2
	ON t1.experience_level = t2.experience_level
    )
    
SELECT t1.experience_level, t1.percentage AS percentage_2021,
t2.percentage AS percentage_2024,
((t2.percentage - t1.percentage) / t1.percentage * 100) AS percentage_change
FROM percentage_of_2021 t1 JOIN percentage_of_2024 t2
ON t1.experience_level = t2.experience_level;


/* 9. AS a Compensation specialist at a Fortune 500 company, you're tasked WITH 
	analyzing salary trends over time. Your objective is to calculate the average salary
    increase percentage for each experience level and job title between the years 2023 
    and 2024, helping the company stay competitive IN the talent market. */
    
SELECT t1. job_title, t1.experience_level, avg_salary_2023, avg_salary_2024,
ROUND(((avg_salary_2024 - avg_salary_2023) / avg_salary_2023 * 100), 2) AS percentage_change
FROM(
	(SELECT job_title, experience_level, ROUND(AVG(salary_in_usd), 2) AS avg_salary_2023
	FROM salaries
	WHERE work_year = 2023
	GROUP BY job_title, experience_level) t1
	JOIN
	(SELECT job_title, experience_level, ROUND(AVG(salary_in_usd), 2) AS avg_salary_2024
	FROM salaries
	WHERE work_year = 2024
	GROUP BY job_title, experience_level) t2
	ON t1.job_title = t2.job_title AND t1.experience_level = t2.experience_level
)
ORDER BY job_title, experience_level;


/* 10. As a database analyst you have been assigned the task to Select Countries where 
	average mid-level salary is higher than overall mid-level salary for the year 2023. */

SET @overall_avg = (SELECT AVG(salary_in_usd)
					FROM salaries
					WHERE experience_level = 'MI'
					AND work_year = 2023);
                    
SELECT company_location
FROM salaries
WHERE experience_level = 'MI'
AND work_year = 2023
GROUP BY company_location
HAVING AVG(salary_in_usd) > @overall_avg;


/* 11. As a database analyst you have been assigned the task to Identify the company 
	locations with the highest and lowest average salary for senior-level (SE) 
    employees in 2023. */
    
(SELECT company_location, AVG(salary_in_usd) AS avg_salary
FROM salaries
WHERE experience_level = 'SE'
AND work_year = 2023
GROUP BY company_location
ORDER BY avg_salary DESC
LIMIT 1)
UNION ALL
(SELECT company_location, AVG(salary_in_usd) AS avg_salary
FROM salaries
WHERE experience_level = 'SE'
AND work_year = 2023
GROUP BY company_location
ORDER BY avg_salary ASC
LIMIT 1);


/* 12. You're a Financial analyst Working for a leading HR Consultancy, and your
 Task is to Assess the annual salary growth rate for various job titles. By
 Calculating the percentage increase in salary from previous year to this
 year, you aim to provide valuable insights into salary trends with different
 job roles. */
 
SELECT job_title, work_year, SUM(salary_in_usd) AS total,
LAG(SUM(salary_in_usd)) OVER(PARTITION BY job_title ORDER BY job_title, work_year) AS next_year,
(SUM(salary_in_usd) - LAG(SUM(salary_in_usd)) OVER(ORDER BY job_title)) / LAG(SUM(salary_in_usd)) OVER(ORDER BY job_title) AS pr
FROM salaries
GROUP BY job_title, work_year
ORDER BY job_title, work_year;

-- Why it gives null when i PARTITION BY job_title & work_year. It should be


/* 13. You are a researcher and you have been assigned the task to Find the year
 with the highest average salary for each job title. */

WITH cte AS(
	SELECT job_title, work_year, AVG(salary_in_usd) AS avg_salary,
	RANK() OVER(PARTITION BY job_title ORDER BY AVG(salary_in_usd) DESC) AS ranked
	FROM salaries
	GROUP BY job_title, work_year
    )
    
SELECT job_title, work_year, avg_salary AS max_avg_salary
FROM cte
WHERE ranked = 1;

