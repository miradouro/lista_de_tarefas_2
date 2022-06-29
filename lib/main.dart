import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';


void main(){
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _todoControler = TextEditingController();

  List _toDoList = [];

  Map<String, dynamic> _lastRemoved = Map();
  int _lastRemovedPos = 0;


  @override
  void initState() {
    super.initState();
    _realData().then((data) {
      setState((){
        _toDoList = json.decode(data);
      });
    });
  }

  void _addTodo() {
    setState((){
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _todoControler.text;
      _todoControler.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
    });
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));

    setState((){
      _toDoList.sort((a,b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"])return -1;
        else return 0;
      });
      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Compras"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: TextField(
                      controller: _todoControler,
                      decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                ),
                ElevatedButton(
                  onPressed: _addTodo,
                  child: Text("ADD", style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 10),
                      itemCount: _toDoList.length,
                      itemBuilder: buildItem),
                  onRefresh: _refresh,
              ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(context, index){
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white,),
        )
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ), onChanged: (value) {
        setState(() {
          _toDoList[index]["ok"] = value;
          _saveData();
        });
      },
      ),
      onDismissed: (direction){
        setState((){
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
              content: Text("Tarefa ${_lastRemoved["title"]} removida!"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: (){
                setState((){
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).removeCurrentSnackBar();
          Scaffold.of(context).showSnackBar(snack);

        });

      },
    );

  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);

    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _realData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    }catch (e) {
      return "errouuuu...";
    }

  }
}

