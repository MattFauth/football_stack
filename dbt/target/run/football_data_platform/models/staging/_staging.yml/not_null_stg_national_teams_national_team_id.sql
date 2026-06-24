
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select national_team_id
from "football"."staging"."stg_national_teams"
where national_team_id is null



  
  
      
    ) dbt_internal_test