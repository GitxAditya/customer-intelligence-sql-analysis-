use customer_intelligence_db;

with review_metrics as (
    select
		count(distinct review_id) as total_reviews,
        round(avg(rating), 2) as avg_rating,
        round(100* sum(case when rating = 5 then 1 else 0 end)/ count(*),2) as five_star_percent,
        round(100* sum(case when rating >=4 then 1 else 0 end) / count(*),2) as positive_review_percent,
        round(100* sum(case when rating <= 2 then 1 else 0 end)/ count(*),2) as negative_review_percent,
        round(100* (sum(case when  rating >= 4 then 1 else 0 end) - sum(case when rating <= 2 then 1 else 0 end)) / count(*), 2) as net_satisfaction_score
	from reviews
),
category_review as(
	select
		p.category,
        count(distinct r.review_id) as review_count,
        round(avg(r.rating), 2) as avg_rating,
        round(100* sum(case when rating >=4 then 1 else 0 end) / count(*),2) as positive_review,
		round(100.0 * sum(case when rating <= 2 then 1 else 0 end) / count(*), 2) as negative_review_percent
	from products p
    join reviews r on p.prod_id = r.prod_id
    group by p.category
    order by avg_rating desc
),
product_review as(
	select
		p.prod_id,
        p.prod_name,
        p.category,
        count(distinct r.review_id) as review_count,
        round(avg(r.rating), 2) as avg_rating,
        round(100.0 * sum(case when r.rating >= 4 then 1 else 0 end) / count(*), 2) as positive_percent
    from products p
    join reviews r on p.prod_id = r.prod_id
    group by p.prod_id, p.prod_name, p.category
    having review_count >= 5
    order by avg_rating desc
    limit 10
)
select
	'total reviews' as metric,
     total_reviews as value
from review_metrics
union all
select
	"average rating",
    avg_rating
from review_metrics
union all
select
	"5 star percentage",
    five_star_percent
from review_metrics
union all
select
	'positive reviews (%)',
    positive_review_percent
from review_metrics
union all
select
    'negative reviews (%)',
    negative_review_percent
from review_metrics
union all
select
    'net satisfaction score (nss)',
    net_satisfaction_score
from review_metrics;

select
    avg_rating,
    case
        when avg_rating >= 4.5 then 'excellent'
        when avg_rating >= 4.0 then 'good'
        when avg_rating >= 3.0 then 'average'
        else 'poor'
    end as satisfaction_category
from review_metrics;