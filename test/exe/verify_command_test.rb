require "minitest/autorun"
require "open3"
require "digest"
require "tmpdir"

class VerifyCommandTest < Minitest::Test
  COMMAND = File.expand_path("../../exe/agreement_engine-verify", __dir__)

  def run_check(bytes, hash_value)
    Dir.mktmpdir do |dir|
      path = File.join(dir, "copy.json")
      File.binwrite(path, bytes)
      Open3.capture2e({"BUNDLE_GEMFILE" => nil, "RUBYOPT" => nil}, "ruby", "--disable-gems", COMMAND, path, hash_value)
    end
  end

  def test_the_command_reports_a_match_without_loading_any_app
    bytes = %({"slug":"terms"})

    output, status = run_check(bytes, Digest::SHA256.hexdigest(bytes))

    assert_equal ["The file matches this hash.\n", true], [output, status.success?]
  end

  def test_the_command_reports_a_mismatch_and_fails
    output, status = run_check(%({"slug":"terms"}), "0" * 64)

    assert_equal ["The file does not match this hash.\n", false], [output, status.success?]
  end
end
