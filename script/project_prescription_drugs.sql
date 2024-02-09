-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, SUM(total_claim_count) AS num_claims 
FROM prescription
GROUP BY npi
ORDER BY num_claims DESC;
--1881634483

--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, num_of_claims 
FROM (SELECT npi, SUM(total_claim_count) AS num_of_claims
	  FROM prescription
	  GROUP BY npi) AS num_claims_by_npi
INNER JOIN prescriber USING (npi)
ORDER BY num_of_claims DESC;


-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description, SUM(num_of_claims) AS total_num_of_claims
FROM (SELECT npi, SUM(total_claim_count) AS num_of_claims
	  FROM prescription
	  GROUP BY npi) AS num_claims_by_npi
INNER JOIN prescriber USING (npi)
GROUP BY specialty_description
ORDER BY total_num_of_claims DESC;


SELECT *
FROM prescription

--"Family Practice" 9752347


--     b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description, SUM(total_claim_count) sum_of_opioids
FROM prescriber
	INNER JOIN prescription USING (npi)
	INNER JOIN drug using (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description 
ORDER BY sum_of_opioids DESC;

--Nurse Practitioner


--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT specialty_description, SUM(total_claim_count) AS total_claim_count 
FROM prescriber LEFT OUTER JOIN prescription USING (npi)
GROUP BY specialty_description
ORDER BY total_claim_count NULLS FIRST;
--15



--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

--Used subquery in FROM statement (getting a slightly different total claim amount)
SELECT specialty_description,total_claims, total_opioid_claims, COALESCE(ROUND(total_opioid_claims/total_claims*100,2),0) AS percent_opioid
FROM(
	SELECT specialty_description, SUM(total_claim_count) AS total_claims,
		SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END) AS total_opioid_claims
	FROM prescriber INNER JOIN prescription USING (npi)
					INNER JOIN drug USING (drug_name)
	GROUP BY specialty_description
)
ORDER BY percent_opioid DESC;


--Used CTEs 
WITH total_claim_table AS (SELECT specialty_description, SUM(total_claim_count) AS total_claim_count
FROM prescriber INNER JOIN prescription USING (npi)
GROUP BY specialty_description)
,
total_opioid_table AS (SELECT specialty_description,
	SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END) AS total_opioid_claims
	FROM prescriber INNER JOIN prescription USING (npi)
					INNER JOIN drug USING (drug_name)
	GROUP BY specialty_description)

SELECT *, COALESCE(ROUND(total_opioid_claims/total_claim_count*100,2),0) AS percent_opioids
FROM total_claim_table INNER JOIN total_opioid_table USING (specialty_description)
ORDER BY percent_opioids DESC

-- "Case Manager/Care Coordinator"	72.00
-- "Orthopaedic Surgery"	68.98
-- "Interventional Pain Management"	60.89
-- "Pain Management"	59.42
-- "Anesthesiology"	59.32
-- "Hand Surgery"	56.07





-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, SUM(total_drug_cost) AS total_drug_cost
FROM prescription INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC;
--INSULIN GLARGINE,HUM.REC.ANLOG

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT generic_name, ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2) AS cost_per_day
FROM prescription INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;
--"C1 ESTERASE INHIBITOR"	3495.22



-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT drug_name, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' 
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug
ORDER BY drug_name;

	  

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on    anibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid' 
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type,
	SUM(total_drug_cost::money) AS total_drug_cost
FROM drug INNER JOIN prescription USING (drug_name)
GROUP BY drug_type
ORDER BY total_drug_cost DESC;
--Opioids ($105,080,626.37)

-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT DISTINCT(cbsa)
FROM cbsa
WHERE cbsaname LIKE '%TN%';
--10

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname, SUM(population) AS combined_pop
FROM cbsa INNER JOIN fips_county ON cbsa.fipscounty=fips_county.fipscounty
		  INNER JOIN population ON fips_county.fipscounty = population.fipscounty
GROUP BY cbsaname
ORDER BY combined_pop DESC;
--Largest: Nashville-Davidson--Murfreesboro--Franklin, TN
--Smallest: Morristown, TN

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT county, population
FROM population LEFT JOIN cbsa USING(fipscounty)
				INNER JOIN fips_county ON fips_county.fipscounty=population.fipscounty
