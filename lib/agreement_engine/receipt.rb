# frozen_string_literal: true

module AgreementEngine
  module Receipt
    module_function

    def byte_form(acceptance)
      copy = acceptance.document.frozen_copy
      ByteForm.encode(slug: copy["slug"], number: copy["number"], document: copy["document"], values: copy["values"] || {})
    end
  end
end
