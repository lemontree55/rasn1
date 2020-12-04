# Rasn1 Changelog

## 0.8.0

* Add support for multi-byte types. This breaks API on minor methods (mainly
  Types::Base#tag removed, partly replaced by Types::Base#id, Types.tag2type renamed into Types.id2type).
* Speed up Model#value when accessing a nested element value.
* Speed up and simplify Types::ObjectID#.
* Remove support for Ruby 2..
* Clean up and refactor code.

## 0.7.1

* Update bundler dependency: now support bundler 2.0.

## 0.7.0

* Add RASN1::Model#value to get value of a (potentially nested) element.
* Add RASN1::Types::Sequence#[]. Access to element by index or by name.
* Add frozen_string literal on all ruby files.
* Optimize RASN1::Types.tag2type.
* Refactoring of RASN1::Types::Base and RASN1::Types::Boolean.
* Fix bugs:
  * RASN1::Types::Base#initialize_copy raises on ruby 2.3 when @value and/or @default were nil, true, false of Integer.
