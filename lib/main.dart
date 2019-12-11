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
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<ToDo> _todoList = [];
  bool _isHideCheckedTodoList = false;

  List<ToDo> get checkedToDoList => _todoList.where((todo) => todo.isDone);
  List<ToDo> get uncheckedToDoList => _todoList.where((todo) => !todo.isDone);

  List<ToDoListItem> get todoList => []
    ..addAll(uncheckedToDoList.toList())
    ..add(SectionTitle(title: '完了済み'))
    ..addAll(checkedToDoList.toList());

  AnimatedListState get _animatedList => _listKey.currentState;

  @override
  void initState() {
    super.initState();
  }

  void _handleListItemTap(ToDo todo) async {
    print('onTap');
    setState(() async {
      // アニメーションのduration
      var deleteDuration = Duration(milliseconds: 275);
      var insertDuration = Duration(milliseconds: 225);
      var delay = deleteDuration;

      // リストから削除
      var removedIndex = _todoList.indexOf(todo);
      ToDo removedToDo = _todoList.removeAt(removedIndex);
      _animatedList.removeItem(
        removedIndex,
        (context, animation) => _buildAnimatedListItem(removedToDo, animation),
        duration: deleteDuration,
      );
      await new Future.delayed(delay);

      // チェック状態を変更
      todo.toggle();

      // リストの先頭に追加
      _todoList.insert(0, removedToDo);
      _animatedList.insertItem(
        0,
        duration: insertDuration,
      );
    });
  }

  void _createToDo(String todoText) {
    // TODO: アニメーションインサート処理を関数化する
    var todo = ToDo(text: todoText);
    _todoList.insert(0, todo);
    _animatedList.insertItem(0);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text('GoriDev'),
        ),
        body: AnimatedList(
          key: _listKey,
          initialItemCount: todoList.length,
          itemBuilder: (context, index, animation) {
            ToDoListItem todo = todoList[index];
            if (todo is ToDo) {
              if (todo.isDone && _isHideCheckedTodoList) return null;
              return _buildAnimatedListItem(todo, animation);
            }
            if (todo is SectionTitle) {
              List<Widget> ret = [];
              if (uncheckedToDoList.isEmpty) ret.add(_buildEmptySheet());
              if (checkedToDoList.isNotEmpty)
                ret.add(_buildCheckedSectionHeader());
              return Column(children: ret);
            }
            return null;
          },
        ),
        floatingActionButton: AddTodoButton(
          onFormSubmit: _createToDo,
        ),
      ),
    );
  }

  Widget _buildAnimatedListItem(ToDo todo, Animation animation) {
    return Dismissible(
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 16.0),
        child: Icon(Icons.delete_forever),
      ),
      key: Key(todo.hashCode.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        void Function() onPressed;
        setState(() {
          // ! クソダサコード注意
          // TODO: デリート処理を共通化する
          // TODO: snackbar処理を共通化する
          if (!todo.isDone) {
            var removedIndex = _unCheckedTodoList.indexOf(todo);
            var removedToDo = _unCheckedTodoList.removeAt(removedIndex);
            _animatedList.removeItem(
              removedIndex,
              (context, animation) =>
                  _buildAnimatedListItem(removedToDo, animation),
              // durationを0にしないとdismissibleの削除アニメーションと重複してエラーが出るっぽい
              // 根本的な解決方法の模索が必要
              duration: Duration(milliseconds: 0),
            );

            onPressed = () {
              // TODO: インサート処理を共通化する
              _unCheckedTodoList.insert(removedIndex, removedToDo);
              _animatedList.insertItem(removedIndex);
            };
          } else {
            var checkedListIndex = _checkedTodoList.indexOf(todo);
            var removedIndex = _unCheckedTodoList.length + 1 + checkedListIndex;
            var removedToDo = _checkedTodoList.removeAt(checkedListIndex);
            _animatedList.removeItem(
              removedIndex,
              (context, animation) =>
                  _buildAnimatedListItem(removedToDo, animation),
              duration: Duration(milliseconds: 0),
            );

            onPressed = () {
              // TODO: インサート処理を共通化する
              _checkedTodoList.insert(checkedListIndex, removedToDo);
              _animatedList.insertItem(removedIndex);
            };
          }
        });
        final snackBar = SnackBar(
          content: Text('タスクを削除しました'),
          action: SnackBarAction(
            label: '元に戻す',
            onPressed: onPressed,
          ),
        );
        _scaffoldKey.currentState.showSnackBar(snackBar);
      },
      child: ScaleTransition(
        scale: animation.drive(
          CurveTween(
            curve: const Interval(0, 1, curve: Curves.fastOutSlowIn),
          ),
        ),
        child: ToDoListItemView(
          todo: todo,
          onPressed: _handleListItemTap,
        ),
      ),
    );
  }

  Widget _buildCheckedSectionHeader() {
    return ListTile(
      title: Text('完了済み', style: TextStyle(fontSize: 12.0)),
      trailing: IconButton(
        icon: Icon(
          _isHideCheckedTodoList ? Icons.expand_more : Icons.expand_less,
          size: 20.0,
        ),
        onPressed: () {
          setState(() {
            _isHideCheckedTodoList = !_isHideCheckedTodoList;
          });
        },
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

class ToDoListItemView extends StatelessWidget {
  final ToDo todo;
  final void Function(ToDo todo) onPressed;
  ToDoListItemView({Key key, @required this.todo, this.onPressed})
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
    // テキス���フィールドをクリアする
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

abstract class ToDoListItem {}

class ToDo extends ToDoListItem {
  String text;
  bool isDone;
  ToDo({@required this.text, this.isDone = false});

  void toggle() => isDone = !isDone;
}

class SectionTitle extends ToDoListItem {
  String title;
  SectionTitle({@required this.title});
}
