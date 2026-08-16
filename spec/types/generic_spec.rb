# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
module RASN2
  module Types
    describe Tag do
      describe '#initialize' do
        it 'creates with a single tag' do
          generic = Tag.new(tag: 5, value: [Integer.new])
          expect(generic.implicit?).to be true
          expect(generic.id).to eq 5
          expect(generic.asn1_class).to eq :context
        end

        it 'creates with a list of tags' do
          generic = Tag.new(tag: [5, 6, 7], value: [Integer.new])
          expect(generic.id).to eq 5
          expect(generic.asn1_class).to eq :context
        end

        it 'creates with any_private option' do
          generic = Tag.new(any_private: true, value: [Integer.new])
          expect(generic.asn1_class).to eq :private
        end

        it 'creates with tag: :private shorthand' do
          generic = Tag.new(tag: :private, value: [Integer.new])
          expect(generic.asn1_class).to eq :private
        end

        it 'creates with custom class' do
          generic = Tag.new(tag: 5, class: :application, value: [Integer.new])
          expect(generic.asn1_class).to eq :application
        end

        it 'defaults value to empty array' do
          generic = Tag.new(tag: 5)
          expect(generic.value).to eq []
        end
      end

      describe '#to_der' do
        it 'encodes with a single context tag' do
          int = Integer.new(value: 42)
          generic = Tag.new(tag: 5, value: [int])
          der = generic.to_der
          # 0xa5 = context(0x80) | constructed(0x20) | tag 5
          expect(der.bytes[0]).to eq 0xa5
          expect(der.bytes[1]).to eq 3
        end

        it 'encodes with an application class tag' do
          int = Integer.new(value: 42)
          generic = Tag.new(tag: 3, class: :application, value: [int])
          der = generic.to_der
          # 0x63 = application(0x40) | constructed(0x20) | tag 3
          expect(der.bytes[0]).to eq 0x63
        end

        it 'encodes with a private class tag' do
          int = Integer.new(value: 42)
          generic = Tag.new(tag: 1, class: :private, value: [int])
          der = generic.to_der
          # 0xe1 = private(0xC0) | constructed(0x20) | tag 1
          expect(der.bytes[0]).to eq 0xe1
        end

        it 'encodes with multi-tag using first tag' do
          int = Integer.new(value: 42)
          generic = Tag.new(tag: [5, 6, 7], value: [int])
          der = generic.to_der
          expect(der.bytes[0]).to eq 0xa5
        end

        it 'encodes multiple child elements' do
          int = Integer.new(value: 42)
          os = OctetString.new(value: 'abc')
          generic = Tag.new(tag: 5, value: [int, os])
          der = generic.to_der
          expect(der.bytes[0]).to eq 0xa5
          expect(der.bytes[1]).to eq 8 # 3 (int) + 5 (os)
        end
      end

      describe '#parse!' do
        it 'parses with a single tag' do
          int = Integer.new
          generic = Tag.new(tag: 5, value: [int])
          # 0xa5 = context, constructed, tag 5
          der = "\xa5\x03\x02\x01\x2a".b
          generic.parse!(der)
          expect(generic.value.first.value).to eq 42
        end

        it 'parses with tag list, matching first tag' do
          int = Integer.new
          generic = Tag.new(tag: [5, 6, 7], value: [int])
          der = "\xa5\x03\x02\x01\x2a".b
          generic.parse!(der)
          expect(generic.matched_tag).to eq 5
          expect(generic.value.first.value).to eq 42
        end

        it 'parses with tag list, matching second tag' do
          int = Integer.new
          generic = Tag.new(tag: [5, 6, 7], value: [int])
          der = "\xa6\x03\x02\x01\x2a".b
          generic.parse!(der)
          expect(generic.matched_tag).to eq 6
          expect(generic.value.first.value).to eq 42
        end

        it 'parses with tag list, matching third tag' do
          int = Integer.new
          generic = Tag.new(tag: [5, 6, 7], value: [int])
          der = "\xa7\x03\x02\x01\x2a".b
          generic.parse!(der)
          expect(generic.matched_tag).to eq 7
          expect(generic.value.first.value).to eq 42
        end

        it 'parses any private tag (tag 0)' do
          int = Integer.new
          generic = Tag.new(tag: :private, value: [int])
          # 0xe0 = private(0xC0) | constructed(0x20) | tag 0
          der = "\xe0\x03\x02\x01\x2a".b
          generic.parse!(der)
          expect(generic.matched_tag).to eq 0
          expect(generic.value.first.value).to eq 42
        end

        it 'parses any private tag (tag 5)' do
          int = Integer.new
          generic = Tag.new(any_private: true, value: [int])
          # 0xe5 = private(0xC0) | constructed(0x20) | tag 5
          der = "\xe5\x03\x02\x01\x2a".b
          generic.parse!(der)
          expect(generic.matched_tag).to eq 5
          expect(generic.value.first.value).to eq 42
        end

        it 'parses multiple child elements' do
          int = Integer.new
          os = OctetString.new
          generic = Tag.new(tag: 5, value: [int, os])
          der = "\xa5\x08\x02\x01\x2a\x04\x03abc".b
          generic.parse!(der)
          expect(generic[0].value).to eq 42
          expect(generic[1].value).to eq 'abc'
        end

        it 'raises on tag mismatch (single tag)' do
          int = Integer.new
          generic = Tag.new(tag: 5, value: [int])
          der = "\xa6\x03\x02\x01\x2a".b
          expect { generic.parse!(der) }.to raise_error(ASN1Error)
        end

        it 'raises on tag mismatch (tag list)' do
          int = Integer.new
          generic = Tag.new(tag: [5, 6], value: [int])
          der = "\xa7\x03\x02\x01\x2a".b
          expect { generic.parse!(der) }.to raise_error(ASN1Error)
        end

        it 'raises on class mismatch (any_private expects private class)' do
          int = Integer.new
          generic = Tag.new(any_private: true, value: [int])
          # 0xa5 = context class, not private
          der = "\xa5\x03\x02\x01\x2a".b
          expect { generic.parse!(der) }.to raise_error(ASN1Error)
        end

        it 'handles optional with no match' do
          int = Integer.new
          generic = Tag.new(tag: 5, optional: true, value: [int])
          der = "\xa6\x03\x02\x01\x2a".b
          result = generic.parse!(der)
          expect(result).to eq 0
          expect(generic.value?).to be false
        end

        it 'handles optional with tag list and no match' do
          int = Integer.new
          generic = Tag.new(tag: [5, 6], optional: true, value: [int])
          der = "\xa7\x03\x02\x01\x2a".b
          result = generic.parse!(der)
          expect(result).to eq 0
        end



      end

      describe '#[]' do
        it 'accesses element by index' do
          int = Integer.new(name: :id, value: 1)
          os = OctetString.new(name: :data, value: 'abc')
          generic = Tag.new(tag: 5, value: [int, os])
          expect(generic[0].value).to eq 1
          expect(generic[1].value).to eq 'abc'
        end

        it 'accesses element by name' do
          int = Integer.new(name: :id, value: 1)
          os = OctetString.new(name: :data, value: 'abc')
          generic = Tag.new(tag: 5, value: [int, os])
          expect(generic[:id].value).to eq 1
          expect(generic[:data].value).to eq 'abc'
        end

        it 'returns nil for non-existent name' do
          int = Integer.new(name: :id, value: 1)
          generic = Tag.new(tag: 5, value: [int])
          expect(generic[:nonexistent]).to be_nil
        end
      end

      describe 'roundtrip' do
        it 'encodes and parses back with single tag' do
          int = Integer.new(value: 42)
          os = OctetString.new(value: 'hello')
          generic = Tag.new(tag: 5, value: [int, os])
          der = generic.to_der

          int2 = Integer.new
          os2 = OctetString.new
          generic2 = Tag.new(tag: 5, value: [int2, os2])
          generic2.parse!(der)
          expect(generic2[0].value).to eq 42
          expect(generic2[1].value).to eq 'hello'
        end

        it 'encodes and parses back with private tag' do
          int = Integer.new(value: 99)
          generic = Tag.new(tag: 3, class: :private, value: [int])
          der = generic.to_der

          int2 = Integer.new
          generic2 = Tag.new(tag: 3, class: :private, value: [int2])
          generic2.parse!(der)
          expect(generic2[0].value).to eq 99
        end

        it 'encodes with first tag and parses back with tag list' do
          int = Integer.new(value: 7)
          generic = Tag.new(tag: [5, 6, 7], value: [int])
          der = generic.to_der

          int2 = Integer.new
          generic2 = Tag.new(tag: [5, 6, 7], value: [int2])
          generic2.parse!(der)
          expect(generic2.matched_tag).to eq 5
          expect(generic2[0].value).to eq 7
        end
      end

      describe '#initialize_copy' do
        it 'deep copies array value' do
          int = Integer.new(value: 42)
          generic = Tag.new(tag: 5, value: [int])
          copy = generic.dup
          copy[0].value = 99
          expect(generic[0].value).to eq 42
        end
      end

      describe '#type' do
        it 'returns GENERIC' do
          generic = Tag.new(tag: 5)
          expect(generic.type).to eq 'TAG'
        end
      end

      describe '#constructed?' do
        it 'is not constructed' do
          generic = Tag.new(tag: 5)
          expect(generic.constructed?).to be false
        end

        it 'is constructed' do
          generic = Tag.new(tag: 5, constructed: true)
          expect(generic.constructed?).to be true
        end
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
