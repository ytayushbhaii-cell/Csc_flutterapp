import 'package:flutter/material.dart';
import 'signature_maker_screen.dart';

class PngSignatureScreen extends StatelessWidget {
  const PngSignatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignatureMakerScreen(
      title: 'PNG Signature',
      transparentBackground: false,
      toolId: 'signature-png',
    );
  }
}
