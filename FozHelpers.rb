# This is a collection of useful hacks, monkeypatches, class extensions, overrides, etc.

require 'rubygems'
require 'enumerator'
require 'rss'
require 'open-uri'
require 'net/http'
require 'etc'
require 'fileutils'
require 'term/ansicolor'

####
#### Useful constants
####

EMAIL_REGEXP =  Regexp.new(/[^ @]+@[^ @]+\.[^ @]+/)

#####
##### Generic monkeypatches to extend existing base classes
#####

class String
   # Give us the ability to do things like puts 'foo'.red.bold
   include Term::ANSIColor

   def shift
      return nil if self.empty?
      item=self[0]
      self.sub!(/^./,"")
      return nil if item.nil?
      item.chr
   end

   def unshift(other)
      newself = other.to_s.dup.pop.to_s + self
      self.replace(newself)
   end

   def pop
      return nil if self.empty?
      item=self[-1]
      self.chop!
      return nil if item.nil?
      item.chr
   end

   def push(other)
      newself = self + other.to_s.dup.shift.to_s
      self.replace(newself)
   end

   def rotate_left(n=1)
      n=1 unless n.kind_of? Integer
      n.times do
         char = self.shift
         self.push(char)
      end
      self
   end

   def rotate_right(n=1)
      n=1 unless n.kind_of? Integer
      n.times do
         char = self.pop
         self.unshift(char)
      end
      self
   end

   @@first_word_re = /^(\w+\W*)/
   @@last_word_re  = /(\w+\W*)$/

   def shift_word
      # shifts first word off of self
      # and returns; changes self
      return nil if self.empty?
      self=~@@first_word_re
      newself = $' || ""   # $' is POSTMATCH
      self.replace(newself) unless $`.nil?
      $1.strip
   end

   def acronym(thresh=0)
      self.split.find_all {|w| w.length > thresh }.
      collect {|w| w[0,1].upcase}.join
   end

   def unshift_word(other)
      # Adds provided string to front of self
      newself = other.to_s + " " + self
      self.replace(newself)
   end

   def pop_word
      # pops and returns last word off self
      # changes self
      return nil if self.empty?
      self=~@@last_word_re
      newself=$` || ""  # $` is PREMATCH
      newself.rstrip!
      self.replace(newself) unless $`.nil?
      $1
   end

   def push_word(other)
      # pushes provided string onto end of self
      newself = self + " " + other.to_s
      self.replace(newself)
   end

   def rotate_word_left
      word = self.shift_word
      self.push_word(word)
   end

   def rotate_word_right
      word = self.pop_word
      self.unshift_word(word)
   end

   # Patch the string class to give a rightstr function
   # Call with String.rightstr(length)

   def rightstr(length)
      if length < 0
         raise ArgumentError, "length cannot be a negative value"
      end
      self.reverse[0,length].reverse
   end

   # Create an each_char iterator that will return 'n' characters each yield

   def each_char(n=1)
      if n < 1
         raise ArgumentError, "length must be > 0"
      end

      if block_given?
         split(//).each_slice(n) do |x|
            yield x.join
         end
      else
         results = Array.new
         split(//).each_slice(n) {|x| results.push(x.join)}
         results
      end
   end

   def blank?
      !(self =~ /\S/)
   end

   # add a coerce function to the String class so we can get automatic type conversion for arithmetic
   # which makes stuff like 1 + "2" work without having to cast
   def coerce(other)
      case other
      when Integer
         begin
            return other, Integer(self)
         rescue
            return Float(other), Float(self)
         end
      when Float
         return other, Float(self)
      else
         super
      end
   end
end

class Fixnum
   def odd?
      (self % 2 == 1) ? true : false
   end
end

class Array
   # Snag a random element from an array
   def rand
      self[Kernel::rand(self.size)]
   end

   # Shuffle the array
   def randomize
      sort {|a,b| Kernel::rand <=> 0.5}
   end

   def randomize!
      replace randomize
   end
end

class Numeric
   # Time calculations
   #   i.e. Numeric.minutes, etc
   # These are ripped out of ActiveSupport and give us things like 2.hours.since(4.hours.ago) and 5.minutes.from_now

   def seconds
      self
   end

   def minutes
      self * 60
   end
   alias :minute :minutes

   def hours
      self * 60.minutes
   end
   alias :hour :hours

   def days
      self * 24.hours
   end
   alias :day :days

   def weeks
      self * 7.days
   end
   alias :week :weeks

   def ago(time = Time.now)
      time - self
   end
   alias :until :ago

   def since(time = Time.now)
      time + self
   end
   alias :from_now :since
end

class Time
   # Monkeypatch the time class to include other conversions

   def internet_time
      t = self.gmtime + 3600 # Biel, Switzerland
      midnight = Time.gm(t.year, t.month, t.day)
      secs = t - midnight
      beats = (secs/86.4).to_i
   end

   def timestamp
      self.strftime("%D %T")
   end

   def iso8601
      # Generate an ISO-8601 formatted date string in UTC, offsetDays from now yyyy-mm-dd'T'HH:MM:SS.fff'Z'.
      self.w3cdtf[/^.+\.\d+/] + "Z"
   end
end

#####
##### Various helpful classes
#####


### Basic node and linked list class
### LL class implements push, pop, and iterators
### as well as convenience getters for LinkedList#last and #first

class Node
   attr_reader :value, :ptr

   def initialize(value, ptr)
      @value, @ptr = value, ptr
   end
end

class LinkedList
   include Enumerable

   attr_reader :size, :head

   def initialize
      clear
      self
   end

   def clear
      @head, @tail, @size = nil, nil, 0
   end

   def empty?
      head.nil?
   end

   def push(value)
      @head = Node.new(value, head)
      @size += 1
      @last = @head if @last.nil?
      self
   end

   def pop
      return nil if empty?
      @size -= 1
      value = head.value
      @head = head.ptr
      @last = nil if empty?
      value
   end

   def append(value)
      replace reverse.push(value).reverse
   end

   def reverse
      new_list = self.class.new
      self.each { |x| new_list << x }
      new_list
   end

   def reverse!
      replace reverse
   end

   def each
      return nil if empty?

      node = head
      loop do
         yield node.value
         node = node.ptr
         break unless node
      end
   end

   def last
      return nil if empty?
      @last.value
   end

   def first
      return nil if empty?
      @head.value
   end

   def ==(other)
     head == other.head
   end

   def replace(other)
      new_list = self.dup
      clear
      other.reverse.each { |x| push(x) }
      self
   end

   alias_method :<<, :push
   alias_method :unshift, :push
   alias_method :length, :size
   alias_method :shift, :pop
end

class Task < Object

   attr_accessor :name, :status, :percent, :start_time, :end_time

   def initialize(name=nil, *options)
      if options.empty?
         options = {}
      else
         options = options[0]
      end

      @name        = name

      @status      = options[:status]     || 'pending'
      @percent     = options[:percent]    || 0
      @start_time  = options[:start_time] || ''
      @end_time    = options[:end_time]   || ''
   end

   def to_s
      "#{@name}\t#{@status}\t#{@percent}\t#{@start_time}\t#{@end_time}"
   end

   def start
      # Mark the current task as active"
      @status     = 'active'
      @start_time = Time.now.iso8601
      @end_time   = ''
      @percent    = 0
      self
   end

    def finish
       # Mark the task as complete
       @status   = 'complete'
       @percent  = 100
       now = Time.now.iso8601
       if @start_time.blank?
           @start_time = now
       end
       @end_time = now
       return self
    end

   def fail
      # Mark the task as failed
      @status   = 'failed'
      @end_time = Time.now.iso8601
      self
   end

   def clear
      # Clear the task and set it to pending
      @status     = 'pending'
      @percent    = 0
      @start_time = ''
      @end_time   = ''
      self
   end
end

class Tasklist
   protected

   attr_writer :current_task

   public

   attr_accessor :filename

   # getters

   def current_task
      @tasks[@current_task]
   end

   def status
      @status
   end

   # constructors, iterators, etc.

   def initialize(filename=nil)
        @tasks = []
        @current_task = -1
        @filename = filename
        @status = 0
        self
   end

   def each
      @tasks.each { |task| yield task }
   end

   def each_with_index
      @tasks.each_with_index {|task, index| yield [task, index] }
   end

   alias :with_index :each_with_index

   def to_s
      @tasks * "\n"
   end

   # class methods

   def add(task)
      if task.instance_of? String
         t = Task.new(task)
      elsif task.instance_of? Task
         t = task
      else
         raise TypeError, "Can only add tasks to tasklist"
      end

      @tasks << t

      self
   end

   def delete(task_number=@current_task)
      if @tasks.empty?
         # Should throw an exception here
         raise ArgumentError, "attempt to delete from an empty tasklist"
      end

      if task_number > @tasks.length - 1 or task_number < 0
         # throw an exception
         raise ArgumentError, "attempt to delete an invalid task"
      end

      if task_number == @current_task
         self.next
         @current_task -= 1
      end

      @tasks.delete_at(task_number)
      self.save

      @status = (@current_task + 1.0 / @tasks.length * 100).to_i

      self
   end

   def next
      if @current_task != -1
         @tasks[@current_task].finish
         @status = (@current_task + 1.0 / @tasks.length * 100).to_i
      end

      @current_task += 1

      if @current_task < @tasks.length
         @tasks[@current_task].start
      else
         @current_task = -1
      end

      self.save
      self
   end

   def abort
      # mark the current task as failed and reset the task pointer
      if @current_task == -1
         self
      end

      @tasks[@current_task].fail
      @current_task = -1
      self.save
      self
   end

   def finish
      # mark all outstanding jobs as finished by incrementing through the task list
      true while self.next

      self.save
      self
   end

   def start
      # Reset all the tasks in the queue to pending and move the task pointer to the beginning

      @tasks.collect! {|x| x.clear}

      @current_task = 0
      @status = 0
      @tasks[@current_task].start

      self.save
      self
   end

   def clear
      @tasks = []
      @current_task = -1
      self
   end

   def save(filename=nil)
      # Persist ourself to a filename

      filename = @filename if filename.nil?

      if not filename.nil?
         marshal = @current_task.to_s + "\n"
         marshal << self.to_s

         File.open(filename, "w") do |fd|
            fd.write(marshal)
         end
      end
      self
   end

   def load(filename=nil)
      filename = @filename if filename.nil?

      if not filename.nil?
         rep = self.class.new
         File.open(filename, "r") do |fd|
            rep.current_task = fd.gets.to_i
            while line = fd.gets
               line.chomp!
               (name, status, percent, start_time, end_time) = line.split("\t")
               rep.add(Task.new(name, :status=>status, :percent=>percent, :start_time=>start_time, :end_time=>end_time))
            end
         end
         rep
      end
   end

   def load!(filename=nil)
      filename = @filename if filename.nil?

      if not filename.nil?
         File.open(filename, "r") do |fd|
            clear
            @current_task = fd.gets.to_i
            while line = fd.gets
               line.chomp!
               (name, status, percent, start_time, end_time) = line.split("\t")
               self.add(Task.new(name, :status=>status, :percent=>percent, :start_time=>start_time, :end_time=>end_time))
            end
         end
         self
      end
   end
end

#####
##### Generic (non class) methods
#####

module Helpers
   def Helpers.fetch_remote_file(url, *options)
      if options.empty?
         options = {}
      else
         options = options[0]
      end

      local_file   = options[:local_file] || nil
      permissions = options[:permissions] || nil
      owner       = options[:owner] || nil
      group       = options[:group] || nil

      # Fetch a remote file and either write it to a local file or return it

      response = URI::parse(url)
      ifd = response.open()

      if local_file.nil?
         filecontents = ifd.read()
         ifd.close()
         filecontents
      else
         ofd = open(local_file, "w")
         bytes = File::copy_stream(ifd, ofd)
         ifd.close()
         ofd.chmod(permissions)
         ofd.close()
         Helpers.chown(local_file, owner, group)
      end
      bytes
   end

   def Helpers.get_ec2_public_hostname
      Helpers.fetch_remote_file("http://169.254.169.254/2009-04-04/meta-data/public-hostname")
   end

   def Helpers.write_file(filename, contents, *options)
      if options.empty?
         options = {}
      else
         options = options[0]
      end

      owner       = options[:owner] || nil
      group       = options[:group] || nil
      permissions = options[:permissions] || nil

      close = false

      if filename.instance_of?(String)
         # we got passed a filename to create
         fd = File.new(filename, "w")
         # if we create the file, we close it, otherwise we leave it open
         close = true
      elsif filename.instance_of?(File)
         # we got passed an open file descriptor
         fd = filename
      else
         raise TypeError, "filename must be a file object or a filename (string)"
      end

      fd << contents

      if permissions
         fd.chmod(permissions)
      end

      unless owner.nil? and group.nil?
         Helpers.chown(fd, owner, group)
      end

      if close
         fd.close()
      end
      return true
   end

   def Helpers.chown(filename, owner, group)
      uid = Etc.getpwnam(owner).uid unless owner.nil?
      gid = Etc.getgrnam(group).gid unless group.nil?

      if filename.instance_of? String
         FileUtils.chown(uid, gid, filename)
      elsif filename.instance_of? File
         filename.chown(uid, gid)
      else
         raise TypeError, "invalid filetype (must be open fd or string)"
      end
      return true
   end

   def Helpers.run_cmd(cmd)
      results = %x[cmd]
      $?
   end

   def Helpers.get_progress_log_name
      me = File::basename($0)[/^.*?(?=\.template)/]
      "/opt/nodeagent/handlers/state/#{me}.status"
   end

   def Helpers.add_user(username, *options)
      if options.empty?
         options = {}
      else
         options = options[0]
      end

      shell       = options[:shell] || nil
      home        = options[:home] || nil
      create_home = options[:create_home] || false

      cmd = "useradd "
      cmd += "-s #{shell} " unless shell.nil?
      cmd += "-d #{homeDir} " unless home.nil?
      cmd += (create_home) ? "-m " : "-M "
      cmd += username

      Helpers.run_cmd(cmd)
   end

   def Helpers.install_packages(packages)
      if packages.instance_of? String
         packages = [packages]

      for pkg in packages
          rc = Helpers.run_cmd("! /usr/bin/yum install -y --nogpgcheck %s | egrep '^No package .+ available\.' 2>&1 >/dev/null " % (pkg))
          if rc
             return rc
          end
       end
       true
    end
   end
end
