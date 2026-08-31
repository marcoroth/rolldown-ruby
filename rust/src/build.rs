use rolldown::Bundler;

use crate::options::Options;
use crate::payload::BuildPayload;
use crate::result::{RolldownErrorCode, RolldownResult};

pub fn build(options_json: &str) -> RolldownResult {
  let options = match Options::parse(options_json).and_then(Options::into_bundler_options) {
    Ok(options) => options,
    Err(failure) => return failure,
  };

  let mut bundler = match Bundler::new(options) {
    Ok(bundler) => bundler,
    Err(batched) => return payload(BuildPayload::from_failure(batched)),
  };

  let runtime = match tokio::runtime::Builder::new_multi_thread().enable_all().build() {
    Ok(runtime) => runtime,
    Err(error) => {
      return RolldownResult::error(
        RolldownErrorCode::Internal,
        format!("could not start a runtime: {error}"),
      )
    }
  };

  match runtime.block_on(bundler.generate()) {
    Ok(output) => payload(BuildPayload::from_output(output)),
    Err(batched) => payload(BuildPayload::from_failure(batched)),
  }
}

fn payload(payload: BuildPayload) -> RolldownResult {
  match serde_json::to_string(&payload) {
    Ok(json) => RolldownResult::value(json),
    Err(error) => RolldownResult::error(RolldownErrorCode::Internal, error.to_string()),
  }
}
