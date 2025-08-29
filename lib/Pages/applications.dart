import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Application {
  final String userId;
  final String name;
  final String phoneNumber;
  final String experience;
  final String role;
  final String gender;
  final String dob;
  final String country;
  final String state;
  final String district;
  final String city;
  final String area;
  final String address;
  String status;
  bool showDetails;

  Application({
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.experience,
    required this.role,
    required this.gender,
    required this.dob,
    required this.country,
    required this.state,
    required this.district,
    required this.city,
    required this.area,
    required this.address,
    required this.status,
    this.showDetails = false,
  });

  factory Application.fromMap(String userId, Map<dynamic, dynamic> data) {
    return Application(
      userId: userId,
      name: data['name']?.toString() ?? 'N/A',
      phoneNumber: data['phoneNumber']?.toString() ?? 'N/A',
      experience: data['experience']?.toString() ?? 'N/A',
      role: data['role']?.toString() ?? 'N/A',
      gender: data['gender']?.toString() ?? 'N/A',
      dob: data['dob']?.toString() ?? 'N/A',
      country: data['country']?.toString() ?? 'N/A',
      state: data['state']?.toString() ?? 'N/A',
      district: data['district']?.toString() ?? 'N/A',
      city: data['city']?.toString() ?? 'N/A',
      area: data['area']?.toString() ?? 'N/A',
      address: data['address']?.toString() ?? 'N/A',
      status: data['status']?.toString() ?? 'applied',
    );
  }
}

class ApplicationsPage extends StatefulWidget {
  final String jobProviderUserId;

  const ApplicationsPage({required this.jobProviderUserId, super.key});

  @override
  _ApplicationsPageState createState() => _ApplicationsPageState();
}

