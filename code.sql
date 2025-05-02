CREATE SCHEMA IF NOT EXISTS pandemic;
use pandemic;

SELECT count(*) FROM infectious_cases;
-- Result: 10521


-- TASK 2 

DROP TABLE IF EXISTS locations;
CREATE TABLE locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    entity TEXT,
    code TEXT
);

DROP TABLE IF EXISTS cases;
CREATE TABLE cases (
    case_id INT AUTO_INCREMENT PRIMARY KEY,
    location_id INT,
    year INT,
    disease VARCHAR(50),
    cases DOUBLE,
    FOREIGN KEY (location_id) REFERENCES locations(location_id)
);

INSERT INTO locations (entity, code)
SELECT DISTINCT Entity, Code
FROM infectious_cases;

DROP TEMPORARY TABLE IF EXISTS disease_temp;
CREATE TEMPORARY TABLE disease_temp (name VARCHAR(50));

INSERT INTO disease_temp (name) VALUES
('Number_yaws'),
('polio_cases'),
('cases_guinea_worm'),
('Number_rabies'),
('Number_malaria'),
('Number_hiv'),
('Number_tuberculosis'),
('Number_smallpox'),
('Number_cholera_cases');


DROP PROCEDURE IF EXISTS insert_normalized_cases;
DELIMITER //

CREATE PROCEDURE insert_normalized_cases()
BEGIN
  DECLARE exit_loop INT DEFAULT FALSE;
  DECLARE disease_col VARCHAR(50);
  DECLARE disease_cursor CURSOR FOR SELECT name FROM disease_temp;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET exit_loop = TRUE;

  OPEN disease_cursor;

  read_loop: LOOP
    FETCH disease_cursor INTO disease_col;
    IF exit_loop THEN
      LEAVE read_loop;
    END IF;

    SET @sql = CONCAT(
      'INSERT INTO cases (location_id, year, disease, cases)
       SELECT l.location_id, i.Year, "', disease_col, '", NULLIF(i.', disease_col, ', '''')
       FROM infectious_cases i
       JOIN locations l ON l.entity = i.Entity AND l.code = i.Code
       WHERE NULLIF(i.', disease_col, ', '''') IS NOT NULL'
    );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
  END LOOP;

  CLOSE disease_cursor;
END;
//
DELIMITER ;

CALL insert_normalized_cases();

SELECT COUNT(*) AS total_records FROM cases;
-- Result: 46303


-- TASK 3

SELECT 
    l.entity,
    l.code,
    COUNT(c.cases) AS count_values,
    ROUND(AVG(c.cases), 2) AS avg_rabies,
    ROUND(MIN(c.cases), 0) AS min_rabies,
    ROUND(MAX(c.cases), 0) AS max_rabies,
    ROUND(SUM(c.cases), 0) AS total_rabies
FROM cases c
JOIN locations l ON l.location_id = c.location_id
WHERE c.disease = 'Number_rabies' AND c.cases IS NOT NULL
GROUP BY l.entity, l.code
ORDER BY avg_rabies DESC
LIMIT 10;

-- TASK 4 

SELECT 
    c.year,
    STR_TO_DATE(CONCAT(c.year, '-01-01'), '%Y-%m-%d') AS year_start_date,
    CURDATE() AS current_dt,
    TIMESTAMPDIFF(YEAR, STR_TO_DATE(CONCAT(c.year, '-01-01'), '%Y-%m-%d'), CURDATE()) AS year_diff
FROM cases c
LIMIT 10;


-- TASK 5 

DROP FUNCTION IF EXISTS year_diff_from_today;

DELIMITER //

CREATE FUNCTION year_diff_from_today(input_year INT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE year_start_date DATE;
  SET year_start_date = STR_TO_DATE(CONCAT(input_year, '-01-01'), '%Y-%m-%d');
  RETURN TIMESTAMPDIFF(YEAR, year_start_date, CURDATE());
END;
//
DELIMITER ;


SELECT 
    c.year,
    year_diff_from_today(c.year) AS year_difference
FROM cases c
LIMIT 10;





