feature:fail task

   Scenario: fail a task
      Given I have a task in progress
      When I have failed a task
      Then the status should be failed
      And the start_time should not be blank
      And the end_time should not be blank