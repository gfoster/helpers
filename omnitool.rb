#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'

class Tool
    @@help_text = {}
    @@setupHook = []

    # This will define some sugar to allow us to define new commands on the fly
    # with "command :command_name, :help_text, do ... end syntax

    protected

    Kernel.send :define_method, :command do |command, help_text, &block|
        cmd_name = "cmd_#{command}"
        @@help_text[command.to_s] = help_text
        Tool.send :define_method, command, &block
    end

    Kernel.send :define_method, :setup do |&block|
        @@setupHook << block
    end

    public

    def initialize(options=nil)
        @options = options
        @@setupHook.each { |step| self.instance_eval(&step) }
        return self
    end

    command :help, "Print this list" do
        cmd_list = self.protected_methods
        puts "list of supported commands: "
        help_output = cmd_list.collect do
            |cmd| cmd + "\t\t" + (@@help_text.include?(cmd) ? @@help_text[cmd] : "")
        end
        puts help_output.join("\n")
    end

    cmd_file = "#{ENV['HOME']}/.ot_cmds/" << File.basename($0) << ".cmd"

    if FileTest.exists?(cmd_file)
        load cmd_file
    else
        puts "Could not find a command file for myself in #{cmd_file}"
        exit 1
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

    command = ARGV[0] || "help"
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



