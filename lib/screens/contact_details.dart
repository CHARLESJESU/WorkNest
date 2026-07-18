import 'package:country_state_city_pro/country_state_city_pro.dart';
import 'package:flutter/material.dart';
import 'package:nivetha123/screens/profile_details.dart';
import 'package:nivetha123/screens/summary.dart';
import 'package:nivetha123/screens/user_data.dart';

import '../login/branding.dart';
import '../widgets/step_progress.dart';

class Page3ContactDetails extends StatefulWidget {
  final UserData userData;
  Page3ContactDetails({required this.userData});

  @override
  _Page3ContactDetailsState createState() => _Page3ContactDetailsState();
}

class _Page3ContactDetailsState extends State<Page3ContactDetails> {
  TextEditingController countryController = TextEditingController();
  TextEditingController stateController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController areaController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  void _validateAndProceed() {
    String phone = phoneController.text.trim();

    if (phone.isEmpty ||
        areaController.text.isEmpty ||
        addressController.text.isEmpty ||
        countryController.text.isEmpty ||
        stateController.text.isEmpty ||
        cityController.text.isEmpty) {
      showWNMessage(context, isError: true, message: 'Please enter all details!');
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      showWNMessage(context, isError: true, message: 'Enter a valid 10-digit phone number!');
      return;
    }

    widget.userData.phoneNumber = '+91 ' + phone;
    widget.userData.country = countryController.text;
    widget.userData.state = stateController.text;
    widget.userData.district = cityController.text;
    widget.userData.city = cityController.text;
    widget.userData.area = areaController.text;
    widget.userData.address = addressController.text;

    if (widget.userData.role == 'Worker') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Page4ProfileDetails(userData: widget.userData),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Page5Summary(userData: widget.userData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WNColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Contact Info',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: WNColors.navy,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StepProgress(currentStep: 3, totalSteps: 5),

                  SizedBox(height: 20),

                  // 📞 Phone Number Input
                  Text(
                    'Enter your Phone Number',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WNColors.navy),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      prefixText: '+91 ',
                      prefixIcon: const Icon(Icons.phone_outlined, color: WNColors.blue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                  ),

                  SizedBox(height: 10),

                  // 📍 Area Input
                  Text(
                    'Area',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WNColors.navy),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: areaController,
                    decoration: InputDecoration(
                      hintText: 'Enter your Area/Village name',
                      prefixIcon: const Icon(Icons.location_on_outlined, color: WNColors.blue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    keyboardType: TextInputType.text,
                  ),

                  SizedBox(height: 20),

                  // 🏠 Full Address Input
                  Text(
                    'Full Address',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WNColors.navy),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      hintText: 'Door no/Flat no/Street name',
                      prefixIcon: const Icon(Icons.home_outlined, color: WNColors.blue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    keyboardType: TextInputType.text,
                  ),

                  SizedBox(height: 20),

                  // 🌍 Country, State, City Picker
                  Text(
                    'Select Country, State & City',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WNColors.navy),
                  ),
                  SizedBox(height: 10),
                  CountryStateCityPicker(
                    country: countryController,
                    state: stateController,
                    city: cityController,
                    dialogColor: Colors.white,
                    textFieldDecoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      suffixIcon: const Icon(Icons.arrow_drop_down, color: WNColors.blue),
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔄 Fixed Navigation Buttons at Bottom
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WNColors.blue,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Back', style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _validateAndProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WNColors.blue,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Next', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
