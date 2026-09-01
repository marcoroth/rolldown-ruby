# frozen_string_literal: true

require "test_helper"

module Rolldown
  class BuildTest < Minitest::Spec
    ENTRY = "test/fixtures/entry.js" #: String
    GREETING = "test/fixtures/greeting.js" #: String

    test "bundles an entry point together with what it imports" do
      expected = <<~JS
        //#region test/fixtures/greeting.js
        function greet(name) {
        	return `hello ${name}`;
        }
        //#endregion
        //#region test/fixtures/entry.js
        console.log(greet("world"));
        //#endregion
      JS

      assert_equal expected, Rolldown.build(input: ENTRY, output: { format: "esm" }).entry.code
    end

    test "emits an es module" do
      expected = <<~JS
        //#region test/fixtures/greeting.js
        function greet(name) {
        	return `hello ${name}`;
        }
        //#endregion
        export { greet };
      JS

      assert_equal expected, Rolldown.build(input: GREETING, output: { format: "esm" }).entry.code
    end

    test "emits commonjs" do
      expected = <<~JS
        Object.defineProperty(exports, Symbol.toStringTag, { value: "Module" });
        //#region test/fixtures/greeting.js
        function greet(name) {
        	return `hello ${name}`;
        }
        //#endregion
        exports.greet = greet;
      JS

      assert_equal expected, Rolldown.build(input: GREETING, output: { format: "cjs" }).entry.code
    end

    test "emits an iife" do
      expected = <<~JS
        (function(exports) {
        	Object.defineProperty(exports, Symbol.toStringTag, { value: "Module" });
        	//#region test/fixtures/greeting.js
        	function greet(name) {
        		return `hello ${name}`;
        	}
        	//#endregion
        	exports.greet = greet;
        	return exports;
        })({});
      JS

      assert_equal expected, Rolldown.build(input: GREETING, output: { format: "iife" }).entry.code
    end

    test "answers what it built" do
      result = Rolldown.build(input: ENTRY)

      assert_equal "#<Rolldown::BuildResult chunks=1>", result.inspect
      assert_equal false, result.failed?
      assert_equal false, result.errors?
      assert_equal [], result.assets
      assert_equal [], result.warnings
    end

    test "describes a chunk by what it holds" do
      chunk = Rolldown.build(input: ENTRY).entry

      assert_equal "entry.js", chunk.filename
      assert_equal "entry", chunk.name
      assert_equal true, chunk.entry?
      assert_equal false, chunk.dynamic_entry?
      assert_equal [], chunk.imports
      assert_equal [], chunk.exports
      assert_nil chunk.map
    end

    test "counts every module that went into a chunk" do
      chunk = Rolldown.build(input: ENTRY).entry

      assert_equal 2, chunk.module_ids.length
    end

    test "names a chunk when the entry is named" do
      result = Rolldown.build(input: [{ name: "app", import: ENTRY }])

      assert_equal "app", result.entry.name
      assert_equal "app.js", result.entry.filename
    end

    test "names entries from a hash, the way the JavaScript config does" do
      result = Rolldown.build(input: { app: ENTRY, lib: GREETING })

      assert_equal ["app.js", "lib.js"], result.chunks.map(&:filename).sort
    end

    test "takes more than one entry point" do
      result = Rolldown.build(input: [ENTRY, GREETING])

      assert_equal 2, result.chunks.count(&:entry?)
      assert_equal ["entry.js", "greeting.js"], result.chunks.map(&:filename).sort
    end

    test "builds from several threads at once" do
      expected = Rolldown.build(input: ENTRY).entry.code

      results = 4.times.map {
        Thread.new { 3.times.map { Rolldown.build(input: ENTRY).entry.code } }
      }.flat_map(&:value)

      assert_equal 12, results.length
      assert_equal [expected], results.uniq
    end

    test "refuses a format it does not know" do
      error = assert_raises(OptionError) { Rolldown.build(input: ENTRY, output: { format: "amd" }) }

      assert_equal "Unknown format: amd. Expected esm, cjs, iife or umd.", error.message
    end

    test "refuses an option a build does not take" do
      error = assert_raises(OptionError) { Rolldown.build(input: ENTRY, nonsense: true) }

      assert_equal "nonsense is not an option for a build", error.message
    end

    test "requires an entry point" do
      error = assert_raises(OptionError) { Rolldown.build(output: { format: "esm" }) }

      assert_equal "input is required", error.message
    end

    test "raises when an entry point does not resolve" do
      error = assert_raises(BuildError) { Rolldown.build(input: "test/fixtures/nope.js") }

      assert_equal "[UNRESOLVED_ENTRY] Cannot resolve entry module test/fixtures/nope.js.\n", error.message
    end
  end
end
