$LOAD_PATH.unshift File.dirname(__FILE__)
require 'helper'

class TestRcronTask < Test::Unit::TestCase
  def test_name
    rcron = RCron.new
    name = nil

    task = rcron.q('my name', '* * * * *') { |t|
      name = t.name
      t.dq
    }
    assert_equal 'my name', task.name
    rcron.start
    assert_equal 'my name', name
  end

  def test_schedule
    rcron = RCron.new
    schedule = '* * * * *'
    task = rcron.q('test_schedule', schedule) { }
    assert_equal RCron::Parser.parse(schedule), task.schedule
  end
  
  def test_rcron
    rcron = RCron.new
    schedule = '* * * * *'
    task = rcron.q('test_rcron', schedule) { }
    assert_equal rcron, task.rcron
  end

  def test_timeout
    rcron = RCron.new
    task = rcron.q('test_timeout', '* * * * *', :timeout => 100) { }
    assert_equal 100, task.timeout
  end

  def test_exclusive
    rcron = RCron.new
    task = rcron.q('test_exclusive', '* * * * *', :exclusive => true) { }
    assert_equal true, task.exclusive?
    task = rcron.q('test_exclusive', '* * * * *', :exclusive => false) { }
    assert_equal false, task.exclusive?
    task = rcron.q('test_exclusive', '* * * * *') { }
    assert_equal false, task.exclusive?
  end

  def test_running
    rcron = RCron.new
    running = nil
    task = rcron.q('test_running', '* * * * *') { |t|
      running = t.running?
      t.dq
    }
    rcron.start
    assert_equal false, task.running?
    assert_equal true, running
  end

  def test_queued
    rcron = RCron.new
    task = rcron.q('test_queued', '* * * * *') { }
    assert_equal true, task.queued?
    task.dq
    assert_equal false, task.queued?
  end

  def test_threads
    rcron = RCron.new
    num_threads = nil
    task = rcron.q('test_threads', '* * * * *') { |t|
      p t.threads
      num_threads = t.threads.length
      sleep 60 + 10
      t.dq
    }
    assert_equal 0, task.threads.length
    rcron.start
    assert_equal 2, num_threads
    assert_equal 0, task.threads.length
  end

  def test_now
    now = Time.parse('2011-08-27 16:16:16')
    rcron = RCron.new
    {
      '* * * * *' => true,
      '0 * * * *' => false,
      '16 * * * *' => true,
      '*/2 * * * *' => true,
      '10-17 * * * *' => true,
      '*/3 * * * *' => false,
      '17-15 * * * *' => false,

      '* 16 * * *' => true,
      '* */2 * * *' => true,
      '* */4 * * *' => true,
      '* 10-17 * * *' => true,
      '* */3 * * *' => false,
      '* 17-15 * * *' => false,

      '* * 27 * *' => true,
      '* * */3 * *' => true,
      '* * */9 * *' => true,
      '* * 20-29 * *' => true,
      '* * 20-22,27,*/4 * *' => true,
      '* * L * *' => false,
      '* * 28 * *' => false,

      '* * * 8 *' => true,
      '* * * */1 *' => true,
      '* * * */2 *' => true,
      '* * * */4 *' => true,
      '* * * */8 *' => true,
      '* * * Aug *' => true,
      '* * * AuG *' => true,
      '* * * 5,7,8 *' => true,
      '* * * 5-9 *' => true,
      '* * * 12-9 *' => true,
      '* * * may-sep *' => true,
      '* * * nov-sep *' => true,
      '* * * jan,dec,aug *' => true,
      '* * * sep *' => false,
      '* * * 9-10 *' => false,
      '* * * */7 *' => false,

      '* * * * sat' => true,
      '* * * * fri-sun' => true,
      '* * * * mon,tue,sat' => true,
      '* * * * 6' => true,
      '* * * * 5-6' => true,
      '* * * * 5-0' => true,
      '* * * * 1,6' => true,
      '* * * * */1' => true,
      '* * * * */2' => true,
      '* * * * */3' => true,
      '* * * * */6' => true,
      '* * * * tue' => false,
      '* * * * fri' => false,
      '* * * * sun-fri' => false,
      '* * * * 0-5' => false,

      '* * * * sat#1' => false,
      '* * * * sat#2' => false,
      '* * * * sat#3' => false,
      '* * * * sat#4' => true,
      '* * * * sat#5' => false,
      '* * * * 6#1' => false,
      '* * * * 6#2' => false,
      '* * * * 6#3' => false,
      '* * * * 6#4' => true,
      '* * * * 6#5' => false,

      '* * * * * 2011' => true,
      '* * * * * */2011' => true,
      '* * * * * 2010-2012' => true,
      '* * * * * 2010' => false,

      '16 16 27 8 6 2010' => false,
      '16 16 27 8 6 2011' => true,
      '16 16 27 8 sat 2011' => true,
      '16 16 27 aug sat 2010-2012' => true,
      '16 16 27 aug sun 2010-2012' => false,
      '*/8 16 27 aug 5-6 2010-2012' => true,
      '17 16 27 aug sat 2010-2012' => false,
      '16 17 27 aug * 2010-2012' => false,
      '16 16 L aug * 2010-2012' => false
    }.each do |sch, ass|
      task = rcron.q('test_now', sch) { }
      puts sch
      assert_equal ass, task.scheduled?(now)
    end
  end
end

