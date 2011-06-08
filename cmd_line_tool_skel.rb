#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'

class Tool
    @@help_text = {}

    def initialize(options)
        @options = options
        return self
    end

    # This will define some sugar to allow us to define new commands on the fly
    # with "command :command_name, :help_text, do ... end syntax

    Kernel.send :define_method, :command do |command, help_text, &block|
        cmd_name = "cmd_#{command}"
        define_method(cmd_name, &block)
        @@help_text[command.to_s] = help_text
    end

    # and here's our commands.  They will automagically show up in any help listings
    # as well

    command :help, "Print this list" do
        cmd_list = self.public_methods.grep(/^cmd_/)
        cmd_list.collect! { |cmd| cmd[4..-1] }
        puts "list of supported commands: "
        help_output = cmd_list.collect { |cmd| cmd + "\t\t" + (@@help_text.include?(cmd) ? @@help_text[cmd] : "") }
        puts help_output.join("\n")
    end

    command :foo, "help text for the foo command" do
        puts "in the #{__method__} method"
    end
end

def main()
    options = {}

    optparse = OptionParser.new do |opts|
        opts.banner = "Usage foo [options] ..."

        options[:user] = nil
        opts.on('-u', '--user USERNAME', 'username (optional)') do |user|
            options[:username] = user
        end

        options[:password] = nil
        opts.on('-p', '--password PASSWORD', 'password (optional)') do |password|
            options[:password] = password
        end

        opts.on('-h', '--help', 'Display this screen') do
            puts opts
            exit
        end
    end

    optparse.parse!

    command = "cmd_" + (ARGV[0].nil? ? "help" : ARGV[0])
    subcommand = ARGV[1..-1]

    tool = Tool.new(options)
    if tool.respond_to?(command)
        tool.send(command, subcommand)
    else
        puts "Unknown command: #{ARGV[0]}, try 'help'"
        exit 1
    end
end

if $0 == __FILE__
    main
end



