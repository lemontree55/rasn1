# frozen_string_literal: true

require_relative 'spec_helper'

# rubocop:disable Metrics/BlockLength
module RASN1 # rubocop:disable Metrics/ModuleLength
  include TestModel

  module TestWrapper
    DER_SIMPLE_WRAPPED_INTEGER = "\xe2\x01\xff".b.freeze
    DER_EXPLICIT_WRAPPED_INTEGER = "\xcc\x05\x84\x03\x02\x01\xff".b.freeze
    DER_WRAPPED_EXPLICIT_MODEL = "\x60\x0a\x30\x08\x02\x01\x01\x02\x03\x01\x00\x00".b.freeze
    DER_IMPLICITLY_WRAPPED_EXPLICIT_MODEL = "\xe8\x0a\x30\x08\x02\x01\x01\x02\x03\x01\x00\x00".b.freeze
    DER_IMPLICITLY_WRAPPED_IMPLICIT_MODEL = "\xe8\x08\x02\x01\x01\x81\x03\x02\x01\x02".b.freeze
    DER_EXPLICITLY_WRAPPED_EXPLICIT_MODEL = "\x89\x0c\x60\x0a\x30\x08\x02\x01\x01\x02\x03\x01\x00\x00".b.freeze
  end

  describe Wrapper do
    describe '#initialize' do
      it 'creates a wrapper around an ASN.1 basic type' do
        wrapper = Wrapper.new(Types::Integer.new)
        expect(wrapper).to be_primitive
        expect(wrapper).to_not be_optional
        expect(wrapper.asn1_class).to eq(:universal)
        expect(wrapper.default).to eq(nil)
      end

      it 'creates a wrapper around an ASN.1 basic type with options' do
        wrapper = Wrapper.new(Types::Integer.new(name: :int, optional: true, default: -1, constructed: true, class: :private))
        expect(wrapper).to_not be_implicit
        expect(wrapper).to_not be_explicit
        expect(wrapper).to be_constructed
        expect(wrapper).to be_optional
        expect(wrapper.asn1_class).to eq(:private)
        expect(wrapper.default).to eq(-1)
      end

      it "accepts options to supersede its element's options" do
        wrapper = Wrapper.new(Types::SequenceOf.new(Integer, explicit: 4), explicit: 12, class: :private, constructed: false)
        expect(wrapper).to be_explicit
        expect(wrapper).to_not be_constructed
        expect(wrapper).to_not be_optional
        expect(wrapper.id).to eq(12)
        expect(wrapper.asn1_class).to eq(:private)
      end
      it 'creates a wrapper around a model' do
        wrapper = Wrapper.new(ExplicitTaggedSeq.new)
        expect(wrapper).to_not be_implicit
        expect(wrapper).to_not be_explicit
        expect(wrapper).to be_constructed
        expect(wrapper.id).to eq(0)
        expect(wrapper.asn1_class).to eq(:application)
      end
      it "creates a wrapper around a model with options superseeding model's root's ones" do
        wrapper = Wrapper.new(ExplicitTaggedSeq.new, explicit: 12, class: :context, constructed: true)
        expect(wrapper).to be_constructed
        expect(wrapper).to be_explicit
        expect(wrapper.id).to eq(12)
        expect(wrapper.asn1_class).to eq(:context)
      end

      it 'raises if wrapper is explicit and implicit' do
        expect { Wrapper.new(Types::Null.new, explicit: 1, implicit: 2) }.to raise_error(RASN1::Error)
      end
    end

    describe '#to_der' do
      it 'generates a DER string for implicitly wrapped explicit base type' do
        wrapper = Wrapper.new(Types::Integer.new(name: :int, value: -1, constructed: true, class: :private))
        expect(wrapper.to_der).to eq(TestWrapper::DER_SIMPLE_WRAPPED_INTEGER)
      end

      it 'generates a DER string for explicitly wrapped explicit base type' do
        wrapper = Wrapper.new(Types::Integer.new(name: :int, value: -1, explicit: 4), explicit: 12, class: :private)
        expect(wrapper.to_der).to eq(TestWrapper::DER_EXPLICIT_WRAPPED_INTEGER)
      end

      it 'generates a DER string for a wrapped explicit model' do
        wrapper = Wrapper.new(ExplicitTaggedSeq.new(id: 1, extern_id: 65_536))
        expect(wrapper.to_der).to eq(TestWrapper::DER_WRAPPED_EXPLICIT_MODEL)
      end

      it 'generates a DER string for an implicitly wrapped explicit model' do
        wrapper = Wrapper.new(ExplicitTaggedSeq.new(id: 1, extern_id: 65_536), implicit: 8, class: :private)
        expect(wrapper.to_der).to eq(TestWrapper::DER_IMPLICITLY_WRAPPED_EXPLICIT_MODEL)
      end

      it 'generates a DER string for an implicitly wrapped implicit model' do
        wrapper = Wrapper.new(ModelTest3.new(id: 1, house: 2), implicit: 8, class: :private)
        expect(wrapper.to_der).to eq(TestWrapper::DER_IMPLICITLY_WRAPPED_IMPLICIT_MODEL)
      end

      it 'generates a DER string for an explicitly wrapped explicit model' do
        wrapper = Wrapper.new(ExplicitTaggedSeq.new(id: 1, extern_id: 65_536), explicit: 9, class: :context)
        expect(wrapper.to_der).to eq(TestWrapper::DER_EXPLICITLY_WRAPPED_EXPLICIT_MODEL)
      end
    end

    describe '#parse!' do
      it 'parses a DER string for an implicitly wrapped explicit base type' do
        wrapper = Wrapper.new(Types::Integer.new(name: :int, constructed: true, class: :private))
        expect { wrapper.parse!(TestWrapper::DER_SIMPLE_WRAPPED_INTEGER) }.not_to raise_error
        expect(wrapper.value).to eq(-1)
      end

      it 'parses a DER string for an explicitly wrapped explicit base type' do
        wrapper = Wrapper.new(Types::Integer.new(name: :int, explicit: 4), explicit: 12, class: :private)
        expect { wrapper.parse!(TestWrapper::DER_EXPLICIT_WRAPPED_INTEGER) }.not_to raise_error
        expect(wrapper.value).to eq(-1)
      end

      it 'parses a DER string for a wrapped explicit model' do
        wrapper = Wrapper.new(ExplicitTaggedSeq.new)
        expect { wrapper.parse!(TestWrapper::DER_WRAPPED_EXPLICIT_MODEL) }.not_to raise_error
        expect(wrapper[:id].value).to eq(1)
        expect(wrapper[:extern_id].value).to eq(65_536)
      end

      it 'parses a DER string for an implicitly wrapped explicit model' do
        wrapper = Wrapper.new(ExplicitTaggedSeq.new, implicit: 8, class: :private)
        expect { wrapper.parse!(TestWrapper::DER_IMPLICITLY_WRAPPED_EXPLICIT_MODEL) }.not_to raise_error
        expect(wrapper[:id].value).to eq(1)
        expect(wrapper[:extern_id].value).to eq(65_536)
      end

      it 'parses a DER string for an implicitly wrapped implicit model' do
        wrapper = Wrapper.new(ModelTest3.new, implicit: 8, class: :private)
        expect { wrapper.parse!(TestWrapper::DER_IMPLICITLY_WRAPPED_IMPLICIT_MODEL) }.not_to raise_error
        expect(wrapper[:id].value).to eq(1)
        expect(wrapper[:house].value).to eq(2)
      end

      it 'parses a DER string for an explicitly wrapped explicit model' do
        wrapper = Wrapper.new(ExplicitTaggedSeq.new, explicit: 9, class: :context)
        expect { wrapper.parse!(TestWrapper::DER_EXPLICITLY_WRAPPED_EXPLICIT_MODEL) }.not_to raise_error
        expect(wrapper[:id].value).to eq(1)
        expect(wrapper[:extern_id].value).to eq(65_536)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
