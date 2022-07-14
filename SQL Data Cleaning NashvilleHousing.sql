/*
Cleaning Data in SQL
*/

 

-- Standarize Data Format

Select SaleDateConverted, CONVERT(Date, SaleDate)
from PortfolioProject.dbo.NashvilleHousing

--this is not working
UPDATE NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- we have to do it this way
-- we created a new column with the right Date format
ALTER TABLE NashvilleHousing
add SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

--Populate Property address Data

Select *
from PortfolioProject.dbo.NashvilleHousing
Where PropertyAddress is null

Select *
from PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is null
order by ParcelID

-- Doing a Self JOIN
-- we joined the same exact table to itself
--and we the ParcelID is the same but it is not the same row
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null


-- we use UPDATE
-- Basically we merge the new address column eliminating the NULL spaces
-- we can alse replace with Strings like ' No address '  if we prefer. it depends on the case.
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null

---------------------------------------------------------------------------------------------------------------------------------
-- Breaking Down Address into Individual Columns (Address, City, State)

Select PropertyAddress
from PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID
--we want to separate the address in 2. the "address" and the "city"
--  we gonna use a SUBSTRING
-- and a "character index" or "char index"
 -- we are gonna use the , as delimiter
 -- it can be any character
 --so this is gona take from the first value to the ,
Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address 
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address 


from PortfolioProject.dbo.NashvilleHousing

/* FIRST SUBSTRING NOTES
 --so this is gona take from the first value to the ,
 --and we delete the coma using the -1*/

 /*SECOND SUBSTRING NOTES
 --we are taking the rest of the address ( the city) and putting into a new column
 --we take the characters after the coma, we changed the 1 for the "CHARINDEX(ETCETCETC)"
 --if we take the +1 out, we gonna see the COMA
 */


 -- we cant separate 2 values into from one column without creating another 2 other columns
 --so just like we added the table before
 --we are gonna create 2 new columns and add that value in.

ALTER TABLE NashvilleHousing
add PropertySplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)

ALTER TABLE NashvilleHousing
add PropertySplitCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

--Testing the changes

Select *
from PortfolioProject.dbo.NashvilleHousing

/*Now we are cleaning/modifying the OwnerAddress*/
--We will be using PARSENAME

Select OwnerAddress
from PortfolioProject.dbo.NashvilleHousing

--parsename just works with periods (.) so we have to replace the , for the .
--It separates the address backwards ( de atras para adelante)
--and thats why we use 3, 2, 1 insetead of 1, 2, 3
Select
PARSENAME(REPLACE(OwnerAddress, ',','.') ,3)
,PARSENAME(REPLACE(OwnerAddress, ',','.') ,2)
,PARSENAME(REPLACE(OwnerAddress, ',','.') ,1)
from PortfolioProject.dbo.NashvilleHousing

--Adding tables and Adding values

ALTER TABLE NashvilleHousing
add OwnerSplitAddress nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',','.') ,3)


ALTER TABLE NashvilleHousing
add OwnerSplitCity nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',','.') ,2)

ALTER TABLE NashvilleHousing
add OwnerSplitState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',','.') ,1)


-- Change Y and N to Yes and No in "Sold as Vacant" field

--Checking the fields
Select Distinct(SoldAsVacant), Count(SoldAsVacant)
from PortfolioProject.dbo.NashvilleHousing
group by SoldAsVacant
order by 2

-- USING CASE
Select SoldAsVacant
,	CASE When SoldAsVacant = 'Y' THEN 'Yes'
		 When SoldAsVacant = 'N' THEN 'No'
		 Else SoldAsVacant
		 END
from PortfolioProject.dbo.NashvilleHousing


Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
		 When SoldAsVacant = 'N' THEN 'No'
		 Else SoldAsVacant
		 END

-------------------------------------------------------------------------------------------------------------
-- Remove Duplicates

--We will be using  CTE
--we're gonna be using ROW NUMBER
--We want to partition our data

--PUTTING IN THE CTE

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num


from PortfolioProject.dbo.NashvilleHousing
--order by ParcelID
)
Select  *
from RowNumCTE
Where row_num > 1
order by PropertyAddress

--DELETING THE DUPLICATES
--lo mismo que arriba pero en vez de Select abajo se cambiar por DELETE
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num


from PortfolioProject.dbo.NashvilleHousing
--order by ParcelID
)
DELETE  
from RowNumCTE
Where row_num > 1
--order by PropertyAddress

--Sweet!

----------------------------------------------------------------------------------------------------------------
--Delete Unused Columns

Select *
from PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate
