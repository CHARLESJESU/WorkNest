import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/user_data.dart';
import '../../theme/branding.dart';

class JobStatusPage extends StatefulWidget {
  final UserData userData;

  const JobStatusPage({Key? key, required this.userData}) : super(key: key);

  @override
  _JobStatusPageState createState() => _JobStatusPageState();
}

class _JobStatusPageState extends State<JobStatusPage> {
  List<Map<String, dynamic>> jobList = [];
  bool isLoading = true;
  String selectedStatus = 'All'; // NEW: filter selection

  @override
  void initState() {
    super.initState();

    fetchAppliedJobs();
  }

  Future<void> fetchAppliedJobs() async {
    try {

      final userId = widget.userData.userId;

      final jobProviderSnapshot = await FirebaseFirestore.instance
          .collection('appliedJobs')
          .doc(userId)
          .collection('jobProviders')
          .get();

      List<Map<String, dynamic>> jobs = [];

      for (var providerDoc in jobProviderSnapshot.docs) {
        final jobProviderId = providerDoc.id;

        final postSnapshot = await FirebaseFirestore.instance
            .collection('appliedJobs')
            .doc(userId)
            .collection('jobProviders')
            .doc(jobProviderId)
            .collection('posts')
            .get();
        print(postSnapshot.docs[0].id);
        for (var postDoc in postSnapshot.docs) {
          final data = postDoc.data();
          jobs.add({
            'jobProviderId': jobProviderId,
            'postId': postDoc.id,
            'description': data['description'] ?? '',
            'imageBase64': data['imageBase64'] ?? '',
            'status': data['status'] ?? 'applied',
          });
        }
      }

      setState(() {
        jobList = jobs;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching applied jobs: $e");
      setState(() => isLoading = false);
    }
  }


  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.hourglass_top;
    }
  }

  IconData _filterIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'applied':
        return Icons.hourglass_top;
      default:
        return Icons.filter_list;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WNColors.bg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedStatus,
                  isExpanded: true,
                  icon: const Icon(Icons.expand_more, color: WNColors.blue),
                  borderRadius: BorderRadius.circular(14),
                  selectedItemBuilder: (context) => ['All', 'Accepted', 'Rejected', 'Applied']
                      .map(
                        (status) => Row(
                          children: [
                            Icon(_filterIcon(status), color: WNColors.blue, size: 20),
                            const SizedBox(width: 10),
                            Text(status, style: const TextStyle(fontWeight: FontWeight.w600, color: WNColors.navy, fontSize: 15)),
                          ],
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                  items:
                      ['All', 'Accepted', 'Rejected', 'Applied']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: WNColors.blue,
              onRefresh: fetchAppliedJobs,
              child:
                isLoading
                    ? const Center(child: CircularProgressIndicator(color: WNColors.blue))
                    : jobList.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.black26),
                          SizedBox(height: 12),
                          Center(
                            child: Text(
                              'No job applications found.',
                              style: TextStyle(color: Colors.black54, fontSize: 15),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: jobList.length,
                  itemBuilder: (context, index) {
                    final job = jobList[index];

                    // Filter logic
                    if (selectedStatus != 'All' &&
                        job['status'].toString().toLowerCase() !=
                            selectedStatus.toLowerCase()) {
                      return const SizedBox.shrink();
                    }

                    final statusColor = getStatusColor(job['status']);
                    final statusIcon = getStatusIcon(job['status']);

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Job Provider ID: ${job['jobProviderId']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: WNColors.navy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (job['imageBase64'] != null &&
                                job['imageBase64'].toString().isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  base64Decode(job['imageBase64']),
                                  height: 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              "Description: ${job['description']}",
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(statusIcon, color: statusColor),
                                const SizedBox(width: 6),
                                Text(
                                  "Status: ${job['status'].toString().toUpperCase()}",
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ),
          ),
        ],
      ),
    );
  }
}
