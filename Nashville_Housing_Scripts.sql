
-- Standardize the Date format

ALTER TABLE Nashville_Housing_Data
ALTER COLUMN [SaleDate] date

-- Populate Property Address

Select *
From Nashville_Housing..Nashville_Housing_Data
--Where PropertyAddress is null
order by ParcelID


Select A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress)
From Nashville_Housing..Nashville_Housing_Data A
JOIN Nashville_Housing..Nashville_Housing_Data B
	on A.ParcelID = B.ParcelID
	AND A.[UniqueID ]<> B.[UniqueID ]
Where A.PropertyAddress is null

UPDATE A
Set PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
From Nashville_Housing..Nashville_Housing_Data A
JOIN Nashville_Housing..Nashville_Housing_Data B
	on A.ParcelID = B.ParcelID
	AND A.[UniqueID ]<> B.[UniqueID ]
Where A.PropertyAddress is null

-- Parsing addresses into seperate Address, City, State columns for both Property and Owner
-- Property

SELECT
Substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address
, Substring(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as City
FROM Nashville_Housing..Nashville_Housing_Data

ALTER TABLE Nashville_Housing_Data
ADD Address NVARCHAR(255);

UPDATE Nashville_Housing_Data
SET Address = Substring(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE Nashville_Housing_Data
ADD City NVARCHAR(255);

UPDATE Nashville_Housing_Data
SET City = Substring(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

-- Owner

SELECT
PARSENAME (REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME (REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME (REPLACE(OwnerAddress, ',', '.') , 1)
FROM Nashville_Housing..Nashville_Housing_Data

ALTER TABLE Nashville_Housing_Data
ADD OwnerAddressSplit NVARCHAR(255);

UPDATE Nashville_Housing_Data
SET OwnerAddressSplit = PARSENAME (REPLACE(OwnerAddress, ',', '.') , 3)

ALTER TABLE Nashville_Housing_Data
ADD OwnerCity NVARCHAR(255);

UPDATE Nashville_Housing_Data
SET OwnerCity = PARSENAME (REPLACE(OwnerAddress, ',', '.') , 2)

ALTER TABLE Nashville_Housing_Data
ADD OwnerState NVARCHAR(255);

UPDATE Nashville_Housing_Data
SET OwnerState = PARSENAME (REPLACE(OwnerAddress, ',', '.') , 1)

-- Changing Y/N to Yes/No in the "Sold as Vacant" field

SELECT SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
FROM Nashville_Housing..Nashville_Housing_Data

UPDATE Nashville_Housing_Data
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
						When SoldAsVacant = 'N' THEN 'No'
						ELSE SoldAsVacant
						END

-- Removing all duplicates with a CTE

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

FROM Nashville_Housing..Nashville_Housing_Data
)
SELECT * 
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- Delete Unused Columns

ALTER TABLE Nashville_Housing_Data
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

SELECT *
FROM Nashville_Housing..Nashville_Housing_Data