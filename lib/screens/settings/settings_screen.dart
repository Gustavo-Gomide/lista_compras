import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../core/customization/customization_provider.dart';
import '../../core/customization/icon_gallery.dart';
import '../../providers/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _fonts = [
    'Roboto', 'Poppins', 'Montserrat', 'Nunito', 'Lato', 'Inter',
    'Open Sans', 'Merriweather', 'Rubik', 'Quicksand', 'Comfortaa',
    'Work Sans', 'Fredoka', 'Baloo 2', 'Mulish', 'Karla',
  ];

  Future<void> _pickColor(BuildContext context) async {
    final provider = context.read<CustomizationProvider>();
    Color selected = provider.model.seedColor;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cor principal'),
        content: SingleChildScrollView(
          child: ColorPicker(pickerColor: selected, onColorChanged: (c) => selected = c, enableAlpha: false),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              provider.updateSeedColor(selected);
              Navigator.pop(context);
            },
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomSvg(BuildContext context, {required bool checked}) async {
    final controller = TextEditingController();
    final provider = context.read<CustomizationProvider>();

    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(checked ? 'SVG personalizado (marcado)' : 'SVG personalizado (desmarcado)'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(hintText: 'Cole o código SVG aqui'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Salvar')),
        ],
      ),
    );
    if (result == null) return;
    final value = result.trim();
    if (value.isEmpty) return;
    // Salva na lista de SVGs do usuário (local) e aplica
    await provider.addCustomSvg(value, checked: checked);
    if (checked) {
      provider.updateCheckedSvg(value);
    } else {
      provider.updateUncheckedSvg(value);
    }
  }

  Future<void> _openIconGallery(BuildContext context, {required bool checked}) async {
    final provider = context.read<CustomizationProvider>();
    final builtInOptions = checked ? IconGallery.checkedOptions : IconGallery.uncheckedOptions;
    final customSvgs = checked
        ? provider.model.userCustomCheckedSvgs
        : provider.model.userCustomUncheckedSvgs;

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  checked ? 'Ícone do checkbox marcado' : 'Ícone do checkbox desmarcado',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      // Opções padrão
                      for (final option in builtInOptions)
                        _GalleryTile(
                          option: option,
                          onTap: () {
                            if (checked) {
                              provider.updateCheckedSvg(option.svg.isEmpty ? null : option.svg);
                            } else {
                              provider.updateUncheckedSvg(option.svg.isEmpty ? null : option.svg);
                            }
                            Navigator.pop(context);
                          },
                        ),
                      // SVGs do usuário (locais)
                      for (int i = 0; i < customSvgs.length; i++)
                        _CustomSvgTile(
                          svg: customSvgs[i],
                          onTap: () {
                            if (checked) {
                              provider.updateCheckedSvg(customSvgs[i]);
                            } else {
                              provider.updateUncheckedSvg(customSvgs[i]);
                            }
                            Navigator.pop(context);
                          },
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Remover SVG?'),
                                content: const Text('Este SVG personalizado será removido da sua lista.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remover')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await provider.removeCustomSvg(i, checked: checked);
                              if (context.mounted) Navigator.pop(context);
                            }
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _pickCustomSvg(context, checked: checked);
                  },
                  icon: const Icon(Icons.code),
                  label: const Text('Colar SVG personalizado'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editDisplayName(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alterar nome'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Nome')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );
    if (result == null || result.isEmpty || !context.mounted) return;
    final error = await context.read<AuthProvider>().updateDisplayName(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Nome atualizado.')),
    );
  }

  Future<void> _editEmail(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alterar e-mail'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Novo e-mail'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Salvar')),
        ],
      ),
    );
    if (result == null || result.isEmpty || !result.contains('@') || !context.mounted) return;
    final error = await context.read<AuthProvider>().updateEmail(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Verifique seu e-mail para confirmar a alteração.')),
    );
  }

  Future<void> _editPassword(BuildContext context) async {
    final controller = TextEditingController();
    bool obscure = true;
    final result = await showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Alterar senha'),
          content: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'Nova senha',
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => obscure = !obscure),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Salvar')),
          ],
        ),
      ),
    );
    if (result == null || result.length < 6 || !context.mounted) return;
    final error = await context.read<AuthProvider>().updatePassword(result);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Senha atualizada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customization = context.watch<CustomizationProvider>();
    final model = customization.model;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Personalização e conta')),
      body: ListView(
        children: [
          const _SectionHeader('Conta'),
          ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Nome'),
            subtitle: Text(auth.user?.userMetadata?['full_name'] as String? ?? 'Toque para definir'),
            onTap: () => _editDisplayName(context),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('E-mail'),
            subtitle: Text(auth.user?.email ?? ''),
            onTap: () => _editEmail(context),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Senha'),
            subtitle: const Text('Toque para alterar'),
            onTap: () => _editPassword(context),
          ),
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('Conta Google'),
            subtitle: Text(auth.hasGoogleLinked ? 'Vinculada' : 'Não vinculada'),
            trailing: TextButton(
              onPressed: () async {
                final error = auth.hasGoogleLinked
                    ? await context.read<AuthProvider>().unlinkGoogle()
                    : await context.read<AuthProvider>().linkGoogle();
                if (!context.mounted) return;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                }
              },
              child: Text(auth.hasGoogleLinked ? 'Desvincular' : 'Vincular'),
            ),
          ),

          const Divider(height: 32),
          const _SectionHeader('Aparência (só neste dispositivo)'),
          ListTile(
            leading: CircleAvatar(backgroundColor: model.seedColor),
            title: const Text('Cor principal'),
            onTap: () => _pickColor(context),
          ),
          SwitchListTile(
            secondary: Icon(model.brightness == Brightness.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
            title: const Text('Modo escuro'),
            value: model.brightness == Brightness.dark,
            onChanged: (_) => customization.toggleBrightness(),
          ),
          ListTile(
            leading: const Icon(Icons.font_download_outlined),
            title: const Text('Fonte'),
            subtitle: DropdownButton<String>(
              value: model.fontFamily,
              isExpanded: true,
              items: _fonts.map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) {
                if (v != null) customization.updateFontFamily(v);
              },
            ),
          ),

          const Divider(height: 32),
          const _SectionHeader('Acessibilidade'),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Tamanho do texto'),
            subtitle: Slider(
              value: model.fontScale,
              min: 0.85,
              max: 1.6,
              divisions: 15,
              label: '${(model.fontScale * 100).round()}%',
              onChanged: (v) => customization.updateFontScale(v),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'O app segue também o leitor de tela do seu aparelho (TalkBack no Android, '
              'VoiceOver no iOS/macOS, Narrador no Windows) — os botões e itens já têm '
              'descrições para navegação por toque/voz.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),

          const Divider(height: 32),
          const _SectionHeader('Ícones do checkbox'),
          ListTile(
            leading: _IconPreview(svg: model.checkedSvg),
            title: const Text('Ícone: marcado'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openIconGallery(context, checked: true),
          ),
          ListTile(
            leading: _IconPreview(svg: model.uncheckedSvg),
            title: const Text('Ícone: desmarcado'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openIconGallery(context, checked: false),
          ),

          const Divider(height: 32),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton(
              onPressed: () => customization.reset(),
              child: const Text('Restaurar aparência padrão'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _IconPreview extends StatelessWidget {
  final String? svg;
  const _IconPreview({required this.svg});

  @override
  Widget build(BuildContext context) {
    if (svg == null || svg!.trim().isEmpty) {
      return const CircleAvatar(child: Icon(Icons.check_box_outlined, size: 18));
    }
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      child: SvgPicture.string(svg!, width: 24, height: 24),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final IconGalleryOption option;
  final VoidCallback onTap;
  const _GalleryTile({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: option.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(8),
          child: option.svg.isEmpty
              ? const Icon(Icons.check_box_outlined, size: 32)
              : SvgPicture.string(option.svg, width: 32, height: 32),
        ),
      ),
    );
  }
}

class _CustomSvgTile extends StatelessWidget {
  final String svg;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _CustomSvgTile({required this.svg, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'SVG personalizado',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SvgPicture.string(svg),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                    ),
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
