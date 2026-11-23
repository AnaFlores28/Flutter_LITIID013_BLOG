import 'package:flutter/material.dart';

import '../services/feature_service.dart';
import '../widgets/admin_drawer.dart';

/// Permite buscar usuarios, listar conversaciones y abrir el chat privado.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final FeatureService _service = FeatureService();
  final TextEditingController _search = TextEditingController();
  late Future<List<Map<String, dynamic>>> _conversations;
  Map<String, dynamic> _user = const {};
  List<Map<String, dynamic>> _matches = [];
  bool _argumentsRead = false;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _conversations = _service.conversaciones();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) _user = Map<String, dynamic>.from(args);
    _argumentsRead = true;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _conversations = _service.conversaciones());

  /// Busca cuentas por nombre y actualiza las coincidencias mostradas.
  Future<void> _findUsers() async {
    if (_search.text.trim().length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe al menos dos caracteres.')),
      );
      return;
    }
    setState(() => _searching = true);
    try {
      final users = await _service.buscarUsuarios(_search.text.trim());
      if (mounted) setState(() => _matches = users);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo buscar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  /// Abre o crea una conversación con la cuenta seleccionada.
  Future<void> _openConversation(Map<String, dynamic> other) async {
    try {
      final id = (other['id_usr'] as num).toInt();
      final conversation = await _service.iniciarConversacion(id);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/conversation',
        arguments: {
          'conversation': conversation,
          'usuario': _user,
        },
      ).then((_) => _reload());
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo iniciar la conversación: $error')),
        );
      }
    }
  }

  /// Muestra la búsqueda de personas y la lista de conversaciones existentes.
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mensajes'),
      actions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ],
    ),
    drawer: AdminDrawer(usuario: _user, rutaActual: '/messages'),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Buscar personas',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _findUsers(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _searching ? null : _findUsers,
                icon: _searching
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
              ),
            ],
          ),
        ),
        if (_matches.isNotEmpty)
          SizedBox(
            height: 114,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: _matches.map((person) {
                final myId = (_user['id_usr'] as num?)?.toInt();
                if ((person['id_usr'] as num?)?.toInt() == myId) {
                  return const SizedBox.shrink();
                }
                return SizedBox(
                  width: 110,
                  child: Card(
                    child: InkWell(
                      onTap: () => _openConversation(person),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.account_circle_outlined, size: 30),
                            Text(
                              person['nom_usr']?.toString() ?? 'Usuario',
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _conversations,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text('No se pudieron cargar los mensajes: ${snapshot.error}'),
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(
                  child: Text('Aún no tienes conversaciones. Busca a alguien para empezar.'),
                );
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final conversation = items[index];
                  final person =
                      conversation['usuario'] as Map<String, dynamic>? ?? {};
                  final unread =
                      (conversation['no_leidos'] as num?)?.toInt() ?? 0;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFFFD93D),
                      child: Text(
                        (person['nom_usr']?.toString().isNotEmpty ?? false)
                            ? person['nom_usr'].toString()[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(person['nom_usr']?.toString() ?? 'Usuario'),
                    subtitle: Text(
                      conversation['ultimo']?.toString() ?? 'Iniciar conversación',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: unread > 0
                        ? CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              '$unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/conversation',
                      arguments: {
                        'conversation': conversation,
                        'usuario': _user,
                      },
                    ).then((_) => _reload()),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

/// Pantalla de chat para consultar y enviar mensajes de una conversación.
class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final FeatureService _service = FeatureService();
  final TextEditingController _message = TextEditingController();
  late Future<List<Map<String, dynamic>>> _messages;
  Map<String, dynamic> _conversation = const {};
  Map<String, dynamic> _user = const {};
  bool _argumentsRead = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages = Future.value([]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argumentsRead) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _conversation =
          args['conversation'] as Map<String, dynamic>? ?? const {};
      _user = args['usuario'] as Map<String, dynamic>? ?? const {};
      _messages = _service.mensajes((_conversation['id_conv'] as num).toInt());
    }
    _argumentsRead = true;
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  void _reload() {
    final id = (_conversation['id_conv'] as num).toInt();
    setState(() => _messages = _service.mensajes(id));
  }

  /// Envía el texto no vacío y vuelve a cargar los mensajes de la conversación.
  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _service.enviarMensaje(
        (_conversation['id_conv'] as num).toInt(),
        text,
      );
      _message.clear();
      _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo enviar el mensaje: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Presenta los mensajes por autor y el campo para enviar uno nuevo.
  @override
  Widget build(BuildContext context) {
    final person =
        _conversation['usuario'] as Map<String, dynamic>? ?? const {};
    final currentId = (_user['id_usr'] as num?)?.toInt();
    return Scaffold(
      appBar: AppBar(
        title: Text(person['nom_usr']?.toString() ?? 'Conversación'),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _messages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('No se pudieron cargar los mensajes: ${snapshot.error}'),
                  );
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Text('Envía el primer mensaje.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final mine =
                        (message['usr_id'] as num?)?.toInt() == currentId;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                        ),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: mine
                              ? const Color(0xFFFFD93D)
                              : Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(message['texto']?.toString() ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _message,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 1000,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje',
                        counterText: '',
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Enviar',
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