WHERE cbsa IS NULL
ORDER BY population DESC;				
--Sevier County



-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count 
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count;



--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid. 
SELECT drug_name, total_claim_count, opioid_drug_flag
FROM prescription INNER JOIN drug USING (drug_name)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;



--     c. Add another column to your answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT p2.nppes_provider_first_name ||' '|| p2.nppes_provider_last_org_name AS prescriber, p1.drug_name, total_claim_count, opioid_drug_flag
FROM prescription AS p1 INNER JOIN drug USING (drug_name)
				        INNER JOIN prescriber AS p2 USING (npi)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;


-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT prescriber.npi, drug.drug_name, specialty_description
FROM prescriber CROSS JOIN drug
WHERE specialty_description = 'Pain Management' 
			AND nppes_provider_city = 'NASHVILLE'
			AND opioid_drug_flag = 'Y';                                   
	  
			

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT combo_med.npi, combo_med.drug_name, total_claim_count AS total_claim_count
FROM (SELECT npi, drug_name, specialty_description
	  FROM prescriber CROSS JOIN drug
	  WHERE specialty_description = 'Pain Management' 
			AND nppes_provider_city = 'NASHVILLE'
			AND opioid_drug_flag = 'Y'     
	 ) AS combo_med
	 LEFT JOIN prescription USING (npi,drug_name)
ORDER BY total_claim_Count DESC NULLS LAST;

  
  
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT combo_med.npi, combo_med.drug_name, COALESCE(prescription.total_claim_count, 0) AS total_claim_count
FROM (SELECT npi, drug_name, specialty_description
	  FROM prescriber CROSS JOIN drug
	  WHERE specialty_description = 'Pain Management' 
			AND nppes_provider_city = 'NASHVILLE'
			AND opioid_drug_flag = 'Y'     
	 ) AS combo_med
	 LEFT JOIN prescription USING (npi,drug_name)
ORDER BY total_claim_Count DESC NULLS LAST;	 
	 


------------------------------------BONUS QUESTIONS --------------------------------
-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT prescriber.npi, prescription.npi
FROM prescriber LEFT JOIN prescription USING(npi)
WHERE prescription.npi IS NULL;
--4458


-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT generic_name, SUM(total_claim_count) AS total_claims_by_fam_prac
FROM prescriber INNER JOIN prescription USING(npi)
				INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claims_by_fam_prac DESC
LIMIT 5;

-- "LEVOTHYROXINE SODIUM"	406547
-- "LISINOPRIL"	311506
-- "ATORVASTATIN CALCIUM"	308523
-- "AMLODIPINE BESYLATE"	304343
-- "OMEPRAZOLE"	273570


--     b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT generic_name, SUM(total_claim_count) AS total_claims_by_card
FROM prescriber INNER JOIN prescription USING(npi)
				INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_claims_by_card DESC
LIMIT 5;

-- "ATORVASTATIN CALCIUM"	120662
-- "CARVEDILOL"	106812
-- "METOPROLOL TARTRATE"	93940
-- "CLOPIDOGREL BISULFATE"	87025
-- "AMLODIPINE BESYLATE"	86928



--     c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
SELECT generic_name, SUM(total_claim_count) AS total_claims_by_fam_prac_card
FROM prescriber INNER JOIN prescription USING(npi)
				INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Cardiology'
	 OR specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claims_by_fam_prac_card DESC
LIMIT 5;

-- 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
 WITH nashville_prescribers AS (
		 SELECT npi, SUM(total_claim_count) AS total_claims
		 FROM prescriber INNER JOIN prescription USING (npi)
		 WHERE nppes_provider_city = 'NASHVILLE'
		 GROUP BY npi
 		 ORDER BY total_claims DESC
	     LIMIT 5)
 
 SELECT npi, total_claims, nppes_provider_city
 FROM nashville_prescribers INNER JOIN prescriber USING (npi)
 ORDER BY total_claims DESC
 ;
 
	
		
