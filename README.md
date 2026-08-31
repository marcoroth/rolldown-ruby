<h2 align="center">Rolldown for Ruby</h2>

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

TODO

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
