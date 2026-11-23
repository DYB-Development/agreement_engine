require "test_helper"

class ReadingTimeTest < ActionDispatch::IntegrationTest
  setup do
    @registered = AgreementEngine.config.document_types
    AgreementEngine.config.document_types = [
      AgreementEngine::DocumentType.new(key: :terms_of_service, title: "Terms Of Service", kind: :standing, strength: :click_accept, prompts: true, reading: {seconds: 30})
    ]
    @terms = AgreementEngine::Document.create!(document_type: "terms_of_service", version: "1.0", content: "Terms content", effective_at: 2.days.ago)
    @user = User.create!(name: "Test User", email: "test@example.com")
    sign_in @user
  end

  teardown do
    AgreementEngine.config.document_types = @registered
  end

  test "an acceptance sent sooner than the minimum time is not recorded" do
    get agreement_engine.agreement_path(:terms_of_service)
    patch agreement_engine.agreement_path(:terms_of_service)

    assert_not AgreementEngine::Acceptance.exists?(signer: @user, document: @terms)
  end

  test "an early acceptance shows the accept page again with the reason" do
    get agreement_engine.agreement_path(:terms_of_service)
    patch agreement_engine.agreement_path(:terms_of_service)

    assert_includes response.body, "Read the Terms Of Service for at least 30 seconds before accepting."
  end

  test "an acceptance sent when the accept page was never served is refused with the reason" do
    patch agreement_engine.agreement_path(:terms_of_service)

    assert_includes response.body, "Read the Terms Of Service for at least 30 seconds before accepting."
  end

  test "an acceptance sent after the minimum time is recorded" do
    get agreement_engine.agreement_path(:terms_of_service)
    travel 30.seconds
    patch agreement_engine.agreement_path(:terms_of_service)

    assert AgreementEngine::Acceptance.exists?(signer: @user, document: @terms)
  end

  test "reloading the accept page does not restart the time already counted" do
    get agreement_engine.agreement_path(:terms_of_service)
    travel 20.seconds
    get agreement_engine.agreement_path(:terms_of_service)
    travel 10.seconds
    patch agreement_engine.agreement_path(:terms_of_service)

    assert AgreementEngine::Acceptance.exists?(signer: @user, document: @terms)
  end

  test "time spent on an earlier version does not count toward a newly issued version" do
    get agreement_engine.agreement_path(:terms_of_service)
    travel 60.seconds
    terms_v2 = AgreementEngine::Document.create!(document_type: "terms_of_service", version: "2.0", content: "Terms v2 content", effective_at: Time.current)
    patch agreement_engine.agreement_path(:terms_of_service)

    assert_not AgreementEngine::Acceptance.exists?(signer: @user, document: terms_v2)
  end

  test "the acceptance keeps the minimum time that applied and the seconds the server measured" do
    get agreement_engine.agreement_path(:terms_of_service)
    travel 42.seconds
    patch agreement_engine.agreement_path(:terms_of_service)

    assert_equal({"minimum_seconds" => 30, "measured_seconds" => 42}, AgreementEngine::Acceptance.find_by(signer: @user, document: @terms).reading)
  end

  test "declining is not held back by the minimum reading time" do
    get agreement_engine.agreement_path(:terms_of_service)
    delete agreement_engine.agreement_path(:terms_of_service)

    assert_redirected_to "/"
  end

  test "the accept page holds the accept button for the minimum reading time" do
    get agreement_engine.agreement_path(:terms_of_service)

    assert_select "[data-controller=reading-hold][data-reading-hold-seconds-value='30'] button[data-reading-hold-target=button]", text: "I Accept"
  end
end
