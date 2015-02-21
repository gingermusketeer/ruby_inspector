# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby_inspector/version'

Gem::Specification.new do |spec|
  spec.name          = 'ruby_inspector'
  spec.version       = RubyInspector::VERSION
  spec.authors       = ['Max Brosnahan']
  spec.email         = ['maximilianbrosnahan@gmail.com']

  spec.summary       = 'Debugging ruby with chrome devtools'
  spec.homepage      = 'https://github.com/gingermusketeer/ruby_inspector'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(/^(test|spec|features)\//)
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(/^exe\//) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'rack', '~> 1.6'
  spec.add_development_dependency 'thin', '~> 1.6'
end
