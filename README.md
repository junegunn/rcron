# rcron

A simple cron-like scheduler for Ruby.

## Installation

Add this line to your application's Gemfile:

    gem 'rcron'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rcron

## Cron format
As of now, most of the expressions except for ? and W are supported.

http://en.wikipedia.org/wiki/Cron#Format

## Examples

### Basic
```ruby
require 'rcron'
rcron = RCron.new

# Enqueue a task running every two minutes
rcron.enq('task #1', '*/2 * * * *') do |task|
  # Task logic
  # ...
end

# You can `enq' any number of tasks before starting rcron

rcron.start
```

### One-time only task
```ruby
rcron = RCron.new
# will run once at 8pm next second friday
rcron.enq('task #2', '0 8 * * fri#2') do |task|
  # Removes the task from the queue
  task.deq

  # Task logic
  # ...
end
rcron.start
```

### Options
```ruby
rcron = RCron.new

# :exclusive - Only one instance of this task will run simultaneously.
# :timeout   - Task will be terminated if it takes longer than the specified seconds.
rcron.enq('Every ten-minutes during summer', 
        '*/10 * * jun-aug *', 
        :exclusive => true, 
        :timeout => 1200) do |task|
  # Task logic
  # ...
end

# log to $stderr instead of default $stdout
rcron.start Logger.new($stderr)
```

## Notes
- Minimum interval for each task is one-minute just like cron. So rcron usually sleeps most of the time and wakes up only once a minute. (Except when short timeouts for the tasks are specified. In that case, rcron wakes up more frequently to check whether the task should be terminated)
- rcron checks to start tasks at the very first second of every minute. e.g. When you first start it at 12:00:45, it will sleep 15 seconds before doing anything.
- Tested on Ruby 1.8.7, Ruby 1.9.3 and JRuby 1.6.7.2

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

Copyright (c) 2011 Junegunn Choi. See LICENSE.txt for
further details.

