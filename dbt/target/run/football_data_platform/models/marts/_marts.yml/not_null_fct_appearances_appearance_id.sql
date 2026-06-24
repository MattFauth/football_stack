
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select appearance_id
from "football"."marts"."fct_appearances"
where appearance_id is null



  
  
      
    ) dbt_internal_test