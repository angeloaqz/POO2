import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/transacao.dart';
import '../repositories/transacao_repository.dart';
import '../services/cambio_api_service.dart';
import 'form_transacao_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Injeção das dependências (Repositório SQLite e Serviço de API)
  final ITransacaoRepository _repository = SqliteTransacaoRepository();
  final CambioApiService _apiService = CambioApiService();

  static const double _limiteOrcamentoMensal = 3000.00;

  List<Transacao> _todasTransacoes = [];
  Map<String, double> _cotacoes = {'BRL': 1.0, 'USD': 5.75, 'EUR': 6.20};
  bool _apiOnline = false;
  String _statusApi = 'Carregando cotações...';
  bool _carregando = true;
  String _filtroAtual = 'TODAS'; // 'TODAS', 'NACIONAL', 'INTERNACIONAL'

  @override
  void initState() {
    super.initState();
    _carregarDadosIntegrados();
  }

  /// Integra API Externa + Banco de Dados SQLite
  Future<void> _carregarDadosIntegrados() async {
    setState(() => _carregando = true);

    final resultadoApi = await _apiService.buscarCotacoesAtuais();
    final listaBanco = await _repository.listarTodas();

    setState(() {
      _cotacoes = resultadoApi.cotacoes;
      _apiOnline = resultadoApi.online;
      _statusApi = resultadoApi.statusMensagem;
      _todasTransacoes = listaBanco;
      _carregando = false;
    });
  }

  /// POLIMORFISMO NA PRÁTICA:
  /// Soma todas as transações chamando calcularValorFinalBrl(),
  /// sem precisar saber se cada item é Nacional ou Internacional.
  double get _totalGastoConsolidadoBrl {
    double soma = 0.0;
    for (final transacao in _todasTransacoes) {
      soma += transacao.calcularValorFinalBrl(_cotacoes);
    }
    return soma;
  }

  List<Transacao> get _transacoesFiltradas {
    if (_filtroAtual == 'TODAS') return _todasTransacoes;
    return _todasTransacoes.where((t) => t.tipo == _filtroAtual).toList();
  }

  Future<void> _abrirFormulario({Transacao? transacao}) async {
    final bool orcamentoEstourado =
        _totalGastoConsolidadoBrl >= _limiteOrcamentoMensal;

    final Transacao? resultado = await Navigator.push<Transacao>(
      context,
      MaterialPageRoute(
        builder: (_) => FormTransacaoScreen(
          transacaoEdicao: transacao,
          cotacoesAtuais: _cotacoes,
          orcamentoEstourado: orcamentoEstourado,
        ),
      ),
    );

    if (resultado != null) {
      if (transacao == null) {
        await _repository.inserir(resultado);
        _mostrarSnackBar('Despesa cadastrada no SQLite!');
      } else {
        await _repository.atualizar(resultado);
        _mostrarSnackBar('Despesa atualizada com sucesso!');
      }
      await _carregarDadosIntegrados();
    }
  }

  Future<void> _confirmarExclusao(Transacao transacao) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Registro'),
        content: Text('Deseja remover "${transacao.titulo}" do banco de dados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true && transacao.id != null) {
      await _repository.excluir(transacao.id!);
      _mostrarSnackBar('Registro excluído do SQLite.');
      await _carregarDadosIntegrados();
    }
  }

  void _mostrarSnackBar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), duration: const Duration(seconds: 2)),
    );
  }

  /// Modal útil para demonstrar a estrutura do SQLite e instâncias de POO na apresentação
  void _exibirEstruturaTecnica() {
    final qtdNacionais =
        _todasTransacoes.whereType<TransacaoNacional>().length;
    final qtdInternacionais =
        _todasTransacoes.whereType<TransacaoInternacional>().length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arquitetura & Banco de Dados'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Instâncias Polimórficas em Memória:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• TransacaoNacional: $qtdNacionais objeto(s)'),
              Text('• TransacaoInternacional: $qtdInternacionais objeto(s)'),
              const SizedBox(height: 12),
              const Text(
                'Estrutura da Tabela SQLite:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade200,
                child: const Text(
                  DatabaseHelper.scriptCriacaoTabela,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalGastoConsolidadoBrl;
    final percentualUso = (total / _limiteOrcamentoMensal).clamp(0.0, 1.0);

    Color corStatusOrcamento = Colors.green;
    String textoAlertaOrcamento = 'Orçamento saudável';
    if (total >= _limiteOrcamentoMensal) {
      corStatusOrcamento = Colors.red;
      textoAlertaOrcamento = 'Limite excedido! Novas compras internacionais bloqueadas.';
    } else if (total >= _limiteOrcamentoMensal * 0.75) {
      corStatusOrcamento = Colors.orange;
      textoAlertaOrcamento = 'Atenção: mais de 75% do orçamento utilizado.';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartFinance Global'),
        actions: [
          IconButton(
            tooltip: 'Estrutura SQLite & POO',
            icon: const Icon(Icons.storage),
            onPressed: _exibirEstruturaTecnica,
          ),
          IconButton(
            tooltip: 'Atualizar API e Banco',
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDadosIntegrados,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. Card de Cotação da API Externa
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _apiOnline
                        ? Colors.teal.shade50
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _apiOnline ? Colors.teal : Colors.amber,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _statusApi,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _apiOnline
                                  ? Colors.teal.shade800
                                  : Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'USD: R\$ ${_cotacoes['USD']!.toStringAsFixed(2)}   |   EUR: R\$ ${_cotacoes['EUR']!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _apiOnline ? Icons.cloud_done : Icons.cloud_off,
                        color: _apiOnline ? Colors.teal : Colors.amber.shade900,
                      ),
                    ],
                  ),
                ),

                // 2. Card de Resumo Orçamentário (Regra de Negócio)
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Consolidado (BRL):'),
                            Text(
                              'Meta: R\$ ${_limiteOrcamentoMensal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        Text(
                          'R\$ ${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: corStatusOrcamento,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: percentualUso,
                          color: corStatusOrcamento,
                          backgroundColor: Colors.grey.shade200,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          textoAlertaOrcamento,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: corStatusOrcamento,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Filtros de Visualização
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Todas'),
                        selected: _filtroAtual == 'TODAS',
                        onSelected: (_) => setState(() => _filtroAtual = 'TODAS'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Nacionais'),
                        selected: _filtroAtual == 'NACIONAL',
                        onSelected: (_) =>
                            setState(() => _filtroAtual = 'NACIONAL'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Internacionais'),
                        selected: _filtroAtual == 'INTERNACIONAL',
                        onSelected: (_) =>
                            setState(() => _filtroAtual = 'INTERNACIONAL'),
                      ),
                    ],
                  ),
                ),

                // 4. Listagem Polimórfica do SQLite
                Expanded(
                  child: _transacoesFiltradas.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma despesa registrada.\nToque em "+ Nova Despesa" para começar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: _transacoesFiltradas.length,
                          itemBuilder: (context, index) {
                            final item = _transacoesFiltradas[index];
                            final isInternacional =
                                item is TransacaoInternacional;
                            final valorFinalBrl =
                                item.calcularValorFinalBrl(_cotacoes);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                onTap: () => _abrirFormulario(transacao: item),
                                leading: CircleAvatar(
                                  backgroundColor: isInternacional
                                      ? Colors.deepPurple.shade100
                                      : Colors.blue.shade100,
                                  child: Icon(
                                    isInternacional
                                        ? Icons.public
                                        : Icons.flag,
                                    color: isInternacional
                                        ? Colors.deepPurple
                                        : Colors.blue,
                                  ),
                                ),
                                title: Text(
                                  item.titulo,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${item.categoria} • ${item.dataFormatada}'),
                                    Text(
                                      item.getResumoRegra(_cotacoes),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isInternacional
                                            ? Colors.deepPurple
                                            : Colors.teal.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'R\$ ${valorFinalBrl.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        if (isInternacional)
                                          Text(
                                            '${item.moeda} ${item.valorOriginal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _confirmarExclusao(item),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nova Despesa'),
      ),
    );
  }
}