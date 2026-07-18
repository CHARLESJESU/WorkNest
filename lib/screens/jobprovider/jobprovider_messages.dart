import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/branding.dart';
import '../shared/chat_page.dart';

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
      final snapshot = await FirebaseFirestore.instance
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
        builder: (_) => ChatPage(
          postId: postId,
          myId: widget.jobProviderId,
          peerId: workerId,
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: WNColors.bg,
      child: RefreshIndicator(
        color: WNColors.blue,
        onRefresh: _refresh,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: WNColors.blue))
            : messages.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: WNColors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.mail_outline_rounded, size: 44, color: WNColors.blue),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No messages yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: WNColors.navy),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Worker responses will appear here.',
                              style: TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: WNColors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.message, color: WNColors.blue),
                          ),
                          title: Text(msg['message'], style: const TextStyle(fontWeight: FontWeight.w600, color: WNColors.navy)),
                          subtitle: Text(
                            'Worker ID: ${msg['workerId']} • Post ID: ${msg['postId']}',
                            style: const TextStyle(fontSize: 12, color: Colors.black45),
                          ),
                          trailing: msg['timestamp'] != null
                              ? Text(
                                  _formatTimestamp(msg['timestamp']),
                                  style: const TextStyle(color: Colors.black38, fontSize: 11),
                                )
                              : null,
                          onTap: () => _openChat(msg['workerId'], msg['postId']),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
