# -*- coding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'execphp/version'

Gem::Specification.new do |spec|
  spec.name          = 'execphp'
  spec.version       = ExecPHP::VERSION
  spec.summary       = 'Lets you run php code bundles on your remote Apache/Nginx/IIS (+mod_php) servers'
  spec.homepage      = 'https://github.com/kerimdzhanov/execphp'

  spec.description   = <<-EOT.chomp
ExecPHP is a ruby library (gem) that lets you run PHP code bundles on your remote servers.
You need to have up and running Apache/Nginx/IIS server with `mod_php` enabled in order to run your PHP code there.
  EOT

  spec.author        = 'Dan Kerimdzhanov'
  spec.email         = 'kerimdzhanov@gmail.com'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = %w[lib]

  spec.platform      = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.0.0'

  spec.add_development_dependency 'bundler', '~> 1.5.2'
end
