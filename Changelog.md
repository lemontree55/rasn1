# Changelog

## 0.9.0 - 2021-12-27

### Changed

* API break: Types::Base#initialize needs `:value` option to set a value. Setting a
  value as first argument is no more supported.
* Types::Base#inspect: add information about ASN.1 class and about tagged value.
* Types::Base: change how type without set value is handled internaly. Add #void_value to define 'value' when no value is set (to always have a well-defined type).
* Model: use a private class Elem instead of an array to define model's root.
* Model: simplify code.
* Types::Integer#enum is always a Hash.

### Fixed

* Fix Types::Utf8String#der_to_value by setting @value.
* Fix some minor issues due to type handling (Types::Base, Types::BitString,
  Types::GeneralizedTime, Types::ObjectIf, Types::Sequence and Types::SequenceOf)
* Types::Constructed#inspect: always show optional fields

## 0.8.0 - 2020-12-04

### Added

* Add support for multi-byte types. This breaks API on minor methods (mainly
  Types::Base#tag removed, partly replaced by Types::Base#id, Types.tag2type renamed into Types.id2type).

### Changed

* Speed up Model#value when accessing a nested element value.
* Speed up and simplify Types::ObjectID#der_to_value.
* Clean up and refactor code.

### Removed

* Remove support for Ruby 2.3.

## 0.7.1 - 2019-11-11

### Changed

* Update bundler dependency: now support bundler 2.0.

## 0.7.0 - 2019-11-11

### Added

* Add RASN1::Model#value to get value of a (potentially nested) element.
* Add RASN1::Types::Sequence#[]. Access to element by index or by name.

### Changed

* Optimize RASN1::Types.tag2type.
* Refactoring of RASN1::Types::Base and RASN1::Types::Boolean.

### Fixed

* Add frozen_string literal on all ruby files.
* RASN1::Types::Base#initialize_copy raises on ruby 2.3 when @value and/or @default were nil, true, false of Integer.
