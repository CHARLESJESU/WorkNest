import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/user_data.dart';

class JobStatusPage extends StatefulWidget {
  final UserData userData;

  const JobStatusPage({Key? key, required this.userData}) : super(key: key);

  @override
  _JobStatusPageState createState() => _JobStatusPageState();
}

class _JobStatusPageState extends State<JobStatusPage> {
  List<Map<String, dynamic>> jobList = [];
  bool isLoading = true;
  String selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    fetchAppliedJobs();
  }

  Future<void> fetchAppliedJobs() async {
    try {
      final userId = widget.userData.userId;
      final jobProviderSnapshot =
          await FirebaseFirestore.instance
              .collection('appliedJobs')
              .doc(userId)
              .collection('jobProviders')
              .get();

      List<Map<String, dynamic>> jobs = [];

      for (var providerDoc in jobProviderSnapshot.docs) {
        final jobProviderId = providerDoc.id;
        final postSnapshot =
            await FirebaseFirestore.instance
                .collection('appliedJobs')
                .doc(userId)
                .collection('jobProviders')
                .doc(jobProviderId)
                .collection('posts')
                .get();

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

  Future<void> deleteAllJobs() async {
    try {
      final userId = widget.userData.userId;
      final jobProviderSnapshot =
          await FirebaseFirestore.instance
              .collection('appliedJobs')
              .doc(userId)
              .collection('jobProviders')
              .get();

      for (var providerDoc in jobProviderSnapshot.docs) {
        final jobProviderId = providerDoc.id;
        final postSnapshot =
            await FirebaseFirestore.instance
                .collection('appliedJobs')
                .doc(userId)
                .collection('jobProviders')
                .doc(jobProviderId)
                .collection('posts')
                .get();

        for (var postDoc in postSnapshot.docs) {
          await postDoc.reference.delete();
        }
      }

      setState(() {
        jobList.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All jobs deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete all jobs')),
      );
    }
  }

  Future<void> deleteJob(String jobProviderId, String postId) async {
    try {
      final userId = widget.userData.userId;
      await FirebaseFirestore.instance
          .collection('appliedJobs')
          .doc(userId)
          .collection('jobProviders')
          .doc(jobProviderId)
          .collection('posts')
          .doc(postId)
          .delete();

      setState(() {
        jobList.removeWhere(
          (job) =>
              job['jobProviderId'] == jobProviderId && job['postId'] == postId,
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Job deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete job')));
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'confirmation':
        return Colors.blue;
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
      case 'confirmation':
        return Icons.verified;
      default:
        return Icons.hourglass_top;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exiting Job Status Page')),
        );
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Job Status"),
          actions: [
            DropdownButton<String>(
              value: selectedStatus,
              onChanged: (value) async {
                if (value != null && value != selectedStatus) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Change Filter'),
                          content: Text(
                            'Do you want to filter jobs by "$value"?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    setState(() {
                      selectedStatus = value;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Filter applied: $value')),
                    );
                  }
                }
              },
              items:
                  ['All', 'Accepted', 'Rejected', 'Applied', 'Confirmation']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete_all') {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Delete All Jobs'),
                          content: const Text(
                            'Are you sure you want to delete all jobs?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    await deleteAllJobs();
                  }
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_forever, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text('Delete All'),
                        ],
                      ),
                    ),
                  ],
            ),
          ],
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : jobList.isEmpty
                ? const Center(child: Text('No job applications found.'))
                : ListView.builder(
                  padding: const EdgeInsets.all(30),
                  itemCount: jobList.length,
                  itemBuilder: (context, index) {
                    final job = jobList[index];

                    if (selectedStatus != 'All' &&
                        job['status'].toString().toLowerCase() !=
                            selectedStatus.toLowerCase()) {
                      return const SizedBox.shrink();
                    }

                    final statusColor = getStatusColor(job['status']);
                    final statusIcon = getStatusIcon(job['status']);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Job Provider ID: ${job['jobProviderId']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.blue,
                                  ),
                                  tooltip: 'Delete this job',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            title: const Text('Delete Job'),
                                            content: const Text(
                                              'Are you sure you want to delete this job?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.of(
                                                      context,
                                                    ).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.of(
                                                      context,
                                                    ).pop(true),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                    );
                                    if (confirm == true) {
                                      deleteJob(
                                        job['jobProviderId'],
                                        job['postId'],
                                      );
                                    }
                                  },
                                ),
                              ],
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
    );
  }
}
