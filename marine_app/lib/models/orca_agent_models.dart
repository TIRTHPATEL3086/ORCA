class OrcaChatMessageData {
  final String role;
  final String content;
  final DateTime createdAt;

  const OrcaChatMessageData({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'created_at': createdAt.toIso8601String(),
  };

  factory OrcaChatMessageData.fromJson(Map<String, dynamic> json) {
    return OrcaChatMessageData(
      role: json['role'] as String,
      content: json['content'] as String,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class OrcaAgentEvidenceData {
  final String tool;
  final String label;
  final String value;
  final String source;
  final String? freshness;
  final Map<String, dynamic> details;

  const OrcaAgentEvidenceData({
    required this.tool,
    required this.label,
    required this.value,
    required this.source,
    required this.freshness,
    required this.details,
  });

  factory OrcaAgentEvidenceData.fromJson(Map<String, dynamic> json) {
    return OrcaAgentEvidenceData(
      tool: json['tool'] as String,
      label: json['label'] as String,
      value: json['value'] as String,
      source: json['source'] as String,
      freshness: json['freshness'] as String?,
      details: Map<String, dynamic>.from(json['details'] as Map? ?? const {}),
    );
  }
}

class OrcaAgentActionData {
  final String id;
  final String label;

  const OrcaAgentActionData({required this.id, required this.label});

  factory OrcaAgentActionData.fromJson(Map<String, dynamic> json) {
    return OrcaAgentActionData(
      id: json['id'] as String,
      label: json['label'] as String,
    );
  }
}

class OrcaAgentResponseData {
  final String intent;
  final String detectedLanguage;
  final String responseLanguage;

  final String decision;
  final String safetyState;

  final String shortAnswer;
  final String laymanExplanation;
  final String recommendation;

  final List<String> plannedTools;
  final List<String> executedTools;

  final List<OrcaAgentEvidenceData> evidence;
  final List<OrcaAgentActionData> actions;

  final bool contextUsed;
  final String orchestrationNote;

  const OrcaAgentResponseData({
    required this.intent,
    required this.detectedLanguage,
    required this.responseLanguage,
    required this.decision,
    required this.safetyState,
    required this.shortAnswer,
    required this.laymanExplanation,
    required this.recommendation,
    required this.plannedTools,
    required this.executedTools,
    required this.evidence,
    required this.actions,
    required this.contextUsed,
    required this.orchestrationNote,
  });

  factory OrcaAgentResponseData.fromJson(Map<String, dynamic> json) {
    final rawEvidence = json['evidence'] as List<dynamic>? ?? const [];

    final rawActions = json['actions'] as List<dynamic>? ?? const [];

    return OrcaAgentResponseData(
      intent: json['intent'] as String,
      detectedLanguage: json['detected_language'] as String,
      responseLanguage: json['response_language'] as String,
      decision: json['decision'] as String,
      safetyState: json['safety_state'] as String,
      shortAnswer: json['short_answer'] as String,
      laymanExplanation: json['layman_explanation'] as String,
      recommendation: json['recommendation'] as String,
      plannedTools: (json['planned_tools'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      executedTools: (json['executed_tools'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      evidence: rawEvidence
          .whereType<Map<String, dynamic>>()
          .map(OrcaAgentEvidenceData.fromJson)
          .toList(),
      actions: rawActions
          .whereType<Map<String, dynamic>>()
          .map(OrcaAgentActionData.fromJson)
          .toList(),
      contextUsed: json['context_used'] as bool? ?? false,
      orchestrationNote: json['orchestration_note'] as String,
    );
  }

  String get spokenText => '$shortAnswer. $laymanExplanation. $recommendation';
}
