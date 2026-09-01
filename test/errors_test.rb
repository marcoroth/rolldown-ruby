# frozen_string_literal: true

require "test_helper"

module Rolldown
  class ErrorsTest < Minitest::Spec
    test "every error is rescuable as one" do
      [OptionError, EncodingError, BuildError, IOError, InternalError, PanicError].each do |klass|
        assert_equal true, klass <= Error
        assert_equal true, klass <= StandardError
      end
    end

    test "a panic is an internal error" do
      assert_equal true, PanicError <= InternalError
    end

    test "the io error is not Ruby's, so rescuing ours does not catch a file problem" do
      refute_equal ::IOError, Rolldown::IOError
      assert_nil Rolldown::IOError <= ::IOError
    end

    test "an option the bundler does not take raises an option error" do
      assert_raises(OptionError) { Rolldown.build(input: "a.js", nonsense: true) }
      assert_raises(OptionError) { Rolldown.build(input: "a.js", output: { nonsense: true }) }
      assert_raises(OptionError) { Rolldown.build(input: "a.js", output: { format: "amd" }) }
    end

    test "a build that produces nothing raises a build error" do
      assert_raises(BuildError) { Rolldown.build(input: "test/fixtures/nope.js") }
    end

    test "writing with nowhere to write raises an io error" do
      assert_raises(Rolldown::IOError) { Rolldown.build(input: "test/fixtures/entry.js").write }
    end

    test "a panic raises a panic error" do
      assert_raises(PanicError) { Backend.panic_for_test }
    end

    test "the backend says which method the extension failed to define" do
      error = assert_raises(NotImplementedError) do
        Module.new { extend Backend::Unavailable }.build("{}")
      end

      assert_equal "Rolldown::Backend.build is defined by the native extension, which did not load", error.message
    end
  end
end
