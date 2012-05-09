Given /^I have a string [\"\'](.*?)[\"\']$/ do |string|
    @my_string = string
end

#When /^I rotate (\w+) (\d+) character|characters$/ do |direction, count|
#    count = count.to_i
#    case direction
#    when 'right'
#        @my_string.rotate_right(count)
#    when 'left'
#        @my_string.rotate_left(count)
#    else
#        raise "direction must be right or left"
#    end
#end

When /^I (\w+) (\d+) times$/ do |action, count|
    count = count.to_i
    (1..count).each do
        @my_string.send(action)
    end
end


Then /^the result should be [\"\'](.*?)[\"\']$/ do |result|
    @my_string.should == result
end

