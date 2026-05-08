import 'package:flutter/material.dart';
import 'package:second_mart/widgets/step_indicator.dart';

class DemeoPage extends StatefulWidget {
  const DemeoPage({super.key});

  @override
  State<DemeoPage> createState() => _DemeoPageState();
}

class _DemeoPageState extends State<DemeoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: CustomStepIndicator(
            current: 1,
            steps: [
              "Cart",
              "Shipping Address",
              "Payment Method policy",
              "Done",
            ],
            primary: Colors.blue,
            isDark: false,
          ),
        ),
      ),
    );
  }
}
