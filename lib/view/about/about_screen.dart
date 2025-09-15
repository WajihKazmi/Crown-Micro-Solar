import 'package:flutter/material.dart';
import 'package:crown_micro_solar/l10n/app_localizations.dart' as gen;

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = gen.AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: theme.primaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, size: 22, color: Colors.white),
          tooltip: l10n.about_us,
        ),
        centerTitle: true,
        title: Text(
          l10n.about_us,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand icon
              Align(
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.solar_power,
                    size: 36,
                    color: theme.primaryColor,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Title
              Text(
                l10n.introduction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle / introduction paragraph
              Text(
                l10n.about_us_introduction.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: .3,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),
              // Visual sections (replacing old images)
              _IconCard(icon: Icons.business),
              const SizedBox(height: 12),
              _IconCard(icon: Icons.lightbulb_outline),
              const SizedBox(height: 12),
              _IconCard(icon: Icons.public),

              const SizedBox(height: 20),
              // Company strip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.company_name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconCard extends StatelessWidget {
  final IconData icon;
  const _IconCard({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // black12 with lower opacity
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Icon(
          icon,
          size: 64,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
