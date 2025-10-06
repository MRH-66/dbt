WITH deddup_query AS
(
SELECT
    *,
    ROW_NUMBER() OVER (PARTITION BY id ORDER BY updated DESC) AS deduplication_id   
FROM
    {{ source('source', 'items') }} 
)
SELECT
    id,name,category,updated
FROM
    deddup_query
WHERE
    deduplication_id = 1