require 'spec_helper'

describe RASN1 do
  describe '.parse' do
    context 'decodes Primitive types' do
      it '(INTEGER)' do
        obj = RASN1.parse("\x02\x02\x80\x79")
        expect(obj).to be_a(RASN1::Types::Integer)
        expect(obj.value).to eq(-32647)
      end

      it '(BIT STRING)' do
        obj = RASN1.parse("\x03\x04\x01\x12\x34\x56")
        expect(obj).to be_a(RASN1::Types::BitString)
        expect(obj.value).to eq("\x12\x34\x56")
        expect(obj.bit_length).to eq(23)
      end

      it '(OCTET STRING)' do
        obj = RASN1.parse("\x04\x05abcde")
        expect(obj).to be_a(RASN1::Types::OctetString)
        expect(obj.value).to eq("abcde")
      end

      it '(OBJECT ID)' do
        obj = RASN1.parse("\x06\x03\x2a\x03\x04")
        expect(obj).to be_a(RASN1::Types::ObjectId)
        expect(obj.value).to eq('1.2.3.4')
      end
    end

    context 'decodes Constructed types' do
      before(:each) do
        @bool = RASN1::Types::Boolean.new(false)
        @int = RASN1::Types::Integer.new(43)
        @os = RASN1::Types::OctetString.new('abcd')
      end

      it '(SEQUENCE of primitives)' do
        seq = RASN1::Types::Sequence.new([@bool, @int, @os])
        obj = RASN1.parse(seq.to_der)
        expect(obj).to be_a(RASN1::Types::Sequence)
        expect(obj.value[0]).to be_a(RASN1::Types::Boolean)
        expect(obj.value[1]).to be_a(RASN1::Types::Integer)
        expect(obj.value[2]).to be_a(RASN1::Types::OctetString)
        expect(obj).to eq(seq)
      end

      it '(SET of primtives)' do
        set = RASN1::Types::Set.new([@bool, @int, @os])
        obj = RASN1.parse(set.to_der)
        expect(obj).to be_a(RASN1::Types::Set)
        expect(obj.value[0]).to be_a(RASN1::Types::Boolean)
        expect(obj.value[1]).to be_a(RASN1::Types::Integer)
        expect(obj.value[2]).to be_a(RASN1::Types::OctetString)
        expect(obj).to eq(set)
      end

      it '(SEQUENCE of SEQUENCE of...)' do
        seq1 = RASN1::Types::Sequence.new([@int, @os])
        seq2 = RASN1::Types::Sequence.new([@bool, seq1])
        seq3 = RASN1::Types::Sequence.new([seq2])

        obj = RASN1.parse(seq3.to_der)
        expect(obj).to be_a(RASN1::Types::Sequence)
        expect(obj.value.size).to eq(1)
        expect(obj.value[0]).to be_a(RASN1::Types::Sequence)
        expect(obj.value[0].value.size).to eq(2)
        expect(obj.value[0].value[0]).to be_a(RASN1::Types::Boolean)
        expect(obj.value[0].value[0].value).to be(false)
        expect(obj.value[0].value[1]).to be_a(RASN1::Types::Sequence)
        expect(obj.value[0].value[1].value.size).to eq(2)
        expect(obj.value[0].value[1].value[0]).to be_a(RASN1::Types::Integer)
        expect(obj.value[0].value[1].value[0].value).to eq(43)
        expect(obj.value[0].value[1].value[1]).to be_a(RASN1::Types::OctetString)
        expect(obj.value[0].value[1].value[1].value).to eq('abcd')
        expect(obj).to eq(seq3)
      end
    end

    context 'decodes tagged types' do
      before(:each) do
        @bool = RASN1::Types::Boolean.new(false)
        @int = RASN1::Types::Integer.new(43)
      end

      it '(IMPLICIT INTEGER)' do
        int = RASN1::Types::Integer.new(-1, implicit: 0, class: :application)
        obj = RASN1.parse(int.to_der)
        expect(obj).to be_instance_of(RASN1::Types::Base)
        expect(obj.id).to eq(0)
        expect(obj.asn1_class).to eq(:application)
        expect(obj.value).to eq(255.chr)
      end

      it '(IMPLICIT INTEGER with long id)' do
        int = RASN1::Types::Integer.new(-2, implicit: 65_534)
        obj = RASN1.parse(int.to_der)
        expect(obj).to be_instance_of(RASN1::Types::Base)
        expect(obj.id).to eq(65_534)
        expect(obj.asn1_class).to eq(:context)
        expect(obj.value).to eq(0xfe.chr)
      end

      it '(EXPLICIT INTEGER)' do
        int = RASN1::Types::Integer.new(1, explicit: 7, class: :context)
        obj = RASN1.parse(int.to_der)
        expect(obj).to be_instance_of(RASN1::Types::Base)
        expect(obj.id).to eq(7)
        expect(obj.asn1_class).to eq(:context)
        expect(obj.value).to eq(RASN1::Types::Integer.new(1).to_der)
      end

      it '(EXPLICIT INTEGER with long id)' do
        int = RASN1::Types::Integer.new(43, explicit: 0x81, class: :private)
        obj = RASN1.parse(int.to_der)
        expect(obj).to be_instance_of(RASN1::Types::Base)
        expect(obj.id).to eq(0x81)
        expect(obj.asn1_class).to eq(:private)
        expect(obj.value).to eq(RASN1::Types::Integer.new(43).to_der)
      end

      it '(IMPLICIT SEQUENCE)' do
        seq = RASN1::Types::Sequence.new([@bool, @int], implicit: 1, class: :context)
        obj = RASN1.parse(seq.to_der)
        expect(obj).to be_a(RASN1::Types::Base)
        expect(obj.id).to eq(1)
        expect(obj.asn1_class).to eq(:context)
        expect(obj.constructed?).to be(true)
        expect(obj.value).to eq(@bool.to_der << @int.to_der)

        seq = RASN1::Types::Sequence.new([@bool, @int], implicit: 1,
                                         class: :context, constructed: false)
        obj = RASN1.parse(seq.to_der)
        expect(obj).to be_a(RASN1::Types::Base)
        expect(obj.id).to eq(1)
        expect(obj.asn1_class).to eq(:context)
        expect(obj.constructed?).to be(false)
      end

      it '(EXPLICIT SEQUENCE)' do
        seq = RASN1::Types::Sequence.new([@bool, @int], explicit: 2, class: :private)
        obj = RASN1.parse(seq.to_der)
        expect(obj).to be_a(RASN1::Types::Base)
        expect(obj.id).to eq(2)
        expect(obj.asn1_class).to eq(:private)
        expect(obj.constructed?).to be(true)
        expect(obj.value).to eq(RASN1::Types::Sequence.new([@bool, @int]).to_der)
      end

      context "(complex example)" do
        it 'decodes a complex example' do
          der = File.read(File.join(__dir__, 'cert_example.der'))
          der.force_encoding('BINARY')
          cert = RASN1.parse(der)
          expect(cert).to be_a(RASN1::Types::Sequence)
          expect(cert.value.size).to eq(3)
          expect(cert.value[0]).to be_a(RASN1::Types::Sequence)
          expect(cert.value[1]).to be_a(RASN1::Types::Sequence)
          expect(cert.value[2]).to be_a(RASN1::Types::BitString)

          expected_str = "\x4d\x52\xbf\xb1\x08\xe6\xc2\xb0".force_encoding('BINARY')
          expect(cert.value[2].value[0..7]).to eq(expected_str)
          expect(cert.value[2].bit_length).to eq(1024)

          expect(cert.value[1].value.size).to eq(2)
          expect(cert.value[1].value[0]).to be_a(RASN1::Types::ObjectId)
          expect(cert.value[1].value[0].value).to eq('1.2.840.113549.1.1.11')
          expect(cert.value[1].value[1]).to be_a(RASN1::Types::Null)

          expect(cert.value[0].value.size).to eq(8)
          expect(cert.value[0].value[0]).to be_instance_of(RASN1::Types::Base)
          expect(cert.value[0].value[0].asn1_class).to eq(:context)
          expect(cert.value[0].value[0].constructed?).to eq(true)
          expect(cert.value[0].value[0].id).to eq(0)
          expected_str = RASN1::Types::Integer.new(2).to_der
          expect(cert.value[0].value[0].value).to eq(expected_str)
          expect(cert.value[0].value[1]).to be_instance_of(RASN1::Types::Integer)
          expect(cert.value[0].value[1].value).to eq(0x123456789123456789)
          expect(cert.value[0].value[3]).to be_instance_of(RASN1::Types::Sequence)
          dn = %w(org example www)
          cert.value[0].value[3].value.each_with_index do |obj, i|
            expect(obj).to be_a(RASN1::Types::Set)
            expect(obj.value.size).to eq(1)
            expect(obj.value[0]).to be_a(RASN1::Types::Sequence)
            expect(obj.value[0].value.size).to eq(2)
            expect(obj.value[0].value[0]).to be_a(RASN1::Types::ObjectId)
            expect(obj.value[0].value[1]).to be_a(RASN1::Types::PrintableString)
            expect(obj.value[0].value[1].value).to eq(dn[i])
          end
          expect(cert.value[0].value[7]).to be_instance_of(RASN1::Types::Base)
          expect(cert.value[0].value[7].asn1_class).to eq(:context)
          expect(cert.value[0].value[7].constructed?).to eq(true)
          expect(cert.value[0].value[7].id).to eq(3)
        end
      end
    end
  end
end
