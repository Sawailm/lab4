import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PokemonProvider()),
      ],
      child: MaterialApp(
        title: 'Pokémon TCG',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false, // Remove the debug banner
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure the context is not used in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PokemonProvider>(context, listen: false).fetchPokemonCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokémon TCG'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const PokemonCardList(),
    );
  }
}

class PokemonProvider with ChangeNotifier {
  List<PokemonCard> _cards = [];

  List<PokemonCard> get cards => _cards;

  Future<void> fetchPokemonCards() async {
    final response = await http.get(
      Uri.parse('https://api.pokemontcg.io/v2/cards'),
      headers: {'X-Api-Key': 'YOUR_API_KEY'}, // Replace with your actual API key
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body)['data'];
      _cards = jsonData.map((data) => PokemonCard.fromJson(data)).toList();
      notifyListeners();
    } else {
      throw Exception('Failed to load Pokémon cards');
    }
  }
}

class PokemonCard {
  final String name;
  final String imageUrl;

  PokemonCard({required this.name, required this.imageUrl});

  factory PokemonCard.fromJson(Map<String, dynamic> json) {
    return PokemonCard(
      name: json['name'],
      imageUrl: json['images']['small'],
    );
  }
}

class PokemonCardList extends StatelessWidget {
  const PokemonCardList({super.key});

  @override
  Widget build(BuildContext context) {
    final pokemonProvider = Provider.of<PokemonProvider>(context);

    return pokemonProvider.cards.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      itemCount: pokemonProvider.cards.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(pokemonProvider.cards[index].name),
          leading: GestureDetector(
            onTap: () => _showCardImageDialog(context, pokemonProvider.cards[index]),
            child: SizedBox(
              width: 80, // Adjust width
              height: 100, // Adjust height
              child: Image.network(
                pokemonProvider.cards[index].imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCardImageDialog(BuildContext context, PokemonCard card) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(card.imageUrl),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  card.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
