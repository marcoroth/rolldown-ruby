# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"

module Rolldown
  class WriteTest < Minitest::Spec
    ENTRY = "test/fixtures/entry.js" #: String

    #: () -> String
    def fixtures
      File.expand_path("fixtures", __dir__)
    end

    test "writes every chunk to the directory the build was given" do
      Dir.mktmpdir do |dir|
        result = Rolldown.build(input: ENTRY, output: { dir: dir })

        assert_equal [File.join(dir, "entry.js")], result.write
        assert_equal ["entry.js"], Dir.children(dir)
        assert_equal result.entry.code, File.read(File.join(dir, "entry.js"))
      end
    end

    test "writes the source map alongside the chunk" do
      Dir.mktmpdir do |dir|
        result = Rolldown.build(input: ENTRY, output: { dir: dir, sourcemap: true })

        result.write

        assert_equal ["entry.js", "entry.js.map"], Dir.children(dir).sort
        assert_equal result.entry.map, File.read(File.join(dir, "entry.js.map"))
      end
    end

    test "takes a directory of its own" do
      Dir.mktmpdir do |dir|
        Rolldown.build(input: ENTRY).write(dir)

        assert_equal ["entry.js"], Dir.children(dir)
      end
    end

    test "creates the directory when it does not exist" do
      Dir.mktmpdir do |dir|
        nested = File.join(dir, "app", "assets", "builds")

        Rolldown.build(input: ENTRY).write(nested)

        assert_equal ["entry.js"], Dir.children(nested)
      end
    end

    test "says so when there is nowhere to write" do
      error = assert_raises(IOError) { Rolldown.build(input: ENTRY).write }

      assert_equal "no directory to write to, pass one or set output.dir or output.file", error.message
    end

    test "writes to the directory the output file names" do
      Dir.mktmpdir do |dir|
        result = Rolldown.build(input: ENTRY, output: { file: File.join(dir, "bundle.js") })

        assert_equal [File.join(dir, "bundle.js")], result.write
        assert_equal ["bundle.js"], Dir.children(dir)
      end
    end

    test "writes relative to the cwd the build was given, not the process's" do
      Dir.mktmpdir do |_dir|
        result = Rolldown.build(input: "entry.js", cwd: fixtures, output: { dir: "builds" })

        assert_equal [File.join(fixtures, "builds", "entry.js")], result.write
        assert_equal false, Dir.exist?(File.join(Dir.pwd, "builds"))
        assert_equal ["entry.js"], Dir.children(File.join(fixtures, "builds"))
      ensure
        FileUtils.rm_rf(File.join(fixtures, "builds"))
      end
    end

    test "answers the cwd it was built for" do
      assert_equal fixtures, Rolldown.build(input: "entry.js", cwd: fixtures).cwd
      assert_nil Rolldown.build(input: ENTRY).cwd
    end

    test "answers the directory it was built for" do
      assert_equal "builds", Rolldown.build(input: ENTRY, output: { dir: "builds" }).dir
      assert_equal "dist", Rolldown.build(input: ENTRY, output: { file: "dist/bundle.js" }).dir
      assert_equal ".", Rolldown.build(input: ENTRY, output: { file: "bundle.js" }).dir
      assert_nil Rolldown.build(input: ENTRY).dir
    end
  end
end
