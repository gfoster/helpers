feature:start task

  Scenario: start a task
     When I have started a task
     Then the status should be active
     And the start_time should not be blank
     And the end_time should be blank
     And the percent should be 0
