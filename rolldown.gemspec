# frozen_string_literal: true

require_relative "lib/rolldown/version"

Gem::Specification.new do |spec|
  spec.name = "rolldown"
  spec.version = Rolldown::VERSION
  spec.authors = ["Marco Roth"]
  spec.email = ["marco.roth@intergga.ch"]

  spec.summary = "Blazing Fast Rust-based bundler for JavaScript"
  spec.description = "Ruby bindings for Rolldown, the Rust bundler behind Vite."
  spec.homepage = "https://github.com/marcoroth/rolldown-ruby"
  spec.licenses = ["MIT"]
  spec.required_ruby_version = ">= 3.2.0"
  spec.require_paths = ["lib"]

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/marcoroth/rolldown-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/marcoroth/rolldown-ruby/releases"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "rolldown.gemspec",
    "LICENSE.txt",
    "licenses/*.txt",
    "licenses/README.md",
    "README.md",
    "lib/**/*.rb",
    "sig/**/*.rbs",
    "ext/rolldown/extconf.rb",
    "ext/rolldown/rolldown.c",
    "ext/rolldown/include/**/*.h",
    "rust/Cargo.toml",
    "rust/Cargo.lock",
    "rust/build.rs",
    "rust/cbindgen.toml",
    "rust/rustfmt.toml",
    "rust/src/**/*.rs"
  ]

  spec.extensions = ["ext/rolldown/extconf.rb"]
end
