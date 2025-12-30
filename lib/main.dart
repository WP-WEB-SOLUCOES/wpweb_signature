import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://gwcdrhbgapgqixnvkolf.supabase.co',
    anonKey: 'sb_publishable_ZYhXOBg2EeHO57_AgrO8-g_kbo4A46H',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WP WEB - Formalização Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0F172A),
        fontFamily: 'Roboto',
      ),
      home: const SignaturePage(),
    );
  }
}

class SignaturePage extends StatefulWidget {
  const SignaturePage({super.key});
  @override
  State<SignaturePage> createState() => _SignaturePageState();
}

class _SignaturePageState extends State<SignaturePage> {
  final SignatureController _sigController = SignatureController(
    penStrokeWidth: 3,
    penColor: const Color(0xFF0F172A),
    exportBackgroundColor: Colors.white,
  );
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _typedNameController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? _contract;
  bool _isLoading = true;
  bool _isSigned = false;
  int _authMethodIndex = 0; 
  String _ipAddress = "Identificando...";
  double _readProgress = 0.0;
  final currency = NumberFormat.currency(symbol: "R\$", locale: "pt_BR");

  @override
  void initState() {
    super.initState();
    _fetchContract();
    _fetchIP();
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        setState(() => _readProgress = (_scrollController.offset / _scrollController.position.maxScrollExtent).clamp(0.0, 1.0));
      }
    });
  }

  // Getters de Dados Dinâmicos
  String get clientName => _contract?['client_name'] ?? "CONTRATANTE";
  bool get isRevShare => _contract?['is_revenue_share'] ?? false;
  double get revSharePercent => (_contract?['revenue_share_percentage'] ?? 0.0).toDouble();

  Future<void> _fetchIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org?format=json'));
      setState(() => _ipAddress = jsonDecode(response.body)['ip']);
    } catch (_) { setState(() => _ipAddress = "PROTOCOLO_PROTEGIDO"); }
  }

  Future<void> _fetchContract() async {
    final token = Uri.base.queryParameters['token'];
    if (token == null) { setState(() => _isLoading = false); return; }
    try {
      final data = await Supabase.instance.client.from('cloud_contracts').select().or('token_client.eq.$token,token_agency.eq.$token').single();
      setState(() { 
        _contract = data; 
        _isLoading = false; 
        _isSigned = data['status'] == 'assinado';
        if (_isSigned) _typedNameController.text = data['typed_name'] ?? "";
      });
    } catch (e) { setState(() => _isLoading = false); }
  }

  // --- PDF DE ALTA FIDELIDADE JURÍDICA ---
  Future<void> _downloadSignedPDF() async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    Uint8List? agencySignatureImg;
    if (_contract!['agency_signature_url'] != null) {
      try {
        final response = await http.get(Uri.parse(_contract!['agency_signature_url']));
        agencySignatureImg = response.bodyBytes;
      } catch (e) { debugPrint("Erro ao carregar rubrica: $e"); }
    }

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(45),
      build: (context) => [
        _buildPdfHeader(),
        pw.SizedBox(height: 20),
        pw.Header(level: 0, text: "CONTRATO DE PRESTAÇÃO DE SERVIÇOS E PARCERIA TECNOLÓGICA"),
        _pdfClause("1. IDENTIFICAÇÃO DAS PARTES", "CONTRATADA: WP WEB SOLUÇÕES TECNOLÓGICAS, CNPJ 55.305.086/0001-52. CONTRATANTE: $clientName, identificado via protocolo digital de segurança e IP $_ipAddress."),
        _pdfClause("2. DO OBJETO", "Desenvolvimento e licenciamento da solução tecnológica '${_contract!['project_title']}', compreendendo engenharia de software e UI/UX."),
        
        if (isRevShare)
          _pdfClause("3. MODALIDADE DE PARCERIA (REVENUE SHARE)", "As partes pactuam regime de parceria, onde a CONTRATADA investe seu capital intelectual em troca de ${revSharePercent.toStringAsFixed(1)}% de participação sobre o faturamento bruto gerado pela plataforma."),

        _pdfClause("4. INVESTIMENTO", isRevShare 
          ? "O valor de ${currency.format(_contract!['total_value'])} refere-se ao SETUP DE INFRAESTRUTURA (Hostinger VPS/Cloud). O desenvolvimento é bonificado pela agência."
          : "Pela execução, o CONTRATANTE pagará à CONTRATADA o valor total de ${currency.format(_contract!['total_value'])}."),

        _pdfClause("5. CONFIDENCIALIDADE E PROPRIEDADE", "As partes obrigam-se ao sigilo absoluto. A titularidade dos fontes será cedida após a quitação do setup e início operacional."),
        _pdfClause("6. VALIDADE JURÍDICA", "Este documento possui validade plena nos termos da MP 2.200-2/2001, certificado via IP e carimbo de tempo."),
        
        pw.SizedBox(height: 60),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text("WP WEB SOLUÇÕES (CONTRATADA)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
              if (agencySignatureImg != null) pw.Image(pw.MemoryImage(agencySignatureImg), width: 100)
              else pw.Text(_contract!['agency_typed_name'] ?? "WP WEB", style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text("CONTRATANTE", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
              pw.Text(_contract!['typed_name'] ?? clientName, style: pw.TextStyle(fontSize: 14, fontStyle: pw.FontStyle.italic)),
              pw.Text("IP: $_ipAddress | Data: $dateStr", style: const pw.TextStyle(fontSize: 7)),
            ]),
          ],
        ),
      ],
    ));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'Contrato_WPWEB_${_contract!['project_title']}.pdf');
  }

  // --- INTERFACE WEB E MOBILE ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFFF007F))));
    if (_contract == null) return const Scaffold(body: Center(child: Text("Link expirado ou contrato inválido.")));

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Center(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: isMobile ? 0 : 40, horizontal: isMobile ? 0 : 20),
                  constraints: const BoxConstraints(maxWidth: 850),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: isMobile ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 40)],
                  ),
                  child: _isSigned ? _buildSuccessUI() : _buildContractBody(isMobile),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 65,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        const Icon(Icons.verified_user, color: Colors.blueAccent, size: 20),
        const SizedBox(width: 10),
        const Text("AUTENTICAÇÃO DIGITAL WP WEB", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1, color: Colors.blueGrey)),
        const Spacer(),
        SizedBox(width: 80, child: LinearProgressIndicator(value: _readProgress, color: const Color(0xFFFF007F), backgroundColor: Colors.grey.shade100)),
      ]),
    );
  }

  Widget _buildContractBody(bool isMobile) {
    return Column(
      children: [
        _buildVisualHeader(),
        Padding(
          padding: EdgeInsets.all(isMobile ? 30 : 60),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("CONTRATO DE PRESTAÇÃO DE SERVIÇOS TÉCNICOS", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.2)),
            const SizedBox(height: 40),
            
            if (isRevShare) _buildPartnershipBadge(),

            _clauseUI("1. IDENTIFICAÇÃO DAS PARTES", "Este contrato vincula juridicamente a CONTRATADA WP WEB SOLUÇÕES TECNOLÓGICAS (CNPJ 55.305.086/0001-52) e o CONTRATANTE $clientName, identificado via IP e Token Único."),
            _clauseUI("2. OBJETO", "Desenvolvimento, design e licenciamento da solução tecnológica '${_contract!['project_title']}'."),
            
            _buildTechSpecs(),

            if (isRevShare)
              _clauseUI("3. DA PARCERIA E COMISSÃO", "O projeto será executado via Revenue Share. A CONTRATADA investe seu capital de desenvolvimento em troca de ${revSharePercent.toStringAsFixed(1)}% do faturamento bruto gerado pela plataforma."),

            _clauseUI(isRevShare ? "4. SETUP E INFRAESTRUTURA" : "3. INVESTIMENTO", 
              isRevShare 
                ? "O CONTRATANTE pagará ${currency.format(_contract!['total_value'])} destinado exclusivamente a custos de Setup e Servidores (Hostinger/Cloud). Mão de obra é investimento da agência."
                : "O CONTRATANTE pagará o montante total de ${currency.format(_contract!['total_value'])} para execução integral."),

            _clauseUI("CONFIDENCIALIDADE", "As partes obrigam-se ao sigilo absoluto de segredos industriais e dados sensíveis sob a vigência deste contrato."),
            _clauseUI("FORO", "Fica eleito o foro da comarca de Contagem/MG para dirimir eventuais controvérsias."),

            const SizedBox(height: 80),
            _buildAuthPanel(),
          ]),
        ),
      ],
    );
  }

  Widget _buildVisualHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      color: const Color(0xFF0F172A),
      child: Column(children: [
        const Icon(Icons.bolt, color: Colors.white, size: 45),
        const SizedBox(height: 15),
        const Text("WP WEB SOLUÇÕES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 4)),
        Text("CERTIFICADO DE CONTRATAÇÃO DIGITAL", style: TextStyle(color: const Color(0xFFFF007F).withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildPartnershipBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), border: Border.all(color: Colors.blue.withOpacity(0.2)), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.handshake, color: Colors.blue, size: 24),
        const SizedBox(width: 15),
        const Expanded(child: Text("DETECTION: MODELO DE PARCERIA POR PERFORMANCE ATIVO.", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11))),
      ]),
    );
  }

  Widget _buildTechSpecs() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: [
        _rowUI("Web Interface", _contract!['is_web'] ? "INCLUSO" : "N/A"),
        _rowUI("Mobile App", _contract!['is_mobile'] ? "INCLUSO" : "N/A"),
        _rowUI("Desktop Software", _contract!['is_desktop'] ? "INCLUSO" : "N/A"),
      ]),
    );
  }

  Widget _buildAuthPanel() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), border: Border.all(color: const Color(0xFFCBD5E1)), borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        const Text("AUTENTICAÇÃO DO CONTRATANTE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1, color: Color(0xFF475569))),
        const SizedBox(height: 30),
        _buildTabs(),
        const SizedBox(height: 30),
        if (_authMethodIndex == 0) _buildPad()
        else if (_authMethodIndex == 1) _buildTyped()
        else _buildOtp(),
        const SizedBox(height: 30),
        _buildSubmitBtn(),
      ]),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        _tabItem(0, "Assinar"), _tabItem(1, "Digitar"), _tabItem(2, "OTP"),
      ]),
    );
  }

  Widget _tabItem(int i, String l) => Expanded(child: GestureDetector(onTap: () => setState(() => _authMethodIndex = i), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _authMethodIndex == i ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Text(l, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: _authMethodIndex == i ? FontWeight.bold : FontWeight.normal)))));

  Widget _buildSubmitBtn() {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF7000FF), Color(0xFFFF007F)]), borderRadius: BorderRadius.circular(12)),
      child: ElevatedButton(
        onPressed: _processSubmit,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white),
        child: const Text("CONFIRMAR ASSINATURA", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1))
      ),
    );
  }

  Future<void> _processSubmit() async {
    if (_authMethodIndex == 0 && _sigController.isEmpty) { _showError("Desenhe sua rubrica no campo."); return; }
    if (_authMethodIndex == 1 && _typedNameController.text.length < 3) { _showError("Digite seu nome completo."); return; }
    if (_authMethodIndex == 2 && _otpController.text != _contract!['otp_code']) { _showError("Código OTP incorreto."); return; }
    
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.from('cloud_contracts').update({
        'status': 'assinado',
        'signed_at': DateTime.now().toIso8601String(),
        'ip_address': _ipAddress,
        'signature_method': _authMethodIndex == 0 ? "Manuscrita" : _authMethodIndex == 1 ? "Digitada" : "Token OTP",
        'typed_name': _authMethodIndex == 1 ? _typedNameController.text : clientName,
      }).eq('id', _contract!['id']);
      setState(() { _isLoading = false; _isSigned = true; });
    } catch (e) { _showError("Erro na conexão."); setState(() => _isLoading = false); }
  }

  // Helpers UI
  Widget _buildPad() => Container(decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)), child: Signature(controller: _sigController, height: 150, backgroundColor: Colors.transparent));
  Widget _buildTyped() => TextField(controller: _typedNameController, textAlign: TextAlign.center, decoration: const InputDecoration(hintText: "Nome Completo", border: OutlineInputBorder()));
  Widget _buildOtp() => TextField(controller: _otpController, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8), decoration: const InputDecoration(hintText: "0000", helperText: "Digite o código fornecido pela WP WEB"));
  
  Widget _clauseUI(String t, String b) => Padding(padding: const EdgeInsets.only(top: 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))), const SizedBox(height: 8), Text(b, textAlign: TextAlign.justify, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6))]));
  Widget _rowUI(String l, String v) => Padding(padding: const EdgeInsets.all(15), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), Text(v, style: const TextStyle(fontSize: 11))]));

  Widget _buildSuccessUI() {
    return Padding(padding: const EdgeInsets.all(60), child: Column(children: [
      const Icon(Icons.check_circle, size: 100, color: Colors.green),
      const SizedBox(height: 20),
      const Text("PROTOCOLO FINALIZADO!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
      const Text("O contrato assinado foi armazenado com segurança.", textAlign: TextAlign.center),
      const SizedBox(height: 60),
      SizedBox(width: double.infinity, height: 60, child: ElevatedButton.icon(onPressed: _downloadSignedPDF, icon: const Icon(Icons.download), label: const Text("BAIXAR CÓPIA PDF OFICIAL"))),
    ]));
  }

  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  pw.Widget _buildPdfHeader() => pw.Container(padding: const pw.EdgeInsets.only(bottom: 20), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("WP WEB SOLUÇÕES", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)), pw.Text("CERTIFICADO DIGITAL #WP${_contract!['id'].toString().substring(0,6)}", style: const pw.TextStyle(fontSize: 8))]));
  pw.Widget _pdfClause(String t, String b) => pw.Padding(padding: const pw.EdgeInsets.only(bottom: 12), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(t, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)), pw.Text(b, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.justify)]));
}