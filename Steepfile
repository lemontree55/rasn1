# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature 'sig'

  check 'lib'

  library 'delegate'

  configure_code_diagnostics(D::Ruby.all_error)
end
