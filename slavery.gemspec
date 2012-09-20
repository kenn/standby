# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slavery/version'

Gem::Specification.new do |gem|
  gem.name          = 'slavery'
  gem.version       = Slavery::VERSION
  gem.authors       = ['Kenn Ejima']
  gem.email         = ['kenn.ejima@gmail.com']
  gem.description   = %q{Simple, conservative slave read for ActiveRecord}
  gem.summary       = %q{Simple, conservative slave read for ActiveRecord}
  gem.homepage      = 'https://github.com/kenn/slavery'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'activerecord', '>= 3.0.0'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'sqlite3'
end
