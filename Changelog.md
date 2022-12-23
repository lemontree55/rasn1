# Changelog

## 0.12.1 - 2022-12-23

### Added

* Add parse tracing capacity.

## 0.12.0 - 2022-11-12

### Added

* In `Model` class, correctly track source location for dynamic class methods, by adfoster-r7.
* In `Model` class, add a check on name uniqueness for embedded types. Raise a `ModelValidationError` on error, by adfoster-r7.
* Add `Wrapper` class to modify options of existing types or models. Add `Model.wrapper` to easily use a wrapper when defining a model, by sdaubert and adfoster-r7.
* Add support for BmpStrings (class `Types::BmpString`).

### Changed

* Rake tasks may be launched before needing presence of yard.
* `Types::Base#value?` and `#can_build?` are now public methods.
* `Types.define_type` may now create the new type in given module (`in_module` parameter).
* A model name may be changed using `Model.root_options`.

### Fixed

* Fix a frozen string crash in `Types::BitString` class, by adfoster-r7.
* Fix a crash in `Types::BitString#to_der` when a Bit String is defined as an explicit one, by adfoster-r7.
* `Types::GeneralizedTime`: parsed value is now always a `Time` and no more sometimes a `DateTime`.
* `Types::Sequence` and `Types::SequenceOf` DER is no more generated when optional and value is void.
* Fix `Model#to_h` for choice subelement, by adfoster-r7.

## 0.11.0 - 2022-10-13

### Added

* Add custom types. A custom type is an ASN.1 type with a custom name. Furthermore, a custom type may be constrained.

### Fixed

* Fix Model doc: specify each element in a model must have a unique name.

## 0.10.0 - 2022-03-11

### Changed

* API break: behavior change of `Types::SequenceOf#<<` when it is a sequence of primitives (in ASN.1 context). Now, `#<<` acts as `Array#<<` by appending only one item to the sequence. It accepts either a primitive type object or its ruby equivalent one.

### Fixed

* Fix `Types::Sequence#[]` when indexing with an integer. It always returned nil.

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

### Removed

* Remove support for Ruby 2.4.

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
