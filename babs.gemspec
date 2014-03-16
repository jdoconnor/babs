# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'babs/version'

Gem::Specification.new do |spec|
  spec.name          = "babs"
  spec.version       = Babs::VERSION
  spec.authors       = ["Jay OConnor"]
  spec.email         = ["jaydoconnor@gmail.com"]
  spec.summary       = %q{ Client for a request response (synchronous) pattern using RabbitMQ. }
  spec.description   = %q{ }
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_dependency "bunny"
  spec.add_dependency "hashie"
end
