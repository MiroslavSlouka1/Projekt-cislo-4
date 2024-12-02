-- krok 1	
CREATE OR REPLACE TABLE t_Miroslav_Slouka_project_SQL_primary_final AS
	SELECT payroll_year, payroll_quarter, 
	    CONCAT(payroll_year, '-', payroll_quarter) AS payroll_year_quarter,
	    value,
		cpvt.name AS cpvt_name,
		cpu.name AS cpu_name,
		cpc.name AS cpc_name,
		cpib.name AS cpib_name
	FROM czechia_payroll cp 
	LEFT JOIN czechia_payroll_value_type cpvt 
	    ON cp.value_type_code = cpvt.code 
	LEFT JOIN czechia_payroll_unit cpu 
	    ON cp.unit_code = cpu.code 
	LEFT JOIN czechia_payroll_calculation cpc 
		ON cp.calculation_code = cpc.code 
	LEFT JOIN czechia_payroll_industry_branch cpib 
		ON cp.industry_branch_code = cpib.code; 	
	
-- krok 2   
CREATE TABLE question2 AS
	SELECT 
	    payroll_year, 
	    payroll_quarter, 
	    payroll_year_quarter,
	    value,
	    cpvt_name,
	    cpu_name,
	    cpc_name,
	    cpib_name,
	    NULL AS pcpc_name,
	    NULL AS pcp_unit
	FROM 
	    t_Miroslav_Slouka_project_SQL_primary_final
	UNION ALL
		SELECT 
		-- NULL AS payroll_year,
		-- NULL AS payroll_quarter,
		YEAR(date_from) AS payroll_year,
		QUARTER(date_from) AS payroll_quarter,
		CONCAT(YEAR(date_from), '-', QUARTER(date_from)) AS payroll_year_quarter,  
		AVG(value) AS value,      
		cpc1.name AS cpvt_name,
		'Price' AS cpu_name,  
		NULL AS cpc_name,
		NULL AS cpib_name,    
		cpc1.price_value AS pcpc_value,
		cpc1.price_unit AS pcpc_unit
		FROM 
		    czechia_price cp 
		LEFT JOIN 
		    czechia_price_category cpc1  
		    ON cp.category_code = cpc1.code
		WHERE 
		    region_code IS NULL
		GROUP BY
	    	-- YEAR(date_from) AS payroll_year,
	    	-- QUARTER(date_from) AS payroll_quarter,
		    CONCAT(YEAR(date_from), '-', QUARTER(date_from)), 
		    cpc1.name;
		    -- cpc1.price_value, 
		    -- cpc1.price_unit;
	   
-- krok 3	    
CREATE OR REPLACE TABLE 
	t_Miroslav_Slouka_project_SQL_primary_final 
AS SELECT 
	* 
FROM question2;

-- krok 4
DROP TABLE question2;


-- krok 5
CREATE TABLE t_miroslav_slouka_project_SQL_secondary_final AS
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


-- otazka cislo 1 -----------------------
WITH question1 AS (
    SELECT 
        payroll_year_quarter, 
        value, 
        LAG(payroll_year_quarter, 4) OVER (PARTITION BY cpib_name ORDER BY payroll_year_quarter, payroll_quarter) AS previous_year,  
        LAG(value, 4) OVER (PARTITION BY cpib_name ORDER BY payroll_year, payroll_quarter) AS previous_value, 
        cpib_name   
    FROM 
        t_miroslav_slouka_project_sql_primary_final tmsp 
    WHERE 
        cpvt_name = 'Průměrná hrubá mzda na zaměstnance' 
        AND cpc_name = 'fyzický'
)
SELECT 
    payroll_year_quarter, 
    value, 
    previous_year,  
    previous_value, 
    cpib_name,
    value - previous_value AS difference, 
    CASE
    	WHEN value - previous_value > 0 THEN 'Mzda roste'
    	WHEN value - previous_value < 0 THEN 'Mzda klesá'
    	WHEN value - previous_value = 0 THEN 'Mzda stagnuje'
    END AS result
