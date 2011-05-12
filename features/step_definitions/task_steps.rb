require 'FozHelpers'

Given /^I have a task$/ do
   @task = Task.new
end

When /I have a (\w+) task$/ do | state |
   case state
   when /pending/
   when /started/
      @task.start
   when /finished/
      @task.finish
   when /failed/
      @task.fail
   when /cleared/
      @task.clear
   else
       raise "Invalid starting condition #{action} requested"
   end
end

When /I attempt to (\w*) it$/ do | action |
    case action
    when /^start$/
        @task.start
    when /^finish$/
        @task.finish
    when /^clear$/
        @task.clear
    when /^fail$/
        @task.fail
    else
        raise "Invalid action #{action} attempted"
    end

end

Then /the status should be (\w*)$/ do | status |
    @task.status.should == status
end

Then /it should be (\w*) % complete$/ do | percent_complete |
    unless percent_complete.blank?
        @task.percent.should == percent_complete.to_i
    end
end

Then /^the start time should be (blank|not_blank)$/ do | start_time |
    if start_time == "blank"
        @task.start_time.blank?.should == true
    else
        @task.start_time.blank?.should == false
    end
end

Then /^the end time should be (\w*)$/ do | end_time |
end