class _ApplicationsPageState extends State<ApplicationsPage> {
  Future<void> deleteOrder(String orderId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Delete all workers under this order
      final workersSnapshot =
          await firestore
              .collection('applications')
              .doc(widget.jobProviderUserId)
              .collection('posts')
              .doc(orderId)
              .collection('workers')
              .get();

      for (var workerDoc in workersSnapshot.docs) {
        final workerUserId = workerDoc.id;
        // Delete from appliedJobs
        await firestore
            .collection('appliedJobs')
            .doc(workerUserId)
            .collection('jobProviders')
            .doc(widget.jobProviderUserId)
            .collection('posts')
            .doc(orderId)
            .delete();
      }

      // Delete all workers subcollection
      for (var workerDoc in workersSnapshot.docs) {
        await workerDoc.reference.delete();
      }

      // Delete the order document itself
      await firestore
          .collection('applications')
          .doc(widget.jobProviderUserId)
          .collection('posts')
          .doc(orderId)
          .delete();

      setState(() {
        groupedApplications.remove(orderId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete order: $e')));
    }
  }

  Future<void> deleteApplicant(String orderId, String workerUserId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      // Delete from applications
      await firestore
          .collection('applications')
          .doc(widget.jobProviderUserId)
          .collection('posts')
          .doc(orderId)
          .collection('workers')
          .doc(workerUserId)
          .delete();

      // Delete from appliedJobs
      await firestore
          .collection('appliedJobs')
          .doc(workerUserId)
          .collection('jobProviders')
          .doc(widget.jobProviderUserId)
          .collection('posts')
          .doc(orderId)
          .delete();

      setState(() {
        final list = groupedApplications[orderId];
        list?.removeWhere((a) => a.userId == workerUserId);
        if (list == null || list.isEmpty) {
          groupedApplications.remove(orderId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Applicant deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete applicant')),
      );
    }
  }

  Map<String, List<Application>> groupedApplications = {};
  List<bool> showOrderDetails = [];
  bool isLoading = true;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    fetchApplications();
  }

  Future<void> fetchApplications() async {
    setState(() => isLoading = true);

    final ref = FirebaseFirestore.instance
        .collection('applications')
        .doc(widget.jobProviderUserId)
        .collection('posts');

    _subscription?.cancel();
    _subscription = ref.snapshots().listen(
      (querySnapshot) async {
        if (!mounted) return;

        Map<String, List<Application>> tempGroupedApps = {};

        for (var postDoc in querySnapshot.docs) {
          final orderId = postDoc.id;
          final workersSnapshot =
              await postDoc.reference.collection('workers').get();
          List<Application> workers = [];

          for (var workerDoc in workersSnapshot.docs) {
            final workerUserId = workerDoc.id;
            final workerData = workerDoc.data();

            workers.add(Application.fromMap(workerUserId, workerData));
          }

          tempGroupedApps[orderId] = workers;
        }

        setState(() {
          groupedApplications = tempGroupedApps;
          showOrderDetails = List.generate(
            tempGroupedApps.length,
            (_) => false,
          );
          isLoading = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load applications: $error')),
        );
      },
    );
  }

  Future<void> updateApplicationStatus(
    String orderId,
    String workerUserId,
    String newStatus,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;

      final applicationsRef = firestore
          .collection('applications')
          .doc(widget.jobProviderUserId)
          .collection('posts')
          .doc(orderId)
          .collection('workers')
          .doc(workerUserId);

      final appliedJobsRef = firestore
          .collection('appliedJobs')
          .doc(workerUserId)
          .collection('jobProviders')
          .doc(widget.jobProviderUserId)
          .collection('posts')
          .doc(orderId);

      WriteBatch batch = firestore.batch();

      batch.update(applicationsRef, {'status': newStatus});
      batch.update(appliedJobsRef, {'status': newStatus});

      await batch.commit();

      await fetchApplications(); // 🔹 Refresh page after status update

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Application $newStatus successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  Future<void> sendIndividualConfirmation(
    String workerUserId,
    String postId,
  ) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final inboxRef = firestore
          .collection('messages')
          .doc(workerUserId)
          .collection('inbox');

      await inboxRef.add({
        'from': widget.jobProviderUserId,
        'postId': postId,
        'message': 'You are allowed to apply for this job.',
        'type': 'job_confirmation',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await updateApplicationStatus(postId, workerUserId, 'confirmation');

      await fetchApplications(); // 🔹 Refresh page after confirmation

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirmation sent to worker.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send confirmation: $e')),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'applied':
        return Colors.blue;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'confirmation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderCard(
    String orderId,
    List<Application> workers,
    int orderIndex,
  ) {
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
        children: [
          Row(
            children: [
              Expanded(
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business,
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
                              'Order ID: $orderId',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              '${workers.length} Applicant${workers.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  initiallyExpanded: showOrderDetails[orderIndex],
                  onExpansionChanged: (expanded) {
                    setState(() {
                      showOrderDetails[orderIndex] = expanded;
                    });
                  },
                  children:
                      workers
                          .asMap()
                          .entries
                          .map(
                            (entry) => _buildWorkerCard(
                              entry.value,
                              orderIndex,
                              entry.key,
                              orderId,
                            ),
                          )
                          .toList(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Color(0xFF2563EB)),
                tooltip: 'Delete Order',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Delete Order'),
                          content: const Text(
                            'Are you sure you want to delete this order and all its applicants?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Color(0xFF2563EB)),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Color(0xFF2563EB)),
                              ),
                            ),
                          ],
                        ),
                  );
                  if (confirm == true) {
                    await deleteOrder(orderId);
                  }
                },
                style: IconButton.styleFrom(
                  backgroundColor: Color(0xFF2563EB).withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(
    Application worker,
    int orderIndex,
    int workerIndex,
    String orderId,
  ) {
    bool showDetails = worker.showDetails;
    String status = worker.status;

    final statusColor = getStatusColor(worker.status);
    IconData statusIcon;
    switch (worker.status.toLowerCase()) {
      case 'accepted':
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusIcon = Icons.cancel;
        break;
      case 'confirmation':
        statusIcon = Icons.verified;
        break;
      default:
        statusIcon = Icons.hourglass_top;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 8,
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
                    Icons.person,
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
                        worker.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'User ID: ${worker.userId}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    showDetails ? Icons.expand_less : Icons.expand_more,
                    color:
                        status == 'rejected' ? Colors.grey : Color(0xFF2563EB),
                  ),
                  onPressed:
                      status == 'rejected'
                          ? null
                          : () {
                            setState(() {
                              groupedApplications[orderId]![workerIndex]
                                  .showDetails = !showDetails;
                            });
                          },
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB).withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFFDC2626)),
                  tooltip: 'Delete Applicant',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Delete Applicant'),
                            content: const Text(
                              'Are you sure you want to delete this applicant?',
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(false),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 235, 37, 37),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    () => Navigator.of(context).pop(true),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 235, 37, 37),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    );
                    if (confirm == true) {
                      await deleteApplicant(orderId, worker.userId);
                    }
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626).withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (showDetails && status != 'rejected')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailText('Phone', worker.phoneNumber),
                  _detailText('Experience', worker.experience),
                  _detailText('Role', worker.role),
                  _detailText('Gender', worker.gender),
                  _detailText('DOB', worker.dob),
                  _detailText('Country', worker.country),
                  _detailText('State', worker.state),
                  _detailText('District', worker.district),
                  _detailText('City', worker.city),
                  _detailText('Area', worker.area),
                  _detailText('Address', worker.address),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(statusIcon, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        worker.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              (status == 'applied' || status == 'confirmation')
                                  ? () async {
                                    await updateApplicationStatus(
                                      orderId,
                                      worker.userId,
                                      'accepted',
                                    );
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              (status == 'applied' || status == 'confirmation')
                                  ? () async {
                                    await updateApplicationStatus(
                                      orderId,
                                      worker.userId,
                                      'rejected',
                                    );
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              status == 'applied'
                                  ? () async {
                                    await sendIndividualConfirmation(
                                      worker.userId,
                                      orderId,
                                    );
                                  }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E42),
                          ),
                          child: const Text('Confirmation'),
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

  Widget _detailText(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: color ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: fetchApplications,
                child:
                    groupedApplications.isEmpty
                        ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 150),
                            Center(
                              child: Icon(
                                Icons.work_off,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 10),
                            Center(child: Text('No applications yet')),
                          ],
                        )
                        : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: groupedApplications.length,
                          itemBuilder: (context, index) {
                            String orderId = groupedApplications.keys.elementAt(
                              index,
                            );
                            final workers = groupedApplications[orderId] ?? [];
                            return _buildOrderCard(orderId, workers, index);
                          },
                        ),
              ),
        ],
      ),
    );
  }
}
