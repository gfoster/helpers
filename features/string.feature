Feature: Test the string extension features
  Scenario Outline: test the basic character string rotation

  Given I have a string "<start>"
  When I rotate <direction> <count> characters
  Then the result should be "<result>"

  Examples:
     | start | direction | count | result |
     | abcd  | right     |     1 | dabc   |
     | abcd  | right     |     2 | cdab   |
     | abcd  | right     |     3 | bcda   |
     | abcd  | right     |     4 | abcd   |
     | abcd  | left      |     1 | bcda   |
     | abcd  | left      |     2 | cdab   |
     | abcd  | left      |     3 | dabc   |
     | abcd  | left      |     4 | abcd   |

  Scenario Outline: Test the string shift and pop

  Given I have a string '<start>'
  When I <action> <count> times
  Then the result should be "<result>"

  Examples:
     | start | action | count | result |
     | abcd  | shift  |     1 | bcd    |
     | abcd  | shift  |     2 | cd     |
     | abcd  | shift  |     3 | d      |
     | abcd  | shift  |     4 |        |
     | abcd  | pop    |     1 | abc    |
     | abcd  | pop    |     2 | ab     |
     | abcd  | pop    |     3 | a      |
     | abcd  | pop    |     4 |        |
