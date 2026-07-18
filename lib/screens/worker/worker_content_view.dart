// lib/worker/worker_content_view.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart'; // Keep for location lookup

// Your existing imports for models and utilities
import 'package:nivetha123/models/job_provider.dart'; // Assuming this is your JobProvider model
import 'package:nivetha123/models/post.dart'; // Assuming this is your Post model


import '../shared/map_page.dart'; // Your existing MapPage
import '../../theme/branding.dart';

class WorkerContentView extends StatelessWidget {
  final List<Post> posts;
  final bool isLoading;
  final Map<String, bool> appliedJobs;
  final Map<String, bool> applyingJobs;
  final Map<String, JobProvider> jobProviderDetails;
  final String? selectedCity;
  final List<String> availableCities;
  final ValueChanged<String?> onCityChanged;
  final Future<void> Function(String jobProviderUserId, String postId) onApplyForJob;
  final Future<void> Function() onRefreshPosts; // Callback to refresh posts


  const WorkerContentView({
    Key? key,
    required this.posts,
    required this.isLoading,
    required this.appliedJobs,
    required this.applyingJobs,
    required this.jobProviderDetails,
    required this.selectedCity,
    required this.availableCities,
    required this.onCityChanged,
    required this.onApplyForJob,
    required this.onRefreshPosts, // Initialize the callback
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filteredPosts = selectedCity == null
        ? posts
        : posts.where((post) {
      final provider = jobProviderDetails[post.userId];
      return provider?.city == selectedCity;
    }).toList();

    return Column(
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
              child: DropdownButton<String?>(
                value: selectedCity,
                hint: Row(
                  children: const [
                    Icon(Icons.location_city, color: WNColors.blue, size: 20),
                    SizedBox(width: 10),
                    Text("Filter by City", style: TextStyle(color: Colors.black54, fontSize: 15)),
                  ],
                ),
                icon: const Icon(Icons.expand_more, color: WNColors.blue),
                isExpanded: true,
                borderRadius: BorderRadius.circular(14),
                selectedItemBuilder: (context) => [
                  Row(
                    children: const [
                      Icon(Icons.location_city, color: WNColors.blue, size: 20),
                      SizedBox(width: 10),
                      Text("All Cities", style: TextStyle(fontWeight: FontWeight.w600, color: WNColors.navy, fontSize: 15)),
                    ],
                  ),
                  ...availableCities.map(
                    (city) => Row(
                      children: [
                        const Icon(Icons.location_city, color: WNColors.blue, size: 20),
                        const SizedBox(width: 10),
                        Text(city, style: const TextStyle(fontWeight: FontWeight.w600, color: WNColors.navy, fontSize: 15)),
                      ],
                    ),
                  ),
                ],
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text("All Cities"),
                  ),
                  ...availableCities.map(
                        (city) => DropdownMenuItem<String?>(value: city, child: Text(city)),
                  ),
                ],
                onChanged: onCityChanged, // Use the callback
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator( // Keep RefreshIndicator here for refreshing content view
            color: WNColors.blue,
            onRefresh: onRefreshPosts,
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: WNColors.blue))
                : filteredPosts.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.work_off_outlined, size: 64, color: Colors.black26),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          "No jobs available for selected city.",
                          style: TextStyle(color: Colors.black54, fontSize: 15),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredPosts.length,
              itemBuilder: (context, index) {
                final post = filteredPosts[index];
                final isApplied = appliedJobs[post.postId] ?? false;
                final isApplying = applyingJobs[post.postId] ?? false;
                final provider = jobProviderDetails[post.userId];
                final providerAddress = provider?.address ?? "";

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              provider?.name.isNotEmpty == true
                                  ? provider!.name
                                  : "Job Provider Id: ${post.userId}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: WNColors.navy,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.location_on,
                                color: WNColors.orange,
                              ),
                              onPressed: () async {
                                if (providerAddress.isNotEmpty) {
                                  try {
                                    List<Location> locations =
                                    await locationFromAddress(providerAddress);
                                    if (locations.isNotEmpty) {
                                      final lat = locations[0].latitude;
                                      final lng = locations[0].longitude;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => MapPage(
                                            latitude: lat,
                                            longitude: lng,
                                            address: providerAddress,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    print("Error getting location: $e");
                                    showWNMessage(context, isError: true, message: "Couldn't find location for the given address");
                                  }
                                } else {
                                  showWNMessage(context, isError: true, message: "Address is empty");
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "City: ${provider?.city ?? ''}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: WNColors.blue,
                          ),
                        ),
                        if (provider != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Phone: ${provider.phone}",
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                          Text(
                            "Address: ${provider.address}",
                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (post.imageBase64.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => Scaffold(
                                        appBar: AppBar(
                                          backgroundColor: Colors.black,
                                          iconTheme: const IconThemeData(
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: Colors.black,
                                        body: Center(
                                          child: InteractiveViewer(
                                            child: Image.memory(
                                              base64Decode(post.imageBase64),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    base64Decode(post.imageBase64),
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.description,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed: (isApplied || isApplying)
                                          ? null
                                          : () => onApplyForJob(
                                        post.userId,
                                        post.postId,
                                      ),
                                      icon: isApplying
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Icon(Icons.work, color: Colors.white),
                                      label: Text(
                                        isApplied ? "Applied" : (isApplying ? "Applying..." : "Apply Now"),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        isApplied ? Colors.grey : WNColors.blue.withOpacity(isApplying ? 0.7 : 1),
                                        disabledBackgroundColor:
                                        isApplied ? Colors.grey : WNColors.blue.withOpacity(0.7),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
    );
  }
}