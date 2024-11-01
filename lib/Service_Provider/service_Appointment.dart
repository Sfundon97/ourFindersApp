import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceProviderAppointmentPage extends StatefulWidget {
  const ServiceProviderAppointmentPage({super.key, required String companyName});

  @override
  _ServiceProviderAppointmentPageState createState() =>
      _ServiceProviderAppointmentPageState();
}

class _ServiceProviderAppointmentPageState
    extends State<ServiceProviderAppointmentPage> {
  bool isRecentSelected = true; // Toggle between recent and history
  String? companyName; // Variable to hold company name

  // Fetch the current user's data
  Future<void> fetchProviderData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userId = user.uid;

      // Fetch company name from Firestore
      DocumentSnapshot providerDoc = await FirebaseFirestore.instance
          .collection('Service Provider')
          .doc(userId)
          .get();

      if (providerDoc.exists && providerDoc.data() != null) {
        var data = providerDoc.data() as Map<String, dynamic>;
        setState(() {
          companyName = data['companyName'] ?? "Unknown Company";
        });
      } else {
        setState(() {
          companyName = "Unknown Company";
        });
      }
    }
  }

  // Function to fetch recent (pending) appointments for the service provider
  Stream<QuerySnapshot> fetchRecentAppointments() {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('companyName', isEqualTo: companyName)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Function to fetch appointment history (accepted/rejected) for the service provider
  Stream<QuerySnapshot> fetchAppointmentHistory() {
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('companyName', isEqualTo: companyName)
        .where('status', whereIn: ['accepted', 'rejected'])
        .snapshots();
  }

  // Function to update booking status to 'accepted' or 'rejected'
  Future<void> updateBookingStatus(String appointmentId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': status});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating booking status')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProviderData(); // Fetch the provider data when the widget initializes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Appointments'),
        backgroundColor: Colors.blueAccent[100],
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isRecentSelected = true;
                  });
                },
                child: const Text('Recent Requests'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isRecentSelected = false;
                  });
                },
                child: const Text('History'),
              ),
            ],
          ),
          Expanded(
            child: companyName != null
                ? (isRecentSelected
                    ? buildAppointmentList(fetchRecentAppointments(), true)
                    : buildAppointmentList(fetchAppointmentHistory(), false))
                : const Center(child: Text('Loading company information...')),
          ),
        ],
      ),
    );
  }

  // Widget to build the list of appointments
  Widget buildAppointmentList(
      Stream<QuerySnapshot> appointmentStream, bool isPending) {
    return StreamBuilder<QuerySnapshot>(
      stream: appointmentStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No appointments found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot appointment = snapshot.data!.docs[index];
            String userId = appointment['userId']; // Assuming userId is stored in each appointment
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(
                    title: Text('Loading...'),
                    subtitle: Text('Loading user data...'),
                  );
                }
                var user = userSnapshot.data?.data() as Map<String, dynamic>?;

                return Card(
                  child: ListTile(
                    title: Text('Reference: ${appointment.id}'),
                    subtitle: Text(
                      'Date: ${appointment['date'].toDate().toString()}\n'
                      'Service: ${appointment['services'].join(", ")}\n'
                      'Client: ${user?['name'] ?? 'No Name'}',
                    ),
                    trailing: isPending
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {
                                  updateBookingStatus(appointment.id, 'accepted');
                                },
                                child: const Text('Accept'),
                              ),
                              TextButton(
                                onPressed: () {
                                  updateBookingStatus(appointment.id, 'rejected');
                                },
                                child: const Text('Reject'),
                              ),
                            ],
                          )
                        : Text('Status: ${appointment['status']}'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
