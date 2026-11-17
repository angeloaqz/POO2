import 'dart:convert';
import 'package:http/http.dart' as http;

class ResultadoCambio {
  final Map<String, double> cotacoes;
  final bool online;
  final String statusMensagem;

  ResultadoCambio({
    required this.cotacoes,
    required this.online,
    required this.statusMensagem,
  });
}

class CambioApiService {
  // API pública gratuita e sem necessidade de chave (retorna Dólar e Euro em relação ao Real)
  static const String _endpoint =
      'https://economia.awesomeapi.com.br/json/last/USD-BRL,EUR-BRL';

  Future<ResultadoCambio> buscarCotacoesAtuais() async {
    try {
      final response = await http
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> dadosJson = jsonDecode(response.body);

        final double usd = double.parse(dadosJson['USDBRL']['bid'].toString());
        final double eur = double.parse(dadosJson['EURBRL']['bid'].toString());

        return ResultadoCambio(
          cotacoes: {
            'BRL': 1.0,
            'USD': usd,
            'EUR': eur,
          },
          online: true,
          statusMensagem: 'Cotações ao vivo (AwesomeAPI)',
        );
      } else {
        throw Exception('Falha HTTP: ${response.statusCode}');
      }
    } catch (e) {
      // Contingência: garante que o app continue funcionando mesmo se a internet falhar
      return ResultadoCambio(
        cotacoes: {
          'BRL': 1.0,
          'USD': 5.75,
          'EUR': 6.20,
        },
        online: false,
        statusMensagem: 'Modo offline: usando cotação de contingência',
      );
    }
  }
}