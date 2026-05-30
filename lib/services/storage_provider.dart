import 'storage_service.dart';
import 'impl/storage_stub.dart'
    if (dart.library.io) 'impl/storage_mobile.dart'
    if (dart.library.js) 'impl/storage_firebase.dart';

StorageService createStorage() => createPlatformStorage();
