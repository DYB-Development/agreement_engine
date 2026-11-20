# frozen_string_literal: true

require "nokogiri"
require "securerandom"

module AgreementEngine
  module HtmlToPage
    Result = Data.define(:document, :left_out)

    HEADINGS = %w[h1 h2 h3 h4 h5 h6].freeze
    HEADING_SIZES = {"h1" => "lg", "h2" => "md"}.freeze
    PARAGRAPHS = %w[p div].freeze
    LISTS = {"ul" => "bulleted", "ol" => "numbered"}.freeze
    INLINE_TAGS = %w[a strong b em i br].freeze

    module_function

    def convert(html)
      elements = []
      left_out = []
      blocks(Nokogiri::HTML5.fragment(html.to_s)).each do |node|
        element = element_for(node)
        element ? elements << element : left_out << node.name
      end
      document = KeystoneUi::Pages::Document.blank
      document["sections"][0]["rows"][0]["columns"][0]["elements"] = elements
      Result.new(document: document, left_out: left_out.uniq)
    end

    def blocks(fragment)
      fragment.children.flat_map do |node|
        next [] if node.text? && node.text.strip.empty?
        next blocks(node) if node.name == "div" && node["class"].to_s.include?("trix-content")

        [node]
      end
    end

    def element_for(node)
      return paragraph(node.to_html) if node.text?
      return heading(node) if HEADINGS.include?(node.name)
      return paragraph(node.inner_html) if PARAGRAPHS.include?(node.name) && node.css("img, table, figure, action-text-attachment").empty?
      list(node) if LISTS.key?(node.name)
    end

    def heading(node)
      element("heading", "text" => node.text.strip, "size" => HEADING_SIZES.fetch(node.name, "sm"))
    end

    def paragraph(inner_html)
      kept = Rails::HTML5::SafeListSanitizer.new.sanitize(inner_html, tags: INLINE_TAGS, attributes: %w[href])
      element("paragraph", "text" => {"html" => "<p>#{kept}</p>"})
    end

    def list(node)
      element("legal_list", "style" => LISTS.fetch(node.name), "items" => node.css("> li").map { |item| {"text" => item.text.strip} })
    end

    def element(key, fields)
      {"id" => SecureRandom.uuid, "key" => key, "fields" => fields}
    end
  end
end
