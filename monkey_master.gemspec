# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'monkey_master/version'

Gem::Specification.new do |spec|
  spec.name          = "monkey_master"
  spec.version       = MonkeyMaster::VERSION
  spec.authors       = ["Lukas Nagl"]
  spec.email         = ["lukas.nagl@innovaptor.com"]
  spec.description   = %q{A tool for conveniently employing Android adb monkeys.}
  spec.summary       = %q{A tool for conveniently employing Android adb monkeys.}
  spec.homepage      = "https://github.com/j4zz/monkey_master.git"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'docopt', '~> 0.5'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'rake', '~> 10.3'
  spec.add_development_dependency 'bundler', '~> 1.3'
end
