# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
module RASN2
  describe SchemaParser do
    describe '.parse' do
      context 'with PersonnelModule fixture' do
        let(:schema) { File.read(File.join(__dir__, 'fixtures', 'personal_module.asn')) }
        let(:namespace) { Module.new }
        let(:models) { SchemaParser.parse(schema, namespace: namespace) }

        it 'returns a hash of model classes' do
          expect(models).to be_a(Hash)
          expect(models.keys).to eq(['PersonnelRecord'])
        end

        it 'creates a Model subclass for PersonnelRecord' do
          klass = models['PersonnelRecord']
          expect(klass).to be < RASN2::Model
        end

        it 'defines the class in the given namespace' do
          models
          expect(namespace.const_defined?(:PersonnelRecord)).to be true
          expect(namespace.const_get(:PersonnelRecord)).to eq(models['PersonnelRecord'])
        end

        context 'PersonnelRecord model' do
          let(:klass) { models['PersonnelRecord'] }
          let(:instance) { klass.new }

          it 'has the expected fields' do
            expect(instance.keys).to include(:personnel_record, :name, :title, :age, :employed, :comment)
          end

          it 'has name as PrintableString' do
            expect(instance[:name]).to be_a(Types::PrintableString)
          end

          it 'has title as VisibleString' do
            expect(instance[:title]).to be_a(Types::VisibleString)
          end

          it 'has age as Integer' do
            expect(instance[:age]).to be_a(Types::Integer)
          end

          it 'has employed as Boolean with default TRUE' do
            expect(instance[:employed]).to be_a(Types::Boolean)
            expect(instance[:employed].default).to eq(true)
          end

          it 'has comment as UTF8String and optional' do
            expect(instance[:comment]).to be_a(Types::Utf8String)
            expect(instance[:comment].optional?).to be true
          end

          it 'can be instantiated with values' do
            record = klass.new(name: 'John Doe', title: 'Engineer', age: 30)
            expect(record[:name].value).to eq('John Doe')
            expect(record[:title].value).to eq('Engineer')
            expect(record[:age].value).to eq(30)
          end

          it 'can round-trip DER encode and decode' do
            record = klass.new(name: 'John', title: 'Dev', age: 25)
            der = record.to_der

            parsed = klass.parse(der)
            expect(parsed[:name].value).to eq('John')
            expect(parsed[:title].value).to eq('Dev')
            expect(parsed[:age].value).to eq(25)
          end
        end
      end

      context 'with a simple SEQUENCE schema' do
        let(:namespace) { Module.new }
        let(:schema) do
          <<~ASN1
            SimpleModule DEFINITIONS ::=
            BEGIN

            SimpleRecord ::= SEQUENCE {
                id    INTEGER,
                flag  BOOLEAN
            }

            END
          ASN1
        end

        it 'parses and creates a model' do
          models = SchemaParser.parse(schema, namespace: namespace)
          expect(models['SimpleRecord']).to be < RASN2::Model

          instance = models['SimpleRecord'].new(id: 42, flag: true)
          expect(instance[:id].value).to eq(42)
          expect(instance[:flag].value).to eq(true)
        end
      end

      context 'with EXPLICIT TAGS' do
        let(:namespace) { Module.new }
        let(:schema) do
          <<~ASN1
            ExplicitModule DEFINITIONS EXPLICIT TAGS ::=
            BEGIN

            ExplicitRecord ::= SEQUENCE {
                value  INTEGER
            }

            END
          ASN1
        end

        it 'parses the module with explicit tags' do
          models = SchemaParser.parse(schema, namespace: namespace)
          expect(models['ExplicitRecord']).to be < RASN2::Model
        end
      end

      context 'with multiple type definitions' do
        let(:namespace) { Module.new }
        let(:schema) do
          <<~ASN1
            MultiModule DEFINITIONS ::=
            BEGIN

            Address ::= SEQUENCE {
                street  PrintableString,
                city    PrintableString
            }

            Person ::= SEQUENCE {
                name     PrintableString,
                age      INTEGER,
                address  Address
            }

            END
          ASN1
        end

        it 'creates models for all definitions' do
          models = SchemaParser.parse(schema, namespace: namespace)
          expect(models.keys).to eq(%w[Address Person])
        end

        it 'supports cross-references between types' do
          models = SchemaParser.parse(schema, namespace: namespace)
          person = models['Person'].new(name: 'Alice', age: 30, address: { street: '123 Main', city: 'NYC' })
          expect(person[:name].value).to eq('Alice')
          expect(person[:address][:street].value).to eq('123 Main')
        end
      end

      context 'with OPTIONAL and DEFAULT fields' do
        let(:namespace) { Module.new }
        let(:schema) do
          <<~ASN1
            DefaultModule DEFINITIONS ::=
            BEGIN

            Config ::= SEQUENCE {
                enabled   BOOLEAN DEFAULT TRUE,
                count     INTEGER DEFAULT 10,
                label     PrintableString OPTIONAL
            }

            END
          ASN1
        end

        it 'handles DEFAULT and OPTIONAL correctly' do
          models = SchemaParser.parse(schema, namespace: namespace)
          instance = models['Config'].new
          expect(instance[:enabled].default).to eq(true)
          expect(instance[:count].default).to eq(10)
          expect(instance[:label].optional?).to be true
        end
      end

      context 'with SET type' do
        let(:namespace) { Module.new }
        let(:schema) do
          <<~ASN1
            SetModule DEFINITIONS ::=
            BEGIN

            MySet ::= SET {
                alpha  INTEGER,
                beta   BOOLEAN
            }

            END
          ASN1
        end

        it 'creates a model with SET root' do
          models = SchemaParser.parse(schema, namespace: namespace)
          instance = models['MySet'].new(alpha: 5, beta: false)
          expect(instance[:alpha].value).to eq(5)
          expect(instance[:beta].value).to eq(false)
        end
      end

      context 'with SEQUENCE OF' do
        let(:namespace) { Module.new }
        let(:schema) do
          <<~ASN1
            SeqOfModule DEFINITIONS ::=
            BEGIN

            Item ::= SEQUENCE {
                id    INTEGER,
                name  PrintableString
            }

            ItemList ::= SEQUENCE OF Item

            END
          ASN1
        end

        it 'creates SEQUENCE OF model referencing another type' do
          models = SchemaParser.parse(schema, namespace: namespace)
          expect(models['ItemList']).to be < RASN2::Model
          expect(models['Item']).to be < RASN2::Model
        end
      end

      context 'with CHOICE type' do
        let(:namespace) { Module.new }
        let(:schema) do
          <<~ASN1
            ChoiceModule DEFINITIONS ::=
            BEGIN

            MyChoice ::= CHOICE {
                number  INTEGER,
                text    PrintableString
            }

            END
          ASN1
        end

        it 'creates a CHOICE model' do
          models = SchemaParser.parse(schema, namespace: namespace)
          expect(models['MyChoice']).to be < RASN2::Model
        end
      end

      context 'with various string types' do
        let(:namespace) { Module.new }
        let(:schema) do
          <<~ASN1
            StringModule DEFINITIONS ::=
            BEGIN

            StringRecord ::= SEQUENCE {
                a  IA5String,
                b  NumericString,
                c  BMPString,
                d  UniversalString,
                e  UTF8String
            }

            END
          ASN1
        end

        it 'maps all string types correctly' do
          models = SchemaParser.parse(schema, namespace: namespace)
          instance = models['StringRecord'].new
          expect(instance[:a]).to be_a(Types::IA5String)
          expect(instance[:b]).to be_a(Types::NumericString)
          expect(instance[:c]).to be_a(Types::BmpString)
          expect(instance[:d]).to be_a(Types::UniversalString)
          expect(instance[:e]).to be_a(Types::Utf8String)
        end
      end

      context 'with invalid schema' do
        it 'raises ParseError for malformed module' do
          expect { SchemaParser.parse('not a valid schema') }
            .to raise_error(SchemaParser::ParseError)
        end

        it 'raises ParseError for unknown types' do
          schema = <<~ASN1
            BadModule DEFINITIONS ::=
            BEGIN

            Bad ::= SEQUENCE {
                field  UnknownType
            }

            END
          ASN1
          expect { SchemaParser.parse(schema) }
            .to raise_error(SchemaParser::ParseError, /Unknown type/)
        end
      end
    end

    describe '.parse_file' do
      it 'parses the personal_module.asn fixture file' do
        namespace = Module.new
        fixture_path = File.join(__dir__, 'fixtures', 'personal_module.asn')
        models = SchemaParser.parse_file(fixture_path, namespace: namespace)
        expect(models.keys).to eq(['PersonnelRecord'])
        expect(models['PersonnelRecord']).to be < RASN2::Model
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
