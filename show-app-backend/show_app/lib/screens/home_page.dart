import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart'; // Ensure this import is correct
import './add_show_page.dart';
import './profile_page.dart';
import './update_show_page.dart'; // Ensure this import is correct

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> shows = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchShows();
  }

  Future<void> fetchShows() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/shows'));

    if (response.statusCode == 200) {
      setState(() {
        shows = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      throw Exception('Failed to load shows');
    }
  }

  Future<void> deleteShow(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/shows/$id'),
    );

    if (response.statusCode == 200) {
      fetchShows(); // Refresh the list after deletion
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to delete show")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              child: Text(
                "Menu",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              title: const Text("Profile"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              title: const Text("Add Show"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddShowPage()),
                ).then(
                  (_) => fetchShows(),
                ); // Refresh the list after adding a show
              },
            ),
          ],
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : ShowList(
                shows: shows,
                onDelete: deleteShow,
                fetchShows: fetchShows, // Pass the fetchShows method
              ),
    );
  }
}

class ShowList extends StatelessWidget {
  final List<dynamic> shows;
  final Function(int) onDelete;
  final Future<void> Function() fetchShows;

  const ShowList({
    super.key,
    required this.shows,
    required this.onDelete,
    required this.fetchShows,
  });

  @override
  Widget build(BuildContext context) {
    if (shows.isEmpty) {
      return const Center(child: Text("No Shows Available"));
    }

    return ListView.builder(
      itemCount: shows.length,
      itemBuilder: (context, index) {
        final show = shows[index];
        return Dismissible(
          key: Key(show['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (direction) => onDelete(show['id']),
          confirmDismiss: (direction) async {
            final confirmed = await showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text("Delete Show"),
                    content: const Text(
                      "Are you sure you want to delete this show?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Delete"),
                      ),
                    ],
                  ),
            );
            if (confirmed == true) {
              await onDelete(show['id']);
              await fetchShows(); // Refresh the list after deletion
            }
            return confirmed;
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading:
                  show['image'] != null
                      ? Image.network(
                        '${ApiConfig.baseUrl}${show['image']}', // Use the full image URL
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) =>
                                const Icon(Icons.broken_image),
                      )
                      : const Icon(Icons.broken_image),
              title: Text(
                show['title'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(show['description']),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateShowPage(show: show),
                    ),
                  ).then(
                    (_) => fetchShows(),
                  ); // Refresh the list after updating
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
