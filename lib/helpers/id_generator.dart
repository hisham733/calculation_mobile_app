String generateId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36) +
    (DateTime.now().millisecondsSinceEpoch % 1000).toString().padLeft(3, '0');
