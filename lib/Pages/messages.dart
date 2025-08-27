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
            'id': doc.id, // Store Firestore doc ID
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

  Future<void> deleteMessage(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('messages')
          .doc(widget.jobProviderId)
          .collection('inbox')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message deleted successfully')),
      );
      await fetchMessages();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete message')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("MESSAGES")),
      body: RefreshIndicator(
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
                          Text(
                            'No messages yet',
                            style: TextStyle(fontSize: 14),
                          ),
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
                    final docId = msg['id']; // Use Firestore doc ID
                    return StreamBuilder<int>(
                      stream: _getUnreadCount(msg['workerId'], msg['postId']),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'From Worker: ${msg['workerId']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            'Post ID: ${msg['postId']}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Color(0xFF2563EB),
                                      ),
                                      tooltip: 'Delete',
                                      onPressed: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder:
                                              (context) => AlertDialog(
                                                title: const Text(
                                                  'Delete Message',
                                                ),
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
                                                        color: Color(
                                                          0xFF2563EB,
                                                        ),
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
                                                        color: Color(
                                                          0xFF2563EB,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        );
                                        if (confirm == true) {
                                          deleteMessage(docId);
                                        }
                                      },
                                    ),
                                    if (isInterested)
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.message,
                                              color: Color(0xFF2563EB),
                                            ),
                                            onPressed: () {
                                              _openChat(
                                                msg['workerId'],
                                                msg['postId'],
                                              );
                                            },
                                          ),
                                          if (unreadCount > 0)
                                            Positioned(
                                              right: 4,
                                              top: 4,
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                      minWidth: 20,
                                                      minHeight: 20,
                                                    ),
                                                child: Text(
                                                  unreadCount.toString(),
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
                                ),
                                const SizedBox(height: 8),
                                Text(msg['message']),
                                if (msg['timestamp'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      _formatTimestamp(msg['timestamp']),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      ),
    );
  }

  // Add this helper at the end of the class
  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
