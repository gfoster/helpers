feature:clear task

   Scenario: clear a task
      Given I have a task in progress
      When I have cleared a task
      Then the status should be pending
      And the start_time should be blank
      And the end_time should be blank
      And the percent should be 0
      
      Given I have a started task
      When I have cleared a task
      Then the status should be pending
      And the start_time should be blank
      And the end_time should be blank
      And the percent should be 0

      Given I have a failed task
      When I have cleared a task
      Then the status should be pending
      And the start_time should be blank
      And the end_time should be blank
      And the percent should be 0
      
      Given I have a finished task
      When I have cleared a task
      Then the status should be pending
      And the start_time should be blank
      And the end_time should be blank
      And the percent should be 0
      
