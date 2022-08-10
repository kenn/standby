# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'standby/version'

Gem::Specification.new do |gem|
  gem.name          = 'standby'
  gem.version       = Standby::VERSION
  gem.authors       = ['Kenn Ejima']
  gem.email         = ['kenn.ejima@gmail.com']
  gem.description   = %q{Read from stand-by databases for ActiveRecord}
  gem.summary       = %q{Read from stand-by databases for ActiveRecord}
  gem.homepage      = 'https://github.com/kenn/standby'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^exe/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
  gem.required_ruby_version = '>= 2.0'

  gem.add_runtime_dependency 'activerecord', '>= 3.0.0', '< 6.0'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'sqlite3'
end
