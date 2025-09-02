import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_state_city_pro/country_state_city_pro.dart';
import '../screens/user_data.dart';
import 'workerpage.dart';
import 'jobproviderpage.dart';

class ProfileDetailsPage extends StatefulWidget {
  final UserData userData;

  const ProfileDetailsPage({Key? key, required this.userData})
    : super(key: key);

  @override
  _ProfileDetailsPageState createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  late UserData userData;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final List<String> profileImages = [
    'assets/images/profile1.png',
    'assets/images/profile2.png',
    'assets/images/profile3.png',
  ];

  int selectedProfileIndex = 0;
  final List<String> genders = ["Male", "Female", "Others"];

  // controllers
  final TextEditingController countryController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  DateTime? selectedDate;

  // show inline errors under pickers after submit attempt
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    userData = widget.userData;
    _loadSelectedProfileIndex();
    _loadSavedProfileImage();

    // prefill
    countryController.text = userData.country;
    stateController.text = userData.state;
    cityController.text = userData.city;
    areaController.text = userData.area;
    addressController.text = userData.address;
    phoneController.text = userData.phoneNumber.replaceAll('+91 ', '');
    selectedDate = userData.dob;
  }

  Future<void> _loadSelectedProfileIndex() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedProfileIndex = prefs.getInt('profileIndex') ?? 0;
    });
  }

  Future<void> _saveSelectedProfileIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('profileIndex', index);
  }

  Future<void> _loadSavedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('localProfileImage_${userData.userId}');
    if (savedPath != null && savedPath.isNotEmpty) {
      setState(() => userData.profileImage = savedPath);
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => userData.profileImage = picked.path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'localProfileImage_${userData.userId}',
        picked.path,
      );
    }
  }

  Future<void> _reloadUserData() async {
    try {
      final rolePath =
          userData.role.toLowerCase() == 'worker' ? 'workers' : 'jobproviders';

      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(rolePath)
          .collection(rolePath)
          .doc(userData.userId);

      final snapshot = await ref.get();
      if (snapshot.exists) {
        setState(() {
          userData = UserData.fromJson(snapshot.data() as Map<String, dynamic>);
        });
      }
    } catch (e) {
      debugPrint("Error reloading user data: $e");
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _submitted = true);

    // manual checks for picker + dob (they're not inside the Form validators)
    final bool pickerOk =
        countryController.text.isNotEmpty &&
        stateController.text.isNotEmpty &&
        cityController.text.isNotEmpty;
    final bool dobOk = selectedDate != null;

    if (!_formKey.currentState!.validate() || !pickerOk || !dobOk) {
      return; // inline errors will show
    }

    // update userData from controllers
    userData.phoneNumber = '+91 ' + phoneController.text.trim();
    userData.country = countryController.text;
    userData.state = stateController.text;
    userData.city = cityController.text;
    userData.area = areaController.text;
    userData.address = addressController.text;
    userData.dob = selectedDate;

    final rolePath =
        userData.role.toLowerCase() == 'worker' ? 'workers' : 'jobproviders';

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(rolePath)
        .collection(rolePath)
        .doc(userData.userId);

    await ref.set(userData.toJson());

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(userData.toJson()));
    await _saveSelectedProfileIndex(selectedProfileIndex);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved successfully')));

    await _reloadUserData();

    // Navigate to jobproviderpage or workerpage after saving
    if (userData.role.toLowerCase() == 'worker') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Workerpage(userData: userData)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Jobproviderpage(userData: userData)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider avatarImage;
    if (userData.profileImage.isNotEmpty &&
        File(userData.profileImage).existsSync()) {
      avatarImage = FileImage(File(userData.profileImage));
    } else {
      avatarImage = AssetImage(profileImages[selectedProfileIndex]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2563EB),

        centerTitle: true,
        elevation: 1,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // --- profile header card ---
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 14,
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: avatarImage,
                          backgroundColor: Colors.grey.shade200,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: const Color(0xFF2563EB),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _pickImage,
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _chip('Role', userData.role),
                          const SizedBox(height: 6),
                          _chip('User ID', userData.userId),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- personal info ---
            _sectionCard(
              title: 'Personal Information',
              child: Column(
                children: [
                  _buildValidatedField(
                    label: "Name",
                    initialValue: userData.name,
                    onChanged: (val) => userData.name = val,
                  ),
                  _buildDropdownField(
                    label: "Gender",
                    value: userData.gender.isNotEmpty ? userData.gender : null,
                    items: genders,
                    onChanged:
                        (val) => setState(() => userData.gender = val ?? ''),
                  ),
                  _buildDobPicker(),
                  if (_submitted && selectedDate == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Please select your date of birth',
                        style: TextStyle(color: Colors.red, fontSize: 12.5),
                      ),
                    ),
                  _buildPhoneField(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --- location (single label) ---
            _sectionCard(
              title: 'Location',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // One compact group for Country, State & City
                  CountryStateCityPicker(
                    country: countryController,
                    state: stateController,
                    city: cityController,
                    dialogColor: Colors.grey.shade100,
                    textFieldDecoration: InputDecoration(
                      // Single consistent decoration for all 3 fields; no inner labels
                      hintText: 'Select Country / State / City',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                    ),
                  ),

                  // Inline errors below the group
                  if (_submitted && countryController.text.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Please select country',
                        style: TextStyle(color: Colors.red, fontSize: 12.5),
                      ),
                    ),
                  if (_submitted && stateController.text.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Please select state',
                        style: TextStyle(color: Colors.red, fontSize: 12.5),
                      ),
                    ),
                  if (_submitted && cityController.text.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Please select city',
                        style: TextStyle(color: Colors.red, fontSize: 12.5),
                      ),
                    ),

                  const SizedBox(height: 12),

                  _buildValidatedField(
                    label: "Area",
                    controller: areaController,
                    onChanged: (val) => userData.area = val,
                  ),
                  _buildValidatedField(
                    label: "Full Address",
                    controller: addressController,
                    onChanged: (val) => userData.address = val,
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            if (userData.role.toLowerCase() == 'worker') ...[
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Work',
                child: _buildValidatedField(
                  label: "Experience",
                  initialValue: userData.experience,
                  onChanged: (val) => userData.experience = val,
                ),
              ),
            ],

            const SizedBox(height: 22),

            // save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                      color: Colors.white,
                      backgroundColor: const Color(0xFF2563EB),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- UI helpers ----------

  Widget _sectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey.shade800,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: Colors.blue.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        value: value,
        items:
            items
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
        onChanged: onChanged,
        validator:
            (val) => val == null || val.isEmpty ? 'Please select $label' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDobPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null) {
            setState(() {
              selectedDate = pickedDate;
              userData.dob = pickedDate;
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: "Date of Birth",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            errorText:
                _submitted && selectedDate == null
                    ? 'Please select your date of birth'
                    : null,
          ),
          child: Text(
            selectedDate == null
                ? 'Tap to select'
                : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: phoneController,
        decoration: InputDecoration(
          labelText: "Phone Number",
          prefixText: '+91 ',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        keyboardType: TextInputType.phone,
        maxLength: 10,
        validator: (val) {
          if (val == null || val.isEmpty) return "Please enter phone number";
          if (val.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(val)) {
            return "Enter valid 10-digit phone number";
          }
          return null;
        },
      ),
    );
  }

  Widget _buildValidatedField({
    required String label,
    String? initialValue,
    TextEditingController? controller,
    required void Function(String) onChanged,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
        maxLines: maxLines,
        validator:
            (val) => val == null || val.isEmpty ? "Please enter $label" : null,
        onChanged: onChanged,
      ),
    );
  }
}
