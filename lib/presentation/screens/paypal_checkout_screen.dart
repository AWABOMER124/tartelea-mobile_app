import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/subscription_provider.dart';
import '../../core/theme/app_colors.dart';

class PayPalCheckoutScreen extends ConsumerStatefulWidget {
  const PayPalCheckoutScreen({super.key});

  @override
  ConsumerState<PayPalCheckoutScreen> createState() => _PayPalCheckoutScreenState();
}

class _PayPalCheckoutScreenState extends ConsumerState<PayPalCheckoutScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..addJavaScriptChannel(
        'PayPalChannel',
        onMessageReceived: (message) {
          if (message.message.startsWith('approved:')) {
            final subscriptionId = message.message.split(':')[1];
            _onSubscriptionApproved(subscriptionId);
          } else if (message.message == 'cancel') {
            Navigator.of(context).pop();
          }
        },
      )
      ..loadHtmlString(_getPayPalHtml());
  }

  void _onSubscriptionApproved(String subscriptionId) async {
    setState(() => _isLoading = true);
    final success = await ref.read(subscriptionContractProvider.notifier).verify(subscriptionId);
    
    if (mounted) {
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر التحقق من الاشتراك. يرجى التواصل مع الدعم.')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('تم الاشتراك بنجاح!'),
        content: const Text('شكراً لانضمامك إلى تـرتـيـلـة Premium. يمكنك الآن الاستمتاع بكافة المزايا.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back from checkout
              Navigator.of(context).pop(); // Go back from pricing
            },
            child: const Text('ابدأ الآن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدفع آمن عبر PayPal'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  String _getPayPalHtml() {
    const clientId = "AXDRH1i1nDBs8LqTA_MV6Vf2PgIpAecYhNFv5ySaWOgcba2qIj_Y5bWF8uIEez2-pJDGbWdhnV5dOnQS";
    const planId = "P-9WT17394MH841673WNGD5T5Q";

    return """
<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <script src="https://www.paypal.com/sdk/js?client-id=$clientId&vault=true&intent=subscription"></script>
    <style>
        body { 
            display: flex; 
            justify-content: center; 
            align-items: center; 
            height: 100vh; 
            margin: 0;
            background-color: #f8fafc;
        }
        #paypal-button-container { width: 90%; }
    </style>
</head>
<body>
    <div id="paypal-button-container"></div>
    <script>
        paypal.Buttons({
            style: {
                shape: 'rect',
                color: 'gold',
                layout: 'vertical',
                label: 'subscribe'
            },
            createSubscription: function(data, actions) {
                return actions.subscription.create({
                    'plan_id': '$planId'
                });
            },
            onApprove: function(data, actions) {
                PayPalChannel.postMessage('approved:' + data.subscriptionID);
            },
            onCancel: function(data) {
                PayPalChannel.postMessage('cancel');
            },
            onError: function(err) {
                console.error(err);
            }
        }).render('#paypal-button-container');
    </script>
</body>
</html>
""";
  }
}
