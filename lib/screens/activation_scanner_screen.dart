import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Scans an activation card's QR and pops the scanned code back to the
// caller (the activation gate), which does the actual redeem API call -
// keeps that logic in one place instead of duplicated across screens.
class ActivationScannerScreen extends StatefulWidget {
  const ActivationScannerScreen({super.key});

  @override
  State<ActivationScannerScreen> createState() => _ActivationScannerScreenState();
}

class _ActivationScannerScreenState extends State<ActivationScannerScreen> with WidgetsBindingObserver {
  MobileScannerController _controller = MobileScannerController();
  bool _hadError = false;
  bool _detected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _hadError) {
      _retry();
    }
  }

  void _retry() {
    setState(() {
      _hadError = false;
      _controller.dispose();
      _controller = MobileScannerController();
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final String? code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _detected = true;
    Navigator.pop(context, code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Activation Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            key: ValueKey(_controller),
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              _hadError = true;
              final bool permissionDenied =
                  error.errorCode == MobileScannerErrorCode.permissionDenied;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.camera_alt, color: Colors.white54, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        permissionDenied
                            ? 'Camera permission denied.\nEnable Camera access for Sajhya in your phone Settings, then tap Retry.'
                            : 'Could not open the camera.\n(${error.errorCode.name})',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white70, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              'Point your camera at the activation card\'s QR code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
