module Rasn1
  module Types

    # Base class for all ASN.1 types
    # @author Sylvain Daubert
    class Base
      # Allowed ASN.1 tag classes
      CLASSES = {
                 universal:   0x00,
                 application: 0x40,
                 context:     0x80,
                 private:     0xc0
                }

      MAX_TAG = 0x1e

      attr_reader :name
      attr_reader :asn1_class
      attr_reader :default
      attr_accessor :value

      def initialize(name, options={})
        @name = name

        set_options options
      end

      def optional?
        @optional
      end

      def to_der
        raise NotImplementedError, 'should be implemented by subclasses'
      end


      private

      def set_options(options)
        set_class options[:class]
        set_optional options[:optional]
        set_default options[:default]
      end

      def set_class(asn1_class)
        case asn1_class
        when nil
          @asn1_class = :universal
        when Symbol
          if CLASSES.keys.include? asn1_class
            @asn1_class = asn1_class
          else
            raise ClassError
          end
        else
          raise ClassError
        end
      end

      def set_optional(optional)
        @optional = !!optional
      end

      def set_default(default)
        @default = default
      end
    end
  end
end
