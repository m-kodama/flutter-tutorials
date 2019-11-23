import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChangeNotifierProvider(
        builder: (_) {
          return Counter(0);
        },
        child: MyHomePage(),
      ),
    );
  }
}

class Hoge with ChangeNotifier {
  int _value;
}

class Counter with ChangeNotifier {
  int _value;
  String _text = 'initial text';

  Counter(this._value);

  int get value => this._value;
  String get text => 'TEXT: ${this._text}';

  _increment() {
    _value++;
    notifyListeners();
  }

  _newText(String newText) {
    _text = newText + newText;
    notifyListeners();
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Provider Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            WidgetCenterText(),
            WidgetNumText(),
          ],
        ),
      ),
      floatingActionButton: IncrementButton(),
    );
  }
}

class WidgetCenterText extends StatelessWidget {
  const WidgetCenterText({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Text('You have pushed the button this many times:');
  }
}

class WidgetNumText extends StatelessWidget {
  const WidgetNumText({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Counter counter = Provider.of(context);
    return Text(
      '${counter.text} ${counter.value}',
      style: Theme.of(context).textTheme.display1,
    );
  }
}

class IncrementButton extends StatelessWidget {
  const IncrementButton({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Counter counter = Provider.of(context);
    return FloatingActionButton(
      onPressed: () {
        counter._newText('hoge');
        counter._increment();
      },
      tooltip: 'インクリメント',
      child: Icon(Icons.add),
    );
  }
}
// class MyHomePage extends StatefulWidget {
//   MyHomePage({Key key, this.title}) : super(key: key);
//   final String title;

//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.display1,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
