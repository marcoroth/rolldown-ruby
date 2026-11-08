# frozen_string_literal: true

require "test_helper"

module Rolldown
  class ModulesTest < Minitest::Spec
    VIRTUAL = File.expand_path("fixtures/virtual", __dir__)

    def build_card(source, others = {})
      Rolldown.build(input: "views/card.scoped.ts", cwd: VIRTUAL, modules: { "views/card.scoped.ts" => source, **others }).entry.code
    end

    test "bundles a module that only exists in memory" do
      result = Rolldown.build(
        input: "herb:entry",
        modules: { "herb:entry" => %(console.log("scoped")) }
      )

      expected = <<~JS
        // herb:entry
        console.log("scoped");
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
        // herb:card
        function bump() {
        \tconsole.log("card");
        }
        // herb:entry
        bump();
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

    test "finds a TypeScript file when the import names no extension" do
      assert_equal <<~JS, build_card(%(import { message } from "../lib/messages"\nconsole.log(message)))
        // views/card.scoped.ts
        console.log("from typescript");
      JS
    end

    test "finds a JavaScript file when the import names no extension" do
      assert_equal <<~JS, build_card(%(import { format } from "../lib/format"\nconsole.log(format)))
        // views/card.scoped.ts
        console.log("from javascript");
      JS
    end

    test "finds the index of a directory" do
      assert_equal <<~JS, build_card(%(import { badge } from "../components/Badge"\nconsole.log(badge)))
        // views/card.scoped.ts
        console.log("from an index");
      JS
    end

    test "still loads an import that names its extension" do
      assert_equal <<~JS, build_card(%(import { message } from "../lib/messages.ts"\nconsole.log(message)))
        // views/card.scoped.ts
        console.log("from typescript");
      JS
    end

    test "drops a type import without looking for the file" do
      assert_equal <<~JS, build_card(%(import type { Nope } from "../lib/nope"\nconst value: Nope = 1\nconsole.log(value)))
        // views/card.scoped.ts
        console.log(1);
      JS
    end

    test "prefers a relative import that names another module in memory" do
      code = build_card(
        %(import { message } from "../lib/messages"\nconsole.log(message)),
        "lib/messages" => %(export const message = "from memory")
      )

      assert_equal <<~JS, code
        // views/card.scoped.ts
        console.log("from memory");
      JS
    end

    test "resolves against cwd, including above it" do
      result = Rolldown.build(
        input: "card.ts",
        cwd: File.join(VIRTUAL, "views"),
        modules: { "card.ts" => %(import { real } from "../real"\nconsole.log(real())) }
      )

      assert_equal [File.join(VIRTUAL, "real.js"), "card.ts"], result.entry.module_ids
    end

    test "resolves against the working directory without cwd" do
      result = Rolldown.build(
        input: "test/fixtures/virtual/views/card.ts",
        modules: { "test/fixtures/virtual/views/card.ts" => %(import { real } from "../real"\nconsole.log(real())) }
      )

      assert_equal [File.join(VIRTUAL, "real.js"), "test/fixtures/virtual/views/card.ts"], result.entry.module_ids
    end

    test "raises on a relative import that is nowhere" do
      error = assert_raises(BuildError) { build_card(%(import "../lib/nope")) }

      assert_equal "[UNRESOLVED_IMPORT]", error.message[/\A\[[A-Z_]+\]/]
    end

    test "leaves a name it does not know external, and warns" do
      result = Rolldown.build(input: "herb:entry", modules: { "herb:entry" => %(import "nope"\nfoo()) })

      assert_equal ["UNRESOLVED_IMPORT"], result.warnings.map(&:kind)
      assert_equal %(import "nope";\n// herb:entry\nfoo();\n), result.entry.code
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
