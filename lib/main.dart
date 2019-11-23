import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    debugPaintSizeEnabled = false;
    return MaterialApp(
      title: 'ToDo List',
      theme: ThemeData.light(),
      home: ToDoScreen(),
    );
  }
}

class ToDoScreen extends StatefulWidget {
  @override
  _ToDoScreenState createState() => _ToDoScreenState();
}

class _ToDoScreenState extends State<ToDoScreen> {
  List<ToDo> _unCheckedTodoList = [];
  List<ToDo> _checkedTodoList = [];

  @override
  void initState() {
    super.initState();

    _unCheckedTodoList.add(ToDo(text: 'ダミー1'));
    _unCheckedTodoList.add(ToDo(text: 'ダミー2'));
    _unCheckedTodoList.add(ToDo(text: 'ダミー3'));
    _unCheckedTodoList.add(ToDo(text: 'ダミー4'));
    _unCheckedTodoList.add(ToDo(text: 'ダミー5'));
    _checkedTodoList.add(ToDo(text: 'ダミー6', isDone: true));
    _checkedTodoList.add(ToDo(text: 'ダミー7', isDone: true));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('GoriDev'),
        ),
        body: ListView.builder(
          itemCount: _unCheckedTodoList.length + _checkedTodoList.length,
          itemBuilder: (BuildContext context, index) {
            ToDo todo = index < _unCheckedTodoList.length
                ? _unCheckedTodoList[index]
                : _checkedTodoList[index - _unCheckedTodoList.length];
            return ListTile(
              leading: IconButton(
                icon: Icon(todo.isDone
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
                onPressed: () {
                  setState(() {
                    // ! クソダサコード注意
                    if (!todo.isDone) {
                      _checkedTodoList.insert(0, todo);
                      _unCheckedTodoList.remove(todo);
                    } else {
                      _unCheckedTodoList.insert(0, todo);
                      _checkedTodoList.remove(todo);
                    }
                    todo.toggle();
                  });
                },
              ),
              title: Text(todo.text),
            );
          },
        ),
        floatingActionButton: AddTodoButton(),
      ),
    );
  }
}

class AddTodoButton extends StatefulWidget {
  @override
  _AddTodoButtonState createState() => _AddTodoButtonState();
}

class _AddTodoButtonState extends State<AddTodoButton> {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: null,
      child: Icon(
        Icons.add,
        size: 32,
      ),
      onPressed: () async {
        await showModalBottomSheet<Widget>(
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          builder: (BuildContext context) {
            return SafeArea(
              child: Container(
                margin: (MediaQuery.of(context).viewInsets.bottom > 0)
                    ? EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom)
                    : EdgeInsets.all(0.0),
                padding: EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 0.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 4.0),
                    ),
                    TextField(
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                        border: InputBorder.none,
                        labelText: '新しいタスク',
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.menu),
                              onPressed: () {},
                            ),
                            IconButton(
                              icon: Icon(Icons.calendar_today),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            FlatButton(
                              child: Text(
                                '保存',
                                style: TextStyle(
                                  fontSize: 16.0,
                                ),
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ToDo {
  String text;
  bool isDone;
  ToDo({@required this.text, this.isDone = false});

  void toggle() => isDone = !isDone;
}
