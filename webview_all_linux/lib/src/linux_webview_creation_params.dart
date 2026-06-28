import 'package:flutter/widgets.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

@immutable
class LinuxWebViewControllerCreationParams
    extends PlatformWebViewControllerCreationParams {
  const LinuxWebViewControllerCreationParams();

  const LinuxWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
    PlatformWebViewControllerCreationParams params,
  );
}

@immutable
class LinuxWebViewWidgetCreationParams
    extends PlatformWebViewWidgetCreationParams {
  const LinuxWebViewWidgetCreationParams({
    super.key,
    required super.controller,
    super.layoutDirection,
    super.gestureRecognizers,
  });

  LinuxWebViewWidgetCreationParams.fromPlatformWebViewWidgetCreationParams(
    PlatformWebViewWidgetCreationParams params,
  ) : this(
        key: params.key,
        controller: params.controller,
        layoutDirection: params.layoutDirection,
        gestureRecognizers: params.gestureRecognizers,
      );
}

@immutable
class LinuxNavigationDelegateCreationParams
    extends PlatformNavigationDelegateCreationParams {
  const LinuxNavigationDelegateCreationParams();

  const LinuxNavigationDelegateCreationParams.fromPlatformNavigationDelegateCreationParams(
    PlatformNavigationDelegateCreationParams params,
  );
}
