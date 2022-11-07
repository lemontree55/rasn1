# frozen_string_literal: true

begin
  require 'simplecov'
  SimpleCov.start do
    add_filter '/spec/'
    add_filter '/vendor/'
  end
rescue LoadError
  nil
end

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'rasn1'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }
#
# RSpec.configure do |config|
#   config.include Binary
# end

module TestModel
  class ModelTest < RASN1::Model
    sequence :record,
             content: [integer(:id),
                       integer(:room, implicit: 0, optional: true),
                       integer(:house, explicit: 1, default: 0)]
  end

  class ConstructedModelTest < RASN1::Model
    sequence :record,
             content: [integer(:id, constructed: true),
                       integer(:room, implicit: 0, constructed: true, optional: true),
                       integer(:house, explicit: 1, constructed: true, default: 0)]
  end

  class ModelTest2 < RASN1::Model
    sequence :record2,
             content: [boolean(:rented),
                       model(:a_record, ModelTest)]
  end

  class ModelTest3 < ModelTest
    root_options implicit: 4
  end

  class OfModel < RASN1::Model
    sequence_of :seqof, ModelTest
  end

  class SuperOfModel < RASN1::Model
    sequence :super,
             content: [model(:of, OfModel)]
  end

  class VoidSeq < RASN1::Model
    sequence :voidseq
  end

  class VoidSeq2 < RASN1::Model
    sequence :voidseq2,
             content: [boolean(:bool), sequence(:seq)]
  end

  class ModelChoice < RASN1::Model
    choice :choice,
           content: [integer(:id),
                     model(:a_record, ModelTest)]
  end

  class ImplicitModelChoice < RASN1::Model
    choice :choice,
           content: [integer(:id, class: :application, implicit: 0),
                     wrapper(model(:a_record, ModelTest), class: :application, implicit: 1)]
  end

  class NestedModelChoice < RASN1::Model
    sequence :seq,
           content: [octet_string(:os),
                     choice(:first_choice,
                            content: [integer(:int, class: :application, implicit: 2),
                                      sequence(:more, class: :application, implicit: 3,
                                               content: [model(:nested_choice, ImplicitModelChoice)])
                                     ])
                    ]
  end

  class ExplicitTaggedSeq < RASN1::Model
    sequence :seq, explicit: 0, class: :application,
                   content: [integer(:id), integer(:extern_id)]
  end

  class ModelExplicitBitString < RASN1::Model
    sequence :bit_string,
             content: [bit_string(:flags, explicit: 0, constructed: true, bit_length: 32)]
  end

  class ModelWithImplicitWrapper < RASN1::Model
    sequence :seq,
             content: [wrapper(model(:a_record, ModelTest3), implicit: 5)]
  end

  class ModelWithExplicitWrapper < RASN1::Model
    sequence :seq,
             content: [wrapper(model(:a_record, ModelTest3), explicit: 6)]
  end

  class RecursiveModel < RASN1::Model
    choice :recursive,
           content: [
             octet_string(:present, implicit: 1),
             wrapper(model(:model, RecursiveModel), implicit: 2)
           ]
  end
end
