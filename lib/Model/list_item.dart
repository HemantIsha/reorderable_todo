class TodoItem {
  final String id;
  final String text;
  bool isChecked;
  bool isSelected;

  TodoItem(
      {required this.id,
      required this.text,
      this.isChecked = false,
      this.isSelected = false});

  factory TodoItem.fromFirestore(Map<String, dynamic> data) {
    return TodoItem(
      id: data['id'],
      text: data['text'],
      isChecked: data['isChecked'] ?? false,
      isSelected: data['isSelected'] ?? false,
    );
  }
}
