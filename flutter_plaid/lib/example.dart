import 'package:flutter/widgets.dart';
import 'package:flutter_plaid/flutter_plaid.dart';

class _Example extends State {

  showPlaidView() {
    bool plaidSandbox = false;

    Configuration configuration = Configuration(
        plaidPublicKey: 'yourPublicKey',
        plaidBaseUrl: 'https://cdn.plaid.com/link/v2/stable/link.html',
        plaidEnvironment: plaidSandbox ? 'sandbox' : 'production',
        environmentPlaidPathAccessToken:
            'https://sandbox.plaid.com/item/public_token/exchange',
        environmentPlaidPathStripeToken:
            'https://sandbox.plaid.com/processor/stripe/bank_account_token/create',
        plaidClientId: 'yourPlaidClientId',
        secret: plaidSandbox ? 'yourSecret' : '');

    FlutterPlaidApi flutterPlaidApi = FlutterPlaidApi(configuration);
    flutterPlaidApi.launch(context, (Result result) {
      ///handle result
    }, stripeToken: true);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
