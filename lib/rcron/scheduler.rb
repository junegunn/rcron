require 'thread'

class RCron
  def initialize
    @tasks = []
    @mutex = Mutex.new
    @sleeping = false
    @log_mutex = Mutex.new
    @log_ostream = $stdout
  end

  # Enqueues a task to be run
  # @param [String] name Name of the task
  # @param [String] schedule Cron-format schedule string
  # @param [Hash] options Additional options for the task. :exclusive and :timeout.
  # @return [RCron::Task]
  def enq name, schedule, options = {}, &block
    raise ArgumentError.new("Block not given") unless block_given?

    new_task = nil
    @mutex.synchronize do
      @tasks << new_task = Task.send(:new,
                      self, name, schedule,
                      options[:exclusive], options[:timeout],
                      &block)
    end
    return new_task
  end
  alias q enq

  # Starts the scheduler
  # @param log_output_stream Stream to output scheduler log. Should implement puts method.
  def start log_output_stream = $stdout
    raise ArgumentError.new(
        "Log output stream should implement puts method") unless
            log_output_stream.respond_to? :puts

    @log_ostream = log_output_stream
    @thread = Thread.current

    log "rcron started"

    now = Time.now
    while @tasks.length > 0
      # At every minute
      next_tick = Time.at( (now + 60 - now.sec).to_i )
      interval = @tasks.select(&:running?).map(&:timeout).compact.min
      begin
        @mutex.synchronize { @sleeping = true }
        #puts [ next_tick - now, interval ].compact.min
        sleep [ next_tick - now, interval ].compact.min
        @mutex.synchronize { @sleeping = false }
      rescue RCron::Alarm => e
        # puts 'woke up'
      end

      # Join completed threads
      @tasks.select(&:running?).each do |t|
        t.send :join
      end

      # Removed dequeued tasks
      @tasks.reject { |e| e.running? || e.queued? }.each do |t|
        @mutex.synchronize { @tasks.delete t }
      end

      # Start new task threads if it's time
      now = Time.now
      @tasks.select { |e| e.queued? && e.scheduled?(now) }.each do |t|
        if t.running? && t.exclusive?
          log "[#{t.name}] already running exclusively"
          next
        end

        log "[#{t.name}] started"
        t.send :start, now
      end if now >= next_tick
    end#while
    log "rcron completed"
  end#start

  # Crontab-like tasklist
  # @return [String]
  def tab
    @tasks.map { |t| "#{t.schedule_expression} #{t.name}" }.join($/)
  end

private
  def wake_up
    @mutex.synchronize {
      if @sleeping
        @sleeping = false
        @thread.raise(RCron::Alarm.new)
      end
    }
  end

  def log msg
    @log_mutex.synchronize do
      @log_ostream.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{msg}"
    end
  end
end#RCron
