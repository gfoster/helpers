Feature: Linked List
   Scenario: We can init a new doubly linked list with a series of values

     Given I have a linked list
      When I push 24
       And I push 19
       And I push 3
      Then My length is 3
       And I contain [3, 19, 24]
      When I reverse myself
      Then I contain [24, 19, 3]
      When I append 12
      Then I contain [24, 19, 3, 12]
       And shift returns 12
       And I contain [24, 19, 3]
       And pop returns 24
       And I contain [19, 3]
      When I clear
      Then My length is 0

   Scenario: A doubly linked can be initialized with a set of values

     Given I have a linked list with values [1, 2, 3]
      Then I contain [1, 2, 3]
