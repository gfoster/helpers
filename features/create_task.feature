feature:create task
    In order to maintain a list of tasks
    As a programmer
    I should be able to create a new empty task
    
    Scenario: create a new task
       When I have created a new task
       Then the status should be pending
       And the start_time should be blank
       And the end_time should be blank
       And the percent should be 0