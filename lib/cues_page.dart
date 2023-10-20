import 'dart:io';

import 'package:enekeskonyv/search_song_page.dart';

import 'settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'song/song_page.dart';

class FavouritesPage extends StatelessWidget {
  const FavouritesPage(this.context, {super.key});

  final BuildContext context;

  // parse verseId list to data structure
  // Book -> Song -> Verse
  Map<String, Map<String, Set<String>>> getFavourites(List<String> verseIds) {
    Map<String, Map<String, Set<String>>> favourites = {};

    for (String id in verseIds) {
      List<String> parts = id.split('/');
      String book = parts[0];
      String song = parts[1];
      String verse = parts[2];

      if (!favourites.containsKey(book)) {
        favourites[book] = {};
      }
      if (!favourites[book]!.containsKey(song)) {
        favourites[book]![song] = {};
      }
      favourites[book]![song]!.add(verse);
    }

    return favourites;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return Scaffold(
            appBar: AppBar(
              title: const Text('Kedvencek'),
            ),
            body: Column(
              children: [
                Material(
                  elevation: 5,
                  child: Container(
                    height: 36,
                    margin: EdgeInsets.all(3),
                    padding: EdgeInsets.all(3),
                    child: ListView(
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      children: [
                        ElevatedButton.icon(
                          label: const Text('Lista beolvasás'),
                          onPressed: null, // TODO
                          icon: const Icon(Icons.qr_code_scanner),
                        ),
                        ElevatedButton.icon(
                          label: const Text('Ének hozzáfűzése'),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MySearchSongPage(
                                book: settings.book,
                                settingsProvider: settings,
                                addToCueSearch: true,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.manage_search),
                        ),
                        ElevatedButton.icon(
                          label: const Text('Új lista'),
                          onPressed: null, // TODO
                          icon: const Icon(Icons.post_add),
                        ),
                        ElevatedButton.icon(
                          label: const Text('Lista törlése'),
                          onPressed: () =>
                              settings.clearCue(settings.selectedCue),
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ReorderableListView(
                    onReorder: (oldIndex, newIndex) => settings.reorderCue(
                        settings.selectedCue, oldIndex, newIndex),
                    physics:
                        Platform.isIOS ? const BouncingScrollPhysics() : null,
                    children: getVerseTiles(settings),
                  ),
                ),
              ],
            ));
      },
    );
  }

  List<Widget> getVerseTiles(SettingsProvider settings) {
    List<Widget> verseTiles = [];

    int i = 0;
    String lastBook = "";
    String lastSong = "";
    for (String verseId in settings.getSelectedCueContent()) {
      List<String> parts = verseId.split('/');
      String bookName = parts[0];
      String songKey = parts[1];
      int verseIndex = int.parse(parts[2]);

      verseTiles.add(
        // Had to factor out for tile removing closure to work properly (???)
        verseTile(bookName, songKey, verseIndex, lastBook != bookName,
            lastSong != songKey, i, settings),
      );
      lastBook = bookName;
      lastSong = songKey;

      i++;
    }

    return verseTiles;
  }

  Widget verseTile(String bookName, String songKey, int verseIndex,
      bool newBook, bool newSong, int cueIndex, SettingsProvider settings) {
    Book book = Book.values.firstWhere((b) => b.name == bookName);
    String verse = songBooks[bookName][songKey]['texts'][verseIndex];
    String verseNumber = verse.split('.')[0];
    String verseText = verse.substring(verseNumber.length + 2);

    return InkWell(
      key: GlobalKey(),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return SongPage(
                book: book,
                songIndex: songBooks[book.name].keys.toList().indexOf(songKey),
                verseIndex: verseIndex,
                initialCueIndex: cueIndex,
              );
            },
          ),
          // request focus to show keyboard when returning from song page
        );
      },
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (newBook) ...[
                  Container(
                    margin: const EdgeInsets.only(left: 15, top: 15),
                    child: Text(
                      '${book.displayName} énekeskönyv',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                if (newSong)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 15, top: 10, bottom: 5),
                    child: Text(
                      '$songKey. ${songBooks[bookName][songKey]['title']}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                    ),
                  ),
                  margin: const EdgeInsets.only(left: 20),
                  padding: const EdgeInsets.all(11),
                  child: Row(
                    children: [
                      Text('$verseNumber. ',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Text(
                          verseText,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () =>
                settings.removeFromCueAt(settings.selectedCue, cueIndex),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 3),
            child: Icon(Icons.drag_handle),
          ),
        ],
      ),
    );
  }
}
