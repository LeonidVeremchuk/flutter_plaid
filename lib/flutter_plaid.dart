library flutter_plaid;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart';
import 'package:webview_flutter/webview_flutter.dart';

class FlutterPlaidApi {
  Configuration _configuration;

  FlutterPlaidApi(Configuration configuration) {
    this._configuration = configuration;
  }

  /// stripeToken = false use for get plaid token and accountId
  /// stripeToken = true: use for add the new payment method, returns stripe_token
  launch(BuildContext context, success(Result result),
      {bool stripeToken = false}) {
    _WebViewPage _webViewPage = new _WebViewPage();
    _webViewPage._init(this._configuration, success, stripeToken, context);

    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return _webViewPage.build(context);
    }));
  }
}

class _WebViewPage {
  String _url;
  Function(Result result) _success;
  Configuration _config;
  bool _stripeToken;
  BuildContext _context;

  _init(Configuration config, success(Result result), bool stripeToken,
      BuildContext context) {
    this._success = success;
    this._config = config;
    this._stripeToken = stripeToken;
    this._context = context;
    _url = config.plaidBaseUrl +
        '?key=' +
        config.plaidPublicKey +
        '&isWebview=true' +
        '&product=auth' +
        '&isMobile=true' +
        '&apiVersion=v2' +
        '&selectAccount=true' +
        '&webhook=https://requestb.in' +
        '&env=' +
        config.plaidEnvironment;
    debugPrint('init plaid: ' + _url);
  }

  _parseUrl(String url) {
    if (url?.isNotEmpty != null) {
      Uri uri = Uri.parse(url);
      debugPrint('PLAID uri: ' + uri.toString());
      Map<String, String> queryParams = uri.queryParameters;
      List<String> segments = uri.pathSegments;
      debugPrint('queryParams: ' + queryParams?.toString());
      debugPrint('segments: ' + segments?.toString());
      _processParams(queryParams, url);
    }
  }

  _processParams(Map<String, String> queryParams, String url) async {
    if (queryParams != null) {
      String eventName = queryParams['event_name'] ?? 'unknow';
      debugPrint("PLAID Event name: " + eventName);

      if (eventName == 'EXIT' || (url?.contains('/exit?') ?? false)) {
        this._closeWebView();
      } else if (eventName == 'HANDOFF') {
        this._closeWebView();
      }
      dynamic token = queryParams['public_token'];
      dynamic accountId = queryParams['account_id'];
      if (token != null && accountId != null) {
        if (!_stripeToken) {
          this._success(Result(token, accountId, queryParams));
        } else {
          await this._fetchStripeToken(token, accountId);
        }
      }
    }
  }

  _fetchStripeToken(String token, String accountId) async {
    var headers = {'Content-Type': 'application/json'};

    Response responseAccessToken =
        await post(_config.environmentPlaidPathAccessToken,
            body: json.encode({
              'public_token': token,
              'client_id': this._config.plaidClientId,
              'secret': this._config.secret
            }),
            headers: headers);
    var accessTokenData =
        json.decode(utf8.decode(responseAccessToken.bodyBytes));
    String accessToken = accessTokenData['access_token'];

    Response responseStripeToken =
        await post(_config.environmentPlaidPathStripeToken,
            body: json.encode({
              'client_id': this._config.plaidClientId,
              'secret': this._config.secret,
              'access_token': accessToken,
              'account_id': accountId
            }),
            headers: headers);

    var stripeTokenData =
        json.decode(utf8.decode(responseStripeToken.bodyBytes));
    _success(Result(
        stripeTokenData['stripe_bank_account_token'], null, stripeTokenData));
  }

  _closeWebView() {
    if (_context != null && Navigator.canPop(_context)) {
      Navigator.pop(_context);
    }
  }

  Widget build(BuildContext context) {
    var webView = new WebView(
      initialUrl: _url,
      javascriptMode: JavascriptMode.unrestricted,
      navigationDelegate: (NavigationRequest navigation) {
        if (navigation.url.contains('plaidlink://')) {
          this._parseUrl(navigation.url);
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    );
    return Scaffold(body: webView);
  }
}

class Configuration {
  String plaidPublicKey;
  String plaidBaseUrl;
  String plaidEnvironment;
  String environmentPlaidPathAccessToken;
  String environmentPlaidPathStripeToken;
  String plaidClientId;
  String secret;

  Configuration(
      {@required this.plaidPublicKey,
      @required this.plaidBaseUrl,
      @required this.plaidEnvironment,
      @required this.environmentPlaidPathAccessToken,
      @required this.environmentPlaidPathStripeToken,
      @required this.plaidClientId,
      @required this.secret});
}

class Result {
  String token;
  String accountId;
  dynamic response;

  Result(this.token, this.accountId, this.response);
}
