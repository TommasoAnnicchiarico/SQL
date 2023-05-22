CREATE DATABASE HospitalManagement;
USE HospitalManagement;
SELECT*FROM health;
SELECT*FROM demographics;


-- 1. How many different admission types are there, and what are their frequencies? Each admission type corresponds 
-- to a specific value such as emergencies,urgent, newborn etc.

SELECT admission_type_id, COUNT(*) AS frequency
FROM health
GROUP BY admission_type_id
ORDER BY frequency DESC;

-- 2.What is the minimum,average and maximum time spent in the hospital for patients?
SELECT 
    MIN(time_in_hospital) AS minimum_time_inhospital,
    ROUND(AVG(time_in_hospital), 1) AS average_time_in_hospital,
    MAX(time_in_hospital) AS maximum_time_inhospital
FROM health;


-- 3.What is the average number of procedures performed by each specialty?
SELECT 
    medical_specialty,
    AVG(num_procedures) AS avg_procedure,
    COUNT(*) AS count
FROM health
GROUP BY medical_specialty
ORDER BY avg_procedure DESC;

-- There are several value with count of 1 procedures that can lead to misleading results 
-- For this reason, I decided to have a look only to the medical specialty with at least 10 procedures
SELECT 
    medical_specialty,
    AVG(num_procedures) AS avg_procedure,
    COUNT(*) AS count
FROM health
GROUP BY medical_specialty
HAVING count >= 10
ORDER BY avg_procedure DESC;


-- 4. Which race has the highest number of encounters in the dataset?
SELECT race, encounters
FROM (
    SELECT race, COUNT(*) AS encounters, DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS dense_ranking
    FROM demographics
    GROUP BY race
) AS subquery
WHERE dense_ranking = 1;



-- 5. Are there racial inequalities in health care?
SELECT 
    race,
    AVG(num_lab_procedures) AS avg_labprocedures,
    AVG(num_medications) AS avg_medications,
    AVG(num_procedures) AS avg_procedure
FROM health
        JOIN demographics ON demographics.encounter_ID = health.encounter_ID
GROUP BY race
ORDER BY avg_labprocedures DESC;
-- From the result there is no clear disparity between treatment of patients from different race

-- 6. Are there gender inequalities in health care?
SELECT 
    gender,
    AVG(num_lab_procedures) AS avg_labprocedures,
    AVG(num_medications) AS avg_medications,
    AVG(num_procedures) AS avg_procedure
FROM health
        JOIN demographics ON demographics.encounter_ID = health.encounter_ID
GROUP BY gender
ORDER BY avg_labprocedures DESC;
-- As well as race, also for gender there is no clear disparity of treatment of patients


-- 7. Analyze if there is a correlation between time spent in hospital and number of diagnosis: 
-- Calculating  MIN,AVG,MAX number of diagnosis before looking at correlation
SELECT MIN(number_diagnoses), AVG(number_diagnoses),MAX(number_diagnoses) FROM health;


SELECT AVG(time_in_hospital) AS avg_timehospital,
CASE WHEN number_diagnoses BETWEEN 1 AND 3 THEN "Few"
WHEN number_diagnoses BETWEEN 4 and 8 THEN "Average"
ELSE "Many" 
END AS total_diagnoses
FROM health
GROUP BY total_diagnoses
ORDER BY avg_timehospital;
-- From the result, there seems to be a correlation between the time spent in the hospital and number of diagnoses. 
-- Where patient with longer hospital stay has a higher number of diagnoses and effective managemnt by the hospital


-- 8. Determine the average time in the hospital for each admission type
SELECT
    admission_type_id,
    AVG(time_in_hospital) AS average_time_in_hospital
FROM health
GROUP BY admission_type_id;


-- 9. Which discharge disposition is the most common?
-- Each discharge type corresponds to a specific value such as dismessed to home,expired etc.
SELECT
    discharge_disposition_id,
    frequency
FROM (
    SELECT
        discharge_disposition_id,
        COUNT(*) AS frequency,
        DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS dense_ranking
    FROM
        health
    GROUP BY
        discharge_disposition_id
) AS subquery
WHERE dense_ranking=1;


-- 10.Most 3 common primary diagnosis. Diagnosis are classified as coded of three digits

SELECT diag_1, frequency
FROM (
    SELECT diag_1, COUNT(*) AS frequency, DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS dense_ranking
    FROM health
    GROUP BY diag_1
) AS subquery
WHERE dense_ranking <= 3;


-- I decided to deep dive by looking into the most common diagnosis by race.
-- Diagnosis 414 is the most common among difference races, however 428 is in first place "only" for AfricanAmerican while being also the 1 overall.
SELECT
    demographics.race,
    health.diag_1,
    COUNT(*) AS frequency
FROM    health
JOIN    demographics ON health.Encounter_ID = demographics.Encounter_ID
GROUP BY demographics.race, health.diag_1
HAVING
    frequency = ( SELECT MAX(sub.frequency)
        FROM
            (SELECT
                    race,
                    COUNT(*) AS frequency
                FROM health
                JOIN demographics ON health.Encounter_ID = demographics.Encounter_ID
                GROUP BY race, diag_1
            ) AS sub
        WHERE sub.race = demographics.race
    )
ORDER BY demographics.race, frequency;



-- 11. What is the percentage of patients with a readmission within 30 days?
SELECT 
    (COUNT(*) / (SELECT 
            COUNT(*)
        FROM health)) * 100 AS percentage_readmitted_within_30_days
FROM health
WHERE readmitted = '<30';


-- 12. How many patients had a change in their diabetic medications?
SELECT
    COUNT(*) AS patients_with_medication_change,
    COUNT(*) / (SELECT COUNT(*) FROM health) * 100 AS percentage_of_total
FROM health
WHERE health.change = 'ch';


-- 13. What is the distribution of age groups among the patients?
-- As expected, the highest frequency is in the age group from 70 to 80 while the lowest from 0 to 10
SELECT 
    age, COUNT(*) AS frequency
FROM demographics
GROUP BY age
ORDER BY frequency DESC;


-- 14. Calculate the average number of outpatient visits, emergency visits, and inpatient visits per patient.
SELECT 
    AVG(number_outpatient) AS avg_outpatient_visits,
    AVG(number_emergency) AS avg_emergency_visits,
    AVG(number_inpatient) AS avg_inpatient_visits
FROM health;


-- 15.Analyze the distribution of A1c test results among different age groups
SELECT
    demographics.age,
    health.A1cresult,
    COUNT(*) AS frequency
FROM
    health
JOIN
    demographics ON health.encounter_id = demographics.encounter_id
GROUP BY
    demographics.age, health.A1cresult
ORDER BY
    demographics.age;


-- 16. Final success story: How many patients in 'emergency conditions' stayed in the hospital less than the average time.
-- There were 33.648 rows returned which could make me think of a good medication and treatment by the hospital

SELECT  COUNT(*) AS total_count
FROM health
WHERE admission_type_id = '1'
        AND time_in_hospital < (SELECT 
            AVG(time_in_hospital)
        FROM
            health
        WHERE
            admission_type_id = '1');
