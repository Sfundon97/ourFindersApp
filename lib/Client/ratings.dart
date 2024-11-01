import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service Provider Rating',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RatingPage(),
    );
  }
}

class RatingPage extends StatefulWidget {
  const RatingPage({super.key});

  @override
  _RatingPageState createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  double _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate Service Provider'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rate the service you received:',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            RatingBar.builder(
              initialRating: 3,  // Default starting rating
              minRating: 1,       // Minimum rating allowed
              direction: Axis.horizontal,
              allowHalfRating: true,
              itemCount: 5,       // Number of stars
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating;
                });
                print('Rating: $_rating');  // This logs the rating to the console
                // Here you can add code to save the rating to Firestore or another database
              },
            ),
            SizedBox(height: 20),
            Text(
              'Your rating: $_rating',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add logic to submit the rating (e.g., save to database)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Rating submitted: $_rating'),
                  ),
                );
              },
              child: Text('Submit Rating'),
            ),
          ],
        ),
      ),
    );
  }
}
