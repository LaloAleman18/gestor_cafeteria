import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_cafeteria/core/failure.dart';
import 'package:gestor_cafeteria/core/http_client.dart';
import 'package:gestor_cafeteria/core/token_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Pruebas unitarias de ApiClient con MockClient (Tarea 1)', () {
    // 1. Éxito
    test('1. Éxito: responde 200 con JSON válido y devuelve el JSON decodificado', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'id': 1, 'customer': 'Ana', 'drink': 'latte', 'size': 'M'}
          ]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'http://localhost:8000');

      final resultado = await api.get('/orders');

      expect(resultado, isA<List>());
      expect((resultado as List).first['customer'], 'Ana');
    });

    // 2. No encontrado
    test('2. No encontrado: responde 404 con detail y lanza NotFoundFailure con ese mensaje', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Order 9 not found'}),
          404,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'http://localhost:8000');

      await expectLater(
        api.get('/orders/9'),
        throwsA(
          isA<NotFoundFailure>().having(
            (f) => f.message,
            'message',
            'Order 9 not found',
          ),
        ),
      );
    });

    // 3. Conflicto
    test('3. Conflicto: responde 409 con detail de texto y lanza ConflictFailure con ese mensaje', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Cannot change status from pending to delivered'}),
          409,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'http://localhost:8000');

      await expectLater(
        api.patch('/orders/1', {'status': 'delivered'}),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.message,
            'message',
            'Cannot change status from pending to delivered',
          ),
        ),
      );
    });

    // 4. Validación
    test('4. Validación: responde 422 con lista detail y lanza ValidationFailure con fields mapeados', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'detail': [
              {
                'loc': ['body', 'customer'],
                'msg': 'Must be 1-50 characters',
              }
            ]
          }),
          422,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'http://localhost:8000');

      await expectLater(
        api.post('/orders', {'customer': '', 'drink': 'te', 'size': 'M'}),
        throwsA(
          isA<ValidationFailure>().having(
            (f) => f.fields['customer'],
            "fields['customer']",
            'Must be 1-50 characters',
          ),
        ),
      );
    });

    // 5. Servidor
    test('5. Error del servidor: responde 503 y lanza ServerFailure con statusCode 503', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Servicio no disponible'}),
          503,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'http://localhost:8000');

      await expectLater(
        api.get('/orders'),
        throwsA(
          isA<ServerFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            503,
          ),
        ),
      );
    });

    // 6. Sin conexión o tiempo agotado
    test('6a. Sin conexión: manejador lanza ClientException y cliente lanza NetworkFailure', () async {
      final mock = MockClient((request) async {
        throw http.ClientException('sin red');
      });
      final api = ApiClient(client: mock, baseUrl: 'http://localhost:8000');

      await expectLater(
        api.get('/orders'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('6b. Tiempo agotado: petición excede timeout y cliente lanza NetworkFailure', () async {
      final mock = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return http.Response('[]', 200);
      });
      final api = ApiClient(
        client: mock,
        baseUrl: 'http://localhost:8000',
        timeout: const Duration(milliseconds: 30),
      );

      await expectLater(
        api.get('/orders'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    // 7. Defecto D3: Código 300 no es éxito
    test('7. Defecto D3: servidor falso responde 300 y se espera UnexpectedFailure', () async {
      final mock = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Multiple Choices'}),
          300,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final api = ApiClient(client: mock, baseUrl: 'http://localhost:8000');

      await expectLater(
        api.get('/orders'),
        throwsA(
          isA<UnexpectedFailure>()
              .having((f) => f.statusCode, 'statusCode', 300)
              .having((f) => f.message, 'message', 'Multiple Choices'),
        ),
      );
    });

    // Pruebas complementarias de seguridad y transporte
    test('Transporte: http:// hacia host remoto lanza ArgumentError', () {
      expect(
        () => ApiClient(baseUrl: 'http://api.remota.com'),
        throwsArgumentError,
      );
    });

    test('Token seguro: 401 borra el token y lanza UnauthorizedFailure', () async {
      final storage = InMemoryTokenStorage('vencido');
      final mock = MockClient((request) async => http.Response('', 401));
      final api = ApiClient(
        client: mock,
        baseUrl: 'http://localhost:8000',
        tokenStorage: storage,
      );

      await expectLater(
        api.get('/orders'),
        throwsA(isA<UnauthorizedFailure>()),
      );
      expect(await storage.read(), isNull);
    });
  });
}
