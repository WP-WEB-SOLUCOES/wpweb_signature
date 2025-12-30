import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/home_page.dart';
import 'pages/signature_page.dart';

void main() async {
  // Garante a inicialização dos bindings do Flutter para o Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização do Banco de Dados Cloud
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
    // Lógica de Roteamento Dinâmico via URL:
    // Captura o parâmetro 'token' da URL (ex: ?token=abc123)
    final String? token = Uri.base.queryParameters['token'];

    return MaterialApp(
      title: 'WP WEB - Portal de Formalização',
      debugShowCheckedModeBanner: false,
      
      // Definição da Identidade Visual (Brand Colors)
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0F172A), // Cor Navy da WP Web
        fontFamily: 'Roboto',
        brightness: Brightness.light,
      ),

      // ROTEADOR:
      // Se houver um token na URL, carregamos a SignaturePage para assinar.
      // Se a URL estiver limpa, carregamos a HomePage com o histórico em cache.
      home: token != null ? const SignaturePage() : const HomePage(),
      
      // Configuração para evitar que o Flutter adicione '#' na URL (Opcional)
      // Se desejar URLs limpas, certifique-se de configurar o servidor/nginx para isso.
    );
  }
}