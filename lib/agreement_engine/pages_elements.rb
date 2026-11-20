# frozen_string_literal: true

module AgreementEngine
  module PagesElements
    module_function

    def register(catalog)
      catalog.register(key: :legal_list, name: "List", component: :agreement_engine_legal_list, icon: :text, group: "Text",
        fields: [{key: :style, label: "Style", kind: :one_of, options: %w[bulleted numbered], default: "bulleted"},
          {key: :items, label: "Items", kind: :list, entry: [{key: :text, label: "Text", kind: :long_text}],
           default: [{"text" => "First item"}, {"text" => "Second item"}]}])
    end
  end
end
