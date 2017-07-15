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
                       ModelTest]
  end                     
             

  describe Model do
    describe '#initialize' do
      it 'creates a class from a Model' do
        expect { ModelTest.new }.to_not raise_error
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
        test2[:record][:id].value = 12
        test2[:record][:house].value = 1
        expect(test2.to_h).to eq({ record2: { rented: true,
                                              record:
                                                { id: 12, house: 1 }
                                            }
                                 })
      end
    end
  end
end
