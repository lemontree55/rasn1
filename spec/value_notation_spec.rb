# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength
module RASN2
  describe ValueNotation do
    let(:schema) { File.read(File.join(__dir__, 'fixtures', 'personal_module.asn')) }
    let(:namespace) { Module.new }
    let(:models) { SchemaParser.parse(schema, namespace: namespace) }

    describe '.parse' do
      context 'with personal_instance.asn fixture' do
        let(:instance_text) { File.read(File.join(__dir__, 'fixtures', 'personal_instance.asn')) }
        let(:record) { ValueNotation.parse(instance_text, models: models) }

        it 'returns a Model instance' do
          expect(record).to be_a(RASN2::Model)
        end

        it 'sets the value name' do
          expect(record.value_name).to eq('myPerson')
        end

        it 'sets the type name' do
          expect(record.type_name).to eq('PersonnelRecord')
        end

        it 'parses string fields correctly' do
          expect(record[:name].value).to eq('John Doe')
          expect(record[:title].value).to eq('Engineer')
        end

        it 'parses integer fields correctly' do
          expect(record[:age].value).to eq(30)
        end

        it 'parses boolean fields correctly' do
          expect(record[:employed].value).to eq(true)
        end
      end

      context 'with inline value notation' do
        it 'parses a simple record' do
          text = <<~ASN1
            myRecord PersonnelRecord ::= {
                name    "Jane Smith",
                title   "Manager",
                age     45,
                employed FALSE
            }
          ASN1
          record = ValueNotation.parse(text, models: models)
          expect(record[:name].value).to eq('Jane Smith')
          expect(record[:title].value).to eq('Manager')
          expect(record[:age].value).to eq(45)
          expect(record[:employed].value).to eq(false)
        end

        it 'handles negative integers' do
          text = <<~ASN1
            myRecord PersonnelRecord ::= {
                name    "Test",
                title   "Dev",
                age     -5,
                employed TRUE
            }
          ASN1
          record = ValueNotation.parse(text, models: models)
          expect(record[:age].value).to eq(-5)
        end

        it 'handles strings with escaped quotes' do
          text = <<~ASN1
            myRecord PersonnelRecord ::= {
                name    "John ""JD"" Doe",
                title   "Dev",
                age     25,
                employed TRUE
            }
          ASN1
          record = ValueNotation.parse(text, models: models)
          expect(record[:name].value).to eq('John "JD" Doe')
        end

        it 'handles optional fields omitted' do
          text = <<~ASN1
            myRecord PersonnelRecord ::= {
                name    "Test",
                title   "Dev",
                age     25
            }
          ASN1
          record = ValueNotation.parse(text, models: models)
          expect(record[:name].value).to eq('Test')
          expect(record[:age].value).to eq(25)
        end
      end

      context 'error handling' do
        it 'raises on invalid format' do
          expect { ValueNotation.parse('garbage', models: models) }
            .to raise_error(ValueNotation::Error, /Invalid value notation format/)
        end

        it 'raises on unknown type' do
          text = 'myVal UnknownType ::= { foo 1 }'
          expect { ValueNotation.parse(text, models: models) }
            .to raise_error(ValueNotation::Error, /Unknown type/)
        end

        it 'raises on unterminated string' do
          text = 'myRecord PersonnelRecord ::= { name "unterminated }'
          expect { ValueNotation.parse(text, models: models) }
            .to raise_error(ValueNotation::Error)
        end
      end
    end

    describe '.parse_file' do
      it 'parses a value notation file' do
        fixture_path = File.join(__dir__, 'fixtures', 'personal_instance.asn')
        record = ValueNotation.parse_file(fixture_path, models: models)
        expect(record[:name].value).to eq('John Doe')
        expect(record[:age].value).to eq(30)
      end
    end

    describe '.emit' do
      it 'generates value notation from a model instance' do
        klass = models['PersonnelRecord']
        record = klass.new(name: 'John Doe', title: 'Engineer', age: 30, employed: true)
        text = ValueNotation.emit(record, name: 'myPerson', type_name: 'PersonnelRecord')
        expect(text).to include('myPerson PersonnelRecord ::= {')
        expect(text).to include('name "John Doe"')
        expect(text).to include('title "Engineer"')
        expect(text).to include('age 30')
        expect(text).to include('employed TRUE')
        expect(text).to end_with("}\n")
      end

      it 'emits FALSE for false boolean values' do
        klass = models['PersonnelRecord']
        record = klass.new(name: 'Test', title: 'Dev', age: 25, employed: false)
        text = ValueNotation.emit(record, name: 'test', type_name: 'PersonnelRecord')
        expect(text).to include('employed FALSE')
      end

      it 'omits optional fields with no value' do
        klass = models['PersonnelRecord']
        record = klass.new(name: 'Test', title: 'Dev', age: 25)
        text = ValueNotation.emit(record, name: 'test', type_name: 'PersonnelRecord')
        expect(text).not_to include('comment')
      end

      it 'escapes quotes in string values' do
        klass = models['PersonnelRecord']
        record = klass.new(name: 'John "JD" Doe', title: 'Dev', age: 25, employed: true)
        text = ValueNotation.emit(record, name: 'test', type_name: 'PersonnelRecord')
        expect(text).to include('name "John ""JD"" Doe"')
      end
    end

    describe 'round-trip' do
      it 'can parse emitted value notation' do
        klass = models['PersonnelRecord']
        original = klass.new(name: 'John Doe', title: 'Engineer', age: 30, employed: true)
        text = ValueNotation.emit(original, name: 'myPerson', type_name: 'PersonnelRecord')
        parsed = ValueNotation.parse(text, models: models)

        expect(parsed[:name].value).to eq('John Doe')
        expect(parsed[:title].value).to eq('Engineer')
        expect(parsed[:age].value).to eq(30)
        expect(parsed[:employed].value).to eq(true)
      end

      it 'can emit parsed value notation' do
        instance_text = File.read(File.join(__dir__, 'fixtures', 'personal_instance.asn'))
        record = ValueNotation.parse(instance_text, models: models)
        text = ValueNotation.emit(record)

        expect(text).to include('myPerson PersonnelRecord ::= {')
        expect(text).to include('name "John Doe"')
        expect(text).to include('age 30')
      end

      it 'round-trips through DER as well' do
        instance_text = File.read(File.join(__dir__, 'fixtures', 'personal_instance.asn'))
        klass = models['PersonnelRecord']
        record = ValueNotation.parse(instance_text, models: models)

        der = record.to_der
        reparsed = klass.parse(der)
        expect(reparsed[:name].value).to eq('John Doe')
        expect(reparsed[:title].value).to eq('Engineer')
        expect(reparsed[:age].value).to eq(30)
      end
    end

    describe 'Model#to_asn1' do
      it 'generates value notation via convenience method' do
        klass = models['PersonnelRecord']
        record = klass.new(name: 'Test', title: 'Dev', age: 25, employed: true)
        text = record.to_asn1(name: 'myVal', type_name: 'PersonnelRecord')
        expect(text).to include('myVal PersonnelRecord ::= {')
        expect(text).to include('name "Test"')
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
