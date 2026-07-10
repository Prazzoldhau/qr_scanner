import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with WidgetsBindingObserver {
  MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  bool _hadError = false;

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
    // If the camera failed (e.g. permission denied) and the user goes to
    // system Settings to grant it, retry automatically when they come back.
    if (state == AppLifecycleState.resumed && _hadError) {
      _retry();
    }
  }

  // Recreate the controller from scratch — restarting a controller whose
  // camera failed to open does not recover it, it must be rebuilt.
  void _retry() {
    setState(() {
      _hadError = false;
      _controller.dispose();
      _controller = MobileScannerController();
    });
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final String? token = capture.barcodes.firstOrNull?.rawValue;
    if (token == null || token.isEmpty) return;

    setState(() => _processing = true);
    _controller.stop();

    try {
      final api = ApiService();
      await api.init();
      final result = await api.qrLogin(token);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(patientData: result)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
      _controller.start();
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
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
          // Scan window outline
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
              'Point your camera at a QR code',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          if (_processing)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}

// Dart <3.0 fallback — firstOrNull on List
extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
