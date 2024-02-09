-- Which prescriber had the highest total number of claims (totaled over all drugs)? 
-- Report the npi and the total number of claims.
SELECT DISTINCT(npi), SUM(total_claim_count) AS total_claim_all
FROM prescriber LEFT JOIN prescription USING (npi)
WHERE total_claim_count > 0 AND total_claim_count NOTNULL
GROUP BY npi
ORDER BY total_claim_all DESC
LIMIT 1;

-- Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  
-- specialty_description, and the total number of claims.

SELECT nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN 
	  (SELECT DISTINCT(npi), SUM(total_claim_count) AS total_claim_all
	  FROM prescriber LEFT JOIN prescription USING (npi)
	  WHERE total_claim_count > 0 AND total_claim_count NOTNULL
	  GROUP BY npi
	  ORDER BY total_claim_all DESC
	  LIMIT 1) AS Highset_claims
USING (npi) INNER JOIN prescription USING (npi)
GROUP BY nppes_provider_first_name, nppes_provider_last_org_name, specialty_description;

-- Which specialty had the most total number of claims totaled over all drugs?
SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescription INNER JOIN prescriber USING (npi)
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 1;


-- Which specialty had the most total nummber of claims for opioids?
SELECT SUM(total_claim_count) AS total_opioids, specialty_description
FROM prescription LEFT JOIN drug USING (drug_name)
	  INNER JOIN prescriber USING (npi)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_opioids DESC
LIMIT 1;

-- **Challenge** Are there any specialties that appear in the presciber table that 
-- have no associated prescriptions in the prescription table?

SELECT drug_name, specialty_description
FROM prescriber INNER JOIN prescription USING (npi)
WHERE specialty_description ISNULL OR drug_name ISNULL;


-- **BONUS** For each specialty, report the percentage of total claims by that specialty which are 
-- for opioids. Which specialties have a high percentage of opioids?


-- Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, SUM(total_drug_cost) AS generic_costs
FROM prescription INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY generic_costs DESC
LIMIT 1;

-- Which drug (generic_name) has the highest total cost per day? 
-- **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**

SELECT generic_name, ROUND(SUM(total_drug_cost) / SUM(total_day_supply),2) AS avg_cost_per_day
FROM prescription INNER JOIN drug USING (drug_name)
GROUP BY generic_name
ORDER BY avg_cost_per_day DESC
LIMIT 1;

-- For each drug in the drug table, return the drug name and then a column named 'drug_type' which 
-- says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs 
-- which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 ELSE 'neither' END AS drug_type
FROM drug;

-- Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) 
-- on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

WITH drug_type_cost AS 
	(SELECT drug_type, total_drug_cost
	FROM prescription 
		INNER JOIN 
			(SELECT *,
		 	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		 	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		 	ELSE 'neither' END AS drug_type
			 FROM drug) AS drug_type_table
		USING (drug_name)
		WHERE drug_type NOT LIKE 'neither'
	ORDER BY drug_type)
SELECT drug_type, SUM(total_drug_cost) AS total_per_drug
FROM drug_type_cost
GROUP BY drug_type;

-- How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.

SELECT COUNT(DISTINCT cbsa)
FROM cbsa INNER JOIN fips_county USING (fipscounty)
WHERE state = 'TN';

-- Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsaname, SUM(population) AS total_population
FROM cbsa INNER JOIN population USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_population;

SELECT cbsaname, SUM(population) AS total_population
FROM cbsa INNER JOIN population USING (fipscounty)
GROUP BY cbsaname
ORDER BY total_population DESC;
-- Morristown, TN Lowest with 116352
-- Nashville-Davidson-Murfreesboro-Franklin, TN Highest with 1830410

-- What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county, population
FROM population INNER JOIN fips_county USING (fipscounty) 
	LEFT JOIN cbsa USING (fipscounty)
WHERE cbsa ISNULL
ORDER BY population DESC
LIMIT 1;

-- Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count > 3000;

-- For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

WITH high_count AS 
	(SELECT drug_name, total_claim_count
	 FROM prescription
	 WHERE total_claim_count > 3000)
SELECT drug_name, total_claim_count, opioid_drug_flag
FROM high_count INNER JOIN drug  USING (drug_name);

-- Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

WITH high_count AS 
	(SELECT *
	 FROM prescription
	 WHERE total_claim_count > 3000)
SELECT drug_name, total_claim_count, opioid_drug_flag, nppes_provider_first_name, nppes_provider_last_org_name
FROM high_count INNER JOIN drug  USING (drug_name)
	INNER JOIN prescriber ON high_count.npi = prescriber.npi;
	
-- First, create a list of all npi/drug_name combinations for pain management specialists
-- in the city of Nashville where the drug is an opioid.

SELECT specialty_description, nppes_provider_city, opioid_drug_flag
FROM prescriber CROSS JOIN drug
WHERE nppes_provider_city ILIKE '%nashville%' AND opioid_drug_flag = 'Y' 
	AND specialty_description ILIKE 'pain management';
		
		
-- Next, report the number of claims per drug per prescriber. Be sure to include all combinations, 
-- whether or not the prescriber had any claims. You should report the npi, the drug name, and the 
-- number of claims (total_claim_count). ** fill missing values with 0

WITH nashville_opioids AS 
	(SELECT specialty_description, nppes_provider_city, opioid_drug_flag, drug_name, npi
	FROM prescriber CROSS JOIN drug
	WHERE nppes_provider_city ILIKE '%nashville%' AND opioid_drug_flag = 'Y' 
	AND specialty_description ILIKE 'pain management')
SELECT npi, drug_name, total_claim_count
FROM prescription RIGHT JOIN nashville_opioids USING (drug_name, npi);

WITH nashville_opioids AS 
	(SELECT specialty_description, nppes_provider_city, opioid_drug_flag, drug_name, npi
	FROM prescriber CROSS JOIN drug
	WHERE nppes_provider_city ILIKE '%nashville%' AND opioid_drug_flag = 'Y' 
	AND specialty_description ILIKE 'pain management')
SELECT npi, drug_name, COALESCE(total_claim_count, '0') AS total_claims
FROM prescription RIGHT JOIN nashville_opioids USING (drug_name, npi)
ORDER BY total_claims DESC;