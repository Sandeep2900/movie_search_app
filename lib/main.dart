import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MovieListScreen(),
    );
  }
}

class MovieListScreen extends StatefulWidget {
  @override
  _MovieListScreenState createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _movies = [];
  bool _isLoading = false;

  Future<void> _searchMovies() async {
    final apiKey = '487ff48e';
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a search term')),
      );
      return;
    }

    final url = 'http://www.omdbapi.com/?apikey=$apiKey&s=$query';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['Search'] != null) {
          List<Movie> movies = (data['Search'] as List)
              .map((movie) => Movie.fromJson(movie))
              .toList();
          for (Movie movie in movies) {
            await _fetchMovieDetails(movie, apiKey);
          }
          setState(() {
            _movies = movies;
          });
        } else {
          setState(() {
            _movies = [];
          });
        }
      } else {
        throw Exception('Failed to fetch movies');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMovieDetails(Movie movie, String apiKey) async {
    final url = 'http://www.omdbapi.com/?apikey=$apiKey&i=${movie.imdbID}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        movie.imdbRating = (data['imdbRating'] ?? 'N/A') as String;
        movie.genre = (data['Genre'] ?? 'N/A') as String;
      }
    } catch (e) {
      print('Error fetching details for movie "${movie.title}" with ID ${movie.imdbID}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Movies'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: (value) => _searchMovies(),
            ),
            SizedBox(height: 10),
            if (_isLoading)
              Center(child: CircularProgressIndicator()),
            if (!_isLoading && _movies.isEmpty)
              Expanded(
                child: Center(
                  child: Text('No movies found. Try another search.'),
                ),
              ),
            if (!_isLoading && _movies.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _movies.length,
                  itemBuilder: (context, index) {
                    final movie = _movies[index];
                    return MovieItem(
                      imageUrl: movie.poster,
                      title: movie.title,
                      genre: movie.genre,
                      imdbRating: movie.imdbRating,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Movie {
  final String imdbID;
  final String title;
  String genre;
  String imdbRating;
  final String poster;

  Movie({
    required this.imdbID,
    required this.title,
    this.genre = 'N/A',
    this.imdbRating = 'N/A',
    required this.poster,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      imdbID: json['imdbID'] ?? 'Unknown ID',
      title: json['Title'] ?? 'Unknown Title',
      poster: json['Poster'] ?? 'https://via.placeholder.com/100x150',
    );
  }
}

class MovieItem extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String genre;
  final String imdbRating;

  MovieItem({
    required this.imageUrl,
    required this.title,
    required this.genre,
    required this.imdbRating,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Image.network(
            imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/100x150',
            width: 100,
            height: 150,
            fit: BoxFit.cover,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    genre,
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'IMDb: $imdbRating',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
