class RCron
  # Timeout exception
  class Timeout < Exception
    attr_reader :started_at
    attr_reader :terminated_at

    def initialize(msg, started_at, terminated_at)
      super(msg)
      @started_at    = started_at
      @terminated_at = terminated_at
    end
  end#Timeout
end#RCron

