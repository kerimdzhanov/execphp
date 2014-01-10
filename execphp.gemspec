# -*- coding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'execphp/version'

Gem::Specification.new do |spec|
  spec.name          = 'execphp'
  spec.version       = ExecPHP::VERSION
  spec.summary       = 'Lets you run php code on a remote server from ruby'
  spec.homepage      = 'https://github.com/kerimdzhanov/execphp'

  spec.description   = <<-EOT.chomp
Lets you run php code on a remote server from ruby
  EOT

  spec.author        = 'Dan Kerimdzhanov'
  spec.email         = 'kerimdzhanov@gmail.com'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = %w[lib]

  spec.platform      = Gem::Platform::RUBY
  spec.required_ruby_version = '~> 2.0'

  spec.add_development_dependency 'bundler', '~> 1.3', '>= 1.3.5'
  spec.add_dependency 'rake', '~> 10.1'
end
