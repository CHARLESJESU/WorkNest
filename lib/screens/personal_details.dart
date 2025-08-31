import 'package:flutter/material.dart';
import 'package:nivetha123/screens/user_data.dart';
import '../widgets/step_progress.dart';
import 'contact_details.dart';

class Page2PersonalDetails extends StatefulWidget {
  final UserData userData;
  Page2PersonalDetails({required this.userData});

  @override
  _Page2PersonalDetailsState createState() => _Page2PersonalDetailsState();
}

class _Page2PersonalDetailsState extends State<Page2PersonalDetails> {
  final List<String> genders = ['Male', 'Female', 'Other'];
  DateTime? selectedDate;
  String? errorMessage;

  void _validateAndProceed() {
    if (widget.userData.gender == null || selectedDate == null) {
      setState(() {
        errorMessage = 'Please select gender and date of birth';
      });
      return;
    }

    if (widget.userData.role == 'Worker') {
      DateTime today = DateTime.now();
      int age = today.year - selectedDate!.year;
      if (selectedDate!.month > today.month ||
          (selectedDate!.month == today.month &&
              selectedDate!.day > today.day)) {
        age--;
      }

      if (age < 18) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Workers must be 18+ to proceed!')),
        );
        return;
      }
    }

    // ✅ Delay navigation so user can see the message
    Future.delayed(Duration(seconds: 0), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Page3ContactDetails(userData: widget.userData),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.account_circle, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text(
              'Personal Info',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
        toolbarHeight: 65,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  StepProgress(currentStep: 2, totalSteps: 5),
                  SizedBox(height: 32),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Gender',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          SizedBox(height: 16),
                          Column(
                            children:
                                genders.map((String gender) {
                                  return RadioListTile<String>(
                                    title: Text(
                                      gender,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    value: gender,
                                    groupValue: widget.userData.gender,
                                    onChanged: (String? value) {
                                      setState(() {
                                        widget.userData.gender = value!;
                                        errorMessage = null;
                                      });
                                    },
                                    activeColor: const Color(0xFF2563EB),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  );
                                }).toList(),
                          ),
                          SizedBox(height: 32),
                          Text(
                            'Date of Birth',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          SizedBox(height: 15),
                          InkWell(
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime(2000),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  selectedDate = pickedDate;
                                  widget.userData.dob = pickedDate;
                                  errorMessage = null;
                                });
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    selectedDate == null
                                        ? 'Select Date'
                                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (errorMessage != null)
                            Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: Color(0xFF2563EB).withOpacity(0.3),
                    ),
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    label: Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _validateAndProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Color(0xFF2563EB).withOpacity(0.3),
                      ),
                      icon: Icon(Icons.arrow_forward, color: Colors.white),
                      label: Text(
                        'Next',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
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
