// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:web/web.dart' as web;
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_all_web/webview_all_web.dart';

import 'web_webview_controller_test.mocks.dart';

@GenerateMocks(
  <Type>[],
  customMocks: <MockSpec<Object>>[
    MockSpec<HttpRequestFactory>(onMissingStub: OnMissingStub.returnDefault),
  ],
)
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('WebWebViewController', () {
    group('WebWebViewControllerCreationParams', () {
      test('sets iFrame fields', () {
        final params = WebWebViewControllerCreationParams();

        expect(params.iFrame.id, contains('webView'));
        expect(params.iFrame.style.width, '100%');
        expect(params.iFrame.style.height, '100%');
        expect(params.iFrame.style.borderStyle, 'none');
        expect(params.iFrame.style.borderWidth, '0px');
      });
    });

    group('loadHtmlString', () {
      test('loadHtmlString loads html into iframe', () async {
        final controller = WebWebViewController(
          WebWebViewControllerCreationParams(),
        );

        await controller.loadHtmlString('test html');
        expect(
          (controller.params as WebWebViewControllerCreationParams).iFrame.src,
          'data:text/html;charset=utf-8,${Uri.encodeFull('test html')}',
        );
      });

      test('loadHtmlString keeps logical current URL', () async {
        final controller = WebWebViewController(
          WebWebViewControllerCreationParams(),
        );

        await controller.loadHtmlString(
          '<p>content</p>',
          baseUrl: 'https://example.com/base/',
        );

        expect(await controller.currentUrl(), 'https://example.com/base/');
      });

      test('loadHtmlString escapes "#" correctly', () async {
        final controller = WebWebViewController(
          WebWebViewControllerCreationParams(),
        );

        await controller.loadHtmlString('#');
        expect(
          (controller.params as WebWebViewControllerCreationParams).iFrame.src,
          contains('%23'),
        );
      });
    });

    group('loadRequest', () {
      test('throws ArgumentError on missing scheme', () async {
        final controller = WebWebViewController(
          WebWebViewControllerCreationParams(),
        );

        await expectLater(
          () async => controller.loadRequest(
            LoadRequestParams(uri: Uri.parse('flutter.dev')),
          ),
          throwsA(const TypeMatcher<ArgumentError>()),
        );
      });

      test('skips XHR for simple GETs (no headers, no data)', () async {
        final mockHttpRequestFactory = MockHttpRequestFactory();
        final controller = WebWebViewController(
          WebWebViewControllerCreationParams(
            httpRequestFactory: mockHttpRequestFactory,
          ),
        );

        when(
          mockHttpRequestFactory.request(
            any,
            method: anyNamed('method'),
            requestHeaders: anyNamed('requestHeaders'),
            sendData: anyNamed('sendData'),
          ),
        ).thenThrow(
          StateError('The `request` method should not have been called.'),
        );

        await controller.loadRequest(
          LoadRequestParams(uri: Uri.parse('https://flutter.dev')),
        );

        expect(
          (controller.params as WebWebViewControllerCreationParams).iFrame.src,
          'https://flutter.dev/',
        );
        expect(await controller.currentUrl(), 'https://flutter.dev');
      });

      test('makes request and loads response into iframe', () async {
        final mockHttpRequestFactory = MockHttpRequestFactory();
        final controller = WebWebViewController(
          WebWebViewControllerCreationParams(
            httpRequestFactory: mockHttpRequestFactory,
          ),
        );

        final fakeResponse = web.Response(
          'test data'.toJS,
          <String, Object>{
                'headers': <String, Object>{'content-type': 'text/plain'},
              }.jsify()!
              as web.ResponseInit,
        );

        when(
          mockHttpRequestFactory.request(
            any,
            method: anyNamed('method'),
            requestHeaders: anyNamed('requestHeaders'),
            sendData: anyNamed('sendData'),
          ),
        ).thenAnswer((_) => Future<web.Response>.value(fakeResponse));

        await controller.loadRequest(
          LoadRequestParams(
            uri: Uri.parse('https://flutter.dev'),
            method: LoadRequestMethod.post,
            body: Uint8List.fromList('test body'.codeUnits),
            headers: const <String, String>{'Foo': 'Bar'},
          ),
        );

        verify(
          mockHttpRequestFactory.request(
            'https://flutter.dev',
            method: 'post',
            requestHeaders: <String, String>{'Foo': 'Bar'},
            sendData: Uint8List.fromList('test body'.codeUnits),
          ),
        );

        expect(
          (controller.params as WebWebViewControllerCreationParams).iFrame.src,
          'data:;charset=utf-8,${Uri.encodeFull('test data')}',
        );
        expect(await controller.currentUrl(), 'https://flutter.dev');
      });

      test('parses content-type response header correctly', () async {
        final mockHttpRequestFactory = MockHttpRequestFactory();
        final controller = WebWebViewController(
          WebWebViewControllerCreationParams(
            httpRequestFactory: mockHttpRequestFactory,
          ),
        );

        final Encoding iso = Encoding.getByName('latin1')!;

        final fakeResponse = web.Response(
          String.fromCharCodes(iso.encode('España')).toJS,
          <String, Object>{
                'headers': <String, Object>{
                  'content-type': 'Text/HTmL; charset=latin1',
                },
              }.jsify()!
              as web.ResponseInit,
        );

        when(
          mockHttpRequestFactory.request(
            any,
            method: anyNamed('method'),
            requestHeaders: anyNamed('requestHeaders'),
            sendData: anyNamed('sendData'),
          ),
        ).thenAnswer((_) => Future<web.Response>.value(fakeResponse));

        await controller.loadRequest(
          LoadRequestParams(
            uri: Uri.parse('https://flutter.dev'),
            method: LoadRequestMethod.post,
          ),
        );

        expect(
          (controller.params as WebWebViewControllerCreationParams).iFrame.src,
          'data:text/html;charset=iso-8859-1,Espa%F1a',
        );
      });

      test('escapes "#" correctly', () async {
        final mockHttpRequestFactory = MockHttpRequestFactory();
        final controller = WebWebViewController(
          WebWebViewControllerCreationParams(
            httpRequestFactory: mockHttpRequestFactory,
          ),
        );

        final fakeResponse = web.Response(
          '#'.toJS,
          <String, Object>{
                'headers': <String, Object>{'content-type': 'text/html'},
              }.jsify()!
              as web.ResponseInit,
        );

        when(
          mockHttpRequestFactory.request(
            any,
            method: anyNamed('method'),
            requestHeaders: anyNamed('requestHeaders'),
            sendData: anyNamed('sendData'),
          ),
        ).thenAnswer((_) => Future<web.Response>.value(fakeResponse));

        await controller.loadRequest(
          LoadRequestParams(
            uri: Uri.parse('https://flutter.dev'),
            method: LoadRequestMethod.post,
            body: Uint8List.fromList('test body'.codeUnits),
            headers: const <String, String>{'Foo': 'Bar'},
          ),
        );

        expect(
          (controller.params as WebWebViewControllerCreationParams).iFrame.src,
          contains('%23'),
        );
      });

      test(
        'reports XHR request failures as main-frame resource errors',
        () async {
          final mockHttpRequestFactory = MockHttpRequestFactory();
          final controller = WebWebViewController(
            WebWebViewControllerCreationParams(
              httpRequestFactory: mockHttpRequestFactory,
            ),
          );
          final delegate = WebNavigationDelegate(
            const WebNavigationDelegateCreationParams(),
          );
          WebResourceError? resourceError;

          await delegate.setOnWebResourceError((WebResourceError error) {
            resourceError = error;
          });
          await controller.setPlatformNavigationDelegate(delegate);

          when(
            mockHttpRequestFactory.request(
              any,
              method: anyNamed('method'),
              requestHeaders: anyNamed('requestHeaders'),
              sendData: anyNamed('sendData'),
            ),
          ).thenThrow(StateError('network down'));

          await expectLater(
            () => controller.loadRequest(
              LoadRequestParams(
                uri: Uri.parse('https://flutter.dev'),
                method: LoadRequestMethod.post,
              ),
            ),
            throwsStateError,
          );

          expect(resourceError, isNotNull);
          expect(resourceError!.isForMainFrame, isTrue);
          expect(resourceError!.errorType, WebResourceErrorType.connect);
          expect(resourceError!.url, 'https://flutter.dev');
        },
      );
    });

    group('loadFlutterAsset', () {
      test(
        'resolves Flutter web asset URLs under the assets directory',
        () async {
          final controller = WebWebViewController(
            WebWebViewControllerCreationParams(),
          );

          await controller.loadFlutterAsset('docs/My File.html');

          expect(
            (controller.params as WebWebViewControllerCreationParams)
                .iFrame
                .src,
            Uri.base.resolve('assets/docs/My%20File.html').toString(),
          );
        },
      );

      test('rejects empty asset keys', () async {
        final controller = WebWebViewController(
          WebWebViewControllerCreationParams(),
        );

        await expectLater(
          () => controller.loadFlutterAsset(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('rejects root-only asset keys', () async {
        final controller = WebWebViewController(
          WebWebViewControllerCreationParams(),
        );

        await expectLater(
          () => controller.loadFlutterAsset('/'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('userAgent', () {
      test(
        'does not report unsupported user agent overrides as applied',
        () async {
          final controller = WebWebViewController(
            WebWebViewControllerCreationParams(),
          );
          final String? originalUserAgent = await controller.getUserAgent();

          await expectLater(
            () => controller.setUserAgent('custom-agent'),
            throwsUnsupportedError,
          );

          expect(await controller.getUserAgent(), originalUserAgent);
        },
      );
    });
  });
}
