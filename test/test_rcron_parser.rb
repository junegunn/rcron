$LOAD_PATH << "."
require 'helper'

class TestRcronParser < Test::Unit::TestCase
  def test_invalid_format
    assert_raise(ArgumentError) { RCron::Parser.parse('* * * *') }
    assert_raise(ArgumentError) { RCron::Parser.parse('* * * * * * *') }
    assert_raise(ArgumentError) { RCron::Parser.parse('a b c d e') }
  end

  def test_asterisk
    RCron::Parser.parse('* * * * *').each do |k, v|
      assert_nil v
    end

    RCron::Parser.parse('* * * * * *').each do |k, v|
      assert_nil v
    end
  end

  def test_single_number
    RCron::Parser.parse('1 1 1 1 1 2000').each do |k, v|
      assert_equal(
        case k
        when :minutes
          {1 => true}
        when :hours
          {1 => true}
        when :days
          {1 => true}
        when :months
          {1 => true}
        when :weekdays
          {1 => true}
        when :years
          {2000 => true}
        end, v)
    end

    # Invalid range
    assert_raise(ArgumentError) { RCron::Parser.parse('61 * * * *') }
    assert_raise(ArgumentError) { RCron::Parser.parse('* 25 * * *') }
    assert_raise(ArgumentError) { RCron::Parser.parse('* * 50 * *') }
    assert_raise(ArgumentError) { RCron::Parser.parse('* * * 14 *') }
    assert_raise(ArgumentError) { RCron::Parser.parse('* * * * 10000') }
  end

  def test_range
    assert_equal({10 => true, 11 => true, 12 => true, 59 => true, 0 => true, 1 => true, 2 => true}, 
        RCron::Parser.parse('10-12,59-2 * * * *')[:minutes])
  end

  def test_dividend
    assert_equal({3 => true, 6 => true, 9 => true, 12 =>true}, 
                 RCron::Parser.parse('* * * */3 *')[:months])
    assert_equal({0 => true, 23 => true, 24 => true, 46 => true, 48 => true}, 
                 RCron::Parser.parse('*/23,*/24 * * * *')[:minutes])
  end

  def test_months
    assert_equal({1 => true, 2 => true, 3 => true, 6 => true, 7 => true, 8 => true}, 
                 RCron::Parser.parse('* * * jan-MAR,Jun-Aug *')[:months])
    assert_equal((1..12).to_a.sort,
                 RCron::Parser.parse('* * * jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec *')[:months].keys.sort)
  end

  def test_weekdays
    assert_equal([0,1,2,3,4,5,6],
                 RCron::Parser.parse('* * * * sun,mon,tue,wed,thu,fri,sat,sun')[:weekdays].keys.sort)
    assert_equal([0,1,2,3,4,5,6],
                 RCron::Parser.parse('* * * * SUN,MON,TUE,WED,THU,FRI,SAT,SUN')[:weekdays].keys.sort)
    assert_equal([0,1,2,3,4,6],
                 RCron::Parser.parse('* * * * WED-THU,SAT-TUE')[:weekdays].keys.sort)
  end

  def test_nearest_weekday
    # TODO FIXME TODO
    assert_raise(NotImplementedError) { RCron::Parser.parse('* * W * *') }
  end

  def test_last_day
    assert_equal([-1, 31], RCron::Parser.parse('* * L,31 * *')[:days].keys.sort)
  end

  def test_year
    assert_equal([2010,2011,2012,2020], RCron::Parser.parse('* * L,31 * * 2010-2012,2020')[:years].keys.sort)
  end
end
