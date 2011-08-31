$LOAD_PATH << "."
require 'helper'

class TestRcron < Test::Unit::TestCase
  class LogStream
    def initialize
      @lines = []
    end

    def puts str
      $stdout.puts str
      @lines << str
    end

    def count pat
      @lines.select { |e| e =~ pat }.count
    end
  end

  def test_empty_q
    rcron = RCron.new
    log = LogStream.new
    rcron.start(log)

    assert_equal 1, log.count(/completed/)
  end

  def test_blockless
    rcron = RCron.new
    assert_raise(ArgumentError) { rcron.q('test task 1', "* * * * *") }
  end

  def test_invalid_schedule
    rcron = RCron.new
    assert_raise(ArgumentError) { rcron.q('test task 1', "* *") { |task| } }
  end

  def test_basic_task_dq
    puts 'basic task eq'
    counter = 0
    rcron = RCron.new
    rcron.q('basic task 1 - auto dq', "* * * * *") do |task|
      counter += 1
      sleep 1
      task.dq
    end

    @task = rcron.q('basic task 2 - auto dq', "* * * * *") do
      counter += 2
      sleep 3
      @task.dq
    end

    st = Time.now
    rcron.start
    assert_equal 3, counter
    assert Time.now - st > 3
  end

  def test_basic_task
    puts 'basic task'
    counter = 0
    rcron = RCron.new
    rcron.q('basic task', "* * * * *") do |task|
      task.dq if counter >= 2

      counter += 1
      sleep 60 + 10
    end

    st = Time.now
    rcron.start
    assert_equal 3, counter
    assert Time.now - st > 3 * 60
  end

  def test_dq
    counter = 0
    rcron = RCron.new
    task = rcron.q('never', "* * * * *") do |task|
      counter += 1
    end

    task.dq
    rcron.start
    assert_equal 0, counter
  end

  def test_timeout
    puts 'timeout'
    counter = 0
    rcron = RCron.new
    rcron.q('timeout', '*/5 * * * *', :timeout => 10) do |task|
      task.dq # no more
      loop do
        counter += 1
        sleep 1
      end
    end

    assert_raise(ArgumentError) { rcron.q('inv timeout', '* * * * *', :timeout => -3) { } }
    assert_raise(ArgumentError) { rcron.q('inv timeout', '* * * * *', :timeout => 'not too long') { } }

    rcron.start
    assert_equal 10, counter
  end

  def test_non_exclusive
    puts 'non exclusive'
    counter = 0
    log = LogStream.new
    rcron = RCron.new
    truth = true
    rcron.q('non-exclusive', '* * * * *') do |task|
      counter += 1
      truth &&= counter == task.threads.length
      puts task.threads.length
      sleep 60 * 2 + 30
      task.dq
    end
    rcron.start(log)

    assert truth
    assert_equal 3, counter
  end

  def test_exclusive
    puts 'exclusive'
    counter = 0
    log = LogStream.new
    rcron = RCron.new
    rcron.q('exclusive', '* * * * *', :exclusive => true) do |task|
      counter += 1
      sleep 60 * 2 + 10
      task.dq
    end

    assert_raise(ArgumentError) {
      rcron.q('inv exclusive', '* * * * *', :exclusive => 'i guess') { }
    }
    rcron.start(log)

    assert_equal 1, counter
    assert log.count(/exclusively/i) > 0
  end

  def test_invalid_output_stream
    rcron = RCron.new
    assert_raise(ArgumentError) { rcron.start("invalid") }
  end

  def test_tab
    rcron = RCron.new
    rcron.q('task number 1', '* * * * *') {}
    rcron.q('task number 2', '*/2 * * * *') {}
    rcron.q('task number 3', '*/3 * * * *') {}

    assert_equal ["* * * * * task number 1", 
                  "*/2 * * * * task number 2", 
                  "*/3 * * * * task number 3"].join($/), rcron.tab
  end

  def test_exception
    log = LogStream.new
    rcron = RCron.new
    rcron.q('Exceptional', '* * * * *') do |task|
      task.dq
      sleep 80
      raise Exception.new("this-error")
    end
    rcron.start(log)

    assert_equal 1, log.count(/this-error/)
  end
end

