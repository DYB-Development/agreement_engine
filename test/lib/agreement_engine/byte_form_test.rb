require "test_helper"

class AgreementEngine::ByteFormTest < ActiveSupport::TestCase
  test "the same content gives the same bytes whatever order its keys were written in" do
    first = AgreementEngine::ByteForm.encode(slug: "terms", number: 1, document: {"title" => "Terms", "rows" => [{"b" => 1, "a" => 2}]})
    second = AgreementEngine::ByteForm.encode(slug: "terms", number: 1, document: {"rows" => [{"a" => 2, "b" => 1}], "title" => "Terms"})

    assert_equal first, second
  end
end
