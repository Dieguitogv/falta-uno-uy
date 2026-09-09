import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_config.dart';
import 'data/match_repository.dart';
import 'data/models.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseKey,
    );
  }
  runApp(const FaltaUnoApp());
}

class FaltaUnoApp extends StatelessWidget {
  const FaltaUnoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Falta Uno UY',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4ED66B), brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF071012),
        fontFamily: 'Roboto',
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF132024),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: AppConfig.hasSupabase ? const AuthGate() : const MainShell(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? subscription;
  Session? session;

  @override
  void initState() {
    super.initState();
    session = Supabase.instance.client.auth.currentSession;
    subscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() => session = data.session);
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => session == null ? const LoginScreen() : const MainShell();
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  bool createAccount = false;
  bool loading = false;

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      showMessage(context, 'Ingresá un email válido y una contraseña de al menos 6 caracteres.');
      return;
    }
    setState(() => loading = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (createAccount) {
        await auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'display_name': name.text.trim().isEmpty ? 'Jugador' : name.text.trim()},
        );
        if (mounted && auth.currentSession == null) {
          showMessage(context, 'Cuenta creada. Revisá tu email para confirmar el registro.');
        }
      } else {
        await auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (_) {
      if (mounted) showMessage(context, 'No se pudo completar el acceso.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.sports_soccer, size: 68),
                  const SizedBox(height: 12),
                  const Text('Falta Uno UY', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                  const Text('¿Te falta uno? Encontralo.', textAlign: TextAlign.center),
                  const SizedBox(height: 30),
                  if (createAccount) ...[
                    TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
                    const SizedBox(height: 12),
                  ],
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
                  const SizedBox(height: 12),
                  TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: loading ? null : submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(loading ? 'CARGANDO...' : createAccount ? 'CREAR CUENTA' : 'INGRESAR'),
                    ),
                  ),
                  TextButton(
                    onPressed: loading ? null : () => setState(() => createAccount = !createAccount),
                    child: Text(createAccount ? 'Ya tengo cuenta' : 'Crear una cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onCreate: () => setState(() => index = 2)),
      const ExploreScreen(),
      CreateMatchScreen(onCreated: () => setState(() => index = 3)),
      const MyMatchesScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0A1417),
        indicatorColor: const Color(0xFF1E5D38),
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Explorar'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Crear'),
          NavigationDestination(icon: Icon(Icons.sports_soccer_outlined), selectedIcon: Icon(Icons.sports_soccer), label: 'Partidos'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final VoidCallback onCreate;
  const HomeScreen({super.key, required this.onCreate});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<MatchModel>> future;
  @override
  void initState() { super.initState(); future = MatchRepository.instance.upcoming(); }
  void reload() => setState(() => future = MatchRepository.instance.upcoming());

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => reload(),
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 22), children: [
        Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('FALTA UNO UY', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: .4)),
            Text('¿Te falta uno? Encontralo.', style: TextStyle(color: Color(0xFFA8B5B8))),
          ])),
          const Icon(Icons.location_on, color: Color(0xFF4ED66B), size: 20),
          const Text('Montevideo', style: TextStyle(fontWeight: FontWeight.w700)),
          IconButton(onPressed: () => showMessage(context, '3 notificaciones nuevas'), icon: const Badge(label: Text('3'), child: Icon(Icons.notifications_none))),
        ]),
        const SizedBox(height: 18),
        Container(
          height: 150,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF173E29), Color(0xFF0A171A)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF245B38)),
          ),
          child: const Row(children: [
            Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MÁS FÚTBOL,', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              Text('MÁS AMIGOS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF4ED66B))),
              SizedBox(height: 8), Text('Armá el partido. Nosotros encontramos al que falta.', style: TextStyle(color: Color(0xFFC1CCCE))),
            ])),
            Icon(Icons.sports_soccer, size: 76, color: Color(0xFF4ED66B)),
          ]),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _QuickAction(icon: Icons.search, text: 'Explorar\npartidos', onTap: () => showMessage(context, 'Abrí Explorar desde la barra inferior.'))),
          const SizedBox(width: 8),
          Expanded(child: _QuickAction(icon: Icons.groups_outlined, text: 'Buscar\njugadores', onTap: () => showMessage(context, 'Elegí un partido y tocá ME FALTA UNO.'))),
          const SizedBox(width: 8),
          Expanded(child: _QuickAction(icon: Icons.shield_outlined, text: 'Ver\nequipos', onTap: () => showMessage(context, 'Equipos: siguiente módulo.'))),
          const SizedBox(width: 8),
          Expanded(child: _QuickAction(icon: Icons.add, text: 'Crear\npartido', highlighted: true, onTap: widget.onCreate)),
        ]),
        if (!AppConfig.hasSupabase) ...[const SizedBox(height: 14), const LocalModeBanner()],
        const SizedBox(height: 24),
        const SectionTitle(title: 'Tus próximos partidos'),
        const SizedBox(height: 12),
        FutureBuilder<List<MatchModel>>(future: future, builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final matches=snap.data??[];
          if(matches.isEmpty) return const EmptyCard(text:'Todavía no hay partidos. Creá el primero.');
          final m=matches.first;
          return Column(children:[
            MatchCard(match:m,onTap:() async {await Navigator.push(context,MaterialPageRoute(builder:(_)=>MatchDetailScreen(initialMatch:m)));reload();}),
            const SizedBox(height:22),
            const Align(alignment:Alignment.centerLeft,child:SectionTitle(title:'Partidos cerca tuyo')),
            const SizedBox(height:12),
            ...matches.skip(1).take(3).map((x)=>Padding(padding:const EdgeInsets.only(bottom:10),child:MatchCard(match:x,onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MatchDetailScreen(initialMatch:x))))))
          ]);
        }),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon; final String text; final VoidCallback onTap; final bool highlighted;
  const _QuickAction({required this.icon, required this.text, required this.onTap, this.highlighted=false});
  @override Widget build(BuildContext context)=>Material(
    color: highlighted ? const Color(0xFF173E29) : const Color(0xFF111E22),
    borderRadius: BorderRadius.circular(18),
    child: InkWell(borderRadius:BorderRadius.circular(18),onTap:onTap,child:Padding(padding:const EdgeInsets.symmetric(vertical:15,horizontal:6),child:Column(children:[Icon(icon,color:highlighted?const Color(0xFF4ED66B):Colors.white),const SizedBox(height:7),Text(text,textAlign:TextAlign.center,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700))]))),
  );
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final search = TextEditingController();
  late Future<List<MatchModel>> future;
  String level = 'Todos';

  @override
  void initState() {
    super.initState();
    future = MatchRepository.instance.upcoming();
    search.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('Explorar', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        TextField(controller: search, decoration: const InputDecoration(hintText: 'Buscar por zona o cancha', prefixIcon: Icon(Icons.search))),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: ['Todos', 'Recreativo', 'Intermedio', 'Competitivo'].map((v) => ChoiceChip(label: Text(v), selected: level == v, onSelected: (_) => setState(() => level = v))).toList()),
        const SizedBox(height: 22),
        FutureBuilder<List<MatchModel>>(
          future: future,
          builder: (context, snap) {
            final q = search.text.trim().toLowerCase();
            final matches = (snap.data ?? []).where((m) {
              final textOk = q.isEmpty || m.zone.toLowerCase().contains(q) || m.venue.toLowerCase().contains(q);
              final levelOk = level == 'Todos' || m.level == level;
              return textOk && levelOk && m.playerCount < m.totalCapacity;
            }).toList();
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (matches.isEmpty) return const EmptyCard(text: 'No encontramos partidos con esos filtros.');
            return Column(children: matches.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MatchCard(match: m, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(initialMatch: m)))),
            )).toList());
          },
        ),
      ],
    );
  }
}

