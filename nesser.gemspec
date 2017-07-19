# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nesser/version'

Gem::Specification.new do |spec|
  spec.name          = "nesser"
  spec.version       = Nesser::VERSION
  spec.authors       = ["iagox86"]
  spec.email         = ["ron-git@skullsecurity.org"]

  spec.summary       = "A simple and straight forward DNS library, created for dnscat2"
  spec.homepage      = "https://github.com/iagox86/nesser"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "test-unit"
  spec.add_dependency "hexhelper"
end
