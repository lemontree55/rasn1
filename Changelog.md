# Rasn1 Changelog

## 0.7.0

* add RASN1::Model#value to get value of a (potentially nested) element.
* add RASN1::Types::Sequence#[]. Access to element by index or by name.
* add frozen_string literal on all ruby files.
* optimize RASN1::Types.tag2type.
* refactoring of RASN1::Types::Base and RASN1::Types::Boolean.
* fix bugs:
  * RASN1::Types::Base#initialize_copy raises on ruby 2.3 when @value and/or @default were nil, true, false of Integer.