class CreateMatchScreen extends StatefulWidget {
  final VoidCallback onCreated;
  const CreateMatchScreen({super.key, required this.onCreated});
  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final zone = TextEditingController();
  final venue = TextEditingController();
  final price = TextEditingController(text: '350');
  DateTime date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay time = const TimeOfDay(hour: 21, minute: 0);
  String level = 'Intermedio';
  bool loading = false;

  Future<void> create() async {
    const maxPlayers = 10;
    final priceValue = int.tryParse(price.text) ?? 0;
    if (zone.text.trim().isEmpty || venue.text.trim().isEmpty) {
      showMessage(context, 'Completá zona y cancha.');
      return;
    }
    final startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!startsAt.isAfter(DateTime.now())) {
      showMessage(context, 'El partido tiene que ser en una fecha futura.');
      return;
    }
    setState(() => loading = true);
    try {
      final match = await MatchRepository.instance.create(
        zone: zone.text.trim(), venue: venue.text.trim(), startsAt: startsAt,
        price: priceValue, level: level, maxPlayers: maxPlayers,
      );
      if (!mounted) return;
      showMessage(context, 'Partido publicado ✅');
      await Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(initialMatch: match)));
      widget.onCreated();
    } catch (e) {
      if (mounted) showMessage(context, 'No se pudo publicar el partido.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('Crear partido', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        TextField(controller: zone, decoration: const InputDecoration(labelText: 'Zona', prefixIcon: Icon(Icons.location_on_outlined))),
        const SizedBox(height: 12),
        TextField(controller: venue, decoration: const InputDecoration(labelText: 'Cancha / complejo', prefixIcon: Icon(Icons.place_outlined))),
        const SizedBox(height: 12),
        ListTile(tileColor: const Color(0xFF111E22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), leading: const Icon(Icons.calendar_month_outlined), title: const Text('Fecha'), subtitle: Text(DateFormat('dd/MM/yyyy').format(date)), onTap: () async {
          final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: date);
          if (picked != null) setState(() => date = picked);
        }),
        const SizedBox(height: 12),
        ListTile(tileColor: const Color(0xFF111E22), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), leading: const Icon(Icons.access_time), title: const Text('Hora'), subtitle: Text(time.format(context)), onTap: () async {
          final picked = await showTimePicker(context: context, initialTime: time);
          if (picked != null) setState(() => time = picked);
        }),
        const SizedBox(height: 12),
        TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Precio por jugador', prefixIcon: Icon(Icons.attach_money))),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: level, decoration: const InputDecoration(labelText: 'Nivel', prefixIcon: Icon(Icons.equalizer)), items: ['Recreativo', 'Intermedio', 'Competitivo', 'Cualquiera'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => level = v ?? level)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF111E22), borderRadius: BorderRadius.circular(16)),
          child: const Row(children: [
            Icon(Icons.groups_outlined, color: Color(0xFF4ED66B)),
            SizedBox(width: 10),
            Expanded(child: Text('Fútbol 5: 10 titulares + 1 suplente de seguridad. El partido queda cubierto con 11 personas.')),
          ]),
        ),
        const SizedBox(height: 18),
        FilledButton(onPressed: loading ? null : create, child: Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(loading ? 'PUBLICANDO...' : 'PUBLICAR PARTIDO'))),
      ],
    );
  }
}

