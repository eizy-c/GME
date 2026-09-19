import 'package:flutter/material.dart';

/// Modal con la Política de Privacidad de CaidaGO conforme a los lineamientos de Google Play Store.
class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const PrivacyPolicyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
      ),
      title: const Row(
        children: [
          Icon(Icons.privacy_tip_rounded, color: Color(0xFF38BDF8), size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Política de Privacidad',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: '1. Compromiso de Privacidad',
                content:
                    'CaidaGO está diseñado respetando la privacidad del usuario. Esta aplicación está desarrollada como un juego seguro, limpio y de entretenimiento familiar.',
              ),
              _buildSection(
                title: '2. Almacenamiento Local de Datos',
                content:
                    'Tu progreso en el juego, estadísticas de partidas, nivel alcanzado, saldo de monedas, tickets y personalizaciones cosméticas se almacenan exclusivamente de forma local en tu dispositivo móvil. No se transfieren ni venden a servidores de terceros.',
              ),
              _buildSection(
                title: '3. No Recopilación de Datos Sensibles',
                content:
                    'CaidaGO NO recopila información personal identificable como nombres reales, correos electrónicos, números telefónicos, ubicación geográfica precisa ni contactos.',
              ),
              _buildSection(
                title: '4. Conectividad y Juego Multijugador',
                content:
                    'Las funciones multijugador utilizan conexiones locales o sesiones efímeras únicamente para sincronizar el estado de la mesa de cartas durante la partida en curso.',
              ),
              _buildSection(
                title: '5. Cumplimiento con Google Play Store',
                content:
                    'Esta política cumple con los estándares del Programa para Desarrolladores de Google Play y las directrices de privacidad infantil y familiar.',
              ),
              const SizedBox(height: 8),
              const Divider(color: Colors.white12),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '© 2026 CaidaGO • Desarrollado por Eizy Systems\nTodos los derechos reservados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Entendido',
            style: TextStyle(
              color: Color(0xFF38BDF8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFDE047),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
