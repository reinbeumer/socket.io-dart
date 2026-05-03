import 'package:test/test.dart';
import 'package:socket_io/src/models/callbacks_models.dart';
import 'package:socket_io/src/value_objects/connection_id_vo.dart';

void main() {
  group('Callbacks', () {
    test('AckCallback accepts list of arguments', () {
      final List<Object?> receivedArgs = <Object?>[];
      final AckCallback callback = (final List<Object?> args) {
        receivedArgs.addAll(args);
      };

      callback(<Object?>['arg1', 42, true]);
      expect(receivedArgs, equals(<Object?>['arg1', 42, true]));
    });

    test('ErrorCallback accepts error object', () {
      Object? receivedError;
      final ErrorCallback callback = (final Object error) {
        receivedError = error;
      };

      final Exception testError = Exception('test error');
      callback(testError);
      expect(receivedError, equals(testError));
    });

    test('MiddlewareCallback accepts socket and next function', () {
      Object? receivedSocket;
      MiddlewareNext? receivedNext;

      final MiddlewareCallback callback = (final Object socket, final MiddlewareNext next) {
        receivedSocket = socket;
        receivedNext = next;
      };

      final Object testSocket = Object();
      void testNext(final Object? error) {}

      callback(testSocket, testNext);
      expect(receivedSocket, equals(testSocket));
      expect(receivedNext, isNotNull);
    });

    test('MiddlewareNext accepts optional error', () {
      Object? receivedError;
      final MiddlewareNext next = (final Object? error) {
        receivedError = error;
      };

      next(null);
      expect(receivedError, isNull);

      final Exception testError = Exception('error');
      next(testError);
      expect(receivedError, equals(testError));
    });

    test('ClientsCallback accepts list of ConnectionId', () {
      List<ConnectionId>? receivedClients;
      final ClientsCallback callback = (final List<ConnectionId> clients) {
        receivedClients = clients;
      };

      final List<ConnectionId> testClients = <ConnectionId>[
        ConnectionId('id1'),
        ConnectionId('id2'),
      ];

      callback(testClients);
      expect(receivedClients, equals(testClients));
    });

    test('ClientsStringCallback accepts list of strings', () {
      List<String>? receivedClients;
      final ClientsStringCallback callback = (final List<String> clients) {
        receivedClients = clients;
      };

      callback(<String>['id1', 'id2']);
      expect(receivedClients, equals(<String>['id1', 'id2']));
    });

    test('VoidCallback has no parameters', () {
      bool called = false;
      final VoidCallback callback = () {
        called = true;
      };

      callback();
      expect(called, isTrue);
    });

    test('DataCallback accepts nullable data', () {
      Object? receivedData;
      final DataCallback callback = (final Object? data) {
        receivedData = data;
      };

      callback('test');
      expect(receivedData, equals('test'));

      callback(null);
      expect(receivedData, isNull);
    });

    test('EmitCallback accepts error and response', () {
      Object? receivedError;
      List<Object?>? receivedResponse;

      final EmitCallback callback = (final Object? error, final List<Object?>? response) {
        receivedError = error;
        receivedResponse = response;
      };

      callback(null, <Object?>['data']);
      expect(receivedError, isNull);
      expect(receivedResponse, equals(<Object?>['data']));

      final Exception testError = Exception('error');
      callback(testError, null);
      expect(receivedError, equals(testError));
      expect(receivedResponse, isNull);
    });
  });
}
