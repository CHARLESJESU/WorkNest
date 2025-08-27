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
  Map<String, List<Application>> groupedApplications = {};
  List<bool> showOrderDetails = [];
  bool isLoading = true;
  StreamSubscription? _subscription;
  String? selectedStatus;
  final List<String> availableStatuses = [
    'All',
    'Applied',
    'Accepted',
    'Rejected',
    'Confirmation',
  ];

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

  List<Application> get _allApplicants {
    return groupedApplications.values.expand((list) => list).toList();
  }

  List<Application> get _filteredApplicants {
    if (selectedStatus == null || selectedStatus == 'All') {
      return _allApplicants;
    }
    return _allApplicants
        .where(
          (app) => app.status.toLowerCase() == selectedStatus!.toLowerCase(),
        )
        .toList();
  }

  Widget _buildStatusFilterDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String?>(
        value: selectedStatus ?? 'All',
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
        items:
            availableStatuses
                .map(
                  (status) => DropdownMenuItem<String?>(
                    value: status,
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: (value) {
          if (value != null && value != selectedStatus) {
            setState(() {
              selectedStatus = value;
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Filter applied: $value')));
          }
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Color(0xFF2563EB), size: 20),
          const SizedBox(width: 12),
          Expanded(child: _buildStatusFilterDropdown()),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int applicantCount) {
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
              Icons.people_outline,
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
                  '$applicantCount Applications',
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

  Widget _buildOrderCard(
    String orderId,
    List<Application> workers,
    int orderIndex,
  ) {
    // Filter workers by status if filter is applied
    final filteredWorkers =
        (selectedStatus == null || selectedStatus == 'All')
            ? workers
            : workers
                .where(
                  (w) =>
                      w.status.toLowerCase() == selectedStatus!.toLowerCase(),
                )
                .toList();
    if (filteredWorkers.isEmpty) return const SizedBox.shrink();
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
      child: ExpansionTile(
        title: Text(
          'Order ID: $orderId',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
        subtitle: Text(
          '${filteredWorkers.length} Applicant${filteredWorkers.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        initiallyExpanded: showOrderDetails[orderIndex],
        onExpansionChanged: (expanded) {
          setState(() {
            showOrderDetails[orderIndex] = expanded;
          });
        },
        children:
            filteredWorkers
                .asMap()
                .entries
                .map(
                  (entry) => _buildWorkerCard(
                    entry.value,
                    orderIndex,
                    workers.indexOf(entry.value),
                    orderId,
                  ),
                )
                .toList(),
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
    Color statusColor = getStatusColor(status);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            offset: const Offset(0, 1),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'User ID: ${worker.userId}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, color: statusColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Status: ${worker.status}',
                            style: TextStyle(
                              fontSize: 13,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    showDetails ? Icons.expand_less : Icons.expand_more,
                    color:
                        status == 'rejected'
                            ? Colors.grey
                            : const Color(0xFF2563EB),
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
              ],
            ),
            if (showDetails && status != 'rejected')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                (status == 'applied' ||
                                        status == 'confirmation')
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
                                (status == 'applied' ||
                                        status == 'confirmation')
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
      appBar: AppBar(title: const Text("APPLICATIONS"), elevation: 0),
      body: Stack(
        children: [
          isLoading
              ? ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: 3,
                itemBuilder:
                    (context, index) => Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
              )
              : _allApplicants.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No applications yet',
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  _buildFilterSection(),
                  _buildStatsCard(_filteredApplicants.length),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: fetchApplications,
                      color: const Color(0xFF2563EB),
                      backgroundColor: Colors.white,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 16, bottom: 100),
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
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
