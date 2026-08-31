# frozen_string_literal: true

require "test_helper"

class RolldownTest < Minitest::Spec
  test "has a version number" do
    assert_equal "0.0.1", Rolldown::VERSION
  end

  test "the native library was built from the version the gem was" do
    assert_equal Rolldown::VERSION, Rolldown::Backend.version
  end

  test "reports the version of rolldown it was compiled against" do
    assert_equal "1.2.6", Rolldown.rolldown_version
  end

  test "the version it reports is the one Cargo.lock pins" do
    locked = File.read(File.expand_path("../rust/Cargo.lock", __dir__))[/name = "rolldown"\nversion = "([^"]+)"/, 1]

    assert_equal locked, Rolldown.rolldown_version
  end

  test "rolldown itself is linked in, not stripped by the optimizer" do
    assert_equal "ok", Rolldown::Backend.probe
  end
end
