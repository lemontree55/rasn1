# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rasn1/version'

Gem::Specification.new do |spec|
  spec.name          = 'rasn1'
  spec.version       = RASN1::VERSION
  spec.license       = 'MIT'
  spec.authors       = ['Sylvain Daubert']
  spec.email         = ['sylvain.daubert@laposte.net']

  spec.summary       = %q{Ruby ASN.1 library}
  spec.description   = %q{
  RASN1 is a pure ruby ASN.1 library. It may encode and decode DER and BER
  encodings.
}
  spec.homepage      = 'https://github.com/sdaubert/rasn1'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.2.0'

  spec.add_development_dependency 'yard', '~>0.9'
  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.14'
end
