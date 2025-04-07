import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/strava_service.dart';
import '../main.dart';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PaymentConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> activity;
  final Function(int selectedRate) onPaymentComplete;
  final bool isMetric;
  final double preSelectedRate;

  const PaymentConfirmationScreen({
    super.key,
    required this.activity,
    required this.onPaymentComplete,
    this.isMetric = true,
    this.preSelectedRate = 10.0,
  });

  @override
  State<PaymentConfirmationScreen> createState() => _PaymentConfirmationScreenState();
}

class _PaymentConfirmationScreenState extends State<PaymentConfirmationScreen> {
  late int _selectedRate;
  String _selectedPaymentMethod = 'credit_card'; // Default payment method
  List<Map<String, dynamic>> _availablePaymentMethods = [];

  @override
  void initState() {
    super.initState();
    // Initialize with the pre-selected rate from run intention
    _selectedRate = widget.preSelectedRate.round();
    _initPaymentMethods();
  }

  void _initPaymentMethods() {
    // Default credit card option available on all platforms
    _availablePaymentMethods = [
      {
        'id': 'credit_card',
        'name': 'Credit Card',
        'icon': Icons.credit_card,
        'lastDigits': '4242',
      },
    ];

    // Add platform-specific payment methods
    if (!kIsWeb) {
      if (Platform.isIOS || Platform.isMacOS) {
        _availablePaymentMethods.add({
          'id': 'apple_pay',
          'name': 'Apple Pay',
          'icon': Icons.apple,
          'lastDigits': '',
        });
      } else if (Platform.isAndroid) {
        // Check for Samsung device (this is a simplified check, you may need a more robust solution)
        bool isSamsungDevice = false;
        try {
          // You would need a proper way to detect Samsung devices
          // This is just a placeholder for demonstration
          // In a real app, you might use a package like 'device_info_plus'
          isSamsungDevice = Platform.operatingSystemVersion.toLowerCase().contains('samsung');
        } catch (e) {
          // Ignore errors
        }

        _availablePaymentMethods.add({
          'id': 'google_pay',
          'name': 'Google Pay',
          'icon': Icons.g_mobiledata,
          'lastDigits': '',
        });

        if (isSamsungDevice) {
          _availablePaymentMethods.add({
            'id': 'samsung_pay',
            'name': 'Samsung Pay',
            'icon': Icons.payments,
            'lastDigits': '',
          });
        }
      }
    }

    // Add "Add New Card" option
    _availablePaymentMethods.add({
      'id': 'add_new_card',
      'name': 'Add New Card',
      'icon': Icons.add_circle_outline,
      'lastDigits': '',
    });
  }

