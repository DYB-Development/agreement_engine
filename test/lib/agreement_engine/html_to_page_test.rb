require "test_helper"

class AgreementEngine::HtmlToPageTest < ActiveSupport::TestCase
  def elements_of(html)
    AgreementEngine::HtmlToPage.convert(html).document["sections"][0]["rows"][0]["columns"][0]["elements"].map { |element| [element["key"], element["fields"]] }
  end

  test "headings, paragraphs with links, bold and italic text, and lists are carried over" do
    assert_equal [
      ["heading", {"text" => "Terms", "size" => "lg"}],
      ["paragraph", {"text" => {"html" => "<p>Be <strong>kind</strong>, see <a href=\"https://example.com\">this</a> and <em>that</em>.</p>"}}],
      ["legal_list", {"style" => "bulleted", "items" => [{"text" => "One"}, {"text" => "Two"}]}],
      ["legal_list", {"style" => "numbered", "items" => [{"text" => "First"}]}]
    ], elements_of("<div class=\"trix-content\"><h1>Terms</h1><div>Be <strong>kind</strong>, see <a href=\"https://example.com\">this</a> and <em>that</em>.</div><ul><li>One</li><li>Two</li></ul><ol><li>First</li></ol></div>")
  end
end
