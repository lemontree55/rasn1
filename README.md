[![Gem Version](https://badge.fury.io/rb/rasn1.svg)](https://badge.fury.io/rb/rasn1)

# Rasn1

Rasn1 is a ruby ASN.1 library to encode, parse and decode ASN.1 data in DER format.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rasn1'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install rasn1

## Simple usage

To decode a DER/BER string without checking a model, do:

```ruby
decoded_der = RASN1.parse(der_string)
decoded_ber = RASN1.parse(ber_string, ber: true)
```

## Advanced usage
All examples below will be based on:

```
Record ::= SEQUENCE {
  id        INTEGER,
  room  [0] INTEGER OPTIONAL,
  house [1] INTEGER DEFAULT 0
}

ComplexRecord ::= SEQUENCE {
  bool      BOOLEAN,
  data  [0] EXPLICIT OCTET STRING,
  a_record  Record
}
```

### Create a ASN.1 model

```ruby
class Record < RASN1::Model
  sequence :record,
           content: [integer(:id),
                     integer(:room, implicit: 0, optional: true),
                     integer(:house, implicit: 1, default: 0)]
end
```

More comple classes may be designed by nesting simple classes. For example:

```ruby
class ComplexRecord < RASN1::Model
  sequence :cplx_record,
           content: [boolean(:bool),
                     octet_string(:data, explicit: 0),
                     model(:a_record, Record)]
end
```

### Parse a DER-encoded string
```ruby
record = Record.parse(der_string)
record[:id]             # => RASN1::Types::Integer
record[:id].value       # => Integer
record[:id].to_i        # => Integer
record[:id].asn1_class  # => Symbol
record[:id].optional?   # => false
record[:id].default     # => nil
record[:room].optional  # => true
record[:house].default  # => 0

record[:id].to_der      # => String

cplx_record = ComplexRecord.parse(der_string)
cplx_record[:bool]            # => RASN1::Types::Boolean
cplx_record[:bool].value      # => TrueClass/FalseClass
cplx_record[:data].value      # => String
cplx_record[:data].explicit?  # => true
cplx_record[:a_record]        # => Record
```

### Generate a DER-encoded string
```ruby
record = Record.new(id: 12)
record[:id].to_i      # => 12
record[:room]         # => nil
record[:house]        # => 0

# Set one value
record[:room] = 43
record[:room]         # => 43

# Set mulitple values
record.set id: 124, house: 155

record.to_der         # => String
```

### More information

see https://github.com/sdaubert/rasn1/wiki

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sdaubert/rasn1.
