import 'package:flutter/material.dart';

class ProductPage extends StatelessWidget {
  final String? id;
  final String? ref;
  const ProductPage({super.key, this.id, this.ref});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: Center(child: Text('id=$id, ref=$ref')),
    );
  }
}
