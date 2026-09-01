# frozen_string_literal: true

require "test_helper"

module Rolldown
  class OptionsTest < Minitest::Spec
    ENTRY = "test/fixtures/entry.js" #: String
    GREETING = "test/fixtures/greeting.js" #: String

    test "minifies" do
      code = Rolldown.build(input: GREETING, output: { minify: true }).entry.code

      assert_equal "function e(e){return`hello ${e}`}export{e as greet};", code
    end

    test "eliminates dead code without mangling names" do
      code = Rolldown.build(input: GREETING, output: { minify: "dce-only" }).entry.code

      assert_equal true, code.include?("greet")
      refute_equal Rolldown.build(input: GREETING, output: { minify: true }).entry.code, code
    end

    test "answers a source map only when asked" do
      assert_nil Rolldown.build(input: ENTRY).entry.map
      refute_nil Rolldown.build(input: ENTRY, output: { sourcemap: true }).entry.map
      refute_nil Rolldown.build(input: ENTRY, output: { sourcemap: "inline" }).entry.map
    end

    test "inlines the map into the chunk instead of writing an asset" do
      inline = Rolldown.build(input: ENTRY, output: { sourcemap: "inline" })
      separate = Rolldown.build(input: ENTRY, output: { sourcemap: true })

      assert_equal [], inline.assets.map(&:filename)
      assert_equal ["entry.js.map"], separate.assets.map(&:filename)
    end

    test "leaves an external import alone" do
      result = Rolldown.build(input: "test/fixtures/external.js", external: ["node:fs"])

      assert_equal ["node:fs"], result.entry.imports
    end

    test "folds a define away at build time" do
      result = Rolldown.build(input: "test/fixtures/defined.js", transform: { define: { "IS_PRODUCTION" => "true" } })

      expected = <<~JS
        //#region test/fixtures/defined.js
        console.log("production");
        //#endregion
      JS

      assert_equal expected, result.entry.code
    end

    test "adds a banner and a footer" do
      result = Rolldown.build(input: GREETING, output: { banner: "/* top */", footer: "/* bottom */" })

      expected = <<~JS.chomp
        /* top */
        //#region test/fixtures/greeting.js
        function greet(name) {
        \treturn `hello ${name}`;
        }
        //#endregion
        export { greet };
        /* bottom */
      JS

      assert_equal expected, result.entry.code
    end

    test "names chunks by a pattern" do
      result = Rolldown.build(input: ENTRY, output: { entry_file_names: "[name]-bundle.js" })

      assert_equal "entry-bundle.js", result.entry.filename
    end

    test "refuses a sourcemap kind it does not know" do
      error = assert_raises(OptionError) { Rolldown.build(input: ENTRY, output: { sourcemap: "both" }) }

      assert_equal "Unknown sourcemap: both. Expected true, false, file, inline or hidden.", error.message
    end

    test "says plainly that a JavaScript function cannot cross" do
      error = assert_raises(OptionError) { Rolldown.build(input: ENTRY, plugins: []) }

      assert_equal "plugins takes a JavaScript function, which cannot cross into Ruby. " \
                   "See https://rolldown.rs for what plugins does.", error.message
    end
  end
end
