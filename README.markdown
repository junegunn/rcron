# rcron

A simple cron-like scheduler for Ruby.

## Installation
```ruby
gem install rcron
```

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
rcron.start $stderr
```

## Notes
- Minimum interval for each task is one-minute just like cron. So rcron usually sleeps most of the time and wakes up only once a minute. (Except when short timeouts for the tasks are specified. In that case, rcron wakes up more frequently to check whether the task should be terminated)
- rcron checks to start tasks at the very first second of every minute. e.g. When you first start it at 12:00:45, it will sleep 15 seconds before doing anything.
- Tested on Ruby 1.8.7, Ruby 1.9.2 and JRuby 1.6.4
- 99.67% test coverage. (a false sense of security, though)

## Contributing to rcron
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Junegunn Choi. See LICENSE.txt for
further details.

