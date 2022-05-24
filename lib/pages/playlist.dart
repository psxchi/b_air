import 'package:flutter/material.dart';
import 'package:pediatko/audio_data.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage(
      {Key? key, required this.audioDataList, required this.color})
      : super(key: key);

  final List<AudioData> audioDataList;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    final Color defaultColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
        appBar: AppBar(
          title: const Text('Pediatko'),
          centerTitle: true,
          backgroundColor: color,
          elevation: 0,
        ),
        backgroundColor: color,
        body: Column(
          children: [
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image(
                  image: NetworkImage(audioDataList[0].imageUrl),
                  width: width / 3),
            ),
            const SizedBox(height: 10),
            Text(
              audioDataList[0].showName,
              style: const TextStyle(
                  fontSize: 25,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 70,
              width: width - 50,
              child: SingleChildScrollView(
                child: Text(
                  audioDataList[0].showDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
            const Spacer(
              flex: 1,
            ),
            Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 247, 249, 255),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
              ),
              child: SizedBox(
                height: height / 2,
                child: ListView.builder(
                    itemCount: audioDataList.length,
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemBuilder: (BuildContext context, int index) {
                      return GestureDetector(
                        onTap: () {
                          audioDataList[index].playAudio(context, color);
                        },
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const SizedBox(height: 50, width: 20),
                                Icon(Icons.play_circle_fill_rounded,
                                    size: 40, color: defaultColor),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Text(
                                      audioDataList[index].title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            divideBetween(audioDataList.length, index),
                          ],
                        ),
                      );
                    }),
              ),
            ),
          ],
        ));
  }

  divideBetween(int listLength, int index) {
    return listLength > (index + 1)
        ? const Divider(
            color: Color.fromARGB(30, 0, 0, 0),
            indent: 20,
            endIndent: 20,
            thickness: 3,
          )
        : const SizedBox(height: 5);
  }
}