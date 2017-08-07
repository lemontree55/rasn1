[![Gem Version](https://badge.fury.io/rb/rasn1.svg)](https://badge.fury.io/rb/rasn1)

# Rasn1

Rasn1 will be a ruby ASN.1 library to encode, parse and decode ASN.1 data in DER format.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rasn1'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rasn1

## Usage
All examples below will be based on:

```
Record ::= SEQUENCE {
  id        INTEGER,
  room  [0] INTEGER OPTIONAL,
  house [1] INTEGER DEFAULT 0
}
```

## Create a ASN.1 model

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

## Parse a DER-encoded string
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
```

## Generate a DER-encoded string
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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sdaubert/rasn1.

