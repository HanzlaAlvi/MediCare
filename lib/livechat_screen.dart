import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({super.key});

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Replace with your actual valid API Key
  final String _apiKey = "AIzaSyCWacvI3ZFJwt_YdPcHZijAI33jmU9LAP8";

  final String _systemInstruction = """
  You are the official AI Support Assistant for the 'Medi Care' app. 
  Your job is ONLY to help users with:
  1. Ordering medicines.
  2. Uploading prescriptions.
  3. App navigation.
  4. General medical guidance.
  
  STRICT RULES:
  - If the user asks about anything irrelevant, reply: "I can only assist with Medi Care app queries."
  - Keep answers short.
  """;

  @override
  void initState() {
    super.initState();
    _checkAndClearOldChat();
  }

  // --- AUTO DELETE OLD CHAT ---
  Future<void> _checkAndClearOldChat() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final chatRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chat_history');
    final snapshot = await chatRef
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final lastMsgDate = (snapshot.docs.first['timestamp'] as Timestamp)
          .toDate();
      final now = DateTime.now();

      if (lastMsgDate.day != now.day) {
        var batch = FirebaseFirestore.instance.batch();
        var allDocs = await chatRef.get();
        for (var doc in allDocs.docs) {batch.delete(doc.reference);}
        await batch.commit();
      }
    }
  }

  // --- SEND MESSAGE ---
  Future<void> _sendMessage() async {
    String userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    _controller.clear();
    setState(() => _isLoading = true);

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Save User Message
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chat_history')
        .add({
          'role': 'user',
          'text': userMessage,
          'timestamp': FieldValue.serverTimestamp(),
        });

    try {
      // 2. Call Gemini
      final model = GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: _apiKey);
      final content = [
        Content.text(_systemInstruction),
        Content.text("User Query: $userMessage"),
      ];
      final response = await model.generateContent(content);
      String botReply = response.text ?? "Connecting...";

      // 3. Save Bot Message (This triggers NotificationService)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('chat_history')
          .add({
            'role': 'bot',
            'text': botReply,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF285D66),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "MediCare Assistant",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .collection('chat_history')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData){return const Center(child: CircularProgressIndicator());}
                  
                var docs = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients)
                    {_scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );}
                });

                if (docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "Hello! I am MediCare AI.\nHow can I help you today?",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isBot = data['role'] == 'bot';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: isBot
                          ? ReceiverMessage(text: data['text'])
                          : SenderMessage(text: data['text']),
                    );
                  },
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "MediCare AI is typing...",
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ChatInputArea(controller: _controller, onSend: _sendMessage),
        ],
      ),
    );
  }
}

// --- WIDGETS ---

class ReceiverMessage extends StatelessWidget {
  final String text;
  const ReceiverMessage({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFF285D66),
          child: Icon(Icons.medical_services, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Color(0xFFF2F4F5),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(15),
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF285D66),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}

class SenderMessage extends StatelessWidget {
  final String text;
  const SenderMessage({super.key, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 40),
        Flexible(
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2F1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF285D66),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(
            'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
          ),
        ),
      ],
    );
  }
}

class ChatInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const ChatInputArea({
    super.key,
    required this.controller,
    required this.onSend,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "Ask about medicines...",
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: onSend,
            child: Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: const Color(0xFF285D66),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
