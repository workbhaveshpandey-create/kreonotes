import 'package:http/http.dart' as http;

class AiService {
  static const String _baseUrl = 'https://text.pollinations.ai';

  Future<String> continueWriting(String text) async {
    return _generate('Continue writing this naturally: $text');
  }

  Future<String> summarize(String text) async {
    return _generate('Summarize this note concisely: $text');
  }

  Future<String> improve(String text) async {
    return _generate('Fix grammar and make this professional: $text');
  }

  Future<String> generateNoteContent(String prompt) async {
    // Enhanced prompt for smart block detection
    final enhancedPrompt =
        '''
You are a note-taking assistant. Generate a structured markdown note for: "$prompt"

RULES:
1. Start with a Title on the first line using # (e.g., "# Grocery List")
2. For actionable lists (grocery list, shopping list, to-do list, checklist, tasks, things to buy, things to do, packing list, bucket list):
   - Use "- [ ] item" format for EACH item (this creates checkboxes)
   - Example: "- [ ] Buy milk"
3. For informational content (notes, letters, summaries, explanations, descriptions):
   - Use normal paragraphs or "- item" for bullet points (no brackets)
4. Be concise and well-organized

Generate the note now:
''';
    return _generate(enhancedPrompt);
  }

  Future<String> _generate(String prompt) async {
    try {
      final encodedPrompt = Uri.encodeComponent(prompt);
      final response = await http.get(Uri.parse('$_baseUrl/$encodedPrompt'));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to generate text');
      }
    } catch (e) {
      throw Exception('AI Error: $e');
    }
  }

  String generateImageUrl(String prompt) {
    final encoded = Uri.encodeComponent(prompt);
    final seed = DateTime.now().millisecondsSinceEpoch;
    // Using 'flux' model and removing 'nologo' to ensure free tier compatibility
    return 'https://image.pollinations.ai/prompt/$encoded?model=flux&seed=$seed';
  }
}
