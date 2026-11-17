/// CLASSE ABSTRATA (Abstração):
/// Define a estrutura base e os contratos que toda transação deve seguir.
/// Não pode ser instanciada diretamente (ex: Transacao() gera erro).
abstract class Transacao {
  int? id;
  String titulo;
  String categoria;
  DateTime data;

  // ENCAPSULAMENTO: Atributo privado (iniciado com _)
  double _valorOriginal;

  Transacao({
    this.id,
    required this.titulo,
    required this.categoria,
    required double valorOriginal,
    required this.data,
  }) : _valorOriginal = valorOriginal {
    if (valorOriginal <= 0) {
      throw ArgumentError('O valor da transação deve ser maior que zero.');
    }
  }

  // Getter e Setter com validação (Encapsulamento)
  double get valorOriginal => _valorOriginal;

  set valorOriginal(double novoValor) {
    if (novoValor <= 0) {
      throw ArgumentError('O valor da transação deve ser maior que zero.');
    }
    _valorOriginal = novoValor;
  }

  // Métodos e propriedades abstratas (serão implementados de formas diferentes nas filhas)
  String get moeda;
  String get tipo;

  /// POLIMORFISMO: Cada subclasse calcula seu valor final em Reais com sua própria regra.
  double calcularValorFinalBrl(Map<String, double> cotacoes);

  /// POLIMORFISMO: Cada subclasse explica a regra de negócio aplicada.
  String getResumoRegra(Map<String, double> cotacoes);

  String get dataFormatada {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year}';
  }

  /// Converte o Objeto em Map (JSON/SQLite) para persistência no banco
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'categoria': categoria,
      'valor_original': _valorOriginal,
      'moeda': moeda,
      'tipo': tipo,
      'data': data.toIso8601String(),
    };
  }

  /// PADRÃO FACTORY: Reconstrói a subclasse correta a partir de um registro do SQLite
  factory Transacao.fromMap(Map<String, dynamic> map) {
    final String tipoRegistro = map['tipo'] as String;
    final DateTime dataRegistro = DateTime.parse(map['data'] as String);
    final double valor = (map['valor_original'] as num).toDouble();

    if (tipoRegistro == 'INTERNACIONAL') {
      return TransacaoInternacional(
        id: map['id'] as int?,
        titulo: map['titulo'] as String,
        categoria: map['categoria'] as String,
        valorOriginal: valor,
        moedaEstrangeira: map['moeda'] as String,
        data: dataRegistro,
      );
    } else {
      return TransacaoNacional(
        id: map['id'] as int?,
        titulo: map['titulo'] as String,
        categoria: map['categoria'] as String,
        valorOriginal: valor,
        data: dataRegistro,
      );
    }
  }
}

/// HERANÇA: TransacaoNacional herda de Transacao
class TransacaoNacional extends Transacao {
  static const double percentualCashback = 0.02; // 2% de cashback
  static const double valorMinimoCashback = 200.0;

  TransacaoNacional({
    super.id,
    required super.titulo,
    required super.categoria,
    required super.valorOriginal,
    required super.data,
  });

  @override
  String get moeda => 'BRL';

  @override
  String get tipo => 'NACIONAL';

  @override
  double calcularValorFinalBrl(Map<String, double> cotacoes) {
    // Regra de negócio: compras nacionais acima de R$ 200 ganham 2% de cashback
    if (valorOriginal > valorMinimoCashback) {
      return valorOriginal * (1 - percentualCashback);
    }
    return valorOriginal;
  }

  @override
  String getResumoRegra(Map<String, double> cotacoes) {
    if (valorOriginal > valorMinimoCashback) {
      final desconto = valorOriginal * percentualCashback;
      return 'Cashback de 2% aplicado (-R\$ ${desconto.toStringAsFixed(2)})';
    }
    return 'Compra nacional sem taxas extras';
  }
}

/// HERANÇA: TransacaoInternacional herda de Transacao
class TransacaoInternacional extends Transacao {
  final String _moedaEstrangeira;
  static const double aliquotaIof = 0.0438; // 4,38% de IOF

  TransacaoInternacional({
    super.id,
    required super.titulo,
    required super.categoria,
    required super.valorOriginal,
    required String moedaEstrangeira,
    required super.data,
  }) : _moedaEstrangeira = moedaEstrangeira.toUpperCase() {
    if (_moedaEstrangeira != 'USD' && _moedaEstrangeira != 'EUR') {
      throw ArgumentError('Moeda não suportada. Utilize USD ou EUR.');
    }
  }

  @override
  String get moeda => _moedaEstrangeira;

  @override
  String get tipo => 'INTERNACIONAL';

  @override
  double calcularValorFinalBrl(Map<String, double> cotacoes) {
    // Regra de negócio: converte pela cotação da API + 4,38% de IOF
    final double taxaCambio = cotacoes[_moedaEstrangeira] ?? 1.0;
    final double valorConvertido = valorOriginal * taxaCambio;
    return valorConvertido * (1 + aliquotaIof);
  }

  @override
  String getResumoRegra(Map<String, double> cotacoes) {
    final double taxaCambio = cotacoes[_moedaEstrangeira] ?? 1.0;
    final double valorIof = (valorOriginal * taxaCambio) * aliquotaIof;
    return 'Câmbio $_moedaEstrangeira (R\$ ${taxaCambio.toStringAsFixed(2)}) + IOF 4,38% (R\$ ${valorIof.toStringAsFixed(2)})';
  }
}