class MatchDetailScreen extends StatefulWidget {
  final MatchModel initialMatch;
  const MatchDetailScreen({super.key, required this.initialMatch});
  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  late MatchModel match;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    match = widget.initialMatch;
  }

  Future<void> toggleJoin() async {
    setState(() => loading = true);
    try {
      match = match.joined ? await MatchRepository.instance.leave(match) : await MatchRepository.instance.join(match);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) showMessage(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final organizer = match.organizerId == MatchRepository.instance.currentUserId;
    final complete = match.reserveFull;
    final startersFull = match.startersFull;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del partido')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('Fútbol 5 · ${match.zone}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(DateFormat('dd/MM/yyyy · HH:mm').format(match.startsAt), style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 4),
          Text('\$${match.price} por jugador · Nivel ${match.level.toLowerCase()}'),
          const SizedBox(height: 4),
          Text(match.venue),
          const SizedBox(height: 18),
          LinearProgressIndicator(value: match.playerCount / match.totalCapacity),
          const SizedBox(height: 8),
          Text(startersFull ? '${match.maxPlayers}/${match.maxPlayers} titulares · ${match.playerCount > match.maxPlayers ? '1/1 suplente ✓' : 'falta 1 suplente'}' : '${match.playerCount}/${match.maxPlayers} titulares · suplente pendiente', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: loading || (complete && !match.joined) ? null : toggleJoin,
            icon: Icon(match.joined ? Icons.logout : Icons.sports_soccer),
            label: Text(loading ? 'PROCESANDO...' : match.joined ? 'BAJARME DEL PARTIDO' : complete ? 'PARTIDO CUBIERTO' : startersFull ? 'SUMARME COMO SUPLENTE' : 'SUMARME AL PARTIDO'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => showMessage(context, 'El chat se agrega en la próxima etapa.'), icon: const Icon(Icons.chat_bubble_outline), label: const Text('CHAT DEL PARTIDO')),
          if (organizer) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(onPressed: complete ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => MissingOneScreen(match: match))), icon: const Icon(Icons.person_search), label: Text(startersFull ? 'BUSCAR SUPLENTE' : 'ME FALTA UNO')),
          ],
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFF111E22), borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Icon(startersFull ? Icons.health_and_safety_outlined : Icons.groups_outlined),
              const SizedBox(width: 10),
              Expanded(child: Text(startersFull
                  ? (match.playerCount > match.maxPlayers ? 'Plantel cubierto: 10 titulares + 1 suplente de seguridad.' : 'Titulares completos. Falta sumar 1 suplente de seguridad.')
                  : 'Primero completamos los titulares; luego buscamos 1 suplente de seguridad.')),
            ]),
          ),
          const SizedBox(height: 28),
          const SectionTitle(title: 'Jugadores'),
          const SizedBox(height: 12),
          ...List.generate(match.playerCount, (i) { final reserve = i >= match.maxPlayers; return ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Text('${i + 1}')), title: Text(reserve ? 'Suplente de seguridad' : (i == 0 && organizer ? 'Organizador' : 'Jugador ${i + 1}')), subtitle: Text(reserve ? 'Entra automáticamente si se libera un lugar' : (i % 3 == 0 ? 'Delantero' : i % 3 == 1 ? 'Mediocampista' : 'Defensa')), trailing: reserve ? const Chip(label: Text('SUPLENTE')) : const Icon(Icons.chevron_right)); }),
        ],
      ),
    );
  }
}

