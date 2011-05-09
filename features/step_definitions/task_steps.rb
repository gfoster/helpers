require 'FozHelpers'

Before do
   @task = Task.new
end

After do
end

When /I have (.*) task$/ do |action|
   case action
   when /created a new/
      @task = Task.new
   when /started a/
      @task.start
   when /finished a/
      @task.finish
   when /failed a/
      @task.fail
   when /cleared a/
      @task.clear
   end
end

Given /I have a task in progress/ do
   @task.start
end

Then /the (.*) should be (.*)/ do |variable, value|
   my_value = @task.instance_variable_get("@#{variable}")
   if value == 'blank'
      my_value.blank?.should == true
   else
      my_value.to_s.should == value
   end
end

Then /the (.*) should not be (.*)/ do |variable, value|
   my_value = @task.instance_variable_get("@#{variable}")
   if value == 'blank'
      my_value.blank?.should == false
   else
      my_value.to_s.should != value
   end
end