#include "webview/webview_internal.h"
#include "common/method_channel_utils.h"

#include <libsoup/soup.h>

#include <cmath>
#include <cstring>

void instance_method_call_cb(FlMethodChannel* channel,
                                    FlMethodCall* method_call,
                                    gpointer user_data) {
  LinuxWebView* webview = static_cast<LinuxWebView*>(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (strcmp(method, "setFrame") == 0) {
    GtkWidget* widget = GTK_WIDGET(webview->web_view);
    const double x = map_lookup_double(args, "x", 0);
    const double y = map_lookup_double(args, "y", 0);
    const double width = map_lookup_double(args, "width", 0);
    const double height = map_lookup_double(args, "height", 0);
    webview->frame_x = std::isfinite(x) ? static_cast<gint>(x) : 0;
    webview->frame_y = std::isfinite(y) ? static_cast<gint>(y) : 0;
    webview->frame_width =
        std::isfinite(width) && width > 0 ? static_cast<gint>(width) : 0;
    webview->frame_height =
        std::isfinite(height) && height > 0 ? static_cast<gint>(height) : 0;
    webview->visible = map_lookup_bool(args, "visible", TRUE) &&
                       webview->frame_width > 0 && webview->frame_height > 0;
    gtk_widget_set_halign(widget, GTK_ALIGN_START);
    gtk_widget_set_valign(widget, GTK_ALIGN_START);
    gtk_widget_set_margin_start(widget, webview->frame_x);
    gtk_widget_set_margin_top(widget, webview->frame_y);
    gtk_widget_set_size_request(widget, webview->frame_width,
                                webview->frame_height);
    if (webview->visible) {
      gtk_widget_show(widget);
      gtk_widget_grab_focus(widget);
    } else {
      gtk_widget_hide(widget);
    }
    update_flutter_view_input_region(webview->plugin);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "loadFile") == 0) {
    const gchar* file_path = map_lookup_string(args, "path");
    GError* error = nullptr;
    gchar* uri = g_filename_to_uri(file_path, nullptr, &error);
    if (error != nullptr) {
      respond(method_call, error_response("load_file_error", error->message));
      g_clear_error(&error);
      g_free(uri);
      return;
    }
    webkit_web_view_load_uri(webview->web_view, uri);
    g_free(uri);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "loadHtmlString") == 0) {
    webkit_web_view_load_html(webview->web_view,
                              map_lookup_string(args, "html"),
                              map_lookup_string(args, "baseUrl"));
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "loadRequest") == 0) {
    const gchar* url = map_lookup_string(args, "url");
    FlValue* headers = map_lookup(args, "headers");
    WebKitURIRequest* request = webkit_uri_request_new(url);
    if (headers != nullptr &&
        fl_value_get_type(headers) == FL_VALUE_TYPE_MAP) {
      SoupMessageHeaders* request_headers =
          webkit_uri_request_get_http_headers(request);
      const size_t header_count = fl_value_get_length(headers);
      for (size_t i = 0; i < header_count; ++i) {
        const gchar* key =
            fl_value_to_string_or_null(fl_value_get_map_key(headers, i));
        const gchar* value =
            fl_value_to_string_or_null(fl_value_get_map_value(headers, i));
        if (key != nullptr && value != nullptr) {
          soup_message_headers_append(request_headers, key, value);
        }
      }
    }
    webkit_web_view_load_request(webview->web_view, request);
    g_object_unref(request);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "currentUrl") == 0) {
    const gchar* uri = webkit_web_view_get_uri(webview->web_view);
    respond(method_call,
            success_response(uri != nullptr ? fl_value_new_string(uri)
                                            : fl_value_new_null()));
    return;
  }

  if (strcmp(method, "canGoBack") == 0) {
    respond(method_call,
            success_response(fl_value_new_bool(
                webkit_web_view_can_go_back(webview->web_view))));
    return;
  }

  if (strcmp(method, "canGoForward") == 0) {
    respond(method_call,
            success_response(fl_value_new_bool(
                webkit_web_view_can_go_forward(webview->web_view))));
    return;
  }

  if (strcmp(method, "goBack") == 0) {
    webkit_web_view_go_back(webview->web_view);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "goForward") == 0) {
    webkit_web_view_go_forward(webview->web_view);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "reload") == 0) {
    webkit_web_view_reload(webview->web_view);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "clearCache") == 0) {
    webkit_web_context_clear_cache(
        webkit_web_view_get_context(webview->web_view));
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "clearLocalStorage") == 0) {
    evaluate_javascript(
        webview->web_view,
        "try { localStorage.clear(); sessionStorage.clear(); } catch (_) {}",
        method_call);
    return;
  }

  if (strcmp(method, "runJavaScript") == 0 ||
      strcmp(method, "runJavaScriptReturningResult") == 0) {
    evaluate_javascript(webview->web_view, map_lookup_string(args, "script"),
                        method_call);
    return;
  }

  if (strcmp(method, "addJavaScriptChannel") == 0) {
    const gchar* name = map_lookup_string(args, "name");
    if (!webkit_user_content_manager_register_script_message_handler(
            webview->content_manager, name)) {
      respond(method_call,
              error_response("channel_error", "Failed to register JS channel."));
      return;
    }
    gchar* signal_name = g_strdup_printf("script-message-received::%s", name);
    JavaScriptChannelHandlerData* data =
        g_new0(JavaScriptChannelHandlerData, 1);
    data->webview = webview;
    data->name = g_strdup(name);
    guint signal_id = g_signal_connect_data(
        webview->content_manager, signal_name,
        G_CALLBACK(javascript_channel_message_received_cb), data,
        destroy_js_channel_handler_data, GConnectFlags(0));
    g_free(signal_name);
    g_hash_table_insert(webview->js_channels, g_strdup(name),
                        GINT_TO_POINTER(1));
    g_hash_table_insert(webview->js_channel_signal_ids, g_strdup(name),
                        GUINT_TO_POINTER(signal_id));
    rebuild_user_scripts(webview);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "removeJavaScriptChannel") == 0) {
    const gchar* name = map_lookup_string(args, "name");
    gpointer signal_id_ptr =
        g_hash_table_lookup(webview->js_channel_signal_ids, name);
    if (signal_id_ptr != nullptr) {
      g_signal_handler_disconnect(webview->content_manager,
                                  GPOINTER_TO_UINT(signal_id_ptr));
      g_hash_table_remove(webview->js_channel_signal_ids, name);
    }
    webkit_user_content_manager_unregister_script_message_handler(
        webview->content_manager, name);
    g_hash_table_remove(webview->js_channels, name);
    rebuild_user_scripts(webview);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "getTitle") == 0) {
    const gchar* title = webkit_web_view_get_title(webview->web_view);
    respond(method_call,
            success_response(title != nullptr ? fl_value_new_string(title)
                                              : fl_value_new_null()));
    return;
  }

  if (strcmp(method, "scrollTo") == 0) {
    gchar* script = g_strdup_printf("window.scrollTo(%" G_GINT64_FORMAT
                                    ", %" G_GINT64_FORMAT ");",
                                    map_lookup_int(args, "x", 0),
                                    map_lookup_int(args, "y", 0));
    evaluate_javascript(webview->web_view, script, method_call);
    g_free(script);
    return;
  }

  if (strcmp(method, "scrollBy") == 0) {
    gchar* script = g_strdup_printf("window.scrollBy(%" G_GINT64_FORMAT
                                    ", %" G_GINT64_FORMAT ");",
                                    map_lookup_int(args, "x", 0),
                                    map_lookup_int(args, "y", 0));
    evaluate_javascript(webview->web_view, script, method_call);
    g_free(script);
    return;
  }

  if (strcmp(method, "getScrollPosition") == 0) {
    FlValue* result = fl_value_new_map();
    fl_value_set_string_take(result, "x",
                             fl_value_new_float(webview->last_scroll_x));
    fl_value_set_string_take(result, "y",
                             fl_value_new_float(webview->last_scroll_y));
    respond(method_call, success_response(result));
    return;
  }

  if (strcmp(method, "setVerticalScrollBarEnabled") == 0 ||
      strcmp(method, "setHorizontalScrollBarEnabled") == 0) {
    gboolean enabled = map_lookup_bool(args, "enabled", TRUE);
    gchar* script = g_strdup_printf(
        "document.documentElement.style.overflow = '%s'; "
        "document.body.style.overflow = '%s';",
        enabled ? "auto" : "hidden", enabled ? "auto" : "hidden");
    evaluate_javascript(webview->web_view, script, method_call);
    g_free(script);
    return;
  }

  if (strcmp(method, "enableZoom") == 0) {
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "setBackgroundColor") == 0) {
    GdkRGBA color = {
        map_lookup_double(args, "r", 1.0), map_lookup_double(args, "g", 1.0),
        map_lookup_double(args, "b", 1.0), map_lookup_double(args, "a", 1.0)};
    webkit_web_view_set_background_color(webview->web_view, &color);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "setJavaScriptMode") == 0) {
    WebKitSettings* settings = webkit_web_view_get_settings(webview->web_view);
    webkit_settings_set_enable_javascript(
        settings, map_lookup_bool(args, "enabled", TRUE));
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "setUserAgent") == 0) {
    WebKitSettings* settings = webkit_web_view_get_settings(webview->web_view);
    const gchar* user_agent = map_lookup_string(args, "userAgent");
    webkit_settings_set_user_agent(settings, user_agent);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "getUserAgent") == 0) {
    WebKitSettings* settings = webkit_web_view_get_settings(webview->web_view);
    const gchar* user_agent = webkit_settings_get_user_agent(settings);
    respond(method_call,
            success_response(user_agent != nullptr
                                 ? fl_value_new_string(user_agent)
                                 : fl_value_new_null()));
    return;
  }

  if (strcmp(method, "setOnConsoleMessage") == 0) {
    webview->console_enabled = map_lookup_bool(args, "enabled", TRUE);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "setOnScrollPositionChange") == 0) {
    webview->scroll_enabled = map_lookup_bool(args, "enabled", TRUE);
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "completeNavigationRequest") == 0) {
    gint request_id = static_cast<gint>(map_lookup_int(args, "requestId", -1));
    gboolean allow = map_lookup_bool(args, "allow", TRUE);
    PendingNavigationDecision* pending =
        static_cast<PendingNavigationDecision*>(
            g_hash_table_lookup(webview->pending_nav_decisions,
                                GINT_TO_POINTER(request_id)));
    if (pending != nullptr) {
      if (allow) {
        if (pending->open_in_place && pending->uri != nullptr) {
          webkit_web_view_load_uri(webview->web_view, pending->uri);
          webkit_policy_decision_ignore(pending->decision);
        } else {
          webkit_policy_decision_use(pending->decision);
        }
      } else {
        webkit_policy_decision_ignore(pending->decision);
      }
      g_hash_table_remove(webview->pending_nav_decisions,
                          GINT_TO_POINTER(request_id));
    }
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "completeHttpAuthRequest") == 0) {
    gint request_id = static_cast<gint>(map_lookup_int(args, "requestId", -1));
    WebKitAuthenticationRequest* request = WEBKIT_AUTHENTICATION_REQUEST(
        g_hash_table_lookup(webview->pending_auth_requests,
                            GINT_TO_POINTER(request_id)));
    if (request != nullptr) {
      const gchar* action = map_lookup_string(args, "action");
      if (g_strcmp0(action, "proceed") == 0) {
        WebKitCredential* credential = webkit_credential_new(
            map_lookup_string(args, "user") != nullptr
                ? map_lookup_string(args, "user")
                : "",
            map_lookup_string(args, "password") != nullptr
                ? map_lookup_string(args, "password")
                : "",
            WEBKIT_CREDENTIAL_PERSISTENCE_NONE);
        webkit_authentication_request_authenticate(request, credential);
        webkit_credential_free(credential);
      } else {
        webkit_authentication_request_cancel(request);
      }
      g_hash_table_remove(webview->pending_auth_requests,
                          GINT_TO_POINTER(request_id));
    }
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "completePermissionRequest") == 0) {
    gint request_id = static_cast<gint>(map_lookup_int(args, "requestId", -1));
    WebKitPermissionRequest* request = WEBKIT_PERMISSION_REQUEST(
        g_hash_table_lookup(webview->pending_permission_requests,
                            GINT_TO_POINTER(request_id)));
    if (request != nullptr) {
      if (map_lookup_bool(args, "grant", FALSE)) {
        webkit_permission_request_allow(request);
      } else {
        webkit_permission_request_deny(request);
      }
      g_hash_table_remove(webview->pending_permission_requests,
                          GINT_TO_POINTER(request_id));
    }
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "completeJavaScriptDialog") == 0) {
    gint request_id = static_cast<gint>(map_lookup_int(args, "requestId", -1));
    WebKitScriptDialog* dialog = static_cast<WebKitScriptDialog*>(
        g_hash_table_lookup(webview->pending_script_dialogs,
                            GINT_TO_POINTER(request_id)));
    if (dialog != nullptr) {
      const gchar* action = map_lookup_string(args, "action");
      switch (webkit_script_dialog_get_dialog_type(dialog)) {
        case WEBKIT_SCRIPT_DIALOG_ALERT:
          break;
        case WEBKIT_SCRIPT_DIALOG_CONFIRM:
        case WEBKIT_SCRIPT_DIALOG_BEFORE_UNLOAD_CONFIRM:
          webkit_script_dialog_confirm_set_confirmed(
              dialog, g_strcmp0(action, "confirm") == 0);
          break;
        case WEBKIT_SCRIPT_DIALOG_PROMPT:
          if (g_strcmp0(action, "cancel") != 0) {
            webkit_script_dialog_prompt_set_text(
                dialog, map_lookup_string(args, "text"));
          }
          break;
      }
      webkit_script_dialog_close(dialog);
      g_hash_table_remove(webview->pending_script_dialogs,
                          GINT_TO_POINTER(request_id));
    }
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "completeSslAuthError") == 0) {
    gint request_id = static_cast<gint>(map_lookup_int(args, "requestId", -1));
    PendingTlsError* pending = static_cast<PendingTlsError*>(
        g_hash_table_lookup(webview->pending_tls_errors,
                            GINT_TO_POINTER(request_id)));
    if (pending != nullptr) {
      if (map_lookup_bool(args, "proceed", FALSE) &&
          pending->certificate != nullptr && pending->host != nullptr) {
        WebKitWebContext* context =
            webkit_web_view_get_context(webview->web_view);
        webkit_web_context_allow_tls_certificate_for_host(
            context, pending->certificate, pending->host);
        if (pending->uri != nullptr) {
          webkit_web_view_load_uri(webview->web_view, pending->uri);
        }
      }
      g_hash_table_remove(webview->pending_tls_errors,
                          GINT_TO_POINTER(request_id));
    }
    respond(method_call, success_response());
    return;
  }

  if (strcmp(method, "dispose") == 0) {
    gtk_widget_hide(GTK_WIDGET(webview->web_view));
    webview->visible = FALSE;
    update_flutter_view_input_region(webview->plugin);
    respond(method_call, success_response());
    return;
  }

  respond(method_call,
          FL_METHOD_RESPONSE(fl_method_not_implemented_response_new()));
}
