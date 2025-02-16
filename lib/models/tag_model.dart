class Tag {
  final String name;
  final String type;

  const Tag({
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
    };
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'],
      type: json['type'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag && other.name == name && other.type == type;
  }

  @override
  int get hashCode => Object.hash(name, type);
}

class TagType {
  final String id;
  final String name;
  final String description;
  final bool required; // 是否必须选择
  final bool multiSelect; // 是否可以选择多个

  const TagType({
    required this.id,
    required this.name,
    this.description = '',
    this.required = false,
    this.multiSelect = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'required': required,
      'multiSelect': multiSelect,
    };
  }

  factory TagType.fromJson(Map<String, dynamic> json) {
    return TagType(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      required: json['required'] ?? false,
      multiSelect: json['multiSelect'] ?? false,
    );
  }
}
