import 'dart:io';
import 'package:crypto/crypto.dart';
import '../status/patch_status.dart';
import '../manager/patch_cache_manager.dart';
import 'patch_meta_fetcher.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// 补丁更新器，负责补丁包的下载、签名校验和本地缓存
class PatchUpdater {
  /// 网络客户端
  final PatchNetworkClient networkClient;
  /// 缓存管理器
  final PatchCacheManager cacheManager;

  /// 构造函数，需传入网络客户端和缓存管理器
  PatchUpdater({required this.networkClient, required this.cacheManager});

  /// 下载并校验补丁包，成功返回本地缓存路径
  /// [patch] 补丁元数据
  /// [headers] 可选的请求头
  Future<String> downloadAndCachePatch(PatchModel patch, {Map<String, String>? headers}) async {
    final String savePath = cacheManager.getPatchFilePath(patch);
    await networkClient.download(patch.downloadUrl, savePath, headers: headers);
    final bool valid = await verifyPatchSignature(patch, savePath);
    if (!valid) {
      // 校验失败，删除无效文件
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }
      throw Exception('补丁包签名校验失败: ${patch.id}');
    }
    return savePath;
  }

  /// 下载、AES-256-CBC 解密并校验补丁包，成功返回本地明文缓存路径
  /// [patch] 补丁元数据
  /// [aesKey] 32字节密钥（utf8）
  /// [iv] 16字节初始向量（utf8）
  /// [headers] 可选请求头
  Future<String> downloadDecryptAndCachePatch(
    PatchModel patch, {
    required String aesKey,
    required String iv,
    Map<String, String>? headers,
  }) async {

    final String encryptedPath = cacheManager.getPatchFilePath(patch) + '.enc';
    final String decryptedPath = cacheManager.getPatchFilePath(patch);

    // 下载加密补丁包
    await networkClient.download(patch.downloadUrl, encryptedPath, headers: headers);

    // AES-256-CBC 解密
    final encryptedBytes = await File(encryptedPath).readAsBytes();
    final key = encrypt.Key.fromUtf8(aesKey);
    final ivObj = encrypt.IV.fromUtf8(iv);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: ivObj);
    await File(decryptedPath).writeAsBytes(decrypted);

    // 校验签名
    final bool valid = await verifyPatchSignature(patch, decryptedPath);
    if (!valid) {
      await File(decryptedPath).delete();
      throw Exception('补丁包签名校验失败:  [31m${patch.id} [0m');
    }

    await File(encryptedPath).delete();
    return decryptedPath;
  }

  /// 校验补丁包签名（默认使用 SHA256）
  /// [patch] 补丁元数据，需包含 signature 字段
  /// [filePath] 本地补丁包路径
  Future<bool> verifyPatchSignature(PatchModel patch, String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes).toString();
    return digest == patch.signature;
  }

  /// 清理本地补丁缓存
  /// [patch] 补丁元数据
  Future<void> clearPatchCache(PatchModel patch) async {
    await cacheManager.clearPatch(patch.id, patch.type);
  }
} 