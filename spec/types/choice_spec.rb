require_relative '../spec_helper'

module RASN1::Types

  describe Integer do
    describe '.type' do
      it 'gets ASN.1 type' do
        expect(Choice.type).to eq('CHOICE')
      end
    end

    describe '#chosen' do
      let(:choice) { Choice.new }

      it 'sets chosen type' do
        choice.chosen = 42
        expect(choice.chosen).to eq(42)
      end
    end

    context '(chosen value)' do
      before(:each) do
        @choice = Choice.new
        @choice.value = [Integer.new, OctetString.new]
      end

      describe '#set_chosen_value' do
        it 'sets a value to chosen type' do
          @choice.chosen = 0
          @choice.set_chosen_value 45
          expect(@choice.value[0].value).to eq(45)

          @choice.chosen = 1
          @choice.set_chosen_value "abcd"
          expect(@choice.value[1].value).to eq('abcd')
        end

        it 'raises if chosen is not set' do
          expect { @choice.set_chosen_value 45 }.to raise_error(RASN1::ChoiceError)
        end
      end

      describe '#chosen_value' do
        it 'gets value from chosen type' do
          @choice.chosen = 0
          @choice.set_chosen_value 45
          expect(@choice.chosen_value).to eq(45)

          @choice.chosen = 1
          @choice.set_chosen_value "abcd"
          expect(@choice.chosen_value).to eq('abcd')
        end

        it 'raises if chosen is not set' do
          expect { @choice.chosen_value }.to raise_error(RASN1::ChoiceError)
        end
      end

      describe '#to_der' do
        it 'generates DER string corresponding to chosen type' do
          @choice.chosen = 0
          @choice.set_chosen_value 45
          expect(@choice.to_der).to eq(binary("\x02\x01\x2d"))

          @choice.chosen = 1
          @choice.set_chosen_value "abcd"
          expect(@choice.to_der).to eq(binary("\x04\x04abcd"))
        end

        it 'raises if chosen is not set' do
          expect { @choice.to_der }.to raise_error(RASN1::ChoiceError)
        end
      end
    end

    describe '#parse!' do
      before(:each) do
        @choice = Choice.new
        @choice.value = [Integer.new, OctetString.new]
      end

      it 'parses a DER string containing a type from CHOICE' do
        nb_bytes = @choice.parse! "\x04\x03abc"
        expect(@choice.chosen).to eq(1)
        expect(@choice.chosen_value).to eq('abc')
        expect(nb_bytes).to eq(5)

        nb_bytes = @choice.parse! "\x02\x02\x01\x02"
        expect(@choice.chosen).to eq(0)
        expect(@choice.chosen_value).to eq(0x102)
        expect(nb_bytes).to eq(4)
      end

      it 'raises when parsin a DER string which does not contain any type from CHOICE' do
        str = Boolean.new(false).to_der
        expect { @choice.parse! str }.to raise_error(RASN1::ASN1Error, /no type matching/)
      end
    end
  end
end
