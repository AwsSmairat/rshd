import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/core/constants/storage_keys.dart';
import 'package:rshd/core/storage/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  late Map<String, String> store;
  late SecureStorageService storage;

  setUp(() {
    store = {};

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
          switch (call.method) {
            case 'write':
              final key = call.arguments['key'] as String;
              final value = call.arguments['value'] as String?;
              if (value == null) {
                store.remove(key);
              } else {
                store[key] = value;
              }
              return null;
            case 'read':
              final key = call.arguments['key'] as String;
              return store[key];
            case 'delete':
              final key = call.arguments['key'] as String;
              store.remove(key);
              return null;
            case 'deleteAll':
              store.clear();
              return null;
            case 'containsKey':
              final key = call.arguments['key'] as String;
              return store.containsKey(key);
            default:
              return null;
          }
        });

    storage = SecureStorageService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('remember me persists email only, never password', () async {
    await storage.saveRememberMe(enabled: true, email: 'student@rshd.test');

    expect(store[StorageKeys.rememberMeEnabled], 'true');
    expect(store[StorageKeys.rememberedEmail], 'student@rshd.test');
    expect(store.containsKey(StorageKeys.rememberedPassword), isFalse);

    final rememberedEmail = await storage.getRememberedEmail();
    expect(rememberedEmail, 'student@rshd.test');
  });

  test(
    'legacy remembered password key is removed on startup cleanup',
    () async {
      store[StorageKeys.rememberedPassword] = 'legacy-secret';
      store[StorageKeys.rememberMeEnabled] = 'true';
      store[StorageKeys.rememberedEmail] = 'student@rshd.test';

      await storage.purgeLegacyRememberedPassword();

      expect(store.containsKey(StorageKeys.rememberedPassword), isFalse);
      expect(store[StorageKeys.rememberedEmail], 'student@rshd.test');
    },
  );

  test('clear remember me removes email and legacy password key', () async {
    await storage.saveRememberMe(enabled: true, email: 'student@rshd.test');
    store[StorageKeys.rememberedPassword] = 'legacy-secret';

    await storage.clearRememberMe();

    expect(store.containsKey(StorageKeys.rememberMeEnabled), isFalse);
    expect(store.containsKey(StorageKeys.rememberedEmail), isFalse);
    expect(store.containsKey(StorageKeys.rememberedPassword), isFalse);
  });

  test('remember me disabled returns null email', () async {
    await storage.saveRememberMe(enabled: false);

    expect(await storage.getRememberedEmail(), isNull);
  });
}
