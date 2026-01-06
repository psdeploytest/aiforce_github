-- Step 1: Source data extraction
WITH source_data AS (
    SELECT * 
    FROM SourceDB.SourceTable
),

-- Step 2: Transformation - Adding a new column
transformed_data AS (
    SELECT 
        *,
        Column1 + Column2 AS NewColumn
    FROM source_data
),

-- Step 3: Filtering data where Column1 is not NULL
filtered_data AS (
    SELECT 
        *
    FROM transformed_data
    WHERE Column1 IS NOT NULL
)

-- Step 4: Final selection of required columns
SELECT 
    NewColumn
FROM filtered_data
-- Ensure unique rows based on NewColumn
QUALIFY ROW_NUMBER() OVER (PARTITION BY NewColumn ORDER BY NewColumn) = 1
