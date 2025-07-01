import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/gemini_service.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

Future<Map<String, dynamic>> fetchUserData() async {
  final activeItems = await ApiService.fetchItems();
  final groceryItems = await ApiService.fetchGroceryItems();
  final used = await ApiService.fetchUsedItems();
  final wasted = await ApiService.fetchWastedItems();
  // print('Active type: ${activeItems.first.runtimeType}');
  // print('Grocery type: ${groceryItems.first.runtimeType}');
  // print('Used type: ${used.first.runtimeType}');
  // print('Wasted type: ${wasted.first.runtimeType}');
  return {
    'active': activeItems,
    'grocery': groceryItems,
    'used': used,
    'wasted': wasted,
  };
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late ChatProvider chatProvider;

  bool isLoading = false;

  void sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    chatProvider.addMessage('user', userMessage);
    setState(() {
      isLoading = true;
      _controller.clear();
    });

    final userData = await fetchUserData();

    final fullPrompt = """
    You are a helpful kitchen assistant. Use the data below to guide your responses.

    Active Ingredients:
    ${userData['active'].map((item) => "- ${item['name']} (${item['quantity']})").join('\n')}

    Grocery List:
    ${userData['grocery'].map((item) => "- ${item.name}").join('\n')}

    Used Items:
    ${userData['used'].map((item) => "- ${item['name']}").join('\n')}

    Wasted Items:
    ${userData['wasted'].map((item) => "- ${item['name']}").join('\n')}

    User question: $userMessage

    Respond helpfully using the above data.
    Do not bold the titles or use any special formatting.
    """;

    final reply = await GeminiService.askGemini(fullPrompt);

    chatProvider.addMessage('ai', reply);
    setState(() {
      isLoading = false;
    });
  }


  Widget buildMessage(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message['text'] ?? '',
          style: TextStyle(color: isUser ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    chatProvider = Provider.of<ChatProvider>(context);
    final _messages = chatProvider.messages;
    return Scaffold(
      appBar: AppBar(title: const Text("Kitchen Assistant AI")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: _messages.length,
              itemBuilder: (context, index) => buildMessage(_messages[index]),
            ),
          ),
          if (isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: "Ask anything..."),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
