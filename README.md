<h2 align="center">⬇️ Rolldown for Ruby</h2>

<h4 align="center">Blazing Fast Rust-based bundler for JavaScript.</h4>

<div align="center">Ruby bindings for <a href="https://rolldown.rs">Rolldown</a>, the Rust bundler behind Vite.</div><br/>

<p align="center">
  <a href="https://rubygems.org/gems/rolldown"><img alt="Gem Version" src="https://img.shields.io/gem/v/rolldown"></a>
  <a href="https://rolldown.rs"><img alt="Documentation" src="https://img.shields.io/badge/rolldown.rs-documentation-green"></a>
  <a href="https://github.com/marcoroth/rolldown-ruby/blob/main/LICENSE.txt"><img alt="License" src="https://img.shields.io/github/license/marcoroth/rolldown-ruby"></a>
  <a href="https://github.com/marcoroth/rolldown-ruby/issues"><img alt="Issues" src="https://img.shields.io/github/issues/marcoroth/rolldown-ruby"></a>
</p>

<br/>

### What is Rolldown for Ruby?

Ruby bindings for [Rolldown](https://rolldown.rs), the Rust-based bundler for JavaScript. Bundle JavaScript from Ruby, without the need for a JavaScript runtime.

Everything here is Rolldown doing the work. For what the options mean and what it can do, [rolldown.rs](https://rolldown.rs) is the reference.

### Installation

```bash
bundle add rolldown
```

Anywhere a precompiled gem is not published, the gem builds from source and needs the [Rust toolchain](https://rustup.rs) at 1.96 or newer.

### Usage

The options follow [Rolldown's JavaScript API](https://rolldown.rs/reference/config-options), so a `rolldown.config.js` ports across as it reads.

```ruby
result = Rolldown.build(
  input: "src/main.js",
  output: {
    file: "bundle.js"
  }
)

result.entry.code
```

Everything comes back in memory. `write` puts it on disk, chunks and source maps together, creating the directory if it is missing.

```ruby
result = Rolldown.build(
  input: "app/javascript/application.js",
  output: {
    dir: "app/assets/builds",
    format: "esm",
    sourcemap: true,
    minify: true
  }
)

result.write
#=> ["app/assets/builds/application.js", "app/assets/builds/application.js.map"]
```

`write` goes to `output.dir`, or to whatever directory `output.file` names, and takes an argument to go somewhere else. `output.dir` also decides what the source map's relative paths look like, so it is worth setting even when writing elsewhere.

Writing happens in Ruby. Rolldown can do it, but it hands the whole bundle back either way, so writing from Rust measured slower while giving the caller less say over where files land.

#### Entry points

An entry point is a string, a list, or a hash of names, matching `string | string[] | Record<string, string>`.

```ruby
Rolldown.build(input: "src/main.js")
Rolldown.build(input: ["src/main.js", "src/admin.js"])
Rolldown.build(input: { app: "src/main.js", admin: "src/admin.js" })
```

#### Bundling something that is not a file

`modules` hands the bundler sources it holds in memory, keyed by whatever name you want to import them under.

```ruby
Rolldown.build(
  input: "app:entry",
  modules: {
    "app:entry" => %(import { card } from "app:users/card"\ncard()),
    "app:users/card" => %(export function card() { ... })
  }
)
```

They mix freely with what is on disk. A module in memory can import an npm package or a relative file, and a file on disk can import a module in memory. A relative import out of a module in memory resolves against that module's own name, so give it a path-shaped one when it needs to reach real files next to it.

This exists so a generator can transform sources in Ruby first and bundle the result without writing anything out. There are no plugins, and no Ruby runs while the bundle does.

#### What comes back

```ruby
result.chunks    # every chunk, each with filename, name, code, map, imports, exports and module_ids
result.assets    # source maps and anything else emitted alongside
result.entry     # the first chunk that is an entry point
result.warnings  # diagnostics that did not stop the build
result.failed?
```

A build that produces nothing usable raises `Rolldown::BuildError` carrying what went wrong. Pass `strict: true` to raise on warnings too.

#### Bundling, not installing

Bare imports resolve with no plugin and no configuration whenever the files are on disk. Putting them there is a package manager, and this gem is not one. An app whose JavaScript is its own code plus a few vendored libraries needs nothing else.

#### Which options are bound

Of the JavaScript API's 22 input options and 49 output options, these are bound so far.

At the top level, `input`, `cwd`, `external`, `platform`, `treeshake`, `shim_missing_exports`, `module_types` and `modules`, plus `transform` for `define`.

Under `output`, `dir`, `file`, `format`, `name`, `exports`, `sourcemap`, `minify`, `banner`, `footer`, `intro`, `outro`, `entry_file_names`, `chunk_file_names`, `asset_file_names`, `keep_names`, `legal_comments` and `es_module`.

Names follow the JavaScript spelling in snake_case, so `entryFileNames` is `entry_file_names`. Where JavaScript and Rust disagree, JavaScript wins, and `define` sits under `transform` for the same reason.

#### What cannot cross

Options that take a JavaScript function in the JavaScript API have nowhere to go in Ruby. `plugins`, `on_log`, `manual_chunks` and `sourcemap_path_transform` are refused by name, and anything else Rolldown does not recognise is refused too.

Watch mode, hot module replacement and the dev server are not bound.

### Development

The gem is a C extension over a Rust crate. `rust/` builds a static library and generates the C header with [cbindgen](https://github.com/mozilla/cbindgen), `ext/rolldown/` wraps it, and `lib/` is the Ruby API over that.

```bash
bin/setup
bundle exec rake
```

`sig/` is generated from the `#:` annotations next to the code. Regenerate it with `rake rbs` after changing a signature, and CI checks that it matches.

### Acknowledgements

[Rolldown](https://rolldown.rs) is maintained at [rolldown/rolldown](https://github.com/rolldown/rolldown) and is part of [VoidZero](https://voidzero.dev)'s toolchain for JavaScript. This gem only calls into it. Thank you for building these tools!

### Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/marcoroth/rolldown-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/marcoroth/rolldown-ruby/blob/main/CODE_OF_CONDUCT.md).

Issues with parsing, transforming or minifying itself belong [upstream](https://github.com/rolldown/rolldown/issues), since this gem does none of that. Issues with the Ruby API, the build, or the bindings belong here.

### License

The Ruby, C, and Rust code in this gem is available under the terms of the [MIT License](https://opensource.org/licenses/MIT).

It builds against [Rolldown](https://github.com/rolldown/rolldown), which is MIT licensed and carries some MIT code of its own. A copy of both travels with the gem in [`licenses/`](licenses).
