// Conditional import: Firebase on web (dart.library.js), SQLite on mobile (dart.library.io), stub otherwise.
import 'storage_service.dart';
import 'impl/storage_stub.dart'
    if (dart.library.io) 'impl/storage_mobile.dart'
    if (dart.library.js) 'impl/storage_firebase.dart';

/// Factory that returns the correct StorageService for the current platform.
StorageService createStorage() => createPlatformStorage();
