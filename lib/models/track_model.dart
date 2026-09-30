class TrackModel {
  final String id;
  final String title;
  final String path;
  final double bpm;
  final String keySignature;
  final bool isUserVerified;

  TrackModel({
    required this.id,
    required this.title,
    required this.path,
    required this.bpm,
    required this.keySignature,
    required this.isUserVerified,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'path': path,
      'bpm': bpm,
      'keySignature': keySignature,
      'isUserVerified': isUserVerified,
    };
  }

  factory TrackModel.fromMap(Map<dynamic, dynamic> map) {
    return TrackModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      path: map['path'] as String? ?? '',
      bpm: (map['bpm'] is num) ? (map['bpm'] as num).toDouble() : 0.0,
      keySignature: map['keySignature'] as String? ?? '',
      isUserVerified: map['isUserVerified'] as bool? ?? false,
    );
  }
}
