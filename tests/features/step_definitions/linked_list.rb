Given /^I have a linked list$/ do
    @list = Helpers::LinkedList.new
end

Given /^I have a linked list with values \[(.+)\]$/i do |value|
    array = value.split(',').map(&:to_i)
    @list = Helpers::LinkedList.new(array)
end

When /^I push (.+)$/i do |value|
    @list.push(value.to_i)
end

Then /^My length is (\d+)$/i do |value|
    @list.length.should == value.to_i
end

Then /^I contain \[(.+?)\]$/i do |value|
    array = value.split(',').map(&:to_i)
    @list.to_a.should == array
end

When /^I reverse myself$/i do
    @list.reverse
end

When /^I clear$/i do
    @list.clear
end

When /^I append (\d+)$/i do |value|
    @list.append(value.to_i)
end

Then /^(\w+) returns (\d+)$/i do |operand, value|
    case operand
    when 'pop'
        retval = @list.pop
    when 'shift'
        retval = @list.shift
    end

    retval.should == value.to_i
end






