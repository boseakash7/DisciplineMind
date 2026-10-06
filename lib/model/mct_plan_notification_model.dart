class MctPlanSection {
  final String heading;
  final String content;

  const MctPlanSection({this.heading = '', this.content = ''});

  factory MctPlanSection.fromJson(Map<String, dynamic> json) {
    return MctPlanSection(
      heading: (json['heading'] ?? '').toString().trim(),
      content: (json['content'] ?? '').toString().trim(),
    );
  }
}

class MctPlanNotification {
  final String type;
  final String title;
  final String body;
  final List<MctPlanSection> sections;

  const MctPlanNotification({
    this.type = '',
    this.title = '',
    this.body = '',
    this.sections = const [],
  });

  factory MctPlanNotification.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'];
    final sections = <MctPlanSection>[];
    if (rawSections is List) {
      for (final rawSection in rawSections) {
        if (rawSection is Map) {
          sections.add(
            MctPlanSection.fromJson(Map<String, dynamic>.from(rawSection)),
          );
        }
      }
    }

    return MctPlanNotification(
      type: (json['type'] ?? '').toString().trim(),
      title: (json['title'] ?? '').toString().trim(),
      body: (json['body'] ?? '').toString().trim(),
      sections: sections,
    );
  }

  bool get hasContent {
    return title.isNotEmpty ||
        body.isNotEmpty ||
        sections.any(
          (section) => section.heading.isNotEmpty || section.content.isNotEmpty,
        );
  }
}
