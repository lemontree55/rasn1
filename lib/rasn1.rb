require 'rasn1/version'
require 'rasn1/types'

module Rasn1

  # Base error class
  class Error < StandardError; end

  # ASN.1 encoding/decoding error
  class ASN1Error < Error; end

  # ASN.1 class error
  class ClassError < Error
    def message
      "Tag class should be a symbol: #{Types::Base::CLASSES.join(', ')}"
    end
  end
end
