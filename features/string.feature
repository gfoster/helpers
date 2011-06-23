Feature: Test the string extension features
  Scenario Outline: test the basic character string rotation

  Given I have a string "<start>"
  When I <action> <count> times
  Then the result should be "<result>"

  Examples:
     | start | action       | count | result |
     | abcd  | rotate_right |     1 | dabc   |
     | abcd  | rotate_right |     2 | cdab   |
     | abcd  | rotate_right |     3 | bcda   |
     | abcd  | rotate_right |     4 | abcd   |
     | abcd  | rotate_left  |     1 | bcda   |
     | abcd  | rotate_left  |     2 | cdab   |
     | abcd  | rotate_left  |     3 | dabc   |
     | abcd  | rotate_left  |     4 | abcd   |

  Scenario Outline: test the word rotation

    Given I have a string "<start>"
    When I <action> <count> times
    Then the result should be "<result>"

    Examples:
       | start              | action            | count | result             |
       | one two three four | rotate_word_right |     1 | four one two three |
       | one two three four | rotate_word_right |     2 | three four one two |
       | one two three four | rotate_word_right |     3 | two three four one |
       | one two three four | rotate_word_right |     4 | one two three four |
       | one two three four | rotate_word_left  |     1 | two three four one |
       | one two three four | rotate_word_left  |     2 | three four one two |
       | one two three four | rotate_word_left  |     3 | four one two three |
       | one two three four | rotate_word_left  |     4 | one two three four |

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

