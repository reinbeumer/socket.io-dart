// transport_error_models.dart
//
// Strongly-typed transport error model used by Transports.onError.

class TransportError {
  final String? msg;
  final String? desc;
  final String type;

  const TransportError({this.msg, this.desc, this.type = 'TransportError'});

  Map<String, dynamic> toMap() => <String, dynamic>{
        'msg': msg,
        'desc': desc,
        'type': type,
      }..removeWhere((final String key, final Object? value) => value == null);

  @override
  String toString() => 'TransportError(type: $type, msg: ${msg ?? ''}, desc: ${desc ?? ''})';
}
