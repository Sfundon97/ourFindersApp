import 'package:finders_v1_1/Reviews/reviewModel.dart';
import 'package:finders_v1_1/Reviews/reviewViewModel.dart';
import 'package:flutter/material.dart';

class ReviewPage extends StatefulWidget {
  final String clientId;
  final String serviceProviderId;
  final String username; // Add username field

  const ReviewPage({
    super.key,
    required this.clientId,
    required this.serviceProviderId,
    required this.username, // Include username in the constructor
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final _formKey = GlobalKey<FormState>();
  String _reviewText = '';
  int _rating = 5;
  bool _loading = false;
  final ReviewViewModel _reviewViewModel = ReviewViewModel();

  void _submitReview() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _loading = true;
      });

      ReviewModel review = ReviewModel(
        clientId: widget.clientId,
        serviceProviderId: widget.serviceProviderId,
        reviewText: _reviewText,
        rating: _rating,
        timestamp: DateTime.now(),
        username: widget.username, // Use the username passed from PaymentPage
      );

      await _reviewViewModel.addReview(review);
      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review submitted successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Review"),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Review'),
                      maxLines: 5,
                      onSaved: (value) => _reviewText = value ?? '',
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a review' : null,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<int>(
                      value: _rating,
                      decoration: InputDecoration(labelText: 'Rating'),
                      items: List.generate(5, (index) {
                        int value = index + 1;
                        return DropdownMenuItem(
                          value: value,
                          child: Text('$value Star${value > 1 ? 's' : ''}'),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _rating = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitReview,
                      child: Text('Submit Review'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
