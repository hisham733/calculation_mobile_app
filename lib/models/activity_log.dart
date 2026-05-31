class ActivityLog {
  final DateTime timestamp;
  final String action;
  final String description;
  final String? details;

  ActivityLog({
    required this.timestamp,
    required this.action,
    required this.description,
    this.details,
  });

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.millisecondsSinceEpoch,
        'action': action,
        'description': description,
        'details': details,
      };

  factory ActivityLog.fromMap(Map<String, dynamic> map) => ActivityLog(
        timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
        action: map['action'] as String,
        description: map['description'] as String,
        details: map['details'] as String?,
      );

  static String formatAction(String action) {
    switch (action) {
      case 'add_expense':
        return 'Added expense';
      case 'edit_expense':
        return 'Edited expense';
      case 'delete_expense':
        return 'Deleted expense';
      case 'add_user':
        return 'Added user';
      case 'rename_user':
        return 'Renamed user';
      case 'delete_user':
        return 'Deleted user';
      case 'add_category':
        return 'Added category';
      case 'edit_category':
        return 'Edited category';
      case 'delete_category':
        return 'Deleted category';
      case 'settle':
        return 'Settled up';
      case 'reset_all':
        return 'Reset all data';
      case 'export_csv':
        return 'Exported CSV';
      default:
        return action;
    }
  }
}
