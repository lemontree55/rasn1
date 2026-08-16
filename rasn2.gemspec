# coding: utf-8
# frozen_string_literal: true

require_relative 'lib/rasn2/version'

Gem::Specification.new do |spec|
  spec.name          = 'rasn2'
  spec.version       = RASN2::VERSION
  spec.license       = 'MIT'
  spec.authors       = ['LemonTree55', 'Rick Mark']
  spec.email         = ['lenontree@proton.me', 'rickmark@outlook.com']

  spec.summary       = 'Ruby ASN.1 library'
  spec.description   = <<~DESC
    Rasn2 is a pure ruby ASN.1 library. It may encode and decode DER and BER
    encodings.
  DESC

  spec.homepage = 'https://github.com/lemontree55/rasn1'

  spec.metadata = {
    'homepage_uri' => 'https://github.com/lemontree55/rasn1',
    'source_code_uri' => 'https://github.com/lemontree55/rasn1',
    'bug_tracker_uri' => 'https://github.com/lemontree55/rasn1/issues',
    'documentation_uri' => 'https://www.rubydoc.info/gems/rasn1',
  }

  spec.files = Dir['lib/**/*']

  spec.extra_rdoc_files = Dir['README.md', 'LICENSE']
  spec.rdoc_options += [
    '--title', 'Rasn2 - A pure ruby ASN.1 library',
    '--main', 'README.md',
    '--inline-source',
    '--quiet'
  ]

  spec.required_ruby_version = '>= 3.0.0'

  spec.add_dependency 'rainbow'
  spec.add_dependency 'strptime', '~>0.2.5'
end
