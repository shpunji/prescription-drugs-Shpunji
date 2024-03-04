-- How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT DISTINCT npi
FROM prescriber LEFT JOIN prescription USING (npi)
WHERE prescription.npi ISNULL;

-- Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT generic_name, SUM(total_claim_count) AS top_five
FROM prescriber INNER JOIN prescription USING (npi)
	INNER JOIN drug USING (drug_name)
WHERE specialty_description ILIKE '%Family Practice%'
GROUP BY generic_name
ORDER BY top_five DESC
LIMIT 5;

-- Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT generic_name, SUM(total_claim_count) AS top_five
FROM prescriber INNER JOIN prescription USING (npi)
	INNER JOIN drug USING (drug_name)
WHERE specialty_description ILIKE '%Cardiology%'
GROUP BY generic_name
ORDER BY top_five DESC
LIMIT 5;

-- Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? 

WITH top_cardiologists AS 
	(SELECT generic_name, SUM(total_claim_count) AS top_five
	FROM prescriber INNER JOIN prescription USING (npi)
		INNER JOIN drug USING (drug_name)
	WHERE specialty_description ILIKE '%Cardiology%'
	GROUP BY generic_name
	ORDER BY top_five DESC
	LIMIT 5),
	top_family_practice AS 
	(SELECT generic_name, SUM(total_claim_count) AS top_five
	FROM prescriber INNER JOIN prescription USING (npi)
		INNER JOIN drug USING (drug_name)
	WHERE specialty_description ILIKE '%Family Practice%'
	GROUP BY generic_name
	ORDER BY top_five DESC
	LIMIT 5)
SELECT generic_name, top_cardiologists.top_five AS top_card, top_family_practice.top_five AS top_fam
FROM top_cardiologists JOIN top_family_practice USING (generic_name);

-- First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims 
-- (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city

SELECT npi AS nashville_npi, SUM(total_claim_count) AS nashville_total_drugs
FROM prescriber JOIN prescription USING (npi)
WHERE nppes_provider_city ILIKE '%nashville%'
GROUP BY nashville_npi
ORDER BY nashville_total_drugs DESC
LIMIT 5;

-- "" For Memphis
SELECT npi AS memphis_npi, SUM(total_claim_count) AS memphis_total_drugs
FROM prescriber JOIN prescription USING (npi)
WHERE nppes_provider_city ILIKE '%memphis%'
GROUP BY memphis_npi
ORDER BY memphis_total_drugs DESC
LIMIT 5;

-- 4 major cities
WITH total_claims AS 
	(SELECT npi, SUM(total_claim_count) AS total_count, nppes_provider_city
	FROM prescriber JOIN prescription USING (npi)
	GROUP BY npi, nppes_provider_city
	ORDER BY total_count DESC),
		
		    nashville AS 
			(SELECT npi AS nashville_npi, total_count AS nashville_total_drugs, ROW_NUMBER() OVER() 
			 FROM total_claims
	 		 WHERE nppes_provider_city ILIKE '%nashville%'
	 		 ORDER BY nashville_total_drugs DESC
	 		 LIMIT 5),
			memphis AS
			(SELECT npi AS memphis_npi, total_count AS memphis_total_drugs, ROW_NUMBER() OVER() 
	 		 FROM total_claims
	 		 WHERE nppes_provider_city ILIKE '%memphis%'
	 		 GROUP BY memphis_npi, memphis_total_drugs
	 		 ORDER BY memphis_total_drugs DESC
	 		 LIMIT 5),
	 		knoxville AS 
	 		(SELECT npi AS knoxville_npi, total_count AS knoxville_total_drugs, ROW_NUMBER() OVER() 
	  		 FROM total_claims
	  		 WHERE nppes_provider_city ILIKE '%knoxville%'
	  		 GROUP BY knoxville_npi, knoxville_total_drugs
	  		 ORDER BY knoxville_total_drugs DESC
	  		 LIMIT 5),
	  		chattanooga AS 
	  		(SELECT npi AS chattanooga_npi, total_count AS chattanooga_total_drugs, ROW_NUMBER() OVER() 
	  		 FROM total_claims
	  		 WHERE nppes_provider_city ILIKE '%chattanooga%'
	  		 GROUP BY chattanooga_npi, chattanooga_total_drugs
	  		 ORDER BY chattanooga_total_drugs DESC
	  		 LIMIT 5)
SELECT *
FROM nashville JOIN memphis USING (row_number)
			   JOIN knoxville USING (row_number)
			   JOIN chattanooga USING (row_number);

-- Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths

SELECT county, overdose_deaths, year
FROM overdose_deaths INNER JOIN fips_county ON overdose_deaths.fipscounty = fips_county.fipscounty::integer
WHERE overdose_deaths > (SELECT AVG(overdose_deaths)
							FROM overdose_deaths INNER JOIN fips_county ON overdose_deaths.fipscounty = fips_county.fipscounty::integer ) AND county LIKE 'ANDERSON'
GROUP BY county, overdose_deaths, year
