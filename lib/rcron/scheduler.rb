require 'thread'

class RCron
  # Thread running this scheduler
  # @return [Thread]
  attr_reader :thread

  def initialize
    @tasks = []
    @log_mutex = Mutex.new
    @log_ostream = $stdout
  end

  # Enqueues a task to be run
  # @param [String] name Name of the task
  # @param [String] schedule Cron-format schedule string
  # @param [Hash] options Additional options for the task. :exclusive and :timeout.
  # @return [RCron::Task]
  def q name, schedule, options = {}, &block
    raise ArgumentError.new("Block not given") unless block_given?
    schedule = Parser.parse schedule

    @tasks << task = Task.send(:new,
                      self, name, schedule,
                      options[:exclusive], options[:timeout],
                      &block)
    return task
  end

  # Starts the scheduler
  # @param log_output_stream Stream to output scheduler log. Should implement puts method.
  def start log_output_stream = $stdout
    @log_ostream = log_output_stream
    @thread = Thread.current

    log "rcron started"

    interval = @tasks.map(&:timeout).compact.min
    while @tasks.length > 0
      # At every minute
      next_tick = (now = Time.now) + 60 - now.sec
      begin
        sleep [ next_tick - now, interval ].compact.min
      rescue RCron::Alarm => e
        # Wake up..
      end

      # Join completed threads
      @tasks.select(&:running?).each do |t|
        t.send :join
      end

      # Removed dequeued tasks
      @tasks.dup.reject(&:running?).reject(&:queued?).each do |t|
        @tasks.delete t
      end

      # Start new task threads if it's time
      @tasks.select(&:queued?).select(&:now?).each do |t|
        if t.running? && t.exclusive?
          log "[#{t.name}] already running exclusively"
          next
        end

        log "[#{t.name}] started"
        t.send :start
      end if Time.now > next_tick
    end
    log "rcron completed"
  end

private
  def log msg
    @log_mutex.synchronize do
      @log_ostream.puts "[#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}] #{msg}"
    end
  end
end#RCron
