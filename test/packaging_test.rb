# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

module Rolldown
  class PackagingTest < Minitest::Spec
    def root
      File.expand_path("..", __dir__)
    end

    def extension
      Dir[File.join(root, "lib", "rolldown", "rolldown.{bundle,so}")].first
    end

    def loads_from(lib)
      ruby = File.join(RbConfig::CONFIG["bindir"], RbConfig::CONFIG["ruby_install_name"])
      script = %(require "rolldown"; print Rolldown.rolldown_version)
      env = { "RUBYOPT" => nil, "BUNDLE_GEMFILE" => nil, "BUNDLER_SETUP" => nil }

      IO.popen(env, [ruby, "-I#{lib}", "-e", script], err: [:child, :out], &:read)
    end

    def layout(dir, into)
      lib = File.join(dir, "lib")

      FileUtils.mkdir_p(File.join(lib, "rolldown"))
      FileUtils.cp(File.join(root, "lib", "rolldown.rb"), lib)
      FileUtils.cp(Dir[File.join(root, "lib", "rolldown", "*.rb")], File.join(lib, "rolldown"))

      if into
        FileUtils.mkdir_p(File.join(lib, "rolldown", into))
        FileUtils.cp(extension, File.join(lib, "rolldown", into))
      end

      lib
    end

    test "loads the extension a platform gem ships, under the Ruby it was built for" do
      Dir.mktmpdir do |dir|
        abi = RUBY_VERSION.split(".").first(2).join(".")

        assert_equal Rolldown.rolldown_version, loads_from(layout(dir, abi))
      end
    end

    test "loads the extension a source install leaves beside the library" do
      Dir.mktmpdir do |dir|
        assert_equal Rolldown.rolldown_version, loads_from(layout(dir, "."))
      end
    end

    test "says so loudly when there is no extension at all" do
      Dir.mktmpdir do |dir|
        assert_equal true, loads_from(layout(dir, nil)).include?("LoadError")
      end
    end
  end
end
