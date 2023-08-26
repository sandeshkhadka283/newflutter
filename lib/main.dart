import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PokemonApp(),
  ));
}

class PokemonApp extends StatelessWidget {
  const PokemonApp({Key? key}) : super(key: key);

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
  const PokemonListScreen({Key? key}) : super(key: key);

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

  int calculateCrossAxisCount(double screenWidth) {
    if (screenWidth >= 600) {
      return 3; // Use 3 columns on larger screens
    } else if (screenWidth >= 400) {
      return 2; // Use 2 columns on medium screens
    } else {
      return 1; // Use 1 column on small screens
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(60.0),
                  child: TextField(
                    onChanged: (value) => filterPokemon(value.toLowerCase()),
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      labelText: 'Search Pokemon',
                      labelStyle:
                          const TextStyle(color: Colors.black, fontSize: 12),
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      filled: true,
                      fillColor:
                          Theme.of(context).primaryColor.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
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
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                calculateCrossAxisCount(screenWidth),
                            childAspectRatio: screenWidth < 600
                                ? 2 // Adjust aspect ratio for mobile
                                : 4, // Adjust aspect ratio for desktop
                          ),
                          itemCount: displayedPokemon.length,
                          itemBuilder: (context, index) {
                            final pokemon = displayedPokemon[index];
                            return InkWell(
                              onTap: () {},
                              child: Card(
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Container(
                                  constraints: BoxConstraints(
                                    maxHeight: screenWidth < 600
                                        ? double.infinity
                                        : 150, // Set maximum card height here
                                  ),
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
                              ),
                            );
                          },
                        ),
                      ),
              ],
            );
          },
        ),
      ),
    );
  }
}
