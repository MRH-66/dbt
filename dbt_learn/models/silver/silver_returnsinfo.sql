WITH returns AS 
(
    SELECT 
        sales_id,
        product_sk,
        returned_qty,
        refund_amount,
        return_reason
    FROM {{ ref('bronze_returns') }}
),
products AS 
(
    SELECT
        product_sk,
        category
    FROM {{ ref('bronze_product') }}
),
joined_query AS
(
    SELECT
        returns.sales_id,
        returns.returned_qty,
        returns.refund_amount,
        returns.return_reason,
        product.category
    FROM returns
    JOIN products AS product 
        ON returns.product_sk = product.product_sk
)

SELECT
    category,
    return_reason,
    SUM(refund_amount)    AS total_refunds,
    SUM(returned_qty)     AS total_items_returned
FROM
    joined_query
GROUP BY
    category, return_reason
ORDER BY
    total_refunds DESC
