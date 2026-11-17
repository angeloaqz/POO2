import 'package:flutter/material.dart';
import '../models/transacao.dart';

class FormTransacaoScreen extends StatefulWidget {
  final Transacao? transacaoEdicao;
  final Map<String, double> cotacoesAtuais;
  final bool orcamentoEstourado;

  const FormTransacaoScreen({
    super.key,
    this.transacaoEdicao,
    required this.cotacoesAtuais,
    required this.orcamentoEstourado,
  });

  @override
  State<FormTransacaoScreen> createState() => _FormTransacaoScreenState();
}

class _FormTransacaoScreenState extends State<FormTransacaoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _valorController = TextEditingController();

  String _tipoSelecionado = 'NACIONAL';
  String _moedaSelecionada = 'USD';
  String _categoriaSelecionada = 'Alimentação';

  final List<String> _categorias = [
    'Alimentação',
    'Transporte',
    'Software / Assinaturas',
    'Viagem',
    'Equipamentos',
    'Outros',
  ];

  @override
  void initState() {
    super.initState();
    // Se recebeu uma transação, preenche o formulário para edição
    if (widget.transacaoEdicao != null) {
      final t = widget.transacaoEdicao!;
      _tituloController.text = t.titulo;
      _valorController.text = t.valorOriginal.toStringAsFixed(2);
      _tipoSelecionado = t.tipo;
      _categoriaSelecionada = _categorias.contains(t.categoria)
          ? t.categoria
          : _categorias.first;
      if (t is TransacaoInternacional) {
        _moedaSelecionada = t.moeda;
      }
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  double _calcularSimulacaoPreview() {
    final valorDigitado =
        double.tryParse(_valorController.text.replaceAll(',', '.')) ?? 0.0;
    if (valorDigitado <= 0) return 0.0;

    if (_tipoSelecionado == 'NACIONAL') {
      final temp = TransacaoNacional(
        titulo: 'Preview',
        categoria: _categoriaSelecionada,
        valorOriginal: valorDigitado,
        data: DateTime.now(),
      );
      return temp.calcularValorFinalBrl(widget.cotacoesAtuais);
    } else {
      final temp = TransacaoInternacional(
        titulo: 'Preview',
        categoria: _categoriaSelecionada,
        valorOriginal: valorDigitado,
        moedaEstrangeira: _moedaSelecionada,
        data: DateTime.now(),
      );
      return temp.calcularValorFinalBrl(widget.cotacoesAtuais);
    }
  }

  void _salvarFormulario() {
    if (!_formKey.currentState!.validate()) return;

    final bool isNova = widget.transacaoEdicao == null;

    // REGRA DE NEGÓCIO: Bloqueia novas despesas internacionais se o orçamento já estourou
    if (isNova &&
        _tipoSelecionado == 'INTERNACIONAL' &&
        widget.orcamentoEstourado) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.block, color: Colors.red),
              SizedBox(width: 8),
              Text('Bloqueio Orçamentário'),
            ],
          ),
          content: const Text(
            'Regra de Negócio: Seu orçamento mensal de R\$ 3.000,00 já foi excedido. '
            'Novas despesas internacionais com incidência de IOF estão bloqueadas até a regularização do saldo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      return;
    }

    final titulo = _tituloController.text.trim();
    final valor = double.parse(_valorController.text.replaceAll(',', '.'));
    final data = widget.transacaoEdicao?.data ?? DateTime.now();

    // Instancia a subclasse adequada (Polimorfismo)
    final Transacao transacaoFinal;
    if (_tipoSelecionado == 'NACIONAL') {
      transacaoFinal = TransacaoNacional(
        id: widget.transacaoEdicao?.id,
        titulo: titulo,
        categoria: _categoriaSelecionada,
        valorOriginal: valor,
        data: data,
      );
    } else {
      transacaoFinal = TransacaoInternacional(
        id: widget.transacaoEdicao?.id,
        titulo: titulo,
        categoria: _categoriaSelecionada,
        valorOriginal: valor,
        moedaEstrangeira: _moedaSelecionada,
        data: data,
      );
    }

    Navigator.pop(context, transacaoFinal);
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.transacaoEdicao != null;
    final valorSimulado = _calcularSimulacaoPreview();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Despesa' : 'Nova Despesa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Seletor de Tipo (Herança: Nacional vs Internacional)
              const Text(
                'Tipo de Operação',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'NACIONAL',
                    label: Text('Nacional (BRL)'),
                    icon: Icon(Icons.flag),
                  ),
                  ButtonSegment(
                    value: 'INTERNACIONAL',
                    label: Text('Internacional'),
                    icon: Icon(Icons.public),
                  ),
                ],
                selected: {_tipoSelecionado},
                onSelectionChanged: (novaSelecao) {
                  setState(() {
                    _tipoSelecionado = novaSelecao.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Campo Título
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Descrição da Despesa',
                  hintText: 'Ex: Servidor Cloud AWS ou Supermercado',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return 'Informe uma descrição com pelo menos 3 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Seletor de Categoria
              DropdownButtonFormField<String>(
                value: _categoriaSelecionada,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categorias
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _categoriaSelecionada = val);
                },
              ),
              const SizedBox(height: 16),

              // Se for Internacional, exibe seletor de Moeda Estrangeira
              if (_tipoSelecionado == 'INTERNACIONAL') ...[
                DropdownButtonFormField<String>(
                  value: _moedaSelecionada,
                  decoration: const InputDecoration(
                    labelText: 'Moeda Estrangeira',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_exchange),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'USD',
                      child: Text(
                          'Dólar Americano (USD) - Cotação: R\$ ${widget.cotacoesAtuais['USD']?.toStringAsFixed(2)}'),
                    ),
                    DropdownMenuItem(
                      value: 'EUR',
                      child: Text(
                          'Euro (EUR) - Cotação: R\$ ${widget.cotacoesAtuais['EUR']?.toStringAsFixed(2)}'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _moedaSelecionada = val);
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Campo Valor
              TextFormField(
                controller: _valorController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _tipoSelecionado == 'NACIONAL'
                      ? 'Valor em Reais (R\$)'
                      : 'Valor em $_moedaSelecionada',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o valor da despesa.';
                  }
                  final numero = double.tryParse(value.replaceAll(',', '.'));
                  if (numero == null || numero <= 0) {
                    return 'Digite um valor numérico maior que zero.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Card de Simulação Polimórfica em Tempo Real
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Simulação da Regra de Negócio:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _tipoSelecionado == 'NACIONAL'
                          ? '• Compras acima de R\$ 200,00 recebem 2% de Cashback automático.'
                          : '• Conversão via API + acréscimo obrigatório de 4,38% de IOF.',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Divider(),
                    Text(
                      'Impacto Final no Orçamento: R\$ ${valorSimulado.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              FilledButton.icon(
                onPressed: _salvarFormulario,
                icon: const Icon(Icons.save),
                label: Text(isEdicao ? 'Atualizar Registro' : 'Salvar Despesa'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}