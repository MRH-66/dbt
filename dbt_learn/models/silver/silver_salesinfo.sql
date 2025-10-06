WITH sales AS 
(
    SELECT 
        sales_id,
        product_sk,
        customer_sk,
        {{ multiply('unit_price', 'quantity') }} AS calculated_gross_amount,
        gross_amount,
        payment_method
    FROM {{ ref('bronze_sales') }}
),
products AS 
(
    SELECT
        product_sk,
        category
    FROM {{ ref('bronze_product') }}
),
customer AS
(
    SELECT
        customer_sk,
        gender
    FROM {{ ref('bronze_customer') }}
),
joined_query AS
(
SELECT
    sales.sales_id,
    sales.gross_amount,
    sales.payment_method,
    product.category,
    customer.gender
FROM sales
JOIN products AS product ON sales.product_sk = product.product_sk
JOIN customer AS customer ON sales.customer_sk = customer.customer_sk
)

SELECT
    category,gender, sum(gross_amount) AS total_sales
FROM
    joined_query
GROUP BY
    category, gender
ORDER BY
    total_sales DESC