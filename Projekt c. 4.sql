-- krok 1 --

CREATE OR REPLACE TABLE t_Miroslav_Slouka_project_SQL_primary_final AS 
	SELECT 
	    payroll_year AS year,
	    AVG(value) AS avg_payroll,
	    cpvt.name AS payroll_category,
	    cpu.name AS payroll_unit,
	    cpib.name AS industry_branch,
	    NULL AS avg_price,
	    -- NULL AS category_code,
	    NULL AS food_name,
	    NULL AS quantity,
	    NULL AS unit
	FROM 
	    czechia_payroll cp 
	LEFT JOIN 
	    czechia_payroll_value_type cpvt 
	    ON cp.value_type_code = cpvt.code 
	LEFT JOIN 
	    czechia_payroll_unit cpu 
	    ON cp.unit_code = cpu.code 
	LEFT JOIN 
	    czechia_payroll_calculation cpc 
	    ON cp.calculation_code = cpc.code 
	LEFT JOIN 
	    czechia_payroll_industry_branch cpib 
	    ON cp.industry_branch_code = cpib.code
	WHERE 
	    cpvt.name = 'Průměrná hrubá mzda na zaměstnance' 
	    AND cpc.name = 'fyzický'
	    AND cpib.name IS NOT NULL 
	GROUP BY  
	    payroll_year,
	    cpvt.name,
	    cpu.name,
	    cpib.name
	UNION ALL
	SELECT 
	    YEAR(date_from) AS year,
	    NULL AS avg_payroll,  -- Přidáno pro spojení s prvním dotazem
	    NULL AS payroll_category,
	    NULL AS payroll_unit,
	    NULL AS industry_branch, -- Přidáno pro spojení s prvním dotazem
	    AVG(value) AS avg_price,
	    -- cp.category_code,
	    cpc1.name AS food_name,
	    cpc1.price_value AS quantity,
	    cpc1.price_unit AS unit
	FROM 
	    czechia_price cp 
	LEFT JOIN 
	    czechia_price_category cpc1  
	    ON cp.category_code = cpc1.code
	WHERE 
	    region_code IS NULL
	GROUP BY
	    `year`, 
	    cp.category_code,
	    cpc1.name,
	    cpc1.price_value,
	    cpc1.price_unit
	ORDER BY
	    `year`,
	    industry_branch, 
	    food_name;

-- krok 2 --	   
	   
CREATE OR REPLACE TABLE t_miroslav_slouka_project_SQL_secondary_final AS
	SELECT 
		year,
		country,
		GDP,
		population,
		gini
	FROM economies e 
	WHERE country IN (
			SELECT country	
			FROM countries c 
			WHERE continent = 'Europe'
	);
	   
-- otázka č.1 --
	   	   
WITH question1 AS (
    SELECT 
        year, 
        avg_payroll , 
        LAG(year) OVER (PARTITION BY industry_branch ORDER BY year) AS previous_year,  
        LAG(avg_payroll) OVER (PARTITION BY industry_branch ORDER BY avg_payroll) AS previous_avg_payroll, 
        industry_branch  
    FROM 
        t_miroslav_slouka_project_sql_primary_final tmsp 
    WHERE 1=1
        AND industry_branch IS NOT NULL
)
SELECT 
    year, 
    avg_payroll, 
    previous_year, 
    previous_avg_payroll,
    industry_branch,
    avg_payroll - previous_avg_payroll AS difference_payroll, 
    CASE
    	WHEN avg_payroll - previous_year > 0 THEN 'Mzda roste'
    	WHEN avg_payroll - previous_year < 0 THEN 'Mzda klesá'
    	WHEN avg_payroll - previous_year = 0 THEN 'Mzda stagnuje'
    END AS result
FROM 
    question1
WHERE 1=1
    AND previous_year IS NOT NULL
ORDER BY `year`;

       
-- otázka č.2 --
 
WITH min_max_year_price AS (
    SELECT 
        MIN(year) AS min_year_price,
        MAX(year) AS max_year_price
    FROM t_miroslav_slouka_project_sql_primary_final
    WHERE avg_price IS NOT NULL 
), query1 AS (
	SELECT
		tmsp.`year`,
	    tmsp.food_name,
	    tmsp.avg_price
	FROM t_miroslav_slouka_project_sql_primary_final tmsp
	JOIN min_max_year_price mmyp
		ON tmsp.`year` = mmyp.min_year_price 
		OR tmsp.`year` = mmyp.max_year_price
	WHERE 
		(tmsp.food_name LIKE '%mléko%' 
		OR tmsp.food_name LIKE '%chléb%')
	GROUP BY 
		tmsp.`year`, 
	  	tmsp.food_name,
	  	tmsp.avg_price
), query2 AS (
	SELECT
    	tmsp.`year`,
	    AVG(tmsp.avg_payroll) AS all_avg_payroll
	FROM t_miroslav_slouka_project_sql_primary_final tmsp
	JOIN min_max_year_price mmyp
		ON tmsp.`year` = mmyp.min_year_price 
		OR tmsp.`year` = mmyp.max_year_price
	WHERE 
		tmsp.avg_payroll IS NOT NULL 
	GROUP BY 
	    tmsp.`year`, 
	    tmsp.food_name,
	    tmsp.avg_price
)
SELECT 
	q1.*,
    q2.all_avg_payroll,
    TRUNCATE(q2.all_avg_payroll / q1.avg_price, 0) AS quantity
