import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const PokemonApp());
}

class PokemonApp extends StatelessWidget {
  const PokemonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Colors.orangeAccent,
        fontFamily: 'Roboto',
      ),
      home: PokemonListScreen(),
    );
  }
}

class Pokemon {
  final String name;
  final String imageUrl;
  final List<String> types;

  Pokemon(this.name, this.imageUrl, this.types);
}

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({super.key});

  @override
  _PokemonListScreenState createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  List<Pokemon> allPokemon = [];
  List<Pokemon> displayedPokemon = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPokemonData();
  }

  void fetchPokemonData() async {
    final response =
        await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final pokemonList = data['results'] as List<dynamic>;

      allPokemon =
          await Future.wait(pokemonList.map<Future<Pokemon>>((pokemon) async {
        final name = pokemon['name'];
        final pokemonInfoResponse = await http.get(Uri.parse(pokemon['url']));
        final pokemonInfo = json.decode(pokemonInfoResponse.body);
        final types = (pokemonInfo['types'] as List<dynamic>)
            .map((type) => type['type']['name'] as String)
            .toList();

        final imageUrl = pokemonInfo['sprites']['front_default'] as String;

        return Pokemon(name, imageUrl, types);
      }));

      setState(() {
        displayedPokemon = allPokemon;
        isLoading = false;
      });
    }
  }

  void filterPokemon(String keyword) {
    setState(() {
      displayedPokemon = allPokemon
          .where((pokemon) => pokemon.name.contains(keyword))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) => filterPokemon(value.toLowerCase()),
                style:
                    const TextStyle(color: Colors.black), // Change text color
                decoration: InputDecoration(
                  labelText: 'Search Pokemon',
                  labelStyle:
                      const TextStyle(color: Colors.black, fontSize: 12),
                  prefixIcon: const Icon(Icons.search,
                      color: Colors.black), // Change icon color
                  filled: true,
                  fillColor: Theme.of(context)
                      .primaryColor
                      .withOpacity(0.05), // Change field background color
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none, // Hide border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: Theme.of(context)
                            .primaryColor), // Change border color
                  ),
                ),
              ),
            ),
            isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: displayedPokemon.length,
                      itemBuilder: (context, index) {
                        final pokemon = displayedPokemon[index];
                        return InkWell(
                          onTap: () {},
                          child: Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: Image.network(pokemon.imageUrl),
                              title: Text(
                                pokemon.name.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                pokemon.types.join(', '),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
