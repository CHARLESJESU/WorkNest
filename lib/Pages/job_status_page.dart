import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/user_data.dart';

class JobStatusPage extends StatefulWidget {
  final UserData userData;

  const JobStatusPage({Key? key, required this.userData}) : super(key: key);

  @override
  State<JobStatusPage> createState() => _JobStatusPageState();
}

class _JobStatusPageState extends State<JobStatusPage> {
  List<Map<String, dynamic>> jobList = [];
  bool isLoading = true;
  String? selectedStatus;
  final List<String> availableStatuses = [
    'All',
    'Accepted',
    'Rejected',
    'Applied',
    'Confirmation',
  ];

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
        return const Color(0xFF10B981); // green
      case 'rejected':
        return const Color(0xFFDC2626); // red
      case 'confirmation':
        return const Color(0xFF2563EB); // blue
      default:
        return const Color(0xFFF59E42); // orange
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
    final filteredJobs =
        selectedStatus == null || selectedStatus == 'All'
            ? jobList
            : jobList
                .where(
                  (job) =>
                      job['status'].toString().toLowerCase() ==
                      selectedStatus!.toLowerCase(),
                )
                .toList();

    return Scaffold(
      body:
          isLoading
              ? ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: 3,
                itemBuilder: (context, index) => _buildLoadingCard(),
              )
              : jobList.isEmpty
              ? _buildEmptyState()
              : Column(
                children: [
                  // Custom top bar with filter left, three-dot menu right
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 16,
                      left: 8,
                      right: 8,
                      bottom: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Filter icon (left)
                        IconButton(
                          icon: const Icon(
                            Icons.filter_list,
                            color: Color(0xFF2563EB),
                          ),
                          tooltip: 'Filter',
                          onPressed: () async {
                            final value = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                return SimpleDialog(
                                  title: const Text('Filter by Status'),
                                  children:
                                      availableStatuses.map((status) {
                                        return SimpleDialogOption(
                                          onPressed: () {
                                            Navigator.of(context).pop(status);
                                          },
                                          child: Row(
                                            children: [
                                              if ((selectedStatus ?? 'All') ==
                                                  status)
                                                const Icon(
                                                  Icons.check,
                                                  color: Color(0xFF2563EB),
                                                  size: 18,
                                                )
                                              else
                                                const SizedBox(width: 18),
                                              const SizedBox(width: 8),
                                              Text(status),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                );
                              },
                            );
                            if (value != null && value != selectedStatus) {
                              setState(() {
                                selectedStatus = value;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Filter applied: $value'),
                                ),
                              );
                            }
                          },
                        ),
                        // Three-dot menu (delete all) right
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Color(0xFF2563EB),
                          ),
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
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
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
                                      Icon(
                                        Icons.delete_forever,
                                        color: Color.fromARGB(255, 251, 3, 3),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Delete All'),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ],
                    ),
                  ),
                  _buildStatsCard(filteredJobs.length),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: fetchAppliedJobs,
                      color: const Color(0xFF2563EB),
                      backgroundColor: Colors.white,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 100),
                        itemCount: filteredJobs.length,
                        itemBuilder: (context, index) {
                          final job = filteredJobs[index];
                          return _buildModernJobCard(context, job);
                        },
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildStatsCard(int jobCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.work_outline,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$jobCount Job Applications',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  selectedStatus == null || selectedStatus == 'All'
                      ? 'All statuses'
                      : 'Status: $selectedStatus',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernJobCard(BuildContext context, Map<String, dynamic> job) {
    final statusColor = getStatusColor(job['status']);
    final statusIcon = getStatusIcon(job['status']);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job Provider ID: ${job['jobProviderId']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
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
                                    () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) {
                      deleteJob(job['jobProviderId'], job['postId']);
                    }
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image if available
          if (job['imageBase64'] != null &&
              job['imageBase64'].toString().isNotEmpty)
            Container(
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap:
                      () => _showFullScreenImage(context, job['imageBase64']),
                  child: Image.memory(
                    base64Decode(job['imageBase64']),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Job Description',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  job['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      job['status'].toString().toUpperCase(),
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
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 160,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No job applications found.',
            style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageBase64) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                iconTheme: const IconThemeData(color: Colors.white),
                elevation: 0,
              ),
              body: Center(
                child: InteractiveViewer(
                  child: Image.memory(
                    base64Decode(imageBase64),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
      ),
    );
  }
}