  void _handleAddNewCard() {
    // Create a text controller to capture card details
    final TextEditingController cardNumberController = TextEditingController();
    final TextEditingController expiryController = TextEditingController();
    final TextEditingController cvvController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    // In a real app, this would open a form to add a new card
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Card'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: expiryController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'John Doe',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Get the last 4 digits of the card
              String lastFourDigits = '';
              if (cardNumberController.text.length >= 4) {
                lastFourDigits = cardNumberController.text.substring(cardNumberController.text.length - 4);
              } else if (cardNumberController.text.isNotEmpty) {
                lastFourDigits = cardNumberController.text;
              } else {
                lastFourDigits = '****'; // Default if no card number entered
              }
              
              // Add the new card to available payment methods
              setState(() {
                // Generate a unique ID for the new card
                final String newCardId = 'card_${DateTime.now().millisecondsSinceEpoch}';
                
                // Add the new card to the payment methods list (insert before "Add New Card" option)
                _availablePaymentMethods.insert(_availablePaymentMethods.length - 1, {
                  'id': newCardId,
                  'name': nameController.text.isNotEmpty 
                      ? '${nameController.text}\'s Card' 
                      : 'Credit Card',
                  'icon': Icons.credit_card,
                  'lastDigits': lastFourDigits,
                });
                
                // Select the new card
                _selectedPaymentMethod = newCardId;
              });
              
              Navigator.pop(context);
              
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Card added successfully'),
                ),
              );
            },
            child: const Text('Add Card'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> paymentMethod) {
    final bool isSelected = _selectedPaymentMethod == paymentMethod['id'];
    final bool isAddNewCard = paymentMethod['id'] == 'add_new_card';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isAddNewCard) {
              _handleAddNewCard();
            } else {
              _selectedPaymentMethod = paymentMethod['id'];
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                paymentMethod['icon'],
                color: isSelected || isAddNewCard ? AppColors.primaryBlue : Colors.grey.shade600,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paymentMethod['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isAddNewCard ? AppColors.primaryBlue : Colors.black87,
                      ),
                    ),
                    if (paymentMethod['lastDigits'].isNotEmpty)
                      Text(
                        '**** **** **** ${paymentMethod['lastDigits']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isAddNewCard)
                Radio(
                  value: paymentMethod['id'],
                  groupValue: _selectedPaymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedPaymentMethod = value.toString();
                    });
                  },
                  activeColor: AppColors.primaryBlue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unitName = widget.isMetric ? 'kilometers' : 'miles';
    final conversionFactor = widget.isMetric ? 1000.0 : 1609.34;
    final distance = (widget.activity['distance'] as num).toDouble() / conversionFactor;
    final donationAmount = (distance * _selectedRate).toStringAsFixed(2);
    final activityName = widget.activity['name'] as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Confirmation'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Your Donation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.deepBlue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'For your recent Strava activity',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textGrey,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activityName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${distance.toStringAsFixed(1)} $unitName',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textGrey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Rate selection dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryBlue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        value: _selectedRate,
                        isExpanded: true,
                        underline: Container(),
                        items: [1, 2, 5, 10, 20].map((rate) {
                          return DropdownMenuItem<int>(
                            value: rate,
                            child: Text('\$$rate per ${widget.isMetric ? 'kilometer' : 'mile'}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRate = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Donation Amount:',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textGrey,
                          ),
                        ),
                        Text(
                          '\$$donationAmount',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepBlue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Payment methods list
            Expanded(
              child: ListView.separated(
                itemCount: _availablePaymentMethods.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _buildPaymentMethodCard(_availablePaymentMethods[index]);
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Simulate payment processing
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Processing payment...'),
                        ],
                      ),
                    ),
                  );

                  // Simulate network delay
                  Future.delayed(const Duration(seconds: 2), () {
                    Navigator.pop(context); // Close progress dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Payment Successful'),
                        content: Text('Thank you for your donation of \$$donationAmount!'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close success dialog
                              Navigator.pop(context); // Return to run screen
                              widget.onPaymentComplete(_selectedRate); // Pass back the selected rate
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Payment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RunIntentionScreen extends StatefulWidget {
  final Function(bool isMetric, double ratePerUnit) onIntentionSet;

  const RunIntentionScreen({
    super.key,
    required this.onIntentionSet,
  });

  @override
  State<RunIntentionScreen> createState() => _RunIntentionScreenState();
}

class _RunIntentionScreenState extends State<RunIntentionScreen> {
  bool _isMetric = true; // true for km, false for miles
  final List<double> _rates = [1.0, 2.0, 5.0, 10.0, 20.0];
  double _selectedRate = 10.0; // Default rate

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Run Intention'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Your Charitable Run',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.deepBlue,
              ),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distance Unit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isMetric = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isMetric ? AppColors.primaryBlue : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Kilometers',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _isMetric ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isMetric = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isMetric ? AppColors.primaryBlue : Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Miles',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: !_isMetric ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Donation Rate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryBlue),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<double>(
                        value: _selectedRate,
                        isExpanded: true,
                        underline: Container(),
                        items: _rates.map((rate) {
                          return DropdownMenuItem<double>(
                            value: rate,
                            child: Text('\$$rate per ${_isMetric ? 'kilometer' : 'mile'}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRate = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onIntentionSet(_isMetric, _selectedRate);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Run',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RunTrackingScreen extends StatefulWidget {
  final Function(double totalDonations, double totalDistance)? onStatsUpdated;
  
  // Static fields to share data between screens
  static List<Map<String, dynamic>> donatedActivities = [];
  static Map<String, int> activityRates = {};
  static Function? onActivitiesUpdated;

  const RunTrackingScreen({
    super.key,
    this.onStatsUpdated,
  });

  @override
  State<RunTrackingScreen> createState() => _RunTrackingScreenState();
}

class _RunTrackingScreenState extends State<RunTrackingScreen> {
  bool _isLoading = true;
  bool _hasActiveRun = false;
  bool _isMetric = true;
  double _ratePerUnit = 10.0;
  late StravaService _stravaService;
  List<Map<String, dynamic>> _activities = [];
  Set<String> _donatedActivityIds = {};
  int _selectedIndex = 0;
  Map<String, int> _activityRates = {};

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadDonatedActivities();
    _loadActivityRates();
    _loadRunSettings();
    
    // Schedule to update home screen stats after this widget is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateHomeScreenStats();
    });
  }

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _stravaService = StravaService(prefs);
    await _loadStravaActivities();
  }

  Future<void> _loadDonatedActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final donatedIds = prefs.getStringList('donated_activity_ids') ?? [];
    setState(() {
      _donatedActivityIds = Set<String>.from(donatedIds);
    });
    _updateDonatedActivities();
  }

  Future<void> _loadActivityRates() async {
    final prefs = await SharedPreferences.getInstance();
    final rates = prefs.getString('activity_rates') ?? '{}';
    _activityRates = Map<String, int>.from(
      Map<String, dynamic>.from(json.decode(rates))
        .map((key, value) => MapEntry(key, value as int))
    );
    RunTrackingScreen.activityRates = _activityRates;
  }

  void _updateDonatedActivities() {
    final donatedActivities = _activities.where((activity) => 
      _donatedActivityIds.contains(activity['id'].toString())).toList();
    RunTrackingScreen.donatedActivities = donatedActivities;
    if (RunTrackingScreen.onActivitiesUpdated != null) {
      RunTrackingScreen.onActivitiesUpdated!();
    }
  }

  Future<void> _saveActivityRate(String activityId, int rate) async {
    final prefs = await SharedPreferences.getInstance();
    _activityRates[activityId] = rate;
    await prefs.setString('activity_rates', json.encode(_activityRates));
  }

  void _updateHomeScreenStats() {
    if (widget.onStatsUpdated != null) {
      double totalDonations = 0;
      double totalDistance = 0;
      
      for (var activity in _donatedActivities) {
        final bool isActivityMetric = activity['is_metric'] != null ? activity['is_metric'] as bool : true;
        final conversionFactor = isActivityMetric ? 1000.0 : 1609.34;
        final distance = (activity['distance'] as num).toDouble() / conversionFactor;
        final activityId = activity['id'].toString();
        final rate = _activityRates[activityId] ?? 10;
        
        // Always convert distance to kilometers for the home screen total
        final distanceInKm = isActivityMetric ? distance : distance * 1.60934;
        
        totalDonations += distance * rate;
        totalDistance += distanceInKm;
      }
      
      widget.onStatsUpdated!(totalDonations, totalDistance);
    }
  }

  Future<void> _markActivityAsDonated(String activityId, int rate) async {
    final prefs = await SharedPreferences.getInstance();
    final donatedIds = prefs.getStringList('donated_activity_ids') ?? [];
    
    if (!donatedIds.contains(activityId)) {
      donatedIds.add(activityId);
      await prefs.setStringList('donated_activity_ids', donatedIds);
      await _saveActivityRate(activityId, rate);
    }
    
    setState(() {
      _donatedActivityIds.add(activityId);
      _activityRates[activityId] = rate;
    });
    
    _updateHomeScreenStats();
    _updateDonatedActivities();
  }

  Future<void> _loadStravaActivities() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final isAuthenticated = await _stravaService.isAuthenticated;
      
      // Initialize with an empty list instead of sample activities
      setState(() {
        _activities = [];
        _isLoading = false;
      });

      // Load donated activities and rates
      await _loadDonatedActivities();
      await _loadActivityRates();
      
      // Update home screen stats
      _updateHomeScreenStats();
    } catch (e) {
      print('Error loading Strava activities: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _getLatestStravaActivity() async {
    try {
      // In a real app, this would fetch the latest activity from Strava API
      // For demo purposes, we'll use a sample activity
      final latestActivity = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': 'Recent Run ${DateTime.now().day}/${DateTime.now().month}',
        'distance': _isMetric ? 5000.0 : 3000.0, // 5 km or ~1.86 miles
        'moving_time': 1800, // 30 minutes
        'start_date': DateTime.now().toIso8601String(),
        'is_metric': _isMetric, // Store the user's metric preference
      };
      
      return latestActivity;
    } catch (e) {
      print('Error getting latest Strava activity: $e');
      return null;
    }
  }

  Future<void> _syncLatestRun() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get only the latest activity from Strava
      final latestActivity = await _getLatestStravaActivity();
      
      if (latestActivity != null) {
        final distance = _isMetric 
          ? (latestActivity['distance'] as num).toDouble() / 1000  // Convert to km
          : (latestActivity['distance'] as num).toDouble() / 1609.34; // Convert to miles
        
        // Show confirmation dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Run Completed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Distance: ${distance.toStringAsFixed(2)} ${_isMetric ? 'km' : 'miles'}'),
                const SizedBox(height: 8),
                Text('Rate: \$${_ratePerUnit.toStringAsFixed(2)} per ${_isMetric ? 'km' : 'mile'}'),
                const SizedBox(height: 8),
                Text(
                  'Total Donation: \$${(distance * _ratePerUnit).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _hasActiveRun = false;
                  });
                  _saveRunSettings();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Add this activity to our activities list
                  setState(() {
                    _activities.insert(0, latestActivity);
                    _hasActiveRun = false;
                  });
                  _saveRunSettings();
                  
                  // Navigate to payment screen without marking as donated yet
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentConfirmationScreen(
                        activity: latestActivity,
                        onPaymentComplete: (selectedRate) {
                          // Mark as donated with the selected rate after payment
                          _markActivityAsDonated(latestActivity['id'].toString(), selectedRate);
                          setState(() {});
                          _updateHomeScreenStats();
                        },
                        isMetric: _isMetric,
                        preSelectedRate: _ratePerUnit,
                      ),
                    ),
                  );
                },
                child: const Text('Proceed to Payment'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No recent activities found on Strava'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error syncing with Strava'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String isoDate) {
    final date = DateTime.parse(isoDate);
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  }

  List<Map<String, dynamic>> get _donatedActivities {
    return _activities.where((activity) => 
      _donatedActivityIds.contains(activity['id'].toString())).toList();
  }
  
  List<Map<String, dynamic>> get _notDonatedActivities {
    return _activities.where((activity) => 
      !_donatedActivityIds.contains(activity['id'].toString())).toList();
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, bool isDonated) {
    final activityId = activity['id'].toString();
    final bool isActivityMetric = activity['is_metric'] != null ? activity['is_metric'] as bool : _isMetric;
    final conversionFactor = isActivityMetric ? 1000.0 : 1609.34;
    final distance = (activity['distance'] as num).toDouble() / conversionFactor;
    final duration = activity['moving_time'] as int;
    final date = activity['start_date'] as String;
    final name = activity['name'] as String;
    final rate = _activityRates[activityId] ?? 10; // Default to $10 if not found
    final String unitName = isActivityMetric ? 'km' : 'mi';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_run,
                color: AppColors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textBlack,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(date)} • ${distance.toStringAsFixed(1)} $unitName • ${_formatDuration(duration)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
            isDonated 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${(distance * rate).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$$rate/$unitName',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                )
              : ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentConfirmationScreen(
                          activity: activity,
                          onPaymentComplete: (selectedRate) {
                            _markActivityAsDonated(activityId, selectedRate);
                          },
                          isMetric: isActivityMetric, // Use the activity's metric setting
                          preSelectedRate: 10.0, // Default rate for older activities
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Donate'),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_run,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connect with Strava to import your activities',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedIndex == 0 ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Not Donated',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedIndex == 0 ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedIndex == 1 ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  'Donated',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedIndex == 1 ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startNewRun() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RunIntentionScreen(
          onIntentionSet: (isMetric, ratePerUnit) {
            setState(() {
              _hasActiveRun = true;
              _isMetric = isMetric;
              _ratePerUnit = ratePerUnit;
            });
            _saveRunSettings();
          },
        ),
      ),
    );
  }

  Future<void> _saveRunSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_active_run', _hasActiveRun);
    await prefs.setBool('is_metric', _isMetric);
    await prefs.setDouble('rate_per_unit', _ratePerUnit);
  }

  Future<void> _loadRunSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hasActiveRun = prefs.getBool('has_active_run') ?? false;
      _isMetric = prefs.getBool('is_metric') ?? true;
      _ratePerUnit = prefs.getDouble('rate_per_unit') ?? 10.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Your Runs'),
        backgroundColor: AppColors.primaryBlue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (!_hasActiveRun) ...[
                  // Start new run button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startNewRun,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Start New Run',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Active run status
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Active Run in Progress',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.deepBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rate: \$${_ratePerUnit.toStringAsFixed(2)} per ${_isMetric ? 'kilometer' : 'mile'}',
                          style: TextStyle(
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _syncLatestRun,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Sync Latest Run from Strava'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Existing activity list
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    'Previous Activities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSegmentedControl(),
                const SizedBox(height: 16),
                Expanded(
                  child: _selectedIndex == 0
                      ? _notDonatedActivities.isEmpty
                          ? _buildEmptyState('No runs to donate')
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              itemCount: _notDonatedActivities.length,
                              itemBuilder: (context, index) {
                                return _buildActivityCard(_notDonatedActivities[index], false);
                              },
                            )
                      : _donatedActivities.isEmpty
                          ? _buildEmptyState('No donated runs yet')
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              itemCount: _donatedActivities.length,
                              itemBuilder: (context, index) {
                                return _buildActivityCard(_donatedActivities[index], true);
                              },
                            ),
                ),
              ],
            ),
    );
  }
} 