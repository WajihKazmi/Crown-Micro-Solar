abstract class BaseModel {
  Map<String, dynamic> toJson();
  
  @override
  String toString() {
    return toJson().toString();
  }
}

abstract class BaseEntity {
  const BaseEntity();
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseEntity;
  }

  @override
  int get hashCode => 0;
} 