FROM 
    question1
WHERE 1=1
    AND previous_year IS NOT NULL
    AND previous_value IS NOT NULL
    AND cpib_name IS NOT NULL
ORDER BY 
	payroll_year_quarter
	-- difference;

	
-- otazka cislo 2 ----------  
 WITH min_max_payroll AS (
    SELECT 
        MIN(payroll_year_quarter) AS min_payroll,
        MAX(payroll_year_quarter) AS max_payroll
    FROM t_miroslav_slouka_project_sql_primary_final
    WHERE cpu_name = 'Price'
),
query1 AS (
    SELECT 
        payroll_year_quarter,
        value,
        cpib_name
    FROM t_miroslav_slouka_project_sql_primary_final tmspspf 
    WHERE 
        cpvt_name = 'Průměrná hrubá mzda na zaměstnance' 
        AND cpc_name = 'fyzický'
        AND payroll_year_quarter IN (SELECT min_payroll FROM min_max_payroll UNION SELECT max_payroll FROM min_max_payroll)
),
query2 AS (
    SELECT 
       *
    FROM t_miroslav_slouka_project_sql_primary_final tmspspf 
    WHERE 
        (cpvt_name LIKE '%mléko%' OR cpvt_name LIKE '%chléb%')
        AND payroll_year_quarter IN (SELECT min_payroll FROM min_max_payroll UNION SELECT max_payroll FROM min_max_payroll)
)
SELECT 
    q1.payroll_year_quarter,
    q1.value AS value,
    q1.cpib_name AS name,
    q2.value AS price,
    q2.cpvt_name,
    TRUNCATE(q1.value / q2.value, 0) AS quantity
FROM 
    query1 q1
LEFT JOIN 
    query2 q2
ON 
    q1.payroll_year_quarter = q2.payroll_year_quarter
WHERE 
    q1.cpib_name IS NOT NULL
ORDER BY
    q2.cpvt_name, 
    q1.payroll_year_quarter;
   
   
   
-- otazka cislo 3 ----------  
WITH question1 AS (
    SELECT 
        payroll_year, 
        LAG(payroll_year) OVER (PARTITION BY cpvt_name ORDER BY payroll_year) AS previous_year, 
        AVG(value) AS average_price,
        LAG(AVG(value)) OVER (PARTITION BY cpvt_name ORDER BY payroll_year) AS previous_price, 
        cpvt_name
    FROM 
        t_miroslav_slouka_project_sql_primary_final tmsp 
    WHERE
        cpu_name = 'Price'
    GROUP BY 
        payroll_year,
        cpvt_name
    ORDER BY 
        cpvt_name,
        payroll_year
),
price_changes AS (
    SELECT
        *,
        average_price - previous_price AS difference,
        ROUND(((average_price - previous_price) / previous_price) * 100, 2) AS price_increase_percentage
    FROM question1
    WHERE previous_year IS NOT NULL
)
SELECT 
    *
FROM 
    price_changes
WHERE 
    price_increase_percentage = (
        SELECT MIN(price_increase_percentage)
        FROM price_changes
    )
ORDER BY 
    cpvt_name, 
    payroll_year;
   

