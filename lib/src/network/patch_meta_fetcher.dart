import 'dart:convert';
import 'dart:io';
import '../status/patch_status.dart';

/// 补丁元数据网络客户端接口，支持自定义实现
abstract class PatchNetworkClient {
  /// GET 请求
  Future<String> get(String url, {Map<String, String>? headers});
  /// 下载文件
  Future<void> download(String url, String savePath, {Map<String, String>? headers});
}

/// 默认实现，基于 HttpClient
class DefaultPatchNetworkClient implements PatchNetworkClient {
  @override
  Future<String> get(String url, {Map<String, String>? headers}) async {
    final Uri uri = Uri.parse(url);
    final HttpClient client = HttpClient();
    final HttpClientRequest request = await client.getUrl(uri);
    headers?.forEach((String k, String v) => request.headers.set(k, v));
    final HttpClientResponse response = await request.close();
    final String body = await response.transform(utf8.decoder).join();
    return body;
  }

  @override
  Future<void> download(String url, String savePath, {Map<String, String>? headers}) async {
    final Uri uri = Uri.parse(url);
    final HttpClient client = HttpClient();
    final HttpClientRequest request = await client.getUrl(uri);
    headers?.forEach((String k, String v) => request.headers.set(k, v));
    final HttpClientResponse response = await request.close();
    final File file = File(savePath);
    final IOSink sink = file.openWrite();
    await response.pipe(sink);
    await sink.close();
  }
}

/// 补丁元数据拉取器，负责从服务端获取补丁列表
class PatchMetaFetcher {
  /// 服务端地址
  final String serverUrl;
  /// 网络客户端
  final PatchNetworkClient networkClient;
  /// 构造函数
  PatchMetaFetcher(this.serverUrl, this.networkClient);

  /// 拉取补丁元数据列表
  Future<List<PatchModel>> fetchMeta() async {
    final String body = await networkClient.get(serverUrl);
    final List<dynamic> jsonList = json.decode(body);
    return jsonList.map((e) => PatchModel.fromJson(e)).toList();
  }
} 