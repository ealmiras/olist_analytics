with reviews as (
    select * from {{ source('olist', 'reviews') }}
),

renamed as (
    select
        review_id,
        order_id,
        review_score,
        review_comment_title as review_title,
        review_comment_message as review_message,
        review_creation_date as review_created_at,
        review_answer_timestamp as review_answered_at
    from reviews
)

select * from renamed