import 'dart:convert';
import 'dart:io';

import 'package:ai_smart_calendar/services/hive_service.dart';
import 'package:path_provider/path_provider.dart';

class AiCache {
  static const String cacheFileName = 'ai_cache.json';

  static Future<Directory> getCacheDir() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory cacheDir = Directory('${appDocDir.path}/ai_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  static Future<Map<String, dynamic>> readCache() async {
    final Directory cacheDir = await getCacheDir();
    final File file = File('${cacheDir.path}/$cacheFileName');

    if (await file.exists()) {
      try {
        final String content = await file.readAsString();
        return json.decode(content) as Map<String, dynamic>;
      } catch (e) {
        await file.delete();
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }

  static Future<void> setAiCache(
      int hash, String data, String identifier,) async {
    final Directory cacheDir = await getCacheDir();
    final File file = File('${cacheDir.path}/$cacheFileName');
    final Map<String, dynamic> cache = await readCache();

    cache[hash.toString()] = <String, Object>{
      'data': data,
      'identifier': identifier,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    await file.writeAsString(json.encode(cache));
    await cleanCache();
  }

  static Future<String?> getAiCache(int hash) async {
    final Map<String, dynamic> cache = await readCache();
    final entry = cache[hash.toString()];
    if (entry != null) {
      final String data = entry['data'] as String;
      final String identifier = entry['identifier'] as String;
      return '$data\n\n> 由 $identifier 缓存';
    }
    return null;
  }

  static Future<void> cleanCache() async {
    final int maxCount = HiveService.maxAiCacheCount;
    final Map<String, dynamic> cache = await readCache();
    if (cache.length > maxCount) {
      final List<String> keys = cache.keys.toList();
      keys.sort((String a, String b) =>
          (cache[a]!['timestamp'] as int) - (cache[b]!['timestamp'] as int),);
      final List<String> keysToRemove = keys.sublist(0, cache.length - maxCount);
      cache.removeWhere((String key, _) => keysToRemove.contains(key));

      final Directory cacheDir = await getCacheDir();
      final File file = File('${cacheDir.path}/$cacheFileName');
      await file.writeAsString(json.encode(cache));
    }
  }

  static Future<int> get cacheCount async {
    final Map<String, dynamic> cache = await readCache();
    return cache.length;
  }

  static Future<void> clearCache() async {
    final Directory cacheDir = await getCacheDir();
    final File file = File('${cacheDir.path}/$cacheFileName');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
