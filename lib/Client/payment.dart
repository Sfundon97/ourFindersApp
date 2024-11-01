// ignore_for_file: use_build_context_synchronously, library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finders_v1_1/Client/bookingConfirmed.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  final String companyName;
  final List<String> services;
  final String address;
  final List<double> prices;
  final double totalPrice;
  final String serviceProviderId;
  final List<int> quantities;

  const PaymentPage({
    super.key,
    required this.serviceProviderId,
    required this.companyName,
    required this.services,
    required this.address,
    required this.prices,
    required this.totalPrice,
    required this.quantities,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  String selectedPaymentMethod = 'Card'; // State variable for payment method
  Map<String, dynamic>? bankingDetails; // To store banking details

  // Fetch banking details of the service provider
  Future<void> fetchBankingDetails(String serviceProviderId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('Service Provider')
          .doc(serviceProviderId)
          .get();
      if (snapshot.exists) {
        setState(() {
          bankingDetails = snapshot.data() as Map<String, dynamic>;
        });
      }
    } catch (e) {
      print("Error fetching banking details: $e");
    }
  }

  // Method to show a Snackbar with the booking reference
  void showBookingSnackbar(BuildContext context, String bookingRef) {
    final snackBar = SnackBar(
      content: Text('Booking saved successfully with reference: $bookingRef'),
      duration: const Duration(seconds: 5),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Fetch the current user's data
  Future<Map<String, String>> fetchClientData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String userName = user.displayName ?? "Unknown User";
      String userId = user.uid;
      return {'userId': userId, 'userName': userName};
    }
    return {'userId': "unknown-user", 'userName': "Unknown User"};
  }

  // Save booking details to Firestore
  Future<void> saveBookingDetails(
    String userId,
    List<int> quantities,
    String userName,
    String serviceProviderId,
    String companyName,
    BuildContext context,
  ) async {
    try {
      String bookingRef = DateTime.now().millisecondsSinceEpoch.toString();
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(bookingRef)
          .set({
        'userId': userId,
        'userName': userName,
        'serviceProviderId': serviceProviderId,
        'companyName': companyName,
        'services': widget.services,
        'address': widget.address,
        'prices': widget.prices.map((price) => price).toList(),
        'quantities': quantities, // Save the quantities
        'totalPrice': widget.totalPrice,
        'date': DateTime.now(),
        'status': 'pending',
      });

      if (!mounted) return; // Ensure the widget is still mounted

      showBookingSnackbar(context, bookingRef);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving booking details')),
        );
      }
    }
  }

  // Validators for the payment form fields
  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter card number';
    } else if (!RegExp(r'^\d{16}$').hasMatch(value)) {
      return 'Card number must be 16 digits';
    }
    return null;
  }

  String? _validateCvv(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter CVV';
    } else if (!RegExp(r'^\d{3}$').hasMatch(value)) {
      return 'CVV must be 3 digits';
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter expiry date (MM/YY)';
    } else if (!RegExp(r'^(0[1-9]|1[0-2])\/(\d{2})$').hasMatch(value)) {
      return 'Expiry date format must be MM/YY';
    } else {
      final now = DateTime.now();
      final parts = value.split('/');
      final month = int.parse(parts[0]);
      final year =
          int.parse(parts[1]) + 2000; // Assuming YY is in the range 00-99
      final expiryDate = DateTime(year, month);

      if (expiryDate.isBefore(now)) {
        return 'Expiry date must be in the future';
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    // Fetch banking details for the selected service provider
    fetchBankingDetails(widget.serviceProviderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.blueAccent[100],
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<Map<String, String>>(
          future: fetchClientData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error fetching user data'));
            } else {
              String userId = snapshot.data?['userId'] ?? "unknown-user";
              String userName = snapshot.data?['userName'] ?? "Unknown User";

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Details',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text('Company: ${widget.companyName}',
                          style: const TextStyle(fontSize: 18)),
                      Text('Services: ${widget.services.join(", ")}',
                          style: const TextStyle(fontSize: 18)),
                      Text('Address: ${widget.address}',
                          style: const TextStyle(fontSize: 18)),
                      Text(
                          'Prices: ${widget.prices.map((price) => 'R${price.toStringAsFixed(2)}').join(", ")}',
                          style: const TextStyle(fontSize: 18)),
                      Text('Quantities: ${widget.quantities.join(", ")}',
                          style: const TextStyle(fontSize: 18)),
                      Text('Total: R${widget.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 16),

                      // Payment Method Selection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedPaymentMethod = 'Card';
                              });
                            },
                            child: const Text('Pay by Card'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedPaymentMethod = 'EFT';
                              });
                            },
                            child: const Text('Pay by EFT'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Show payment fields based on selection
                      if (selectedPaymentMethod == 'Card') ...[
                        const Text('Please enter your card details:'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cardNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Card Number',
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 16,
                          keyboardType: TextInputType.number,
                          validator: _validateCardNumber,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cvvController,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 3,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          validator: _validateCvv,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _expiryController,
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date (MM/YY)',
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 5,
                          keyboardType: TextInputType.text,
                          validator: _validateExpiry,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Show banking details for EFT payment
                      if (selectedPaymentMethod == 'EFT' &&
                          bankingDetails != null) ...[
                        const Text('Banking Details:'),
                        const SizedBox(height: 16),
                        Text('Bank Name: ${bankingDetails!['bankName']}'),
                        Text(
                            'Account Number: ${bankingDetails!['accountNumber']}'),
                        Text('Account Name: ${bankingDetails!['accountName']}'),
                        Text('Branch Code: ${bankingDetails!['branchCode']}'),
                        const SizedBox(height: 16),
                        const Text(
                          'Please use the account details above for EFT payment.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Pay Now button only for Card payment
                      if (selectedPaymentMethod == 'Card') ...[
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() == true) {
                              saveBookingDetails(
                                userId,
                                widget.quantities,
                                userName,
                                widget.serviceProviderId,
                                widget.companyName,
                                context,
                              );
                             // Navigate to BookingConfirmationPage after saving
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => BookingConfirmationPage(
                                  userId: userId,
                                  serviceProviderId: widget.serviceProviderId,
                                  
                                ),
                              ),
                            );
                          }
                        },
                          child: const Text('Pay Now'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}