FROM
	query1 q1
LEFT JOIN query2 q2
    ON q1.`year` = q2.`year` 

    
    
-- otázka č.3 --
	
WITH query1 AS (
    SELECT
        `year`, 
        food_name,
        avg_price,
        LAG(year) OVER (PARTITION BY food_name ORDER BY `year`) AS previous_year,  
        LAG(avg_price) OVER (PARTITION BY food_name ORDER BY `year`) AS previous_avg_price 
    FROM t_miroslav_slouka_project_sql_primary_final
    WHERE
        food_name IS NOT NULL
)
SELECT 
	*,
	avg_price - previous_avg_price AS difference,
	ROUND(((avg_price - previous_avg_price) / previous_avg_price) * 100, 2) AS price_increase_percentage
FROM query1
WHERE
	previous_year IS NOT NULL
ORDER BY 
    price_increase_percentage;
	-- food_name,
	-- `year`;
	
-- otázka č.4 --

WITH query1 AS (
    SELECT
        `year`, 
   	    AVG(avg_price)AS all_avg_price,   --  OVER (PARTITION BY `year`), 
   	    LAG(`year`) OVER (ORDER BY `year`) AS previous_year,   	    
   	    LAG(AVG(avg_price)) OVER (ORDER BY `year`) AS previous_avg_price
    FROM t_miroslav_slouka_project_sql_primary_final
    WHERE
        food_name IS NOT NULL
    GROUP BY
    	`year`
	    ), query2 AS (
    SELECT
         `year`,     
         AVG(avg_payroll)AS all_avg_payroll,
   	     LAG(`year`) OVER (ORDER BY `year`) AS previous_year,
   	     LAG(AVG(avg_payroll)) OVER (ORDER BY `year`) AS previous_avg_payroll
    FROM t_miroslav_slouka_project_sql_primary_final
    WHERE
        avg_payroll IS NOT NULL
    GROUP BY
    	`year`
)
SELECT 
	-- q1.*,
    q1.`year`,
    ROUND(((q1.all_avg_price - q1.previous_avg_price) / q1.previous_avg_price) * 100, 2) AS price_value_percentage,
    -- q2.*,
    ROUND(((q2.all_avg_payroll - q2.previous_avg_payroll) / q2.previous_avg_payroll) * 100, 2) AS payroll_value_percentage,
    (ROUND(((q1.all_avg_price - q1.previous_avg_price) / q1.previous_avg_price) * 100, 2)) -
    (ROUND(((q2.all_avg_payroll - q2.previous_avg_payroll) / q2.previous_avg_payroll) * 100, 2)) AS difference_value
FROM 
	query1 q1
LEFT JOIN 
    query2 q2
ON 
	q1.`year` = q2.`year`
WHERE 
    q1.previous_year IS NOT NULL
    AND q2.previous_year IS NOT NULL 
ORDER BY difference_value DESC

   

 -- otázka č.5 --  

WITH query1 AS (
    SELECT
        `year`, 
   	    -- AVG(avg_price) AS all_avg_price, 
   	    -- LAG(`year`) OVER (ORDER BY `year`) AS previous_year,   	    
   	    -- LAG(AVG(avg_price)) OVER (ORDER BY `year`) AS previous_avg_price,
   	    AVG(avg_price) - LAG(AVG(avg_price)) OVER (ORDER BY `year`) AS difference_price
    FROM t_miroslav_slouka_project_sql_primary_final
    WHERE
        food_name IS NOT NULL
    GROUP BY
    	`year`
), query2 AS (
    SELECT
        `year`, 
   	     -- AVG(avg_payroll) AS all_avg_payroll, 
   	     -- LAG(`year`) OVER (ORDER BY `year`) AS previous_year,   	    
   	     -- LAG(AVG(avg_payroll)) OVER (ORDER BY `year`) AS previous_avg_payroll,
   	     AVG(avg_payroll) - LAG(AVG(avg_payroll)) OVER (ORDER BY `year`) AS difference_payroll
    FROM t_miroslav_slouka_project_sql_primary_final
     WHERE
        avg_payroll IS NOT NULL
    GROUP BY
    	`year` 
), query3 AS (    
     	SELECT
 	    `year`,
 	    -- GDP, 
 	    -- LAG(GDP) OVER (ORDER BY year) AS previous_GDP,
 		GDP - LAG(GDP) OVER (ORDER BY year) AS difference_GDP
 	FROM
		t_miroslav_slouka_project_sql_secondary_final tmss
    WHERE
    	country = 'Czech Republic'
    	AND GDP IS NOT NULL
)    	
SELECT
    q1.`year`,
	difference_price,
	difference_payroll,
	difference_GDP
FROM 
	query1 q1
LEFT JOIN 
    query2 q2
	ON q1.year = q2.year
LEFT JOIN
    query3 q3
	ON q1.year =q3.year 
WHERE 
	difference_price IS NOT NULL 
    
