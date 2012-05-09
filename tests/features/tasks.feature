Feature: Task Transition Features
  Scenario Outline: A task changes state

  Given I have a task
  When I have a <start_state> task
  And I attempt to <action> it
  Then the status should be <end_state>
  And the start time should be <start_time>
  And the end time should be <end_time>
  And it should be <percent> % complete

  Examples:
     | start_state | action | end_state | start_time | end_time  | percent |
     | pending     | start  | active    | not_blank  | blank     |       0 |
     | pending     | finish | complete  | not_blank  | not_blank |     100 |
     | pending     | clear  | pending   | blank      | blank     |       0 |
     | pending     | fail   | failed    | blank      | not_blank |       0 |
     | started     | start  | active    | not_blank  | blank     |       0 |
     | started     | finish | complete  | not_blank  | not_blank |     100 |
     | started     | clear  | pending   | blank      | blank     |       0 |
     | started     | fail   | failed    | not_blank  | not_blank |         |
     | finished    | start  | active    | not_blank  | blank     |       0 |
     | finished    | finish | complete  | not_blank  | not_blank |     100 |
     | finished    | clear  | pending   | blank      | blank     |       0 |
     | finished    | fail   | failed    | not_blank  | not_blank |         |
     | failed      | start  | active    | not_blank  | blank     |       0 |
     | failed      | finish | complete  | not_blank  | not_blank |     100 |
     | failed      | clear  | pending   | blank      | blank     |       0 |
     | failed      | fail   | failed    | blank      | not_blank |         |
