
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select club_id
from "football"."staging"."stg_clubs"
where club_id is null



  
  
      
    ) dbt_internal_test