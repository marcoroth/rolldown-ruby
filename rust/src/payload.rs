use rolldown::BundleOutput;
use rolldown_common::Output;
use rolldown_error::{BatchedBuildDiagnostic, BuildDiagnostic};
use serde::Serialize;

#[derive(Serialize, Default)]
pub struct BuildPayload {
  pub chunks: Vec<Chunk>,
  pub assets: Vec<Asset>,
  pub warnings: Vec<Diagnostic>,
  pub errors: Vec<Diagnostic>,
  pub failed: bool,
}

#[derive(Serialize)]
pub struct Chunk {
  pub filename: String,
  pub name: String,
  pub code: String,
  pub map: Option<String>,
  pub is_entry: bool,
  pub is_dynamic_entry: bool,
  pub imports: Vec<String>,
  pub dynamic_imports: Vec<String>,
  pub exports: Vec<String>,
  pub module_ids: Vec<String>,
}

#[derive(Serialize)]
pub struct Asset {
  pub filename: String,
  pub names: Vec<String>,
  pub source: Option<String>,
}

#[derive(Serialize)]
pub struct Diagnostic {
  pub kind: String,
  pub severity: String,
  pub message: String,
  pub file: Option<String>,
  pub line: Option<usize>,
  pub column: Option<usize>,
}

impl BuildPayload {
  pub fn from_output(output: BundleOutput) -> Self {
    let mut payload = Self {
      warnings: convert(&output.warnings),
      ..Default::default()
    };

    for asset in output.assets {
      match asset {
        Output::Chunk(chunk) => payload.chunks.push(Chunk {
          filename: chunk.filename.to_string(),
          name: chunk.name.to_string(),
          code: chunk.code.clone(),
          map: chunk.map.as_ref().map(|map| map.to_json_string()),
          is_entry: chunk.is_entry,
          is_dynamic_entry: chunk.is_dynamic_entry,
          imports: chunk.imports.iter().map(ToString::to_string).collect(),
          dynamic_imports: chunk.dynamic_imports.iter().map(ToString::to_string).collect(),
          exports: chunk.exports.iter().map(ToString::to_string).collect(),
          module_ids: chunk.module_ids.iter().map(ToString::to_string).collect(),
        }),
        Output::Asset(asset) => payload.assets.push(Asset {
          filename: asset.filename.to_string(),
          names: asset.names.clone(),
          source: asset.source.clone().try_into_string().ok(),
        }),
      }
    }

    payload
  }

  pub fn from_failure(batched: BatchedBuildDiagnostic) -> Self {
    Self {
      errors: convert(&batched.into_vec()),
      failed: true,
      ..Default::default()
    }
  }
}

fn convert(diagnostics: &[BuildDiagnostic]) -> Vec<Diagnostic> {
  diagnostics
    .iter()
    .map(|diagnostic| {
      let rendered = diagnostic.to_diagnostic();
      let location = rendered.get_primary_location();

      Diagnostic {
        kind: diagnostic.kind().to_string(),
        severity: format!("{:?}", diagnostic.severity()).to_lowercase(),
        message: rendered.convert_to_string(false),
        file: location.as_ref().map(|(file, ..)| file.clone()),
        line: location.as_ref().map(|(_, line, ..)| *line),
        column: location.as_ref().map(|(_, _, column, _)| *column),
      }
    })
    .collect()
}
