import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class PageOne extends StatelessWidget {
  const PageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.blue,
      child: Container(
        color: Colors.white,
        child: TextButton(
          onPressed: (){
            Navigator.push(context,
                MaterialPageRoute(builder: (context) =>  const PageTwo())
            ).then((_){
              print("returned");
            });
          },
          child: const Text("go to page 2"),
        ),
      ),
    );
  }
}

class PageTwo extends StatelessWidget {
  const PageTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.green,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: Center(
              child: TextButton(
                onPressed: (){
                  //Navigator.push(context, MaterialPageRoute(builder: (context) =>  const PageThree()));
                  Navigator.push(context, MaterialPageRoute(builder: (context) =>  const SizedBox()));
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  const PageThree()));
                },
                child: const Text("go to page 3"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PageThree extends StatelessWidget {
  const PageThree({super.key});
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.red,
      child: Container(
        color: Colors.white,
        child: TextButton(
          onPressed: (){
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: const Text("this is page 3")
        ),
      ),
    );
  }
}
