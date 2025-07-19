// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patch_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatchModel _$PatchModelFromJson(Map<String, dynamic> json) => PatchModel(
  id: json['id'] as String,
  type: $enumDecode(_$PatchTypeEnumMap, json['type']),
  version: json['version'] as String,
  entry: json['entry'] as String,
  downloadUrl: json['downloadUrl'] as String,
  signature: json['signature'] as String,
  channel: json['channel'] as String?,
  region: json['region'] as String?,
  expireAt: json['expireAt'] == null
      ? null
      : DateTime.parse(json['expireAt'] as String),
  extra: json['extra'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PatchModelToJson(PatchModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$PatchTypeEnumMap[instance.type]!,
      'version': instance.version,
      'channel': instance.channel,
      'region': instance.region,
      'entry': instance.entry,
      'downloadUrl': instance.downloadUrl,
      'signature': instance.signature,
      'expireAt': instance.expireAt?.toIso8601String(),
      'extra': instance.extra,
    };

const _$PatchTypeEnumMap = {
  PatchType.dartAot: 'dartAot',
  PatchType.jsScript: 'jsScript',
};

PatchStatus _$PatchStatusFromJson(Map<String, dynamic> json) => PatchStatus(
  patchId: json['patchId'] as String,
  type: $enumDecode(_$PatchTypeEnumMap, json['type']),
  applied: json['applied'] as bool,
  appliedAt: json['appliedAt'] == null
      ? null
      : DateTime.parse(json['appliedAt'] as String),
  error: json['error'] as String?,
  extra: json['extra'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$PatchStatusToJson(PatchStatus instance) =>
    <String, dynamic>{
      'patchId': instance.patchId,
      'type': _$PatchTypeEnumMap[instance.type]!,
      'applied': instance.applied,
      'appliedAt': instance.appliedAt?.toIso8601String(),
      'error': instance.error,
      'extra': instance.extra,
    };
