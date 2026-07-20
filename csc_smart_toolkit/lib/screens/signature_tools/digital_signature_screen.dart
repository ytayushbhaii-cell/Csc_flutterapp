import 'package:flutter/material.dart';
import 'signature_maker_screen.dart';

class DigitalSignatureScreen extends StatelessWidget {
  const DigitalSignatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignatureMakerScreen(
      title: 'Digital Signature',
      transparentBackground: false,
      whiteBackground: true,
      toolId: 'signature-digital',
    );
  }
}
