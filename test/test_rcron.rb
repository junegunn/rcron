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
    counter = 0
    rcron = RCron.new
    rcron.q('basic task 1 - auto dq', "* * * * *") do |task|
      counter += 1
      sleep 1
      task.dq
    end

    rcron.q('basic task 2 - auto dq', "* * * * *") do |task|
      counter += 2
      sleep 3
      task.dq
    end

    st = Time.now
    rcron.start
    assert_equal 3, counter
    assert Time.now - st > 3
  end

  def test_basic_task
    counter = 0
    rcron = RCron.new
    rcron.q('basic task', "* * * * *") do |task|
      counter += 1
      sleep 60 + 10

      task.dq if counter >= 2
    end

    st = Time.now
    rcron.start
    assert_equal 2, counter
    assert Time.now - st > 2 * 60
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
    counter = 0
    rcron = RCron.new
    rcron.q('timeout', '* * * * *', :timeout => 10) do |task|
      task.dq # no more
      loop do
        counter += 1
        sleep 1
      end
    end
    rcron.start
    assert_equal 10, counter
  end

  def test_non_exclusive
    counter = 0
    log = LogStream.new
    rcron = RCron.new
    rcron.q('non-exclusive', '* * * * *') do |task|
      counter += 1
      sleep 60 * 2 + 10
      task.dq
    end
    rcron.start(log)

    assert_equal 3, counter
  end

  def test_exclusive
    counter = 0
    log = LogStream.new
    rcron = RCron.new
    rcron.q('exclusive', '* * * * *', :exclusive => true) do |task|
      counter += 1
      sleep 60 * 2 + 10
      task.dq
    end
    rcron.start(log)

    assert_equal 1, counter
    assert log.count(/exclusively/i) > 0
  end
end

