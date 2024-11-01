import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FAQsPage extends StatelessWidget {
  const FAQsPage({super.key});

  // Fetch FAQs from Firestore
  Stream<QuerySnapshot> _fetchFAQs() {
    return FirebaseFirestore.instance.collection('FAQs').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        backgroundColor: Colors.blueAccent, // Custom AppBar color
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchFAQs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching FAQs'));
          }

          final faqs = snapshot.data?.docs;

          if (faqs == null || faqs.isEmpty) {
            return const Center(
              child: Text(
                'No FAQs available.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              var faq = faqs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 3,
                child: ListTile(
                  title: Text(
                    faq['Question'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade900,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      faq['Answer'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  tileColor: Colors.blueGrey.shade50,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
