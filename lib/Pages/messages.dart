import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nivetha123/Pages/worker_chatpage.dart'; // Make sure this path is correct

class MessagesPage extends StatefulWidget {
  final String jobProviderId;

  const MessagesPage({super.key, required this.jobProviderId});

  @override
  _MessagesPageState createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    setState(() => isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('messages')
              .doc(widget.jobProviderId)
              .collection('inbox')
              .orderBy('timestamp', descending: true)
              .get();

      final List<Map<String, dynamic>> fetchedMessages = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'worker_response') {
          fetchedMessages.add({
            'workerId': data['from'] ?? 'Unknown',
            'postId': data['postId'] ?? 'Unknown',
            'message': data['message'] ?? 'No message',
            'timestamp': data['timestamp'],
          });
        }
      }

      setState(() {
        messages = fetchedMessages;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching messages: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await fetchMessages();
  }

  void _openChat(String workerId, String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChatPage(
              postId: postId,
              myId: widget.jobProviderId,
              peerId: workerId,
            ),
      ),
    );
  }

  // 🔹 Count only unread messages from worker
  Stream<int> _getUnreadCount(String workerId, String postId) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc('${workerId}_${widget.jobProviderId}_${postId}')
        .collection('messages')
        .where('from', isEqualTo: workerId) // only worker messages
        .where('isRead', isEqualTo: false) // only unread ones
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : messages.isEmpty
              ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  const Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 48,
                          color: Colors.black54,
                        ),
                        SizedBox(height: 8),
                        Text('No messages yet', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              )
              : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final bool isInterested = msg['message']
                      .toString()
                      .toLowerCase()
                      .contains('i am interested');

                  return StreamBuilder<int>(
                    stream: _getUnreadCount(msg['workerId'], msg['postId']),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      return ListTile(
                        leading: const Icon(Icons.message, color: Colors.blue),
                        title: Text(msg['message']),
                        subtitle: Text(
                          'Worker ID: ${msg['workerId']} • Post ID: ${msg['postId']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (msg['timestamp'] != null)
                              Text(
                                _formatTimestamp(msg['timestamp']),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            const SizedBox(width: 6),
                            if (unreadCount > 0)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap:
                            isInterested
                                ? () {
                                  _openChat(msg['workerId'], msg['postId']);
                                }
                                : null,
                      );
                    },
                  );
                },
              ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