class MissingOneScreen extends StatefulWidget {
  final MatchModel match;
  const MissingOneScreen({super.key, required this.match});
  @override
  State<MissingOneScreen> createState() => _MissingOneScreenState();
}

class _MissingOneScreenState extends State<MissingOneScreen> {
  final invited = <String>{};
  final players = const [
    {'name':'Martín Silva','position':'Mediocampista','zone':'Malvín','rating':'4.8','attendance':'98%','distance':'2,1 km','team':'Los del Parque FC'},
    {'name':'Lucas Pereira','position':'Delantero','zone':'Buceo','rating':'4.7','attendance':'96%','distance':'3,4 km','team':'Barrio Unido'},
    {'name':'Nicolás Gómez','position':'Defensa','zone':'Pocitos','rating':'4.9','attendance':'100%','distance':'4,0 km','team':'Sin cuadro fijo'},
    {'name':'Facundo Rodríguez','position':'Arquero','zone':'La Blanqueada','rating':'4.6','attendance':'94%','distance':'5,2 km','team':'La 10 FC'},
  ];

  @override
  Widget build(BuildContext context) {
    final lookingReserve = widget.match.startersFull;
    return Scaffold(
      appBar: AppBar(title: Text(lookingReserve ? 'Buscar suplente' : 'Me falta uno')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Fútbol 5 · ${widget.match.zone}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('${DateFormat('dd/MM · HH:mm').format(widget.match.startsAt)} · ${widget.match.venue}'),
              const SizedBox(height: 8),
              Text(lookingReserve ? '10/10 titulares · buscamos 1 suplente de seguridad' : '${widget.match.playerCount}/${widget.match.maxPlayers} titulares · después sumamos 1 suplente', style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: const [Chip(label: Text('Posición')), Chip(label: Text('Nivel')), Chip(label: Text('Distancia')), Chip(label: Text('Disponible hoy'))]),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => setState(() { for (final p in players) invited.add(p['name']!); }),
            icon: const Icon(Icons.campaign_outlined),
            label: Text(lookingReserve ? 'INVITAR SUPLENTES COMPATIBLES' : 'INVITAR A TODOS LOS COMPATIBLES'),
          ),
          const SizedBox(height: 20),
          Text(lookingReserve ? 'Suplentes recomendados' : 'Jugadores compatibles', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...players.map((p) => Card(
            color: const Color(0xFF111E22),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  CircleAvatar(radius: 28, child: Text(p['name']!.substring(0,1))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['name']!, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text('${p['position']} · ${p['zone']}'),
                    Text('⭐ ${p['rating']} · ${p['attendance']} asistencia · ${p['distance']}'),
                    Text('🛡 ${p['team']}', style: const TextStyle(color: Color(0xFFA8B5B8))),
                  ])),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => showMessage(context, 'Perfil: ${p['name']} · historial de cuadros visible.'), child: const Text('VER PERFIL'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(
                    onPressed: invited.contains(p['name']) ? null : () => setState(() => invited.add(p['name']!)),
                    child: Text(invited.contains(p['name']) ? 'ENVIADA ✓' : 'INVITAR'),
                  )),
                ]),
              ]),
            ),
          )),
          const SizedBox(height: 8),
          const Text('La primera aceptación ocupa el lugar disponible. Si ya están los 10 titulares, la siguiente aceptación queda como suplente de seguridad. Si un titular se baja, el suplente sube automáticamente.', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class MyMatchesScreen extends StatelessWidget {
  const MyMatchesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        const Padding(padding: EdgeInsets.fromLTRB(18, 18, 18, 8), child: Align(alignment: Alignment.centerLeft, child: Text('Mis partidos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)))),
        const TabBar(tabs: [Tab(text: 'Próximos'), Tab(text: 'Organizo'), Tab(text: 'Historial')]),
        Expanded(child: FutureBuilder<List<MatchModel>>(future: MatchRepository.instance.upcoming(), builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final all = snap.data ?? [];
          final mine = all.where((m) => m.joined || m.organizerId == MatchRepository.instance.currentUserId).toList();
          final organize = all.where((m) => m.organizerId == MatchRepository.instance.currentUserId).toList();
          return TabBarView(children: [MatchList(matches: mine), MatchList(matches: organize), const Center(child: Text('Todavía no hay partidos finalizados'))]);
        })),
      ]),
    );
  }
}

