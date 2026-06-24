
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    appearance_id as unique_field,
    count(*) as n_records

from "football"."marts"."fct_appearances"
where appearance_id is not null
group by appearance_id
having count(*) > 1



  
  
      
    ) dbt_internal_test