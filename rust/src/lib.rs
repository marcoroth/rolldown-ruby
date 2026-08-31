use std::ffi::{c_char, CString};

use rolldown::{Bundler, BundlerOptions};

/// The version of the `rolldown` gem this library was built for.
#[no_mangle]
pub extern "C" fn rolldown_version() -> *mut c_char {
  into_c_string(env!("CARGO_PKG_VERSION"))
}

/// The version of the rolldown crate this library was compiled against.
#[no_mangle]
pub extern "C" fn rolldown_rolldown_version() -> *mut c_char {
  into_c_string(env!("ROLLDOWN_VERSION"))
}

/// Constructs a bundler and throws it away.
///
/// M0 ships no bundling. This exists so the linker keeps rolldown, and through it oxc, in the
/// shared object. Without a real call, link-time optimization strips the dependency entirely and
/// the coexistence test proves nothing.
#[no_mangle]
pub extern "C" fn rolldown_probe() -> *mut c_char {
  let options = BundlerOptions {
    cwd: Some(std::env::temp_dir()),
    ..Default::default()
  };

  match Bundler::new(options) {
    Ok(_) => into_c_string("ok"),
    Err(_) => into_c_string("error"),
  }
}

/// Frees a string this library handed out.
///
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

fn into_c_string(value: &str) -> *mut c_char {
  CString::new(value)
    .unwrap_or_else(|_| CString::new("unknown").expect("a string with no interior nul"))
    .into_raw()
}
