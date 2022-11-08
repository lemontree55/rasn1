# frozen_string_literal: true

require 'spec_helper'

module RASN1Test
  module X509Example
    class AttributeTypeAndValue < RASN1::Model
      sequence :attributeTypeAndValue,
               content: [objectid(:type),
                         any(:value)]
    end

    class AlgorithmIdentifier < RASN1::Model
      sequence :algorithmIdentifier
    end

    class RelativeDN < RASN1::Model
      set_of :relativeDN, AttributeTypeAndValue
    end

    class X509Name < RASN1::Model
      sequence_of :rdnSequence, RelativeDN
    end

    class Extension < RASN1::Model
      sequence :extension,
               content: [objectid(:extnID),
                         boolean(:critical, default: false),
                         octet_string(:extnValue)]
    end

    class TBSCertificate < RASN1::Model
      sequence :tbsCertificate,
               content: [integer(:version, explicit: 0, constructed: true,
                                           default: 0, enum: { v1: 0, v2: 1, v3: 2 }),
                         integer(:serialNumber),
                         model(:signature, AlgorithmIdentifier),
                         model(:issuer, X509Name),
                         sequence(:validity),
                         model(:subject, X509Name),
                         sequence(:subjectPublicKeyInfo),
                         bit_string(:issuerUniqueID, implicit: 1, optional: true),
                         bit_string(:subjectUniqueID, implicit: 2, optional: true),
                         sequence_of(:extensions, Extension, explicit: 3,
                                                             optional: true)]
    end

    class X509Certificate < RASN1::Model
      sequence :certificate,
               content: [model(:tbsCertificate, TBSCertificate),
                         model(:signatureAlgorithm, AlgorithmIdentifier),
                         bit_string(:signatureValue)]
    end
  end

  class OptionalWrappedSubModel < RASN1::Model
    sequence :s, content: [integer(:superid),
                           wrapper(model(:submodel, TestModel::ModelTest), optional: true, explicit: 5)]
  end

  class OptionalWrappedConstructedSubModel < RASN1::Model
    sequence :s, content: [integer(:superid),
                           wrapper(model(:submodel, TestModel::ConstructedModelTest), optional: true, explicit: 5)]
  end
end

