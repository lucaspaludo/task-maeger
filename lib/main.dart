import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final toDoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List _tarefas = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _tarefas = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      {
        Map<String, dynamic> newToDo = Map();
        if (_formKey.currentState.validate()) {
          newToDo["title"] = toDoController.text;
          toDoController.text = "";
          newToDo["ok"] = false;
          _tarefas.add(newToDo);
          _saveData();
        }
      }
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _tarefas.sort((x, y) {
        if (x["ok"] && !y["ok"]) {
          return 1;
        } else if (!x["ok"] && y["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 10.0, 1.0),
            child: Form(
              key: _formKey,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      validator: (value) {
                        if (value.isEmpty) return "Digite a sua tarefa.";
                        if (value.length < 4)
                          return "Sua tarefa é muito curta.";
                        return null;
                      },
                      controller: toDoController,
                      decoration: InputDecoration(
                        labelText: "Nova tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  RaisedButton(
                    color: Colors.blueAccent,
                    child: Text("𝔸𝔻𝔻"),
                    textColor: Colors.black,
                    onPressed: _addToDo,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.builder(
                    padding: EdgeInsets.only(top: 10.0),
                    itemCount: _tarefas.length,
                    itemBuilder: buildItem),
              ))
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index) {
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_tarefas[index]["title"]),
        value: _tarefas[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_tarefas[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _tarefas[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_tarefas[index]);
          _lastRemovedPos = index;
          _tarefas.removeAt(index);
          _saveData();
          final snack = SnackBar(
            content:
            Text("Tarefa \"${_lastRemoved["title"]}\" ℝ𝕖𝕞𝕠𝕧𝕚𝕕𝕒!"),
            action: SnackBarAction(
                label: "𝔻𝕖𝕤𝕗𝕒𝕫𝕖𝕣",
                onPressed: () {
                  setState(() {
                    _tarefas.insert(_lastRemovedPos, _lastRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );
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
    String data = json.encode(_tarefas);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
