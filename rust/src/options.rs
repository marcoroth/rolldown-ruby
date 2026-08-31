use std::path::PathBuf;

use rolldown::{BundlerOptions, InputItem, OutputFormat, Platform};
use serde::Deserialize;

use crate::result::{RolldownErrorCode, RolldownResult};

#[derive(Deserialize, Default)]
#[serde(default, deny_unknown_fields)]
pub struct Options {
  pub input: Vec<Input>,
  pub cwd: Option<String>,
  pub dir: Option<String>,
  pub file: Option<String>,
  pub format: Option<String>,
  pub name: Option<String>,
  pub platform: Option<String>,
}

#[derive(Deserialize)]
#[serde(untagged)]
pub enum Input {
  Bare(String),
  Named { name: Option<String>, import: String },
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

    Ok(BundlerOptions {
      input: Some(input),
      cwd: self.cwd.map(PathBuf::from),
      dir: self.dir,
      file: self.file,
      format: self.format.as_deref().map(format).transpose()?,
      name: self.name,
      platform: self.platform.as_deref().map(platform).transpose()?,
      ..Default::default()
    })
  }
}

fn format(value: &str) -> Result<OutputFormat, RolldownResult> {
  match value {
    "esm" => Ok(OutputFormat::Esm),
    "cjs" => Ok(OutputFormat::Cjs),
    "iife" => Ok(OutputFormat::Iife),
    "umd" => Ok(OutputFormat::Umd),
    other => Err(RolldownResult::error(
      RolldownErrorCode::Option,
      format!("Unknown format: {other}. Expected esm, cjs, iife or umd."),
    )),
  }
}

fn platform(value: &str) -> Result<Platform, RolldownResult> {
  match value {
    "browser" => Ok(Platform::Browser),
    "node" => Ok(Platform::Node),
    "neutral" => Ok(Platform::Neutral),
    other => Err(RolldownResult::error(
      RolldownErrorCode::Option,
      format!("Unknown platform: {other}. Expected browser, node or neutral."),
    )),
  }
}
