// Favourite books, stored on the phone.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalogue.dart';
import '../l10n/strings.dart';
import '../services/store.dart';
import 'book_tile.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final favs = libraryBooks
        .where((b) => state.isFavorite(b.id))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, 'favorites'))),
      body: favs.isEmpty
          ? Center(child: Text(tr(context, 'noFavorites')))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: favs.length,
              itemBuilder: (context, index) => BookTile(book: favs[index]),
            ),
    );
  }
}
