-- 1. Создаем таблицу с точной структурой из вашего CSV

CREATE TABLE `Nashville Housing Data for Data Cleaning` (
    UniqueID INT,
    ParcelID VARCHAR(50),
    LandUse VARCHAR(100),
    PropertyAddress VARCHAR(255),
    SaleDate VARCHAR(50),
    SalePrice INT,
    LegalReference VARCHAR(100),
    SoldAsVacant VARCHAR(10),
    OwnerName VARCHAR(255),
    OwnerAddress VARCHAR(255),
    Acreage DECIMAL(10,2),
    TaxDistrict VARCHAR(100),
    LandValue INT,
    BuildingValue INT,
    TotalValue INT,
    YearBuilt INT,
    Bedrooms INT,
    FullBath INT,
    HalfBath INT
);
-- 2. Загружаем данные
LOAD DATA LOCAL INFILE '/Users/apple/Desktop/project sql/Nashville Housing Data for Data Cleaning (reuploaded).csv'
INTO TABLE `Nashville Housing Data for Data Cleaning`
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 LINES;

SELECT COUNT(*)
FROM `Nashville Housing Data for Data Cleaning`;

-- ОЧИСТКА ДАННЫХ В ЗАПРОСАХ 
SELECT SaleDate
  FROM `Nashville Housing Data for Data Cleaning`;

DESCRIBE `Nashville Housing Data for Data Cleaning`;

-- ЕСЛИ ОБНОВЛЕНИЕ НЕ ВЫПОЛНЯЕТСЯ ДОЛЖНЫМ ОБРАЗОМ 

ALTER TABLE `Nashville Housing Data for Data Cleaning` 
ADD COLUMN SaleDateConverted DATE;

UPDATE `Nashville Housing Data for Data Cleaning`
SET SaleDateConverted = STR_TO_DATE(SaleDate, '%M %e, %Y');

SELECT SaleDate, SaleDateConverted 
  FROM `Nashville Housing Data for Data Cleaning`;

-- ЗАПОЛНИТЬ ДАННЫЕ ОБ АДРЕСЕ ОБЬЕКТА НЕДВИЖИМОСТИ 

SELECT *
  FROM `Nashville Housing Data for Data Cleaning`
--  WHERE PropertyAddress IS NULL
ORDER BY ParcelID;
 
 SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
		IFNULL(a.PropertyAddress, b.PropertyAddress) AS UpdatedAddress
   FROM `Nashville Housing Data for Data Cleaning` a
  INNER JOIN `Nashville Housing Data for Data Cleaning` b
     ON a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
  WHERE a.PropertyAddress IS NULL;
  
  UPDATE `Nashville Housing Data for Data Cleaning` a
    JOIN `Nashville Housing Data for Data Cleaning` b
      ON a.ParcelID = b.ParcelID 
     AND a.UniqueID <> b.UniqueID
     SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
   WHERE a.PropertyAddress IS NULL;
 
-- РАЗДЕЛЕНИЕ АДРЕСА НА ОТДЕЛЬНЫЕ СТОЛБЦЫ (АДРЕС, ГОРОД, ШТАТ)
SELECT PropertyAddress
FROM `Nashville Housing Data for Data Cleaning`;

SELECT
    SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS Address,
    SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 1, LENGTH(PropertyAddress)) AS City
FROM `Nashville Housing Data for Data Cleaning`;

-- 1. Добавляем колонки для улицы и города
ALTER TABLE `Nashville Housing Data for Data Cleaning` 
ADD COLUMN PropertySplitAddress VARCHAR(255),
ADD COLUMN PropertySplitCity VARCHAR(255);

-- 2. Заполняем их данными
UPDATE `Nashville Housing Data for Data Cleaning`
SET PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1),
    PropertySplitCity = SUBSTRING_INDEX(PropertyAddress, ',', -1);

-- 3. Проверяем результат
SELECT PropertyAddress, PropertySplitAddress, PropertySplitCity
  FROM `Nashville Housing Data for Data Cleaning`
 LIMIT 5;


-- В ПОЛЕ ПРОДАНО КАК СВОБОДНОЕ ЗАМЕНИТЬ Y and N ДА И НЕТ 
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM `Nashville Housing Data for Data Cleaning`
GROUP BY SoldAsVacant
ORDER BY 2;

SELECT SoldAsVacant,
	   CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END
FROM `Nashville Housing Data for Data Cleaning`;

UPDATE `Nashville Housing Data for Data Cleaning`
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   WHEN SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END;
		

-- УДАЛЕНИЕ ДУБЛИКАТОВ
WITH RowNumCTE AS (
	SELECT *,
		   ROW_NUMBER() OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
		   ORDER BY UniqueID) AS row_num
	  FROM `Nashville Housing Data for Data Cleaning`
	  -- ORDER BY ParcelID
)
SELECT *
   FROM RowNumCTE
  WHERE row_num > 1
  ORDER BY PropertyAddress;
  
  -- Безопасное и быстрое удаление дубликатов через временную таблицу (обход ошибки 1288 и таймаутов)
CREATE TEMPORARY TABLE ids_to_keep AS 
SELECT MIN(UniqueID) AS UniqueID  
  FROM `Nashville Housing Data for Data Cleaning` 
 GROUP BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference;

-- Удаляем строки, которых нет в списке уникальных ID
DELETE t 
  FROM `portffolioproject`.`Nashville Housing Data for Data Cleaning` t
  LEFT JOIN ids_to_keep k ON t.UniqueID = k.UniqueID
 WHERE k.UniqueID IS NULL;

-- Очищаем временную таблицу
DROP TEMPORARY TABLE ids_to_keep;

-- УДАЛИТЬ НЕ ИСПОЬЗУЕМЫЕ СТОЛБЦЫ 


ALTER TABLE `portffolioproject`.`Nashville Housing Data for Data Cleaning`
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress, 
DROP COLUMN SaleDate;

-- Финальная проверка таблицы
SELECT *
FROM `portffolioproject`.`Nashville Housing Data for Data Cleaning`
LIMIT 100;
