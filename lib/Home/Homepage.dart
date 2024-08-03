import 'package:crud_operation/Home/SQLHelper.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';



class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Map<String, dynamic>> _journals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshJournals();
    _printTableNames();
  }

  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _journals = data;
      _isLoading = false;
      print('..number of items ${_journals.length}'); // just for testing
    });
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<List<String>> getAllTableNames(Database dbClient) async {
    List<Map> maps = await dbClient.rawQuery('SELECT * FROM sqlite_master WHERE type="table" ORDER BY name;');

    List<String> tableNameList = [];
    if (maps.isNotEmpty) {
      for (int i = 0; i < maps.length; i++) {
        try {
          tableNameList.add(maps[i]['name'].toString());
        } catch (e) {
          print('Exception: ' + e.toString());
        }
      }
    }
    return tableNameList;
  }

  Future<void> _printTableNames() async {
    final db = await SQLHelper.db();
    final tableNames = await getAllTableNames(db);
    print('Table names: $tableNames');
    for (var tableName in tableNames) {
      await _printTableEntries(db, tableName);
    }
  }

  Future<void> _printTableEntries(Database dbClient, String tableName) async {
    List<Map<String, dynamic>> entries = await dbClient.query(tableName);
    print('Entries for table $tableName: $entries');
  }

  void _showForm(int? id, BuildContext context) async {
    if (id != null) {
      final existingJournal = _journals.firstWhere(
            (element) => element['id'] == id,
      );
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'];
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                // text field for title
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      borderSide: BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      borderSide: BorderSide(color: Colors.grey, width: 1.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // text field for description
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      borderSide: BorderSide(color: Colors.blue, width: 2.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      borderSide: BorderSide(color: Colors.grey, width: 1.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (id == null) {
                      await _addItem();
                    }
                    if (id != null) {
                      await _updateItem(id);
                    }
                    _titleController.text = "";
                    _descriptionController.text = "";
                    Navigator.of(context).pop();
                  },
                  child: Text(id == null ? 'Create new' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addItem() async {
    await SQLHelper.createItem(
        _titleController.text, _descriptionController.text);
    _refreshJournals();
  }

  Future<void> _updateItem(int id) async {
    await SQLHelper.updateItem(
        id, _titleController.text, _descriptionController.text);
    _refreshJournals();
  }

  void _deleteItem(int id, BuildContext context) async {
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted journal'),
    ));
    _refreshJournals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: _journals.length,
        itemBuilder: (context, index) => Card(
          color: Colors.lightBlueAccent,
          margin: const EdgeInsets.all(15),
          child: ListTile(
            title: Text(_journals[index]['title']),
            subtitle: Text(_journals[index]['description']),
            trailing: SizedBox(
              width: 100,
              child: Row(
                children: [
                  IconButton(
                      onPressed: () => _showForm(_journals[index]['id'], context),
                      icon: const Icon(Icons.edit)),
                  IconButton(
                      onPressed: () => _deleteItem(_journals[index]['id'], context),
                      icon: const Icon(Icons.delete)),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add), onPressed: () => _showForm(null, context)),
    );
  }
}

