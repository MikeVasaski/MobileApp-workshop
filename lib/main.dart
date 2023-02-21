import 'package:flutter/material.dart';
import 'package:listtitle/details.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  //const MyApp({super.key});
  const MyApp({Key? key}) : super(key: key);
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Album> futureAlbum;

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Json"),
      ),
      body: Center(
        child: FutureBuilder<Album>(
          future: futureAlbum,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data!.title);
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
  // final items = List<String>.generate(1000, (i) => "Item $i");
  // @override
  // Widget build(BuildContext context) {
  //   List mydata = ['apple', 'banana', 'papaya'];
  //   return Scaffold(
  //       appBar: AppBar(
  //         title: Text(widget.title),
  //       ),
  //       body: ListView.builder(
  //         itemBuilder: (BuildContext context, int index) {
  //           return ListTile(
  //             leading: FlutterLogo(),
  //             title: Text(mydata[index]),
  //             onTap: () {
  //               Navigator.push(
  //                   context,
  //                   MaterialPageRoute(
  //                       builder: (context) => const DetailsPage()));
  //             },
  //           );
  //         },
  //         itemCount: mydata.length,
  //       ));
  // }
}

// Album was created on 3rd January 2023

// convert the response into s custom Dart object
class Album {
  final int userId;
  final int id;
  final String title;

  Album({
    required this.userId,
    required this.id,
    required this.title,
  });

  factory Album.formJson(Map<String, dynamic> json) {
    return Album(userId: json['userId'], id: json['id'], title: json['title']);
  }
}

// Convert the http.Response to an Album
Future<Album> fetchAlbum() async {
  final response = await http
      .get(Uri.parse('https://jsonplaceholder.typicode.com/albums/1'));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    print(response.body);
    print(jsonDecode(jsonDecode(response.body)));
    print(Album.formJson(jsonDecode(response.body)));
    return Album.formJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}
