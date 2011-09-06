require 'date'
require 'time'

class RCron
  class Task
    # RCron scheduler for this task
    attr_reader :rcron

    # Name of the task
    attr_reader :name
    
    # Cron schedule expression
    attr_reader :schedule_expression
    
    # Parsed cron schedule
    attr_reader :schedule
    
    # Timeout for the task
    attr_reader :timeout
    
    # Threads running this task
    def threads
      @mutex.synchronize { return @threads.dup }
    end

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
      @mutex.synchronize {
        return @threads.empty? == false
      }
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
    def deq
      @queued = false
      nil
    end
    alias dq deq

    # Returns if the task is supposed to be triggered at the given moment.
    # @param [Time] at
    # @return [Boolean]
    def scheduled? at
      if @previous_start.nil? || (at - at.sec).to_i > (@previous_start - @previous_start.sec).to_i
        s, m, h, day, mon, year, wd = at.to_a

        td = Date.new(year, mon, day) # at.to_date # Doesn't work with current JRuby
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
    def start now
      @previous_start = now
      @mutex.synchronize do
        @threads << TaskThread.new(self, now)
      end
    end

    def join
      @threads.dup.each do |thr|
        if thr.alive?
          # Timeout!
          if @timeout && thr.elapsed > @timeout
            thr.kill!
            @mutex.synchronize { @threads.delete thr }
          end
        else
          # Finished already
          thr.cleanup
          @mutex.synchronize { @threads.delete thr }
        end
      end
    end

  private
    private_class_method :new

    def initialize scheduler, name, schedule, exclusive, timeout, &block
      if timeout && (timeout.is_a?(Numeric) == false || timeout < 1)
        raise ArgumentError.new("Invalid timeout: #{timeout} (sec)") 
      end
      unless [true, false, nil].include? exclusive
        raise ArgumentError.new("exclusive option must be true or false") 
      end

      @rcron     = scheduler
      @name      = name
      @schedule  = Parser.parse schedule
      @schedule_expression    = schedule
      @exclusive = exclusive == true
      @timeout   = timeout
      @block     = block
      @queued    = true
      @threads   = []
      @mutex     = Mutex.new

      @previous_start = nil
    end

    class TaskThread
      attr_reader :started_at, :ended_at
      attr_reader :exception

      def initialize task, started_at
        @started_at = started_at
        @thread = Thread.new {
          begin
            task.run
            @ended_at = Time.now

            task.rcron.send :log, "[#{task.name}] completed (#{'%.2f' % elapsed}s)"
          rescue Exception => e
            @ended_at = Time.now

            task.rcron.send :log, "[#{task.name}] terminated: #{[e, e.backtrace].join($/)}"
            # Ignore exception?
          end
          task.rcron.send :wake_up
        }
      end

      def cleanup
        @thread.join
      end

      def elapsed
        (@ended_at || Time.now) - @started_at
      end

      def alive?
        @thread.alive?
      end

      def kill!
        @thread.raise RCron::Timeout.new("Timeout: task terminated by rcron", @started_at, Time.now)
        cleanup
      end
    end
  end#Task
end#RCron
