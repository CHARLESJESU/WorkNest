import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nivetha123/Pages/worker_chatpage.dart';

class WorkerMessagesPage extends StatefulWidget {
  final String workerId;

  const WorkerMessagesPage({super.key, required this.workerId});

  @override
  State<WorkerMessagesPage> createState() => _WorkerMessagesPageState();
}

class _WorkerMessagesPageState extends State<WorkerMessagesPage> {
  final Set<String> _sentInterest = {};
  final Set<String> _notInterestedSent = {};
  final Set<String> _showChatIcon = {};

  @override
  Widget build(BuildContext context) {
    final inboxRef = FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.workerId)
        .collection('inbox')
        .orderBy('timestamp', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("MESSAGES")),
      body: StreamBuilder<QuerySnapshot>(
        stream: inboxRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text("No messages yet."));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final from = data['from'] ?? 'Unknown';
              final message = data['message'] ?? '';
              final postId = data['postId'] ?? 'Unknown';
              final type = data['type'] ?? 'general';
              final key = '$from-$postId';

              final response = data['response'] ?? '';
              final hasSentInterested =
                  _sentInterest.contains(key) || response == 'interested';
              final hasSentNotInterested =
                  _notInterestedSent.contains(key) ||
                  response == 'not_interested';
              final showIcon =
                  _showChatIcon.contains(key) || response == 'interested';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'From Job Provider: $from',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Color(0xFF2563EB)),
                            tooltip: 'Delete',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Delete Message'),
                                      content: const Text(
                                        'Are you sure you want to delete this message?',
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
                                deleteMessage(docs[index].id);
                              }
                            },
                          ),
                          if (showIcon)
                            StreamBuilder<QuerySnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc('${widget.workerId}${from}$postId')
                                      .collection('messages')
                                      .where('to', isEqualTo: widget.workerId)
                                      .snapshots(),
                              builder: (context, msgSnapshot) {
                                final msgCount =
                                    msgSnapshot.data?.docs.length ?? 0;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.message,
                                            color: Color(0xFF2563EB),
                                          ),
                                          onPressed: () {
                                            _navigateToChat(postId, from);
                                          },
                                        ),
                                        if (msgCount > 0)
                                          Positioned(
                                            right: 4,
                                            top: 4,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 20,
                                                minHeight: 20,
                                              ),
                                              child: Text(
                                                msgCount.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Post ID: $postId'),
                      const SizedBox(height: 8),
                      Text(message),
                      const SizedBox(height: 12),

                      if (type == 'job_confirmation') ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    (hasSentInterested || hasSentNotInterested)
                                        ? null
                                        : () async {
                                          final alreadySent =
                                              await _checkIfAlreadySent(
                                                jobProviderId: from,
                                                postId: postId,
                                              );

                                          if (alreadySent) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'You have already sent your interest.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          await _sendResponseToJobProvider(
                                            jobProviderId: from,
                                            workerResponse: 'interested',
                                            postId: postId,
                                          );

                                          await FirebaseFirestore.instance
                                              .collection('messages')
                                              .doc(widget.workerId)
                                              .collection('inbox')
                                              .doc(docs[index].id)
                                              .update({
                                                'response': 'interested',
                                              });

                                          setState(() {
                                            _sentInterest.add(key);
                                            _showChatIcon.add(key);
                                          });
                                        },
                                icon: const Icon(Icons.thumb_up),
                                label: const Text("I'm interested"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed:
                                    (hasSentInterested || hasSentNotInterested)
                                        ? null
                                        : () async {
                                          await _sendResponseToJobProvider(
                                            jobProviderId: from,
                                            workerResponse: 'not_interested',
                                            postId: postId,
                                          );

                                          await FirebaseFirestore.instance
                                              .collection('messages')
                                              .doc(widget.workerId)
                                              .collection('inbox')
                                              .doc(docs[index].id)
                                              .update({
                                                'response': 'not_interested',
                                              });

                                          setState(() {
                                            _notInterestedSent.add(key);
                                          });
                                        },
                                icon: const Icon(Icons.thumb_down),
                                label: const Text("Not interested"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _sendResponseToJobProvider({
    required String jobProviderId,
    required String workerResponse,
    required String postId,
  }) async {
    final responseRef = FirebaseFirestore.instance
        .collection('messages')
        .doc(jobProviderId)
        .collection('inbox');

    await responseRef.add({
      'from': widget.workerId,
      'type': 'worker_response',
      'postId': postId,
      'response': workerResponse,
      'timestamp': FieldValue.serverTimestamp(),
      'message':
          workerResponse == 'interested'
              ? 'I am interested in this job.'
              : 'I am not interested in this job.',
      'status': 'sent',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Response sent to job provider (${workerResponse.replaceAll('_', ' ')})',
        ),
      ),
    );
  }

  Future<bool> _checkIfAlreadySent({
    required String jobProviderId,
    required String postId,
  }) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('messages')
            .doc(jobProviderId)
            .collection('inbox')
            .where('from', isEqualTo: widget.workerId)
            .where('postId', isEqualTo: postId)
            .where('response', isEqualTo: 'interested')
            .get();

    return snapshot.docs.isNotEmpty;
  }

  void _navigateToChat(String postId, String to) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChatPage(postId: postId, myId: widget.workerId, peerId: to),
      ),
    );
  }

  Future<void> deleteMessage(String postId) async {
    try {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.workerId)
          .collection('inbox')
          .doc(postId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete message')));
    }
  }
}
