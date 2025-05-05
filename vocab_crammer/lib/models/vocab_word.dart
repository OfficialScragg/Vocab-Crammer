class VocabWord {
  final String word;
  final String translation;
  final String language;
  bool isLearned;
  DateTime? lastReviewed;

  VocabWord({
    required this.word,
    required this.translation,
    required this.language,
    this.isLearned = false,
    this.lastReviewed,
  });

  factory VocabWord.fromJson(Map<String, dynamic> json) {
    return VocabWord(
      word: json['word'],
      translation: json['translation'],
      language: json['language'],
      isLearned: json['isLearned'] ?? false,
      lastReviewed: json['lastReviewed'] != null 
          ? DateTime.parse(json['lastReviewed']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
      'language': language,
      'isLearned': isLearned,
      'lastReviewed': lastReviewed?.toIso8601String(),
    };
  }
} 