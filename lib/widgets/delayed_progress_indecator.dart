import 'package:flutter/material.dart';

class DelayedProgressIndicator extends StatefulWidget {
  const DelayedProgressIndicator({super.key});
  @override
  State<DelayedProgressIndicator> createState() =>
      _DelayedProgressIndicatorState();
}

class _DelayedProgressIndicatorState extends State<DelayedProgressIndicator> {
  late Future<void> duration;
  @override
  void initState() {
    duration = Future<void>.delayed(const Duration(seconds: 5));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: duration,
        builder: (BuildContext context, AsyncSnapshot<void> data) {
          if (data.hasData) {
            return const CircularProgressIndicator();
          } else {
            return const SizedBox(
              height: 1,
            );
          }
        });
  }
}
