import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return Text("text $index");
            },
          ),
          DraggableScrollableSheet(
            maxChildSize: 0.5,
            builder: (BuildContext context, ScrollController controller) {
              return Container(
                color: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: ListView.builder(
                  controller: controller,
                  itemCount: 10,
                  itemBuilder: (BuildContext context, int index) {
                    return Text("text $index");
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