# rubocop:disable Metrics/BlockLength
module RASN1 # rubocop:disable Metrics/moduleLength
  include TestModel

  SIMPLE_VALUE = "\x30\x0e\x02\x03\x01\x00\x01\x80\x01\x2b\x81\x04\x02\x02\x12\x34".b.freeze
  OPTIONAL_VALUE = "\x30\x0b\x02\x03\x01\x00\x01\x81\x04\x02\x02\x12\x34".b.freeze
  DEFAULT_VALUE = "\x30\x08\x02\x03\x01\x00\x01\x80\x01\x2b".b.freeze
  NESTED_VALUE = "\x30\x0d\x01\x01\xff\x30\x08\x02\x03\x01\x00\x01\x80\x01\x2b".b.freeze
  ERRORED_VALUE = "\x01\x01\x00".b.freeze
  CHOICE_INTEGER = "\x02\x01\x10".b.freeze
  CHOICE_SEQUENCE = SIMPLE_VALUE
  IMPLICIT_WRAPPED_SUBMODEL = "\x30\x0a\xa5\x08\x02\x01\x0a\x81\x03\x02\x01\x33".b.freeze
  EXPLICIT_WRAPPED_SUBMODEL = "\x30\x0c\x86\x0a\xa4\x08\x02\x01\x0a\x81\x03\x02\x01\x33".b.freeze
  OPTIONAL_VOID_WRAPPED_SUBMODEL = "\x30\x03\x02\x01\x01".b.freeze
  OPTIONAL_PLAIN_WRAPPED_SUBMODEL = "\x30\x0f\x02\x01\x01\x85\x0a\x30\x08\x02\x01\x0a\x81\x03\x02\x01\x33".b.freeze
  OPTIONAL_CONSTRUCTED_WRAPPED_SUBMODEL = "\x30\x0f\x02\x01\x01\x85\x0a\x30\x08\x22\x01\x0a\xa1\x03\x02\x01\x33".b.freeze

  describe Model do
    describe '.root_options' do
      let(:model) { ModelTest3.new }

      it 'updates root options from a super class' do
        classical_model = ModelTest.new
        expect(classical_model.id).to eq(Types::Sequence::ID)
        expect(model.id).to eq(4)
      end

      it 'does not update other elements' do
        expect(model[:id].id).to eq(Types::Integer::ID)
      end
    end

    %i[sequence sequence_of set set_of choice].each do |method_name|
      describe ".#{method_name}" do
        it 'has a line number and source location associated with the rasn1 namespace' do
          method = described_class.method(method_name)
          method_source_file, method_source_line = method.source_location

          # By default this will be `["(eval)", 1]` if line/source are not passed to eval
          # This verifies it is located within the rasn1 namespace
          expect(method_source_file).to match(/rasn1/)
          expect(method_source_line).to be_an_instance_of(Integer)
        end
      end
    end

    describe '.wrapper' do
      it 'implicitly wraps a submodel' do
        model = ModelWithImplicitWrapper.new(a_record: { id: 10, house: 51 })
        expect(model.to_der).to eq(IMPLICIT_WRAPPED_SUBMODEL)

        model = ModelWithImplicitWrapper.new
        expect { model.parse!(IMPLICIT_WRAPPED_SUBMODEL) }.to_not raise_error
      end

      it 'explicitly wraps a submodel' do
        model = ModelWithExplicitWrapper.new(a_record: { id: 10, house: 51 })
        expect(model.to_der).to eq(EXPLICIT_WRAPPED_SUBMODEL)

        model = ModelWithExplicitWrapper.new
        expect { model.parse!(EXPLICIT_WRAPPED_SUBMODEL) }.to_not raise_error
      end

      it 'optionally wraps a submodel' do
        model = RASN1Test::OptionalWrappedSubModel.new(superid: 1)
        expect(model.to_der).to eq(OPTIONAL_VOID_WRAPPED_SUBMODEL)

        model = RASN1Test::OptionalWrappedSubModel.new(superid: 1, submodel: { id: 10, house: 51 })
        expect(model.to_der).to eq(OPTIONAL_PLAIN_WRAPPED_SUBMODEL)
      end

      it 'optionally wraps a submodel with a constructed value' do
        model = RASN1Test::OptionalWrappedConstructedSubModel.new(superid: 1)
        expect(model.to_der).to eq(OPTIONAL_VOID_WRAPPED_SUBMODEL)

        model = RASN1Test::OptionalWrappedConstructedSubModel.new(superid: 1, submodel: { id: 10, house: 51 })
        expect(model.to_der).to eq(OPTIONAL_CONSTRUCTED_WRAPPED_SUBMODEL)
      end
    end

    describe '#initialize' do
      it 'creates a class from a Model' do
        expect { ModelTest.new }.to_not raise_error
      end

      it 'initializes a model from a parameter hash' do
        model = SuperOfModel.new(of: [{ id: 1234 }, { id: 4567, room: 43, house: 21 }])
        expect(model[:of][:seqof].length).to eq(2)
        expect(model[:of][:seqof][0]).to be_a(ModelTest)
        expect(model[:of][:seqof][0][:id].to_i).to eq(1234)
        expect(model[:of][:seqof][0][:room].value).to be_nil
        expect(model[:of][:seqof][0][:house].to_i).to eq(0)
        expect(model[:of][:seqof][1]).to be_a(ModelTest)
        expect(model[:of][:seqof][1][:id].to_i).to eq(4567)
        expect(model[:of][:seqof][1][:room].value).to eq(43)
        expect(model[:of][:seqof][1][:house].to_i).to eq(21)
      end

      it 'initializes a model with an implicit wrapper from a parameter hash' do
        model = ModelWithImplicitWrapper.new(a_record: { id: 12_345, room: 42, house: 19 })
        expect(model[:a_record][:id].value).to eq(12_345)
        expect(model[:a_record][:room].value).to eq(42)
        expect(model[:a_record][:house].value).to eq(19)
      end

      it 'initializes a model with an explicit wrapper from a parameter hash' do
        model = ModelWithExplicitWrapper.new(a_record: { id: 52, room: 41, house: 18 })
        expect(model[:a_record][:id].value).to eq(52)
        expect(model[:a_record][:room].value).to eq(41)
        expect(model[:a_record][:house].value).to eq(18)
      end

      context 'when there are duplicate names present in the model' do
        it 'raises an exception when the sequence name is the same as the content name' do
          expect do
            Class.new(described_class) do
              sequence :foo,
                       content: [integer(:foo),
                                 integer(:bar)]
            end
          end.to raise_error(ModelValidationError).with_message('Duplicate name foo found')
        end

        it 'raises an exception when the content has duplicate names' do
          expect do
            Class.new(described_class) do
              sequence :model,
                       content: [integer(:foo),
                                 objectid(:bar),
                                 integer(:baz),
                                 bit_string(:bar)]
            end
          end.to raise_error(ModelValidationError).with_message('Duplicate name bar found')
        end
      end
    end

    describe '#name' do
      it 'returns name of root element' do
        expect(ModelTest.new.name).to eq(:record)
      end
    end

    describe '#[]' do
      it 'gives access to element which name is given' do
        model = ModelTest.new
        expect(model[:id]).to be_a(Types::Integer)
        expect(model[:record]).to be_a(Types::Sequence)
      end
    end

    describe '#[]=' do
      let(:model) { ModelTest2.new }

      it 'sets value to base element which name is given' do
        int = model[:a_record][:id]
        model[:a_record][:id] = 156
        expect(int.value).to eq(156)
      end

      it 'raises if element is a Model' do
        expect { model[:a_record] = ModelTest.new }.to raise_error(RASN1::Error)
      end
    end

    describe '#to_h' do
      it 'generates a Hash image of model' do
        test = ModelTest.new
        test[:id].value = 12
        test[:room].value = 3
        expect(test.to_h).to eq({ record: { id: 12, room: 3, house: 0 } })
      end

      it 'generates a Hash image of a nested model' do
        test2 = ModelTest2.new
        test2[:rented].value = true
        test2[:a_record][:id].value = 12
        test2[:a_record][:house].value = 1
        expect(test2.to_h).to eq({ record2: { rented: true,
                                              a_record:
                                                { id: 12, house: 1 } } })
      end

      it 'generates a Hash image of a model with a SequenceOf' do
        model = OfModel.new
        model[:seqof] << { id: 1, house: 1 }
        model[:seqof] << { id: 2, house: 1 }
        expect(model.to_h).to eq({ seqof: [{ id: 1, house: 1 },
                                           { id: 2, house: 1 }] })
      end

      it 'generates a Hash image of a model with a choice model' do
        model = ModelChoice.parse(CHOICE_INTEGER)
        expect(model.to_h).to eq({ choice: 16 })

        model = ModelChoice.parse(CHOICE_SEQUENCE)
        expect(model.to_h).to eq({ choice: { id: 65537, room: 43, house: 4660 } })

        model = ModelChoice.new
        expect { model.to_h }
          .to raise_error(an_instance_of(RASN1::ChoiceError).and having_attributes({"message" => "CHOICE choice: #chosen not set"}))
      end

      it 'generates a Hash image of a model with an implicit wrapped submodel' do
        model = ModelWithImplicitWrapper.new
        model[:a_record][:id] = 2
        model[:a_record][:house] = 3
        expect(model.to_h).to eq({ seq: { a_record: { id: 2, house: 3 } } })
      end

      it 'generates a Hash image of a model with an explicit wrapped submodel' do
        model = ModelWithExplicitWrapper.new
        model[:a_record][:id] = 4
        model[:a_record][:house] = 5
        expect(model.to_h).to eq({ seq: { a_record: { id: 4, house: 5 } } })
      end
    end

    describe '#to_der' do
      it 'generates a DER string from a simple model' do
        test = ModelTest.new(id: 65_537, room: 43, house: 0x1234)
        expect(test.to_der).to eq(SIMPLE_VALUE)
      end

      it 'generates a DER string from a simple model, without optional value' do
        test = ModelTest.new(id: 65_537, house: 0x1234)
        expect(test.to_der).to eq(OPTIONAL_VALUE)
      end

      it 'generates a DER string from a simple model, without default value' do
        test = ModelTest.new(id: 65_537, room: 43)
        expect(test.to_der).to eq(DEFAULT_VALUE)
      end
      it 'generates a DER string from a nested model' do
        test2 = ModelTest2.new(rented: true, a_record: { id: 65_537, room: 43 })
        expect(test2.to_der).to eq(NESTED_VALUE)
      end

      it 'generates a DER string from a model with bit string' do
        test = ModelExplicitBitString.new(flags: "\x50\xa0\x00\x00".b)
        expect(test.to_der).to eq("\x30\x09\xa0\x07\x03\x05\x00\x50\xa0\x00\x00".b)
      end
    end

    describe '.parse' do
      it 'parses a DER string from a simple model' do
        test = ModelTest.parse(SIMPLE_VALUE)
        expect(test[:id].value).to eq(65_537)
        expect(test[:room].value).to eq(43)
        expect(test[:house].value).to eq(0x1234)
      end

      it 'parses a DER string from a simple model, optional value being not present' do
        test = ModelTest.parse(OPTIONAL_VALUE)
        expect(test[:id].value).to eq(65_537)
        expect(test[:room].value).to eq(nil)
        expect(test[:house].value).to eq(0x1234)
      end

      it 'parses a DER string from a simple model, default value being not present' do
        test = ModelTest.parse(DEFAULT_VALUE)
        expect(test[:id].value).to eq(65_537)
        expect(test[:room].value).to eq(43)
        expect(test[:house].value).to eq(0)
      end

      it 'parses a DER string from a nested model' do
        test2 = ModelTest2.parse(NESTED_VALUE)
        expect(test2.to_h).to eq(record2: { rented: true,
                                            a_record: { id: 65_537,
                                                        room: 43,
                                                        house: 0 } })
      end

      it 'parses a DER string with a model containing a void SEQUENCE' do
        voidseq = VoidSeq.parse(SIMPLE_VALUE)
        expect(voidseq[:voidseq].value).to eq(SIMPLE_VALUE[2, SIMPLE_VALUE.length])

        voidseq2 = VoidSeq2.parse(NESTED_VALUE)
        expect(voidseq2[:seq].value).to eq(NESTED_VALUE[7..-1])
      end

      it 'parses a DER string with an explicit tagged model (issue #5)' do
        exp = ExplicitTaggedSeq.parse("\x60\x08\x30\x06\x02\x01\x01\x02\x01\x10")
        expect(exp.root.value).to_not be_a(String)
        expect(exp.root.value[0]).to be_a(Types::Integer)
        expect(exp.root.value[1]).to be_a(Types::Integer)
        expect(exp[:id]).to be_a(Types::Integer)
        expect(exp[:extern_id]).to be_a(Types::Integer)
        expect(exp[:id].value).to eq(1)
        expect(exp[:extern_id].value).to eq(0x10)
      end

      it 'parses a DER string with a CHOICE' do
        choice = ModelChoice.parse(CHOICE_INTEGER)
        expect(choice.chosen).to eq(0)
        expect(choice[:id].value).to eq(16)
        expect(choice.chosen_value).to eq(16)

        choice = ModelChoice.parse(CHOICE_SEQUENCE)
        expect(choice.chosen).to eq(1)
        expect(choice[:a_record][:id].value).to eq(65_537)
        expect(choice[:a_record][:room].value).to eq(43)
        expect(choice[:a_record][:house].value).to eq(0x1234)
      end
    end

    describe 'delegation' do
      it 'example 1: delegation to Sequence#value' do
        model = ModelTest.new
        expect(model.value).to be_a(Array)
        expect(model.value.first).to be_a(Types::Integer)
      end

      it 'example2: delegation to Choice#chosen' do
        model = ModelChoice.new
        model.chosen = 1
        expect(model[:choice].chosen).to eq(1)
        expect(model.chosen_value).to be_a(ModelTest)
      end
    end

    context 'complex example' do
      it 'may parse a X.509 certificate' do
        der = File.read(File.join(__dir__, 'cert_example.der')).b
        cert = RASN1Test::X509Example::X509Certificate.parse(der)
        expect(cert[:tbsCertificate][:version].value).to eq(:v3)
        expect(cert[:tbsCertificate][:serialNumber].value).to eq(0x123456789123456789)
        validity = [0x17, 0x0d, 0x31, 0x37, 0x30, 0x38, 0x30, 0x37, 0x31, 0x33, 0x30,
                    0x36, 0x30, 0x30, 0x5a, 0x17, 0x0d, 0x31, 0x38, 0x30, 0x38, 0x30,
                    0x37, 0x31, 0x33, 0x30, 0x36, 0x30, 0x30, 0x5a].pack('C*')
        expect(cert[:tbsCertificate][:validity].value).to eq(validity)
        expect(cert[:tbsCertificate][:issuerUniqueID].value).to be(nil)
        expect(cert[:tbsCertificate][:subjectUniqueID].value).to be(nil)
        expect(cert[:tbsCertificate][:extensions].value.size).to eq(4)
        expect(cert[:signatureValue].value).to eq(der[0x1b6, 128])

        issuer = cert[:tbsCertificate][:issuer].to_h
        expect(issuer[:rdnSequence][0][0][:value]).to eq("\x13\x03org".b)
      end

      it 'may generate a X.509 certificate' do
        der = File.read(File.join(__dir__, 'cert_example.der')).b
        cert = RASN1Test::X509Example::X509Certificate.parse(der)
        expect(cert.to_der).to eq(der)
      end

      it 'may directly access an inner element' do
        der = File.read(File.join(__dir__, 'cert_example.der')).b
        cert = RASN1Test::X509Example::X509Certificate.parse(der)

        expect(cert.value(:version)).to eq(:v3)
        expect(cert.value(:serialNumber)).to eq(0x123456789123456789)
        expect(cert.value(:issuer, 0, 0, :type)).to eq('2.5.4.46')
        expect(cert.value(:issuer, 0, 0, :value)).to eq("\x13\x03org".b)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
