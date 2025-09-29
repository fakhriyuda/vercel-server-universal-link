import 'package:flutter/material.dart';
import 'package:iseng/page3.dart';

class PageTwo extends StatefulWidget {
  const PageTwo({super.key});

  @override
  State<PageTwo> createState() => _PageTwoState();
}

class _PageTwoState extends State<PageTwo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Two'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        color: Colors.red,
        child: InkWell(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (ctx) => const PageThree())),
          child: Text('This is Page Two')),
      ),
    );
  }
}