class MatchList extends StatelessWidget {
  final List<MatchModel> matches;
  const MatchList({super.key, required this.matches});
  @override
  Widget build(BuildContext context) => matches.isEmpty
      ? const Center(child: Text('No hay partidos todavía.'))
      : ListView(padding: const EdgeInsets.all(18), children: matches.map((m) => Padding(padding: const EdgeInsets.only(bottom: 12), child: MatchCard(match: m, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(initialMatch: m)))))).toList());
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = AppConfig.hasSupabase ? Supabase.instance.client.auth.currentUser : null;
    final name = (user?.userMetadata?['display_name'] ?? 'Diego Velazco').toString();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(children: [
          const CircleAvatar(radius: 38, child: Icon(Icons.person, size: 38)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)), const Text('Delantero / Volante · Montevideo')])),
        ]),
        const SizedBox(height: 20),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Stat(value: '5.0', label: 'Reputación'), Stat(value: '0', label: 'Partidos'), Stat(value: '100%', label: 'Asistencia')]),
        const SizedBox(height: 26),
        const SectionTitle(title: 'Mis cuadros'),
        const SizedBox(height: 12),
        const TeamTile(name: 'Los Pibes FC', years: '2025 · Actualidad', matches: '18 partidos'),
        const TeamTile(name: 'La Banda FC', years: '2024 · 2025', matches: '11 partidos'),
        const SizedBox(height: 24),
        const SectionTitle(title: 'Historial reciente'),
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check_circle_outline), title: Text('Los Pibes FC vs La Banda'), subtitle: Text('28 AGO · Participó')),
        const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.check_circle_outline), title: Text('Partido abierto · Malvín'), subtitle: Text('21 AGO · Participó')),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: () => showMessage(context, 'Edición de perfil: próxima etapa.'), icon: const Icon(Icons.edit_outlined), label: const Text('EDITAR PERFIL')),
        if (AppConfig.hasSupabase) ...[
          const SizedBox(height: 8),
          TextButton.icon(onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout), label: const Text('Cerrar sesión')),
        ],
      ],
    );
  }
}

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback onTap;
  const MatchCard({super.key, required this.match, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final organizer = match.organizerId == MatchRepository.instance.currentUserId;
    return Card(
      color: const Color(0xFF111E22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Expanded(child: Text('Fútbol 5 · ${match.zone}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))), if (organizer) const Chip(label: Text('Organizás'))]),
            const SizedBox(height: 10),
            Text('${DateFormat('dd/MM · HH:mm').format(match.startsAt)} · \$${match.price}'),
            const SizedBox(height: 6),
            Text(match.startersFull ? '${match.maxPlayers}/${match.maxPlayers} titulares · ${match.playerCount > match.maxPlayers ? '1 suplente ✓' : 'falta suplente'} · ${match.level}' : '${match.playerCount}/${match.maxPlayers} titulares · ${match.level}'),
            const SizedBox(height: 12),
            Row(children: [const Icon(Icons.location_on_outlined, size: 18), const SizedBox(width: 4), Expanded(child: Text(match.venue)), const Icon(Icons.chevron_right)]),
          ]),
        ),
      ),
    );
  }
}

