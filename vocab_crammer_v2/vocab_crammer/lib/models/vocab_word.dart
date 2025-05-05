class VocabWord {
  final String word;
  final String translation;
  final String language;
  final bool isLearned;
  final DateTime? lastReviewed;
  final DateTime? nextReview;
  final int reviewCount;

  VocabWord({
    required this.word,
    required this.translation,
    required this.language,
    this.isLearned = false,
    this.lastReviewed,
    this.nextReview,
    this.reviewCount = 0,
  });

  factory VocabWord.fromJson(Map<String, dynamic> json) {
    return VocabWord(
      word: json['word'],
      translation: json['translation'],
      language: json['language'],
      isLearned: json['is_learned'] ?? false,
      lastReviewed: json['last_reviewed'] != null 
          ? DateTime.parse(json['last_reviewed'])
          : null,
      nextReview: json['next_review'] != null 
          ? DateTime.parse(json['next_review'])
          : null,
      reviewCount: json['review_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
      'language': language,
      'is_learned': isLearned,
      'last_reviewed': lastReviewed?.toIso8601String(),
      'next_review': nextReview?.toIso8601String(),
      'review_count': reviewCount,
    };
  }

  VocabWord copyWith({
    String? word,
    String? translation,
    String? language,
    bool? isLearned,
    DateTime? lastReviewed,
    DateTime? nextReview,
    int? reviewCount,
  }) {
    return VocabWord(
      word: word ?? this.word,
      translation: translation ?? this.translation,
      language: language ?? this.language,
      isLearned: isLearned ?? this.isLearned,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
} 