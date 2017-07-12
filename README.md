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

```
Record ::= SEQUENCE {
  id        INTEGER,
  room  [0] INTEGER OPTIONAL,
  house [1] INTEGER DEFAULT 0
}
```

## Create a ASN.1 model

```ruby
class Record < Rasn1::Model

  set_model sequence(integer(:id),
                     integer(:room, class: :contex, optional: true),
		     integer(:house, class: :contex, default: 0))
end
                           
```

## Parse a DER-encoded string
```ruby
record = Record.parse(der_string)
record[:id]             # => Rasn1::Types::Integer
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

record.set :room, 43
record[:room]         # => 43

record.to_der         # => String
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sdaubert/rasn1.

