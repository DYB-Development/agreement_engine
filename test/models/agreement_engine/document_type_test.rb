require "test_helper"

class AgreementEngine::DocumentTypeTest < ActiveSupport::TestCase
  setup do
    @registered = AgreementEngine.config.document_types
  end

  teardown do
    AgreementEngine.config.document_types = @registered
  end

  test "a host registers a document type with a key, title, kind and strength" do
    nda = AgreementEngine::DocumentType.new(key: :nda, title: "Mutual NDA", kind: :standing, strength: :click_accept)
    AgreementEngine.config.document_types = [nda]

    assert_equal nda, AgreementEngine.document_type(:nda)
  end

  test "a host that still sets the old agreement list gets an error naming its replacement" do
    error = assert_raises(ArgumentError) { AgreementEngine.config.agreements = [] }

    assert_includes error.message, "config.document_types"
  end

  test "a host marks a document type as needing a signature by setting its strength" do
    assert AgreementEngine::DocumentType.new(key: :sow, title: "Statement of work", kind: :standing, strength: :signature).signature?
  end

  test "a host registers a per-record type naming the template page it is filled from" do
    plan = AgreementEngine::DocumentType.new(key: :plan_sign_off, title: "Plan sign-off", kind: :per_record, strength: :signature, template: "plan-sign-off")

    assert_equal "plan-sign-off", plan.template
  end

  test "a reading requirement with an unknown setting is refused with a message naming the type and the setting" do
    error = assert_raises(ArgumentError) { AgreementEngine::DocumentType.new(key: :nda, title: "Mutual NDA", kind: :standing, strength: :click_accept, reading: {secs: 30}) }

    assert_equal "Document type nda has an unknown reading setting: secs.", error.message
  end

  test "a minimum reading time of zero seconds is refused with a message naming the type" do
    error = assert_raises(ArgumentError) { AgreementEngine::DocumentType.new(key: :nda, title: "Mutual NDA", kind: :standing, strength: :click_accept, reading: {seconds: 0}) }

    assert_equal "Document type nda needs its minimum reading time as a positive whole number of seconds.", error.message
  end

  test "a minimum reading time given as a fraction of a second is refused" do
    assert_raises(ArgumentError) { AgreementEngine::DocumentType.new(key: :nda, title: "Mutual NDA", kind: :standing, strength: :click_accept, reading: {seconds: 2.5}) }
  end

  test "an open requirement on a per-record type is refused because per-record documents have no public page" do
    error = assert_raises(ArgumentError) { AgreementEngine::DocumentType.new(key: :quote, title: "Quote", kind: :per_record, strength: :click_accept, template: "quote", reading: {open: true}) }

    assert_equal "Document type quote cannot require opening, because per-record documents have no public page.", error.message
  end

  test "a host registers a type that requires scrolling to the end" do
    assert AgreementEngine::DocumentType.new(key: :nda, title: "Mutual NDA", kind: :standing, strength: :click_accept, reading: {scroll: true}).requires_scroll?
  end
end
