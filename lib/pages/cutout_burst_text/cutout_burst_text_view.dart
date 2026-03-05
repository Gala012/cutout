import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'cutout_burst_text_logic.dart';

class CutoutBurstTextView extends GetView<CutoutBurstTextLogic> {
  const CutoutBurstTextView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(
          () => controller.xcqimn.value
              ? const CircularProgressIndicator(color: Colors.blueAccent)
              : buildError(),
        ),
      ),
    );
  }

  Widget buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: () {
              controller.vrzuoawm();
            },
            icon: const Icon(
              Icons.restart_alt,
              size: 50,
            ),
          ),
        ],
      ),
    );
  }
}
