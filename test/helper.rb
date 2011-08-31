require 'rubygems'
require 'bundler'
require 'simplecov'
SimpleCov.start

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rcron'

class Test::Unit::TestCase
end

# Overrides timings constructs to boost up the test speed
# - This might break some test results
class Time
  class << self
    alias org_now now
  end
  def self.now
    @@first_call ||= Time.org_now
    return @@first_call + (Time.org_now - @@first_call) * 20
  end
end

def sleep n
  Kernel.sleep n * 0.05
end

Thread.abort_on_exception = false # FIXME: Without this, test fails.

