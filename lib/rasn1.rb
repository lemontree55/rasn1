require 'rasn1/version'
require 'rasn1/types'
require 'rasn1/model'

# Rasn1 is a pure ruby library to parse, decode and encode ASN.1 data.
# @author Sylvain Daubert
module RASN1

  # Base error class
  class Error < StandardError; end

  # ASN.1 encoding/decoding error
  class ASN1Error < Error; end

  # ASN.1 class error
  class ClassError < Error
    # @return [String]
    def message
      "Tag class should be a symbol: #{Types::Base::CLASSES.keys.join(', ')}"
    end
  end

  # Enumerated error
  class EnumeratedError < Error; end

  # CHOICE error: #chosen not set
  class ChoiceError < RASN1::Error
    def message
      "CHOICE #@name: #chosen not set"
    end
  end
end
