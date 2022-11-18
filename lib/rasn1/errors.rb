# frozen_string_literal: true

module RASN1
  # Base error class
  class Error < StandardError; end

  # ASN.1 encoding/decoding error
  class ASN1Error < Error; end

  # ASN.1 class error
  class ClassError < Error
    # @return [String]
    def message
      "Tag class should be a symbol among: #{Types::Base::CLASSES.keys.join(', ')}"
    end
  end

  # Enumerated error
  class EnumeratedError < Error; end

  # CHOICE error: {Types::Choice#chosen} not set
  class ChoiceError < RASN1::Error
    # @param [Types::Base] object
    def initialize(object)
      @object = object
      super()
    end

    # @return [String]
    def message
      "CHOICE #{@object.name}: #chosen not set"
    end
  end

  # Exception raised when a constraint is not verified on a constrained type.
  # @version 0.11.0
  # @author Sylvain Daubert
  class ConstraintError < Error
    # @param [Types::Base] object
    def initialize(object)
      @object = object
      super()
    end

    # @return [String]
    def message
      "Constraint not verified on #{@object.inspect}"
    end
  end

  # Exception raised when model validation fails
  # @since 0.12.0
  class ModelValidationError < Error
  end
end
