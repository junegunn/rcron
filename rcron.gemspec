# -*- encoding: utf-8 -*-
require File.expand_path('../lib/rcron/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Junegunn Choi"]
  gem.email         = ["junegunn.c@gmail.com"]
  gem.description   = %q{A simple cron-like scheduler}
  gem.summary       = %q{A simple cron-like scheduler for Ruby}
  gem.homepage      = "https://github.com/junegunn/rcron"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "rcron"
  gem.require_paths = ["lib"]
  gem.version       = RCron::VERSION
  gem.add_development_dependency "simplecov"
end
