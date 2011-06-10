# This defines a setup hook that will be called within the constructor.
# You can use this to setup any ivars and such you might want down the road

# You can have multiple of these

setup do
    puts "in the initialize method"
    @blah = "la dee da"
end

setup do
    puts "still in the constructor"
    puts "@blah = #{@blah}"
end

# and here's our commands.  They will automagically show up in any help listings
# as well
command :foo, "help text for the foo command" do
    puts "in the foo method, @blah = #{@blah}"
    help
end

# and this is how we define options

# This one defines options[:s] and is the "-s" switch

option :s

# This one defines options[:medium] and will show up as "-m" and "--medium"

option :m, :medium # this one will show up as "-m and --medium"

# this one will set the value of options[:long] to "foo" when encountered
# don't use a return, because this is a closure that doesn't expect a return

option :l, :long do
    "foo"
end

