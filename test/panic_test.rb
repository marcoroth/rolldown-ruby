# frozen_string_literal: true

require "test_helper"

module Rolldown
  class PanicTest < Minitest::Spec
    test "turns a panic into an exception instead of taking the process down" do
      error = assert_raises(PanicError) { Backend.panic_for_test }

      assert_equal "a deliberate panic", error.message
    end

    test "a panic is an internal error, so rescuing either catches it" do
      assert_raises(InternalError) { Backend.panic_for_test }
      assert_raises(Error) { Backend.panic_for_test }
    end

    test "the process keeps working afterwards" do
      assert_raises(PanicError) { Backend.panic_for_test }

      assert_equal 1, Rolldown.build(input: "test/fixtures/entry.js").chunks.length
    end
  end
end
