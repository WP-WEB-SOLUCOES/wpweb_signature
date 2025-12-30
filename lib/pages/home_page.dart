import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html; // Necessário para redirecionar via URL no Web

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _cachedContracts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCache();
  }

  Future<void> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contractsJson = prefs.getString('wpweb_history');
    if (contractsJson != null) {
      setState(() {
        _cachedContracts = List<Map<String, dynamic>>.from(jsonDecode(contractsJson));
      });
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 850),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHomeHeader(),
              const SizedBox(height: 40),
              const Text(
                "MEUS DOCUMENTOS RECENTES",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2, color: Colors.blueGrey),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _loading 
                  ? const Center(child: CircularProgressIndicator())
                  : _cachedContracts.isEmpty 
                    ? _buildEmptyState() 
                    : _buildContractList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeHeader() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt, color: Colors.white, size: 40),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("WP WEB PORTAL", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              Text("Gestão de Formalizações Digitais", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          const Text("Nenhum contrato visualizado ainda", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text("Acesse um link de contrato para vê-lo aqui.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildContractList() {
    return ListView.builder(
      itemCount: _cachedContracts.length,
      itemBuilder: (context, index) {
        final contract = _cachedContracts[index];
        final bool isSigned = contract['status'] == 'assinado';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(20),
            leading: CircleAvatar(
              backgroundColor: isSigned ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              child: Icon(isSigned ? Icons.verified : Icons.history, color: isSigned ? Colors.green : Colors.orange, size: 20),
            ),
            title: Text(contract['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text("Status: ${contract['status'].toString().toUpperCase()}", style: const TextStyle(fontSize: 11)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            onTap: () {
              // Redireciona com o token para abrir a SignaturePage
              html.window.location.href = "/?token=${contract['token']}";
            },
          ),
        );
      },
    );
  }
}