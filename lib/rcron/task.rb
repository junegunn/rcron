require 'date'
require 'time'

class RCron
  class Task
    # RCron scheduler for this task
    attr_reader :rcron

    # Name of the task
    attr_reader :name
    
    # Parsed cron schedule
    attr_reader :schedule
    
    # Timeout for the task
    attr_reader :timeout
    
    # Threads running this task
    attr_reader :threads

    # Executes the task manually
    def run
      if @block.arity >= 1
        @block.call self
      else
        @block.call
      end
    end

    # Returns if the task is being executed by one or more threads
    # @return [Boolean]
    def running?
      @threads.empty? == false
    end

    # Returns whether if the same task should not run simultaneously
    # @return [Boolean]
    def exclusive?
      @exclusive
    end

    # Returns if the task is queued to the scheduler
    # @return [Boolean]
    def queued?
      @queued
    end

    # Removes the task from the scheduler
    def dq
      @queued = false
      nil
    end

    # Returns if the task should be triggered at the moment.
    # @param [Time] now
    # @return [Boolean]
    def now? now = Time.now
      if @previous_start.nil? || (now - now.sec).to_i > (@previous_start - @previous_start.sec).to_i
        s, m, h, day, mon, year, wd = now.to_a

        td = Date.new(year, mon, day) # now.to_date # Doesn't work with current JRuby
        wom = ((td - td.day + 1).wday + td.day - 1) / 7 + 1
        last_day = (td + 1).month > td.month

        (@schedule[:years].nil?    || @schedule[:years].has_key?(year)) &&
        (@schedule[:months].nil?   || @schedule[:months].has_key?(mon)) &&
        (@schedule[:weekdays].nil? || [true, wom].include?(@schedule[:weekdays][wd])) &&
        (@schedule[:days].nil?     || @schedule[:days].has_key?(day) || (last_day && @schedule[:days].has_key?(-1)) ) &&
        (@schedule[:hours].nil?    || @schedule[:hours].has_key?(h)) &&
        (@schedule[:minutes].nil?  || @schedule[:minutes].has_key?(m))
      else
        false
      end
    end

  private
    def start
      @previous_start = Time.now
      @threads << TaskThread.new(self)
    end

    def join
      @threads.dup.each do |thr|
        if thr.alive?
          # Timeout!
          if thr.elapsed && @timeout && thr.elapsed > @timeout
            thr.kill!
            @threads.delete thr
          end
        else
          # Finished already
          thr.cleanup
          @threads.delete thr
        end
      end
    end

  private
    private_class_method :new

    def initialize scheduler, name, schedule, exclusive, timeout, &block
      @rcron     = scheduler
      @name      = name
      @schedule  = schedule
      @exclusive = exclusive || false
      @timeout   = timeout
      @block     = block
      @queued    = true
      @threads   = []

      @previous_start = nil
    end

    class TaskThread
      attr_reader :started_at, :ended_at
      attr_reader :exception

      def initialize task
        @started_at = Time.now
        @thread = Thread.new {
          begin
            task.run
            task.rcron.send :log, "[#{task.name}] completed"
          rescue Exception => e
            task.rcron.send :log, "[#{task.name}] terminated: #{e}#{$/ + caller.join($/)}"
            # Ignore exception?
          ensure
            @ended_at = Time.now
            task.rcron.thread.raise(RCron::Alarm.new)
          end
        }
      end

      def cleanup
        begin
          @thread.join
        rescue RCron::Alarm
        end
      end

      def elapsed
        @thread.alive? ? (Time.now - @started_at) : nil
      end

      def alive?
        @thread.alive?
      end

      def kill!
        @thread.raise Exception.new("Timeout")
        begin
          @thread.join
        rescue RCron::Alarm
        end
      end
    end
  end#Task
end#RCron
