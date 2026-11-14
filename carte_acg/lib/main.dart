import 'package:material_ui/material_ui.dart';

import 'config.dart';
import 'screens/contacts_screen.dart';
import 'screens/my_card_screen.dart';

void main() => runApp(const CarteAcgApp());

class CarteAcgApp extends StatelessWidget {
  const CarteAcgApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: kBordeaux,
      primary: kBordeaux,
    );
    return MaterialApp(
      title: 'Carte ACG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        fontFamily: 'Montserrat',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: kBordeaux,
          foregroundColor: Colors.white,
          centerTitle: false,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [MyCardScreen(), ContactsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            label: 'Ma carte',
          ),
          NavigationDestination(
            icon: Icon(Icons.contacts_outlined),
            label: 'Contacts',
          ),
        ],
      ),
    );
  }
}