class LocalModeBanner extends StatelessWidget {
  const LocalModeBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(14)),
    child: const Row(children: [
      Icon(Icons.phone_android_outlined),
      SizedBox(width: 10),
      Expanded(child: Text('Modo local persistente. Los partidos quedan guardados en este celular. Al conectar Supabase se sincronizarán entre usuarios.')),
    ]),
  );
}

class EmptyCard extends StatelessWidget {
  final String text;
  const EmptyCard({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Card(color: const Color(0xFF111E22), child: Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(text, textAlign: TextAlign.center))));
}

class ErrorCard extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;
  const ErrorCard({super.key, required this.text, required this.onRetry});
  @override
  Widget build(BuildContext context) => Card(color: const Color(0xFF111E22), child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [Text(text), TextButton(onPressed: onRetry, child: const Text('Reintentar'))])));
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800));
}

class Stat extends StatelessWidget {
  final String value, label;
  const Stat({super.key, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: Color(0xFFA8B5B8)))]);
}

class TeamTile extends StatelessWidget {
  final String name, years, matches;
  const TeamTile({super.key, required this.name, required this.years, required this.matches});
  @override
  Widget build(BuildContext context) => Card(color: const Color(0xFF111E22), child: ListTile(leading: const CircleAvatar(child: Icon(Icons.shield_outlined)), title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('$years · $matches'), trailing: const Icon(Icons.chevron_right)));
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
