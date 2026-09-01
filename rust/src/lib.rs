use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use std::panic::{catch_unwind, AssertUnwindSafe};

mod build;
mod modules;
mod options;
mod payload;
mod result;

use result::{RolldownErrorCode, RolldownResult};

/// # Safety
///
/// `options_json` must be a valid, nul-terminated UTF-8 string.
#[no_mangle]
pub unsafe extern "C" fn rolldown_build(options_json: *const c_char) -> RolldownResult {
  let Some(options) = borrow(options_json) else {
    return RolldownResult::error(RolldownErrorCode::Encoding, "options were not valid UTF-8");
  };

  match catch_unwind(AssertUnwindSafe(|| build::build(options))) {
    Ok(result) => result,
    Err(payload) => RolldownResult::error(RolldownErrorCode::Panic, panic_message(&payload)),
  }
}

#[no_mangle]
pub extern "C" fn rolldown_version() -> *mut c_char {
  into_c_string(env!("CARGO_PKG_VERSION"))
}

#[no_mangle]
pub extern "C" fn rolldown_rolldown_version() -> *mut c_char {
  into_c_string(env!("ROLLDOWN_VERSION"))
}

/// # Safety
///
/// `value` must be a pointer this library returned, and must not be used afterwards.
#[no_mangle]
pub unsafe extern "C" fn rolldown_string_free(value: *mut c_char) {
  if value.is_null() {
    return;
  }

  drop(CString::from_raw(value));
}

/// # Safety
///
/// `result` must be one this library returned, and must not be used afterwards.
#[no_mangle]
pub unsafe extern "C" fn rolldown_result_free(result: RolldownResult) {
  if !result.value.is_null() {
    drop(CString::from_raw(result.value));
  }

  if !result.error.is_null() {
    drop(CString::from_raw(result.error));
  }
}

#[no_mangle]
pub extern "C" fn rolldown_panic_for_test() -> RolldownResult {
  match catch_unwind(AssertUnwindSafe(|| -> RolldownResult { panic!("a deliberate panic") })) {
    Ok(result) => result,
    Err(payload) => RolldownResult::error(RolldownErrorCode::Panic, panic_message(&payload)),
  }
}

unsafe fn borrow<'a>(value: *const c_char) -> Option<&'a str> {
  if value.is_null() {
    return None;
  }

  CStr::from_ptr(value).to_str().ok()
}

fn panic_message(payload: &Box<dyn std::any::Any + Send>) -> String {
  payload
    .downcast_ref::<&str>()
    .map(|message| (*message).to_string())
    .or_else(|| payload.downcast_ref::<String>().cloned())
    .unwrap_or_else(|| "rolldown panicked".to_string())
}

fn into_c_string(value: &str) -> *mut c_char {
  CString::new(value)
    .unwrap_or_else(|_| CString::new("unknown").expect("a string with no interior nul"))
    .into_raw()
}
