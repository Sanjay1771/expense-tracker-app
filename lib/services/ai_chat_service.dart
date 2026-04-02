import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/transaction_model.dart';
import '../config/api_keys.dart';

class AIChatService {
  final String _apiKey = ApiKeys.geminiApiKey;
  late GenerativeModel _model;
  ChatSession? _chatSession;

  AIChatService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  /// Initialize chat with financial context
  void startChat(List<TransactionModel> transactions, double balance) {
    // Generate context summary
    final totalExp = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    Map<String, double> categories = {};
    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        categories[t.category] = (categories[t.category] ?? 0) + t.amount;
      }
    }
    
    String topCat = "None";
    double maxAmt = 0;
    categories.forEach((k, v) { if (v > maxAmt) { maxAmt = v; topCat = k; } });

    final systemInstruction = """
You are a helpful Financial Assistant for an Expense Tracker App. 
The user's current financial status:
- Current Balance: ₹${balance.toStringAsFixed(2)}
- Total Expenses: ₹${totalExp.toStringAsFixed(2)}
- Top Spending Category: $topCat (₹${maxAmt.toStringAsFixed(2)})

Provide concise, smart, and encouraging financial advice. 
If the user asks about their spending, use this data to answer.
Always be polite and helpful.
""";

    _chatSession = _model.startChat(history: [
      Content.text(systemInstruction),
      Content.model([TextPart("Understood. I'm ready to help you manage your finances! How can I assist you today?")]),
    ]);
  }

  /// Send message and get response
  Future<String> sendMessage(String message) async {
    if (_chatSession == null) return "Chat not initialized.";
    
    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? "I'm sorry, I couldn't process that.";
    } catch (e) {
      return "Error connecting to AI: $e";
    }
  }
}
