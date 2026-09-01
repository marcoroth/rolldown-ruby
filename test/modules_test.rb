# frozen_string_literal: true

require "test_helper"

module Rolldown
  class ModulesTest < Minitest::Spec
    test "bundles a module that only exists in memory" do
      result = Rolldown.build(
        input: "herb:entry",
        modules: { "herb:entry" => %(console.log("scoped")) }
      )

      expected = <<~JS
        //#region herb:entry
        console.log("scoped");
        //#endregion
      JS

      assert_equal expected, result.entry.code
    end

    test "resolves an import between two modules in memory" do
      result = Rolldown.build(
        input: "herb:entry",
        modules: {
          "herb:entry" => %(import { bump } from "herb:card"\nbump()),
          "herb:card" => %(export function bump() { console.log("card") }),
        }
      )

      expected = <<~JS
        //#region herb:card
        function bump() {
        \tconsole.log("card");
        }
        //#endregion
        //#region herb:entry
        bump();
        //#endregion
      JS

      assert_equal expected, result.entry.code
    end

    test "resolves a relative import out of a module in memory" do
      entry = File.expand_path("fixtures/virtual/entry.js", __dir__)
      result = Rolldown.build(
        input: entry,
        modules: { entry => %(import { real } from "./real.js"\nconsole.log(real())) }
      )

      assert_equal 2, result.entry.module_ids.length
      assert_equal true, result.entry.code.include?("from a real file")
    end

    test "leaves a name it does not know external, and warns" do
      result = Rolldown.build(input: "herb:entry", modules: { "herb:entry" => %(import "nope"\nfoo()) })

      assert_equal ["UNRESOLVED_IMPORT"], result.warnings.map(&:kind)
      assert_equal %(import "nope";\n//#region herb:entry\nfoo();\n//#endregion\n), result.entry.code
    end

    test "raises on that warning under strict" do
      error = assert_raises(BuildError) do
        Rolldown.build(input: "herb:entry", modules: { "herb:entry" => %(import "nope") }, strict: true)
      end

      assert_equal "[UNRESOLVED_IMPORT]", error.message[/\A\[[A-Z_]+\]/]
    end

    test "adds no plugin when nothing is passed" do
      result = Rolldown.build(input: "test/fixtures/entry.js")

      assert_equal 1, result.chunks.length
    end

    test "refuses a module source that is not a string" do
      error = assert_raises(OptionError) { Rolldown.build(input: "a", modules: { "a" => 1 }) }

      assert_equal true, error.message.start_with?("invalid type: integer")
    end
  end
end
