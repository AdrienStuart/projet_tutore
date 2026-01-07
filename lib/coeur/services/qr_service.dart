
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';

class QRService {
  // Générer QR Code Widget
  static Widget generateQRCode(String data, {double size = 200}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
    );
  }
  
  // Scanner QR Code (retourne le widget du scanner)
  static Widget buildQRScanner({
    required Function(String) onScan,
    required Function(String) onError,
  }) {
    return QRScannerWidget(
      onScan: onScan,
      onError: onError,
    );
  }
}

class QRScannerWidget extends StatefulWidget {
  final Function(String) onScan;
  final Function(String) onError;
  
  const QRScannerWidget({
    required this.onScan,
    required this.onError,
    Key? key,
  }) : super(key: key);
  
  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
  
  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null) {
        widget.onScan(scanData.code!);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.green,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: 300,
      ),
    );
  }
}
