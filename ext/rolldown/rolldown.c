#include <ruby.h>
#include <ruby/encoding.h>
#include "include/rolldown.h"

static VALUE rb_mRolldown;
static VALUE rb_mBackend;
static VALUE rb_eError;
static VALUE rb_eOptionError;
static VALUE rb_eRolldownEncodingError;
static VALUE rb_eBuildError;
static VALUE rb_eRolldownIOError;
static VALUE rb_eInternalError;
static VALUE rb_ePanicError;

static VALUE take_utf8_string(char *cstring) {
  if (!cstring) return Qnil;

  VALUE string = rb_enc_str_new_cstr(cstring, rb_utf8_encoding());

  rolldown_string_free(cstring);

  return string;
}

static VALUE rb_native_version(VALUE self) {
  (void) self;

  return take_utf8_string(rolldown_version());
}

static VALUE rb_rolldown_version(VALUE self) {
  (void) self;

  return take_utf8_string(rolldown_rolldown_version());
}

static VALUE rb_probe(VALUE self) {
  (void) self;

  return take_utf8_string(rolldown_probe());
}

void Init_rolldown(void) {
  rb_mRolldown = rb_define_module("Rolldown");
  rb_mBackend = rb_define_module_under(rb_mRolldown, "Backend");

  rb_eError = rb_define_class_under(rb_mRolldown, "Error", rb_eStandardError);
  rb_eOptionError = rb_define_class_under(rb_mRolldown, "OptionError", rb_eError);
  rb_eRolldownEncodingError = rb_define_class_under(rb_mRolldown, "EncodingError", rb_eError);
  rb_eBuildError = rb_define_class_under(rb_mRolldown, "BuildError", rb_eError);
  rb_eRolldownIOError = rb_define_class_under(rb_mRolldown, "IOError", rb_eError);
  rb_eInternalError = rb_define_class_under(rb_mRolldown, "InternalError", rb_eError);
  rb_ePanicError = rb_define_class_under(rb_mRolldown, "PanicError", rb_eInternalError);

  rb_define_singleton_method(rb_mBackend, "version", rb_native_version, 0);
  rb_define_singleton_method(rb_mBackend, "rolldown_version", rb_rolldown_version, 0);
  rb_define_singleton_method(rb_mBackend, "probe", rb_probe, 0);
}
