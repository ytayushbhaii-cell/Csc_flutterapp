import 'package:flutter/material.dart';
import 'signature_maker_screen.dart';

class TransparentSignatureScreen extends StatelessWidget {
  const TransparentSignatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SignatureMakerScreen(
      title: 'Transparent Signature',
      transparentBackground: true,
      toolId: 'signature-transparent',
    );
  }
}
