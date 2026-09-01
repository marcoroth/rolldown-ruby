use std::path::PathBuf;

use std::collections::BTreeMap;

use rolldown::{
  AddonOutputOption, AssetFilenamesOutputOption, BundlerOptions, ChunkFilenamesOutputOption, InputItem, IsExternal,
  LegalComments, OutputExports, OutputFormat, Platform, RawMinifyOptions, SourceMapType, TreeshakeOptions,
};

use rolldown_utils::pattern_filter::StringOrRegex;
use serde::Deserialize;

use crate::result::{RolldownErrorCode, RolldownResult};

#[derive(Deserialize, Default)]
#[serde(default, deny_unknown_fields)]
pub struct Options {
  pub input: Vec<Input>,
  pub cwd: Option<String>,
  pub external: Vec<String>,
  pub platform: Option<String>,
  pub treeshake: Option<bool>,
  pub transform: Transform,
  pub shim_missing_exports: Option<bool>,
  pub output: Output,
}

#[derive(Deserialize, Default)]
#[serde(default, deny_unknown_fields)]
pub struct Transform {
  pub define: BTreeMap<String, String>,
}

#[derive(Deserialize, Default)]
#[serde(default, deny_unknown_fields)]
pub struct Output {
  pub dir: Option<String>,
  pub file: Option<String>,
  pub format: Option<String>,
  pub name: Option<String>,
  pub exports: Option<String>,
  pub sourcemap: Option<SourceMap>,
  pub minify: Option<Minify>,
  pub banner: Option<String>,
  pub footer: Option<String>,
  pub intro: Option<String>,
  pub outro: Option<String>,
  pub entry_file_names: Option<String>,
  pub chunk_file_names: Option<String>,
  pub asset_file_names: Option<String>,
  pub keep_names: Option<bool>,
  pub legal_comments: Option<String>,
  pub es_module: Option<bool>,
}

#[derive(Deserialize)]
#[serde(untagged)]
pub enum Input {
  Bare(String),
  Named { name: Option<String>, import: String },
}

#[derive(Deserialize)]
#[serde(untagged)]
pub enum SourceMap {
  Toggle(bool),
  Kind(String),
}

#[derive(Deserialize)]
#[serde(untagged)]
pub enum Minify {
  Toggle(bool),
  Kind(String),
}

impl Options {
  pub fn parse(json: &str) -> Result<Self, RolldownResult> {
    serde_json::from_str(json).map_err(|error| RolldownResult::error(RolldownErrorCode::Option, error.to_string()))
  }

  pub fn into_bundler_options(self) -> Result<BundlerOptions, RolldownResult> {
    if self.input.is_empty() {
      return Err(RolldownResult::error(RolldownErrorCode::Option, "input is required"));
    }

    let input = self
      .input
      .into_iter()
      .map(|entry| match entry {
        Input::Bare(import) => InputItem { name: None, import },
        Input::Named { name, import } => InputItem { name, import },
      })
      .collect();

    let output = self.output;

    Ok(BundlerOptions {
      input: Some(input),
      cwd: self.cwd.map(PathBuf::from),
      platform: self.platform.as_deref().map(platform).transpose()?,
      external: external(self.external),
      define: (!self.transform.define.is_empty()).then(|| self.transform.define.into_iter().collect()),
      treeshake: self
        .treeshake
        .map_or(TreeshakeOptions::Boolean(true), TreeshakeOptions::Boolean),
      shim_missing_exports: self.shim_missing_exports,
      dir: output.dir,
      file: output.file,
      format: output.format.as_deref().map(format).transpose()?,
      name: output.name,
      exports: output.exports.as_deref().map(exports).transpose()?,
      sourcemap: sourcemap(output.sourcemap)?,
      minify: minify(output.minify)?,
      banner: addon(output.banner),
      footer: addon(output.footer),
      intro: addon(output.intro),
      outro: addon(output.outro),
      entry_filenames: output.entry_file_names.map(ChunkFilenamesOutputOption::String),
      chunk_filenames: output.chunk_file_names.map(ChunkFilenamesOutputOption::String),
      asset_filenames: output.asset_file_names.map(AssetFilenamesOutputOption::String),
      keep_names: output.keep_names,
      legal_comments: output.legal_comments.as_deref().map(legal_comments).transpose()?,
      es_module: output.es_module.map(Into::into),
      ..Default::default()
    })
  }
}

fn external(patterns: Vec<String>) -> Option<IsExternal> {
  if patterns.is_empty() {
    return None;
  }

  Some(IsExternal::StringOrRegex(
    patterns.into_iter().map(StringOrRegex::String).collect(),
  ))
}

fn addon(value: Option<String>) -> Option<AddonOutputOption> {
  value.map(|text| AddonOutputOption::String(Some(text)))
}

fn sourcemap(value: Option<SourceMap>) -> Result<Option<SourceMapType>, RolldownResult> {
  match value {
    None | Some(SourceMap::Toggle(false)) => Ok(None),
    Some(SourceMap::Toggle(true)) => Ok(Some(SourceMapType::File)),
    Some(SourceMap::Kind(kind)) => match kind.as_str() {
      "file" => Ok(Some(SourceMapType::File)),
      "inline" => Ok(Some(SourceMapType::Inline)),
      "hidden" => Ok(Some(SourceMapType::Hidden)),
      other => Err(unknown("sourcemap", other, "true, false, file, inline or hidden")),
    },
  }
}

fn minify(value: Option<Minify>) -> Result<Option<RawMinifyOptions>, RolldownResult> {
  match value {
    None => Ok(None),
    Some(Minify::Toggle(toggle)) => Ok(Some(RawMinifyOptions::Bool(toggle))),
    Some(Minify::Kind(kind)) => match kind.as_str() {
      "dce-only" => Ok(Some(RawMinifyOptions::DeadCodeEliminationOnly)),
      other => Err(unknown("minify", other, "true, false or dce-only")),
    },
  }
}

fn format(value: &str) -> Result<OutputFormat, RolldownResult> {
  match value {
    "esm" => Ok(OutputFormat::Esm),
    "cjs" => Ok(OutputFormat::Cjs),
    "iife" => Ok(OutputFormat::Iife),
    "umd" => Ok(OutputFormat::Umd),
    other => Err(unknown("format", other, "esm, cjs, iife or umd")),
  }
}

fn platform(value: &str) -> Result<Platform, RolldownResult> {
  match value {
    "browser" => Ok(Platform::Browser),
    "node" => Ok(Platform::Node),
    "neutral" => Ok(Platform::Neutral),
    other => Err(unknown("platform", other, "browser, node or neutral")),
  }
}

fn exports(value: &str) -> Result<OutputExports, RolldownResult> {
  match value {
    "auto" => Ok(OutputExports::Auto),
    "named" => Ok(OutputExports::Named),
    "default" => Ok(OutputExports::Default),
    "none" => Ok(OutputExports::None),
    other => Err(unknown("exports", other, "auto, named, default or none")),
  }
}

fn legal_comments(value: &str) -> Result<LegalComments, RolldownResult> {
  match value {
    "none" => Ok(LegalComments::None),
    "inline" => Ok(LegalComments::Inline),
    other => Err(unknown("legal_comments", other, "none or inline")),
  }
}

fn unknown(option: &str, given: &str, expected: &str) -> RolldownResult {
  RolldownResult::error(
    RolldownErrorCode::Option,
    format!("Unknown {option}: {given}. Expected {expected}."),
  )
}
