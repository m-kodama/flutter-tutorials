import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    debugPaintSizeEnabled = false;
    return MaterialApp(
      title: 'ToDo List',
      theme: ThemeData.dark(),
      home: ToDoScreen(),
    );
  }
}

class ToDoScreen extends StatefulWidget {
  @override
  _ToDoScreenState createState() => _ToDoScreenState();
}

class _ToDoScreenState extends State<ToDoScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<ToDo> _unCheckedTodoList = [];
  List<ToDo> _checkedTodoList = [];

  List<ToDo> get _todoList => List.from(_unCheckedTodoList)
    ..add(null)
    ..addAll(_checkedTodoList);

  AnimatedListState get _animatedList => _listKey.currentState;

  @override
  void initState() {
    super.initState();
  }

  void _handleListItemTap(ToDo todo) {
    print('onTap');
    setState(() {
      // ! クソダサコード注意
      if (!todo.isDone) {
        var removedIndex = _unCheckedTodoList.indexOf(todo);
        ToDo removedToDo = _unCheckedTodoList.removeAt(removedIndex);
        _animatedList.removeItem(
          removedIndex,
          (context, animation) =>
              _buildAnimatedListItem(removedToDo, animation),
        );
        _checkedTodoList.insert(0, todo);
        _animatedList.insertItem(_unCheckedTodoList.length + 1);
      } else {
        var removedIndex =
            _unCheckedTodoList.length + 1 + _checkedTodoList.indexOf(todo);
        ToDo removedToDo =
            _checkedTodoList.removeAt(_checkedTodoList.indexOf(todo));
        _animatedList.removeItem(
          removedIndex,
          (context, animation) =>
              _buildAnimatedListItem(removedToDo, animation),
        );
        _unCheckedTodoList.insert(0, todo);
        _animatedList.insertItem(0);
      }
      todo.toggle();
    });
  }

  void _createToDo(String todoText) {
    // TODO: アニメーションインサート処理を関数化する
    var todo = ToDo(text: todoText);
    _unCheckedTodoList.insert(0, todo);
    _animatedList.insertItem(0);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text('GoriDev'),
        ),
        body: AnimatedList(
          key: _listKey,
          initialItemCount: _todoList.length,
          itemBuilder: (context, index, animation) {
            ToDo todo = _todoList[index];
            // nullの時はセクション区切りを表示する（nullでリスト区切りを表現するのはヤバいが...）
            // TODO: ここのコード整理したい
            if (todo != null) return _buildAnimatedListItem(todo, animation);
            if (_unCheckedTodoList.isEmpty && _checkedTodoList.isEmpty)
              return _buildEmptySheet();
            if (_checkedTodoList.isNotEmpty)
              return Container(
                padding: EdgeInsets.all(16.0),
                child: Text('完了済み'),
              );
            return null;
          },
        ),
        floatingActionButton: AddTodoButton(
          onFormSubmit: _createToDo,
        ),
        // FABをcenterにおきたい時はこれ
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildAnimatedListItem(ToDo todo, Animation animation) {
    return ScaleTransition(
      scale: animation.drive(
        CurveTween(
          curve: const Interval(0, 1, curve: Curves.fastOutSlowIn),
        ),
      ),
      child: ToDoListItem(
        todo: todo,
        onPressed: _handleListItemTap,
      ),
    );
  }

  Widget _buildEmptySheet() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          padding: EdgeInsets.fromLTRB(32, 64, 32, 0),
          child: Image.asset(
            'assets/images/empty_image.png',
          ),
        ),
        Text(
          'やるべきことはありません',
          style: Theme.of(context).primaryTextTheme.body1,
        ),
        Text(
          'タスクを追加してみましょう',
          style: Theme.of(context).primaryTextTheme.caption,
        ),
      ],
    );
  }
}

class ToDoListItem extends StatelessWidget {
  final ToDo todo;
  final void Function(ToDo todo) onPressed;
  ToDoListItem({Key key, @required this.todo, this.onPressed})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        icon: Icon(todo.isDone ? Icons.check : Icons.radio_button_unchecked),
        onPressed: () {
          this.onPressed(todo);
        },
      ),
      title: Text(todo.text),
    );
  }
}

class AddTodoButton extends StatefulWidget {
  final void Function(String todo) onFormSubmit;
  AddTodoButton({Key key, this.onFormSubmit}) : super(key: key);

  @override
  _AddTodoButtonState createState() => _AddTodoButtonState();
}

class _AddTodoButtonState extends State<AddTodoButton> {
  final inputTodoTextController = TextEditingController();

  void _handleSaveButtonTap() {
    // フォームが空ならボトムシートを閉じる
    if (inputTodoTextController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }
    widget.onFormSubmit(inputTodoTextController.text);
    // テキストフィールドをクリアする
    inputTodoTextController.clear();
    // ボトムシートを閉じる
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: null,
      icon: Icon(
        Icons.edit,
        // size: 32,
      ),
      label: Text(
        'タスクを追加',
        style: TextStyle(fontWeight: FontWeight.bold),
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
                    TextFormField(
                      autofocus: true,
                      controller: inputTodoTextController,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (text) {
                        _handleSaveButtonTap();
                      },
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.0),
                        border: InputBorder.none,
                        labelText: '新しいタスク',
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 8.0),
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
                              onPressed: _handleSaveButtonTap,
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

  @override
  void dispose() {
    inputTodoTextController.dispose();
    super.dispose();
  }
}

class ToDo {
  String text;
  bool isDone;
  ToDo({@required this.text, this.isDone = false});

  void toggle() => isDone = !isDone;
}
