#include "common/method_channel_utils.h"

FlMethodCodec* method_codec() {
  static FlStandardMethodCodec* codec = nullptr;
  if (codec == nullptr) {
    codec = fl_standard_method_codec_new();
  }
  return FL_METHOD_CODEC(codec);
}

FlValue* map_lookup(FlValue* map, const gchar* key) {
  if (map == nullptr || fl_value_get_type(map) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }
  return fl_value_lookup_string(map, key);
}

const gchar* map_lookup_string(FlValue* map, const gchar* key) {
  FlValue* value = map_lookup(map, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_STRING) {
    return nullptr;
  }
  return fl_value_get_string(value);
}

gboolean map_lookup_bool(FlValue* map,
                                const gchar* key,
                                gboolean fallback) {
  FlValue* value = map_lookup(map, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_BOOL) {
    return fallback;
  }
  return fl_value_get_bool(value);
}

double map_lookup_double(FlValue* map,
                                const gchar* key,
                                double fallback) {
  FlValue* value = map_lookup(map, key);
  if (value == nullptr) {
    return fallback;
  }
  if (fl_value_get_type(value) == FL_VALUE_TYPE_FLOAT) {
    return fl_value_get_float(value);
  }
  if (fl_value_get_type(value) == FL_VALUE_TYPE_INT) {
    return static_cast<double>(fl_value_get_int(value));
  }
  return fallback;
}

gint64 map_lookup_int(FlValue* map, const gchar* key, gint64 fallback) {
  FlValue* value = map_lookup(map, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_INT) {
    return fallback;
  }
  return fl_value_get_int(value);
}

FlMethodResponse* success_response(FlValue* value) {
  return FL_METHOD_RESPONSE(fl_method_success_response_new(value));
}

FlMethodResponse* error_response(const gchar* code,
                                        const gchar* message) {
  return FL_METHOD_RESPONSE(
      fl_method_error_response_new(code, message, nullptr));
}

void respond(FlMethodCall* method_call, FlMethodResponse* response) {
  GError* error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send method response: %s",
              error != nullptr ? error->message : "unknown");
    g_clear_error(&error);
  }
}

FlValue* make_event(const gchar* type) {
  FlValue* map = fl_value_new_map();
  fl_value_set_string_take(map, "type", fl_value_new_string(type));
  return map;
}

const gchar* fl_value_to_string_or_null(FlValue* value) {
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_STRING) {
    return nullptr;
  }
  return fl_value_get_string(value);
}
