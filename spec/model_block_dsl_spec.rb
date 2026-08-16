# frozen_string_literal: true

require 'spec_helper'

module BlockDslTest
  class BlockModelTest < RASN2::Model
    sequence :record do
      integer :id
      integer :room, implicit: 0, optional: true
      integer :house, explicit: 1, default: 0
    end
  end

  class BlockModelTest2 < RASN2::Model
    sequence :record2 do
      boolean :rented
      model :a_record, BlockModelTest
    end
  end

  class BlockNestedModel < RASN2::Model
    sequence :root do
      boolean :bool
      sequence :seq do
        integer :int
        octet_string :os
      end
    end
  end

  class BlockOfModel < RASN2::Model
    sequence :super do
      sequence_of :of, BlockModelTest
    end
  end

  class BlockChoiceModel < RASN2::Model
    choice :choice do
      integer :id
      model :a_record, BlockModelTest
    end
  end

  class BlockMixedModel < RASN2::Model
    sequence :mixed, content: [boolean(:bool)] do
      integer :int
    end
  end

  class BlockModelWithWrapperArg < RASN2::Model
    sequence :seq do
      integer :superid
      wrapper(model(:a_record, BlockModelTest), explicit: 6)
    end
  end

  class BlockModelWithWrapperBlock < RASN2::Model
    sequence :seq do
      integer :superid
      wrapper explicit: 6 do
        model :a_record, BlockModelTest
      end
    end
  end

  class BlockWrapperRootModel < RASN2::Model
    wrapper implicit: 5 do
      model :a_record, BlockModelTest
    end
  end

  class BlockObjectIdAndAnyModel < RASN2::Model
    sequence :attributeTypeAndValue do
      objectid :type
      any :value
    end
  end
end

module RASN2
  describe Model do
    context '(content defined through a block)' do
      let(:simple_der) { "\x30\x0e\x02\x03\x01\x00\x01\x80\x01\x2b\x81\x04\x02\x02\x12\x34".b }

      it 'defines the same model as the :content option' do
        expect(BlockDslTest::BlockModelTest.new.to_h).to eq(TestModel::ModelTest.new.to_h)
      end

      it 'generates a DER string' do
        model = BlockDslTest::BlockModelTest.new(id: 65537, room: 43, house: 0x1234)
        expect(model.to_der).to eq(simple_der)
      end

      it 'parses a DER string' do
        model = BlockDslTest::BlockModelTest.parse(simple_der)
        expect(model[:id].value).to eq(65537)
        expect(model[:room].value).to eq(43)
        expect(model[:house].value).to eq(0x1234)
      end

      it 'keeps element order' do
        expect(BlockDslTest::BlockModelTest.new.keys).to eq(TestModel::ModelTest.new.keys)
        expect(BlockDslTest::BlockModelTest.new.keys).to eq(%i[id room house record])
      end

      it 'accepts a nested model' do
        model = BlockDslTest::BlockModelTest2.new(rented: true, a_record: { id: 12 })
        expect(model[:rented].value).to be(true)
        expect(model[:a_record]).to be_a(BlockDslTest::BlockModelTest)
        expect(model.value(:id)).to eq(12)
        expect(model.to_h).to eq({ record2: { rented: true, a_record: { id: 12, house: 0 } } })
      end

      it 'accepts nested blocks' do
        model = BlockDslTest::BlockNestedModel.new(bool: false, int: 1, os: 'abc')
        expect(model.keys).to eq(%i[bool int os seq root])
        expect(model[:seq]).to be_a(Types::Sequence)
        expect(model.to_h).to eq({ root: { bool: false, seq: { int: 1, os: 'abc' } } })
      end

      it 'accepts a sequence_of' do
        model = BlockDslTest::BlockOfModel.new
        expect(model[:of]).to be_a(Types::SequenceOf)
        expect(model[:of].of_type).to eq(BlockDslTest::BlockModelTest)
      end

      it 'accepts a choice' do
        model = BlockDslTest::BlockChoiceModel.parse("\x02\x01\x10".b)
        expect(model[:choice].chosen).to eq(0)
        expect(model[:choice].chosen_value).to eq(16)
      end

      it 'accepts objectid and any' do
        model = BlockDslTest::BlockObjectIdAndAnyModel.new(type: '1.2.3', value: "\x02\x01\x10".b)
        expect(model[:type].value).to eq('1.2.3')
        expect(model[:value]).to be_a(Types::Any)
      end

      it 'appends block content to :content option one' do
        model = BlockDslTest::BlockMixedModel.new(bool: true, int: 42)
        expect(model.keys).to eq(%i[bool int mixed])
        expect(model.to_h).to eq({ mixed: { bool: true, int: 42 } })
      end

      it 'accepts a wrapper defined with an element as argument' do
        model = BlockDslTest::BlockModelWithWrapperArg.new(superid: 1, a_record: { id: 12 })
        expect(model.keys).to eq(%i[superid a_record a_record_wrapper seq])
        expect(model.to_h).to eq({ seq: { superid: 1, a_record: { id: 12, house: 0 } } })
      end

      it 'accepts a wrapper defined with a block' do
        block_model = BlockDslTest::BlockModelWithWrapperBlock.new(superid: 1, a_record: { id: 12 })
        arg_model = BlockDslTest::BlockModelWithWrapperArg.new(superid: 1, a_record: { id: 12 })
        expect(block_model.keys).to eq(arg_model.keys)
        expect(block_model.to_der).to eq(arg_model.to_der)
      end

      it 'accepts a wrapper as root element' do
        model = BlockDslTest::BlockWrapperRootModel.new(id: 12)
        expect(model.root).to be_a(Wrapper)
        expect(model[:a_record]).to be_a(BlockDslTest::BlockModelTest)
      end

      it 'raises on duplicate names' do
        expect do
          Class.new(Model) do
            sequence :seq do
              integer :int
              integer :int
            end
          end
        end.to raise_error(ModelValidationError, 'Duplicate name int found')
      end

      it 'raises when a wrapper block does not define exactly one element' do
        expect do
          Class.new(Model) do
            wrapper implicit: 5 do
              integer :int1
              integer :int2
            end
          end
        end.to raise_error(ModelValidationError, /exactly one element/)
      end
    end
  end
end
