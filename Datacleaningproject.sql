-- DATA Cleaning in MYSQL. Database is about Housing details in Nashville,US

ALTER TABLE `NashvilleHousingDB`.`nashville housing data for data cleaning` 
RENAME TO  `NashvilleHousingDB`.`NashvilleHousing` ;

SELECT * FROM NashvilleHousing; -- QA only

ALTER TABLE NashvilleHousing MODIFY COLUMN SaleDate DATE; -- Standardize date format

SELECT * FROM NashvilleHousing
WHERE PropertyAddress IS NULL; -- Checking NULL VALUES


UPDATE NashvilleHousing SET PropertyAddress='No Address' 
WHERE PropertyAddress IS NULL;

-- Breaking Address into individual column

SELECT 
PropertyAddress,
SUBSTRING(PropertyAddress,1,LOCATE(',',PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress,LOCATE(',',PropertyAddress)+1) AS Address_2
FROM NashvilleHousing;

ALTER TABLE NashvilleHousing ADD COLUMN PropertySplitCity VARCHAR(255);

ALTER TABLE NashvilleHousing ADD COLUMN PropertySplitAddress VARCHAR(255);

UPDATE NashvilleHousing SET PropertySplitAddress=SUBSTRING(PropertyAddress,1,LOCATE(',',PropertyAddress)-1);

UPDATE NashvilleHousing SET PropertySplitCity=SUBSTRING(PropertyAddress,LOCATE(',',PropertyAddress)+1);


SELECT
substring_index(OwnerAddress,',',1) AS OwnerAddress,
SUBSTRING_INDEX((SUBSTRING_INDEX(OwnerAddress,',',-2)),',',1) AS Ownercity,
substring_index(OwnerAddress,',',-1) AS Ownerstate
FROM NashvilleHousing; -- Breaking OwnerAddress into individual columns


ALTER TABLE NashvilleHousing ADD COLUMN OwnerSplitAddress VARCHAR(255);

UPDATE NashvilleHousing SET OwnerSplitAddress=substring_index(OwnerAddress,',',1);

ALTER TABLE NashvilleHousing ADD COLUMN OwnerSplitCity VARCHAR(255);

UPDATE NashvilleHousing SET OwnerSplitCity=SUBSTRING_INDEX((SUBSTRING_INDEX(OwnerAddress,',',-2)),',',1);

ALTER TABLE NashvilleHousing ADD COLUMN OwnerSplitState VARCHAR(255);

UPDATE NashvilleHousing SET OwnerSplitState=substring_index(OwnerAddress,',',-1);


-- Standardize 'Sold as Vacant' column by changing Y and N to Yes and No for the column

SELECT DISTINCT(SoldasVacant),COUNT(SoldasVacant) FROM NashvilleHousing
GROUP BY 1; -- QA only

SELECT SoldasVacant,
CASE WHEN SoldasVacant='Y' THEN 'Yes'
WHEN SoldasVacant='N' THEN 'No'
ELSE SoldasVacant END
FROM NashvilleHousing;

UPDATE NashvilleHousing SET SoldasVacant=CASE WHEN SoldasVacant='Y' THEN 'Yes'
WHEN SoldasVacant='N' THEN 'No'
ELSE SoldasVacant END;

-- Remove Duplicate

WITH RownumCTE AS (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY
ParcelID,
PropertyAddress,
SalePrice,
Saledate,
LegalReference
ORDER BY UniqueID) AS row_num
FROM NashvilleHousing)
SELECT * FROM RownumCTE WHERE row_num > 1;


WITH RownumCTE AS (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY
ParcelID,
PropertyAddress,
SalePrice,
Saledate,
LegalReference -- Assumption is that if all the above values are equal, data are duplicates
ORDER BY UniqueID) AS row_num
FROM NashvilleHousing)
DELETE FROM NashvilleHousing USING NashvilleHousing 
JOIN RownumCTE ON RownumCTE.ParcelID=NashvilleHousing.ParcelID AND
RownumCTE.PropertyAddress=NashvilleHousing.PropertyAddress AND
RownumCTE.SalePrice=NashvilleHousing.SalePrice AND
RownumCTE.Saledate=NashvilleHousing.Saledate AND
RownumCTE.LegalReference=NashvilleHousing.LegalReference
WHERE row_num > 1;

-- Delete unused columns
ALTER TABLE NashvilleHousing DROP COLUMN PropertyAddress, DROP COLUMN OwnerAddress, DROP COLUMN TaxDistrict;
