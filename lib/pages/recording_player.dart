import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'audioplay/player_seekbar.dart';
import 'audioplay/control_buttons.dart';
import '../audio_data.dart';
import '../auth/secrets.dart' as secret;
import 'package:pediatko/dialog.dart';

/// This is a player specifically for recordings
/// It has a different UI compared to the radio player
/// Player fetches all needed audio data, creates a fitting audio source to play
///
/// Do not remove 'hls' and 'hls_sec'
/// some files, although not live, are given in those formats
class RecordingPlayer extends StatefulWidget {
  const RecordingPlayer({Key? key, required this.audioData, this.audioDataList})
      : super(key: key);

  final AudioData audioData;
  final List<AudioData>? audioDataList;

  @override
  _RecordingState createState() => _RecordingState();
}

class _RecordingState extends State<RecordingPlayer> {
  late AudioPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      //print('A stream error occurred: $e');
    });
    try {
      final AudioSource audio;

      // fetch jwt key
      final responseJWT = await http.get(Uri.parse(
          'https://api.rtvslo.si/ava/getRecordingDrm/${widget.audioData.id}?client_id=${secret.clientId}'));

      if (responseJWT.statusCode != 200) {
        throw Exception(
            'Failed to load website for title: ${widget.audioData.title}, link: ${widget.audioData.url}');
      }

      final String jwt = json.decode(responseJWT.body)['response']['jwt'];

      // fetch mp3 file
      final responseMP3 = await http.get(Uri.parse(
          'https://api.rtvslo.si/ava/getMedia/${widget.audioData.id}?client_id=${secret.clientId}&jwt=$jwt'));

      if (responseMP3.statusCode != 200) {
        throw Exception(
            'Failed to load website for title: ${widget.audioData.title}, link: ${widget.audioData.url}');
      }

      var mp3 = json.decode(responseMP3.body);
      mp3 = mp3['response']['mediaFiles'][0]['streams'];

      // some recordings are in saved in hls, do not remove this!
      if (mp3['hls_sec'] != null) {
        mp3 = mp3['hls_sec'];

        audio = HlsAudioSource(
          Uri.parse(mp3),
          tag: MediaItem(
            id: '0',
            album: widget.audioData.showName,
            title: widget.audioData.title,
            displayDescription: widget.audioData.titleDescription,
            artUri: Uri.parse(widget.audioData.imageUrl),
          ),
        );
      } else {
        if (mp3['https'] != null) {
          mp3 = mp3['https'];
        } else if (mp3['http'] != null) {
          mp3 = mp3['http'];
        } else {
          mp3 = mp3['mpeg-dash'];
        }

        audio = ProgressiveAudioSource(
          Uri.parse(mp3),
          tag: MediaItem(
            id: '0',
            album: widget.audioData.showName,
            title: widget.audioData.title,
            displayDescription: widget.audioData.titleDescription,
            artUri: Uri.parse(widget.audioData.imageUrl),
          ),
        );
      }

      await _player.setAudioSource(audio);
      _player.play();
    } on TimeoutException {
      noInternetConnectionDialog(context, 2);
    } catch (e) {
      throw Exception('$e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          _player.positionStream,
          _player.bufferedPositionStream,
          _player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;
    final double width = MediaQuery.of(context).size.height;
    final hw = height * width;
    final iconSize = hw * 0.00020;
    //final iconSize = height * 0.169;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: widget.audioData.bgColor,
        appBar: AppBar(
          title: Image.asset('assets/pediatko-logo.png', height: 25),
          centerTitle: true,
          backgroundColor: widget.audioData.bgColor,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_downward),
            onPressed: () => Navigator.pop(context),
            color: Colors.white,
            iconSize: 30,
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              color: Colors.white),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: widget.audioData.bgColor,
                              ),
                              child: Hero(
                                tag: 'imageUrl',
                                child: Image.network(
                                  widget.audioData.imageUrl,
                                ),
                                transitionOnUserGestures: true,
                              ),
                              height: iconSize,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              widget.audioData.showName,
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: widget.audioData.bgColor),
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                widget.audioData.title,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: height * 0.25,
                              child: SingleChildScrollView(
                                child: Text(widget.audioData.titleDescription),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: SizedBox(
                    height: height * 0.18,
                    child: ControlButtons(_player,
                        audioDataList: widget.audioDataList,
                        index: widget.audioData.current),
                  ),
                ),

                StreamBuilder<PositionData>(
                  stream: _positionDataStream,
                  builder: (context, snapshot) {
                    final positionData = snapshot.data;
                    return SeekBar(
                      duration: positionData?.duration ?? Duration.zero,
                      position: positionData?.position ?? Duration.zero,
                      bufferedPosition:
                          positionData?.bufferedPosition ?? Duration.zero,
                      onChangeEnd: (newPosition) {
                        _player.seek(newPosition);
                      },
                    );
                  },
                ),
                const SizedBox(height: 30.0),
                //const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