--     b. Now, report the same for Memphis.
 WITH memphis_prescribers AS (
		 SELECT npi, SUM(total_claim_count) AS total_claims
		 FROM prescriber INNER JOIN prescription USING (npi)
		 WHERE nppes_provider_city = 'MEMPHIS'
		 GROUP BY npi
 		 ORDER BY total_claims DESC
	     LIMIT 5)
 
 SELECT npi, total_claims, nppes_provider_city
 FROM memphis_prescribers INNER JOIN prescriber USING (npi)
 ORDER BY total_claims DESC;
    
--     c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
(WITH nashville_prescribers AS (
		 SELECT npi, SUM(total_claim_count) AS total_claims
		 FROM prescriber INNER JOIN prescription USING (npi)
		 WHERE nppes_provider_city = 'NASHVILLE'
		 GROUP BY npi
 		 ORDER BY total_claims DESC
	     LIMIT 5)
 
 SELECT npi, total_claims, nppes_provider_city
 FROM nashville_prescribers INNER JOIN prescriber USING (npi)
)
 UNION
 (WITH memphis_prescribers AS (
		 SELECT npi, SUM(total_claim_count) AS total_claims
		 FROM prescriber INNER JOIN prescription USING (npi)
		 WHERE nppes_provider_city = 'MEMPHIS'
		 GROUP BY npi
 		 ORDER BY total_claims DESC
	     LIMIT 5)
 SELECT npi, total_claims, nppes_provider_city
 FROM memphis_prescribers INNER JOIN prescriber USING (npi)
 )
UNION
 (WITH knoxville_prescribers AS (
		 SELECT npi, SUM(total_claim_count) AS total_claims
		 FROM prescriber INNER JOIN prescription USING (npi)
		 WHERE nppes_provider_city = 'KNOXVILLE'
		 GROUP BY npi
 		 ORDER BY total_claims DESC
	     LIMIT 5)
 SELECT npi, total_claims, nppes_provider_city
 FROM knoxville_prescribers INNER JOIN prescriber USING (npi)
 )
 UNION
  (WITH chattanooga_prescribers AS (
		 SELECT npi, SUM(total_claim_count) AS total_claims
		 FROM prescriber INNER JOIN prescription USING (npi)
		 WHERE nppes_provider_city = 'CHATTANOOGA'
		 GROUP BY npi
 		 ORDER BY total_claims DESC
	     LIMIT 5)
 SELECT npi, total_claims, nppes_provider_city
 FROM chattanooga_prescribers INNER JOIN prescriber USING (npi)
 )
 ORDER BY nppes_provider_city DESC,total_claims DESC; 
 
  
 
--  SELECT * FROM nashville_prescribers
--  UNION 
--  SELECT * FROM memphis_prescribers
--  UNION 
--  SELECT * FROM knoxville_prescribers
--  UNION  
--  SELECT * FROM chattanooga_prescribers



 
-- 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

--County overall average above the average
WITH avg_ods_county_yearly AS
 		( SELECT county, ROUND(AVG(overdose_deaths),2) AS avg_yearly_ods
	      FROM overdose_deaths INNER JOIN fips_county ON overdose_deaths.fipscounty=fips_county.fipscounty::numeric
		  GROUP BY county)
		  
SELECT county, avg_yearly_ods
FROM avg_ods_county_yearly
WHERE avg_yearly_ods > (
		SELECT AVG(overdose_deaths)
		FROM overdose_deaths)

ORDER BY avg_yearly_ods DESC;	



--County by year above average		  
SELECT county, overdose_deaths, year
FROM overdose_deaths INNER JOIN fips_county ON overdose_deaths.fipscounty=fips_county.fipscounty::numeric
WHERE overdose_deaths > (
		SELECT AVG(overdose_deaths)
	    FROM overdose_deaths INNER JOIN fips_county ON overdose_deaths.fipscounty=fips_county.fipscounty::numeric)
GROUP BY county, overdose_deaths, year
ORDER BY county	




-- 5.
--     a. Write a query that finds the total population of Tennessee.
SELECT SUM(population) AS total_pop_TN
FROM population INNER JOIN fips_county USING (fipscounty)
WHERE state = 'TN';


--     b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.

SELECT county, population, ROUND(population/(SELECT SUM(population)
									   FROM population) * 100,2) AS percent_pop
FROM population  JOIN fips_county USING (fipscounty)
ORDER BY percent_pop DESC;

									






