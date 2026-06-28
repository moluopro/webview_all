#ifndef WEBVIEW_ALL_LINUX_METHOD_CHANNEL_UTILS_H_
#define WEBVIEW_ALL_LINUX_METHOD_CHANNEL_UTILS_H_

#include <flutter_linux/flutter_linux.h>

FlMethodCodec* method_codec();
FlValue* map_lookup(FlValue* map, const gchar* key);
const gchar* map_lookup_string(FlValue* map, const gchar* key);
gboolean map_lookup_bool(FlValue* map, const gchar* key, gboolean fallback);
double map_lookup_double(FlValue* map, const gchar* key, double fallback);
gint64 map_lookup_int(FlValue* map, const gchar* key, gint64 fallback);
FlMethodResponse* success_response(FlValue* value = nullptr);
FlMethodResponse* error_response(const gchar* code,
                                  const gchar* message);
void respond(FlMethodCall* method_call, FlMethodResponse* response);
FlValue* make_event(const gchar* type);
const gchar* fl_value_to_string_or_null(FlValue* value);

#endif  // WEBVIEW_ALL_LINUX_METHOD_CHANNEL_UTILS_H_
