import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firestore_collection/firestore_collection.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _userTextFieldController = TextEditingController();
  TextEditingController _messageTextFieldController = TextEditingController();
  FirestoreCollection _fireCollection = FirestoreCollection(
    collection: FirebaseFirestore.instance.collection('posts'),
    initializeOnStart: true,
    // first page will fetched immediately
    offset: 15,
    // page size
    serverOnly: false,
    // cache first
    live: true,
    // notifies to newest documents
    query: FirebaseFirestore.instance.collection('posts'),
    queryOrder: QueryOrder(orderField: 'timestamp'),
  );

  @override
  void initState() {
    // TODO: Firebase Emulator only in specific situations!
    // Switch host based on platform.
    String host = 'localhost:8080'; // for android:  '10.0.2.2:8080'
    // Set the host as soon as possible.
    FirebaseFirestore.instance.settings =
        Settings(host: host, sslEnabled: false);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _displayDialog(context),
      ),
      body: new CustomScrollView(slivers: <Widget>[
        new SliverAppBar(
          title: new Text('firestore_collection'),
          floating: true,
          snap: true,
        ),
        StreamBuilder(
          stream: _fireCollection.stream,
          builder: (BuildContext context,
              AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Dismissible(
                    key: UniqueKey(),
                    background: Container(),
                    direction: DismissDirection.endToStart,
                    secondaryBackground: Container(
                      child: Center(
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      color: Colors.red,
                    ),
                    onDismissed: (DismissDirection direction) {
                      setState(() {
                        _fireCollection
                            .removeID(snapshot.data.elementAt(index).id);
                      });
                    },
                    child: AwareListItem(
                      itemCreated: () {
                        if (index % 15 == 0) _fireCollection.nextPage();
                      },
                      child: GestureDetector(
                        child: ListTile(
                          leading: CircleAvatar(child: Icon(Icons.person)),
                          title: Text(snapshot.data
                              .elementAt(index)
                              .data()['userName']),
                          subtitle: Text(
                              snapshot.data.elementAt(index).data()['message']),
                        ),
                      ),
                    ),
                  );
                },
                childCount: snapshot.hasData ? snapshot.data.length : 0,
              ),
            );
          },
        ),
      ]),
    );
  }

  _displayDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('add post'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _userTextFieldController,
                  keyboardType: TextInputType.numberWithOptions(),
                  decoration: InputDecoration(hintText: "name"),
                ),
                TextField(
                  controller: _messageTextFieldController,
                  keyboardType: TextInputType.numberWithOptions(),
                  decoration: InputDecoration(hintText: "message"),
                ),
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Submit'),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('posts').add({
                    'userName': _userTextFieldController.text,
                    'message': _messageTextFieldController.text,
                    'timestamp': Timestamp.now()
                  });
                  _userTextFieldController.clear();
                  _messageTextFieldController.clear();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}

class AwareListItem extends StatefulWidget {
  final Function itemCreated;
  final Widget child;

  const AwareListItem({
    Key key,
    this.itemCreated,
    this.child,
  }) : super(key: key);

  @override
  _AwareListItemState createState() => _AwareListItemState();
}

class _AwareListItemState extends State<AwareListItem> {
  @override
  void initState() {
    super.initState();
    if (widget.itemCreated != null) {
      widget.itemCreated();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