-- otazka cislo 4 ----------
WITH query1 AS (
SELECT 
    payroll_year, 
    LAG(payroll_year) OVER (PARTITION BY cpvt_name ORDER BY payroll_year) AS previous_year, 
    AVG(value) AS avg_value,  
    LAG(AVG(value)) OVER (PARTITION BY cpvt_name ORDER BY payroll_year) AS avg_previous_price,
    cpvt_name
FROM 
    t_miroslav_slouka_project_sql_primary_final tmsp 
WHERE
    cpu_name = 'Price'
GROUP BY 
    payroll_year,
    cpvt_name
), query2 AS (
    SELECT 
        payroll_year, 
        value, 
        LAG(payroll_year) OVER (PARTITION BY cpib_name ORDER BY payroll_year) AS previous_year,
        AVG(value) AS p_avg_value,       
        LAG(AVG(value)) OVER (PARTITION BY cpib_name ORDER BY payroll_year) AS p_avg_previous_value, 
        cpib_name   
    FROM 
        t_miroslav_slouka_project_sql_primary_final tmsp 
    WHERE 
        cpvt_name = 'Průměrná hrubá mzda na zaměstnance' 
        AND cpc_name = 'fyzický'
   GROUP BY 
        payroll_year,
        cpvt_name     
)
SELECT 
    q1.payroll_year, 
    q1.cpvt_name,
    -- q1.*,
	-- q1.avg_value - q1.avg_previous_price AS payroll_rozdil,
	ROUND(((q1.avg_value - q1.avg_previous_price) / q1.avg_previous_price) * 100, 2) AS price_value_percentage,
	q2.cpib_name,
    ROUND(((q2.p_avg_value - q2.p_avg_previous_value) / q2.p_avg_previous_value) * 100, 2) AS payroll_value_percentage
FROM 
	query2 q2
LEFT JOIN 
    query1 q1
ON 
  q2.payroll_year = q1.payroll_year
WHERE 1=1
	AND avg_previous_price IS NOT NULL
    AND cpib_name IS NOT NULL
    AND q1.previous_year IS NOT NULL
    AND q2.previous_year IS NOT NULL 
ORDER BY price_value_percentage DESC
-- ORDER BY payroll_value_percentage DESC


	
-- otazka cislo 5 ----------
WITH query1 AS (
SELECT 
    payroll_year, 
    LAG(payroll_year) OVER (PARTITION BY cpvt_name ORDER BY payroll_year) AS previous_year, 
    AVG(value) AS avg_value,  
    LAG(AVG(value)) OVER (PARTITION BY cpvt_name ORDER BY payroll_year) AS avg_previous_price,
    cpvt_name
FROM 
    t_miroslav_slouka_project_sql_primary_final tmsp 
WHERE
    cpu_name = 'Price'
GROUP BY 
    payroll_year,
    cpvt_name
), query2 AS (
    SELECT 
        payroll_year, 
        value, 
        LAG(payroll_year) OVER (PARTITION BY cpib_name ORDER BY payroll_year) AS previous_year,
        AVG(value) AS p_avg_value,       
        LAG(AVG(value)) OVER (PARTITION BY cpib_name ORDER BY payroll_year) AS p_avg_previous_value, 
        cpib_name   
    FROM 
        t_miroslav_slouka_project_sql_primary_final tmsp 
    WHERE 
        cpvt_name = 'Průměrná hrubá mzda na zaměstnance' 
        AND cpc_name = 'fyzický'
   GROUP BY 
        payroll_year,
        -- cpvt_name
        cpib_name     
 ), query3 AS (
 	SELECT
 	    YEAR,
 	    LAG(GDP) OVER (ORDER BY year) AS previous_GDP,
 		GDP
 	FROM
		t_miroslav_slouka_project_sql_secondary_final tmss
    WHERE
    	country = 'Czech Republic'
) 
SELECT 
    q1.payroll_year, 
    q1.cpvt_name,
    -- q1.*,
	q2.cpib_name,    
	q1.avg_value - q1.avg_previous_price AS price_difference,
	q2.p_avg_value - q2.p_avg_previous_value AS payroll_difference,
	q3.GDP - q3.previous_GDP AS GDP_difference
FROM 
	query2 q2
LEFT JOIN 
    query1 q1
ON 
  q2.payroll_year = q1.payroll_year
LEFT JOIN
    query3 q3
ON
  q2.payroll_year =q3. year 
WHERE 1=1
	AND avg_previous_price IS NOT NULL
    AND cpib_name IS NOT NULL
    AND q1.previous_year IS NOT NULL
    AND q2.previous_year IS NOT NULL 
ORDER BY payroll_year;
-- ORDER BY price_difference


