import 'package:json_annotation/json_annotation.dart';
part 'patch_status.g.dart';

@JsonEnum()
enum PatchType {
  dartAot,
  jsScript,
}

@JsonSerializable()
class PatchModel {
  
  final String id;
  final PatchType type;
  final String version;
  final String? channel;
  final String? region;
  final String entry;
  final String downloadUrl;
  final String signature;
  final DateTime? expireAt;
  final Map<String, dynamic>? extra;


  PatchModel({
    required this.id,
    required this.type,
    required this.version,
    required this.entry,
    required this.downloadUrl,
    required this.signature,
    this.channel,
    this.region,
    this.expireAt,
    this.extra,
  });

  factory PatchModel.fromJson(Map<String, dynamic> json) => _$PatchModelFromJson(json);
  Map<String, dynamic> toJson() => _$PatchModelToJson(this);

}

@JsonSerializable()
class PatchStatus {

  final String patchId;
  final PatchType type;
  final bool applied;
  final DateTime? appliedAt;
  final String? error;
  final Map<String, dynamic>? extra;

  PatchStatus({
    required this.patchId,
    required this.type,
    required this.applied,
    this.appliedAt,
    this.error,
    this.extra,
  });

  factory PatchStatus.fromJson(Map<String, dynamic> json) => _$PatchStatusFromJson(json);
  Map<String, dynamic> toJson() => _$PatchStatusToJson(this);


} 