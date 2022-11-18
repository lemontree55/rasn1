# frozen_string_literal: true

module RASN1
  module Types
    # Mixin to add constraints on a RASN1 type.
    # Should not be used directly but through {Types.define_type}.
    # @version 0.11.0
    # @author Sylvain Daubert
    module Constrained
      # Define class/module methods for {Constrained} module
      module ClassMethods
        # Setter for constraint
        # @param [Proc,nil] constraint
        # @return [Proc,nil]
        def constraint=(constraint)
          @constraint = constraint
        end

        # Check if a constraint is really defined
        # @return [Boolean]
        def constrained?
          @constraint.is_a?(Proc)
        end

        # Check constraint, if defined
        # @param [Object] value the value of the type to check
        # @raise [ConstraintError] constraint is not verified
        def check_constraint(value)
          return unless constrained?
          raise ConstraintError.new(self) unless @constraint.call(value)
        end
      end

      class << self
        # @return [Proc] proc to check constraints
        attr_reader :constraint

        # Extend +base+ with {ClassMethods}
        def included(base)
          base.extend ClassMethods
        end
      end

      # Redefined +#value=+ to check constraint before assigning +val+
      # @see Types::Base#value=
      # @raise [ConstraintError] constraint is not verified
      def value=(val)
        self.class.check_constraint(val)
        super
      end

      private

      def der_to_value(der, ber: false)
        super
        self.class.check_constraint(@value)
      end
    end
  end
end
