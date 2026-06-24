
    
    

select
    appearance_id as unique_field,
    count(*) as n_records

from "football"."marts"."fct_appearances"
where appearance_id is not null
group by appearance_id
having count(*) > 1


