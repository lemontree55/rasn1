# coding: utf-8
# frozen_string_literal: true

require_relative 'lib/rasn1/version'

Gem::Specification.new do |spec|
  spec.name          = 'rasn1'
  spec.version       = RASN1::VERSION
  spec.license       = 'MIT'
  spec.authors       = ['Sylvain Daubert']
  spec.email         = ['sylvain.daubert@laposte.net']

  spec.summary       = 'Ruby ASN.1 library'
  spec.description   = <<~DESC
    RASN1 is a pure ruby ASN.1 library. It may encode and decode DER and BER
    encodings.
  DESC

  spec.homepage = 'https://github.com/sdaubert/rasn1'

  spec.metadata = {
    'homepage_uri' => 'https://github.com/sdaubert/rasn1',
    'source_code_uri' => 'https://github.com/sdaubert/rasn1',
    'bug_tracker_uri' => 'https://github.com/sdaubert/rasn1/issues',
    'documentation_uri' => 'https://www.rubydoc.info/gems/rasn1',
  }

  spec.files = Dir['lib/**/*']

  spec.extra_rdoc_files = Dir['README.md', 'LICENSE']
  spec.rdoc_options += [
    '--title', 'RASN1 - A pure ruby ASN.1 library',
    '--main', 'README.md',
    '--inline-source',
    '--quiet'
  ]
  spec.required_ruby_version = '>= 2.4.0'

  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'yard', '~>0.9'
  spec.add_development_dependency 'rbs', '>=1.3.3', '~>1.3'
end
