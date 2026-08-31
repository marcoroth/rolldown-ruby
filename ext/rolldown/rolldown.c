#include <ruby.h>
#include <ruby/encoding.h>
#include <ruby/thread.h>
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

typedef struct RolldownResult (*rolldown_function)(const char *);

struct call_arguments {
  rolldown_function function;
  const char *options;
  struct RolldownResult result;
};

static VALUE make_utf8_string(const char *cstring) {
  return rb_enc_str_new_cstr(cstring, rb_utf8_encoding());
}

static VALUE take_utf8_string(char *cstring) {
  if (!cstring) return Qnil;

  VALUE string = make_utf8_string(cstring);
  rolldown_string_free(cstring);

  return string;
}

static VALUE error_class_for(enum RolldownErrorCode code) {
  switch (code) {
    case ROLLDOWN_ERROR_CODE_OPTION: return rb_eOptionError;
    case ROLLDOWN_ERROR_CODE_ENCODING: return rb_eRolldownEncodingError;
    case ROLLDOWN_ERROR_CODE_BUILD: return rb_eBuildError;
    case ROLLDOWN_ERROR_CODE_IO: return rb_eRolldownIOError;
    case ROLLDOWN_ERROR_CODE_PANIC: return rb_ePanicError;
    default: return rb_eInternalError;
  }
}

static VALUE unwrap(struct RolldownResult result) {
  if (result.error) {
    VALUE message = make_utf8_string(result.error);
    VALUE error_class = error_class_for(result.code);

    rolldown_result_free(result);

    rb_raise(error_class, "%s", StringValueCStr(message));
  }

  if (!result.value) {
    rolldown_result_free(result);

    rb_raise(rb_eInternalError, "rolldown returned no result");
  }

  VALUE value = rb_enc_str_new(result.value, (long) result.value_len, rb_utf8_encoding());

  rolldown_result_free(result);

  return value;
}

static void *without_gvl(void *data) {
  struct call_arguments *arguments = (struct call_arguments *) data;

  arguments->result = arguments->function(arguments->options);

  return NULL;
}

static VALUE call(rolldown_function function, VALUE options) {
  struct call_arguments arguments;

  arguments.function = function;
  arguments.options = StringValueCStr(options);

  rb_thread_call_without_gvl(without_gvl, &arguments, NULL, NULL);

  return unwrap(arguments.result);
}

static VALUE rb_build(VALUE self, VALUE options) {
  (void) self;

  return call(rolldown_build, options);
}

static VALUE rb_native_version(VALUE self) {
  (void) self;

  return take_utf8_string(rolldown_version());
}

static VALUE rb_rolldown_version(VALUE self) {
  (void) self;

  return take_utf8_string(rolldown_rolldown_version());
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

  rb_define_singleton_method(rb_mBackend, "build", rb_build, 1);
  rb_define_singleton_method(rb_mBackend, "version", rb_native_version, 0);
  rb_define_singleton_method(rb_mBackend, "rolldown_version", rb_rolldown_version, 0);
}
