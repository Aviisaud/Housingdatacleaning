use project1;
select * from housingdata;

/*Standarize date formart in SQL with CONVERT*/
SELECT SaleDate, str_to_date(SaleDate, '%M %e,%Y')
FROM housingdata
where SaleDate is not null;

update housingdata 
set SaleDate = str_to_date(SaleDate, '%M %e,%Y')
where SaleDate is not null;
    

select SoldAsVacant, count(*)
from housingdata
group by 1;


/* Modifying incomplete words*
   As we can see, there are 52 and 399 values that shows ‘Y’, ‘N’ instead of ‘Yes’, ‘No’.  */

select case when SoldAsVacant2='Y' then 'Yes'
			when SoldAsVacant2='N' then 'No'
            else SoldAsVacant2 end as a
from housingdata;

update housingdata 
set SoldAsVacant = case when SoldAsVacant='Y' then 'Yes'
						 when SoldAsVacant='N' then 'No'
						 else SoldAsVacant end ;

select Count(PropertyAddress), count(*)
from housingdata;

/*Populate missing property addresses
 Every property has only one Parcel ID, as well as a unique address.
 I realized that missing PropertyAddress had their Parcel ID, so I populated the missing addresses based on the Parcel ID.*/
 
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress)
from housingdata a 
join housingdata b
on a.ParcelID=b.ParcelID
and a.UniqueID<>B.UniqueID
where a.PropertyAddress is null;

set SQL_SAFE_UPDATES = 0;

update housingdata a 
	join housingdata b
    on a.ParcelID=b.ParcelID
	and a.UniqueID<>B.UniqueID
set a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
                      where a.PropertyAddress is null;

set SQL_SAFE_UPDATES = 1;




with RowNumCTE as(
Select *,
	ROW_NUMBER () over (
	Partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order BY
				 UniqueID
				 ) as row_num
From housingdata
)
select * from RowNumCTE
where row_num>1;


/* -3.Break Address into individual columns (Address, City, State)*/
SELECT 
	SUBSTRING(PropertyAddress, 1, POSITION(',' in PropertyAddress)-1) as Address, 
	SUBSTRING(PropertyAddress, POSITION(',' in PropertyAddress)+1, length(PropertyAddress)) as City
FROM housingdata;

ALTER TABLE housingdata
ADD COLUMN Address VARCHAR(50);
ALTER TABLE housingdata
ADD COLUMN City varchar(20);

update housingdata
set Address = Substring(PropertyAddress, 1, position(',' in PropertyAddress)-1);

update housingdata
set City = Substring(PropertyAddress, position(',' in PropertyAddress)+1, LENGTH(PropertyAddress));


/*Breaking 'Owner' address into individual columns (Address, city, State)*/
SELECT 
	SUBSTRING(OwnerAddress, 1, POSITION(',' in OwnerAddress)-1) as Owner_Address, 
	SUBSTRING_INDEX(SUBSTRING(OwnerAddress, POSITION(',' in OwnerAddress)+1, length(PropertyAddress)-4), ",", 1) as Owner_City,
    SUBSTR(OwnerAddress, -2, 2) AS Owner_state
FROM housingdata;

ALTER TABLE housingdata
ADD COLUMN Owner_Address VARCHAR(50);
update housingdata
set Owner_Address = SUBSTRING(OwnerAddress, 1, POSITION(',' in OwnerAddress)-1);

ALTER TABLE housingdata
ADD COLUMN Owner_City varchar(20);
update housingdata
set Owner_City = SUBSTRING_INDEX(SUBSTRING(OwnerAddress, POSITION(',' in OwnerAddress)+1, length(PropertyAddress)-4), ",", 1);

ALTER TABLE housingdata
ADD COLUMN Owner_state varchar(2);
update housingdata
set Owner_state = SUBSTR(OwnerAddress, -2, 2);

/* Indentify and remove duplicates usig CTE */
with CTE as(
Select *,
	ROW_NUMBER () over (
	Partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 Order BY
				 UniqueID
				 ) as row_num
From housingdata
)

Delete 
from CTE
where row_num>1;

/* Delete unused columns */
Alter Table housingdata
DROP Column ownerAddress; 

Alter Table housingdata
DROP Column PropertyAddress;