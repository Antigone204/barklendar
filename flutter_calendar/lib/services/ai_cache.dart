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
    final cacheDir = await getCacheDir();
    final file = File('${cacheDir.path}/$cacheFileName');

    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        return json.decode(content) as Map<String, dynamic>;
      } catch (e) {
        await file.delete();
        return {};
      }
    }
    return {};
  }

  static Future<void> setAiCache(
      int hash, String data, String identifier) async {
    final cacheDir = await getCacheDir();
    final file = File('${cacheDir.path}/$cacheFileName');
    final cache = await readCache();

    cache[hash.toString()] = {
      'data': data,
      'identifier': identifier,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    };

    await file.writeAsString(json.encode(cache));
    await cleanCache();
  }

  static Future<String?> getAiCache(int hash) async {
    final cache = await readCache();
    final entry = cache[hash.toString()];
    if (entry != null) {
      String data = entry['data'] as String;
      String identifier = entry['identifier'] as String;
      return '$data\n\n> 由 $identifier 缓存';
    }
    return null;
  }

  static Future<void> cleanCache() async {
    final maxCount = HiveService.maxAiCacheCount;
    var cache = await readCache();
    if (cache.length > maxCount) {
      final keys = cache.keys.toList();
      keys.sort((a, b) =>
          (cache[a]!['timestamp'] as int) - (cache[b]!['timestamp'] as int));
      final keysToRemove = keys.sublist(0, cache.length - maxCount);
      cache.removeWhere((key, _) => keysToRemove.contains(key));

      final cacheDir = await getCacheDir();
      final file = File('${cacheDir.path}/$cacheFileName');
      await file.writeAsString(json.encode(cache));
    }
  }

  static Future<int> get cacheCount async {
    final cache = await readCache();
    return cache.length;
  }

  static Future<void> clearCache() async {
    final cacheDir = await getCacheDir();
    final file = File('${cacheDir.path}/$cacheFileName');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
