feature:finish task

   Scenario: finish a task
      Given I have already started a task
      When I have finished a task
      Then the status should be complete
      And the start_time should not be blank
      And the end_time should not be blank
      And the percent should be 100
