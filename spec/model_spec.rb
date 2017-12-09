require 'spec_helper'

module RASN1

  class ModelTest < Model
    sequence :record,
             content: [integer(:id),
                       integer(:room, implicit: 0, optional: true),
                       integer(:house, explicit: 1, default: 0)]
  end

  class ModelTest2 < Model
    sequence :record2,
             content: [boolean(:rented),
                       model(:a_record, ModelTest)]
  end

  class ModelTest3 < ModelTest
    root_options implicit: 4
  end

  class OfModel < Model
    sequence_of :seqof, ModelTest
  end

  class VoidSeq < Model
    sequence :voidseq
  end

  class VoidSeq2 < Model
    sequence :voidseq2,
             content: [boolean(:bool), sequence(:seq)]
  end

  class ModelChoice < Model
    choice :choice,
           content: [integer(:id),
                     model(:a_record, ModelTest)]
  end

  SIMPLE_VALUE = "\x30\x0e\x02\x03\x01\x00\x01\x80\x01\x2b\x81\x04\x02\x02\x12\x34".force_encoding('BINARY')
  OPTIONAL_VALUE = "\x30\x0b\x02\x03\x01\x00\x01\x81\x04\x02\x02\x12\x34".force_encoding('BINARY')
  DEFAULT_VALUE = "\x30\x08\x02\x03\x01\x00\x01\x80\x01\x2b".force_encoding('BINARY')
  NESTED_VALUE = "\x30\x0d\x01\x01\xff\x30\x08\x02\x03\x01\x00\x01\x80\x01\x2b".force_encoding('BINARY')
  ERRORED_VALUE = "\x01\x01\x00"

  describe Model do
    describe '.root_options' do
      let(:model) { ModelTest3.new }

      it 'updates root options from a super class' do
        classical_model = ModelTest.new
        expect(classical_model.tag).to eq(0x30)
        expect(model.tag).to eq(0xa4)
      end

      it 'does not update other elements' do
        expect(model[:id].tag).to eq(0x02)
      end
    end

    describe '#initialize' do
      it 'creates a class from a Model' do
        expect { ModelTest.new }.to_not raise_error
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
                                                { id: 12, house: 1 }
                                            }
                                 })
      end

      it 'generates a Hash image of a model with a SequenceOf' do
        model = OfModel.new
        model[:seqof] << { id: 1, house: 1 }
        model[:seqof] << { id: 2, house: 1 }
        expect(model.to_h).to eq({ seqof: [{ id: 1, house: 1 },
                                           { id: 2, house: 1 }]
                                 })
      end
    end

    describe '#to_der' do
      it 'generates a DER string from a simple model' do
        test = ModelTest.new(id: 65537, room: 43, house: 0x1234)
        expect(test.to_der).to eq(SIMPLE_VALUE)
      end

      it 'generates a DER string from a simple model, without optional value' do
        test = ModelTest.new(id: 65537, house: 0x1234)
        expect(test.to_der).to eq(OPTIONAL_VALUE)
      end

      it 'generates a DER string from a simple model, without default value' do
        test = ModelTest.new(id: 65537, room: 43)
        expect(test.to_der).to eq(DEFAULT_VALUE)
      end
      it 'generates a DER string from a nested model' do
        test2 = ModelTest2.new(rented: true, a_record: { id: 65537, room: 43 })
        expect(test2.to_der).to eq(NESTED_VALUE)
      end
    end

    describe '.parse' do
      it 'parses a DER string from a simple model' do
        test = ModelTest.parse(SIMPLE_VALUE)
        expect(test[:id].value).to eq(65537)
        expect(test[:room].value).to eq(43)
        expect(test[:house].value).to eq(0x1234)
      end

      it 'parses a DER string from a simple model, optional value being not present' do
        test = ModelTest.parse(OPTIONAL_VALUE)
        expect(test[:id].value).to eq(65537)
        expect(test[:room].value).to eq(nil)
        expect(test[:house].value).to eq(0x1234)
      end

      it 'parses a DER string from a simple model, default value being not present' do
        test = ModelTest.parse(DEFAULT_VALUE)
        expect(test[:id].value).to eq(65537)
        expect(test[:room].value).to eq(43)
        expect(test[:house].value).to eq(0)
      end

      it 'parses a DER string from a nested model' do
        test2 = ModelTest2.parse(NESTED_VALUE)
        expect(test2.to_h).to eq(record2: { rented: true,
                                            a_record: { id: 65537,
                                                        room: 43,
                                                        house: 0 }
                                          })
      end

      it 'parses a DER string with a model containing a void SEQUENCE' do
        voidseq = VoidSeq.parse(SIMPLE_VALUE)
        expect(voidseq[:voidseq].value).to eq(SIMPLE_VALUE[2, SIMPLE_VALUE.length])

        voidseq2 = VoidSeq2.parse(NESTED_VALUE)
        expect(voidseq2[:seq].value).to eq(NESTED_VALUE[7..-1])
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
      class AttributeTypeAndValue < Model
        sequence :attributeTypeAndValue,
                 content: [objectid(:type),
                           any(:value)]
      end

      class AlgorithmIdentifier < Model
        sequence :algorithmIdentifier
      end

      class RelativeDN < Model
        set_of :relativeDN, AttributeTypeAndValue
      end

      class X509Name < Model
        sequence_of :rdnSequence, RelativeDN
      end

      class Extension < Model
        sequence :extension,
                 content: [objectid(:extnID),
                           boolean(:critical, default: false),
                           octet_string(:extnValue)]
      end

      class TBSCertificate < Model
        sequence :tbsCertificate,
                 content: [enumerated(:version, explicit: 0, constructed: true,
                                      enum: { 'v1' => 0, 'v2' => 1, 'v3' => 2 },
                                      default: 'v1'),
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

      class X509Certificate < Model
        sequence :certificate,
                 content: [model(:tbsCertificate, TBSCertificate),
                           model(:signatureAlgorithm, AlgorithmIdentifier),
                           bit_string(:signatureValue)]
      end

      it 'may parse a X.509 certificate' do
        der = binary(File.read(File.join(__dir__, 'cert_example.der')))
        cert = X509Certificate.parse(der)
        expect(cert[:tbsCertificate][:version].value).to eq('v3')
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
        expect(issuer[:rdnSequence][0][0][:value]).to eq(binary("\x13\x03org"))
      end

      it 'may generate a X.509 certificate' do
        der = binary(File.read(File.join(__dir__, 'cert_example.der')))
        cert = X509Certificate.parse(der)
        expect(cert.to_der).to eq(der)
      end
    end
  end
end
