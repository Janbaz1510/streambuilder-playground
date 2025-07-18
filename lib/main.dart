import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ApiStreamExample());
  }
}

class ApiStreamExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("StreamBuilder + Post Model")),
      body: StreamBuilder<List<Post>>(
        stream: ApiService.fetchPostStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            final posts = snapshot.data!;
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (_, index) {
                final post = posts[index];
                return ListTile(
                  leading: Text("ID: ${post.id}"),
                  title: Text(post.title),
                  subtitle: Text(post.body),
                );
              },
            );
          } else {
            return Center(child: Text("No data yet."));
          }
        },
      ),
    );
  }
}

class ApiService {
  static int _currentId = 1;

  static Stream<List<Post>> fetchPostStream() async* {
    List<Post> posts = [];

    while (true) {
      try {
        final response = await http.get(
          Uri.parse('https://jsonplaceholder.typicode.com/posts/$_currentId'),
          headers: {
            'User-Agent': 'Mozilla/5.0',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final post = Post.fromJson(data);
          posts.add(post);
          yield List.from(posts); // emit new list
        } else {
          posts.add(Post(
            userId: 0,
            id: _currentId,
            title: 'Error ${response.statusCode}',
            body: 'Failed to fetch',
          ));
          yield List.from(posts);
        }
      } catch (e) {
        posts.add(Post(
          userId: 0,
          id: _currentId,
          title: 'Exception',
          body: e.toString(),
        ));
        yield List.from(posts);
      }

      _currentId++;
      if (_currentId > 10) _currentId = 1; // loop 1-10

      await Future.delayed(Duration(seconds: 5));
    }
  }
}

class Post {
  final int userId;
  final int id;
  final String title;
  final String body;

  Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: json['userId'] ?? 0,
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
    );
  }
}
