import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import 'audioplay/player_seekbar.dart';
import 'audioplay/control_buttons.dart';
import '../audio_data.dart';

class RadioPlayer extends StatefulWidget {
  const RadioPlayer({Key? key, required this.audioData}) : super(key: key);

  final AudioData audioData;

  @override
  _RadioState createState() => _RadioState();
}

class _RadioState extends State<RadioPlayer> {
  late AudioPlayer _player;

/*
  final _playlist = HlsAudioSource(
    Uri.parse(
        "https://di-br2e5p7r.a.eurovisionflow.net/radiodvr/otp/playlist.m3u8"),
    tag: MediaItem(
      id: '0',
      album: "radioZ",
      title: "RTV RadioZ",
      artUri: Uri.parse(
          "https://media.wnyc.org/i/1400/1400/l/80/1/ScienceFriday_WNYCStudios_1400.jpg"),
    ),
  );
*/

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

      /// HLS stream
      if (widget.audioData.url.endsWith(".m3u8")) {
        audio = HlsAudioSource(
          Uri.parse(widget.audioData.url),
          tag: MediaItem(
            id: '0',
            title: widget.audioData.title,
            artUri: Uri.parse(widget.audioData.imageUrl),
          ),
        );
      } else {
        /// regular media file
        audio = ProgressiveAudioSource(
          Uri.parse(widget.audioData.url),
          tag: MediaItem(
            id: '0',
            title: widget.audioData.title,
            artUri: Uri.parse(widget.audioData.imageUrl),
          ),
        );
      }

      await _player.setAudioSource(audio);
    } catch (e, stackTrace) {
      // TODO: Catch load errors: 404, invalid url ...
      //print("Error loading playlist: $e");
      //print(stackTrace);
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: StreamBuilder<SequenceState?>(
                  stream: _player.sequenceStateStream,
                  builder: (context, snapshot) {
                    final state = snapshot.data;
                    if (state?.sequence.isEmpty ?? true) {
                      return const SizedBox();
                    }
                    final metadata = state!.currentSource!.tag as MediaItem;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                                child:
                                    Image.network(metadata.artUri.toString())),
                          ),
                        ),
                        /*Text(metadata.album!,
                            style: Theme.of(context).textTheme.headline6),
                        Text(metadata.title),*/
                        Text(metadata.title,
                            style: Theme.of(context).textTheme.headline6),
                      ],
                    );
                  },
                ),
              ),
              ControlButtons(_player),
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
              const SizedBox(height: 10.0),
            ],
          ),
        ),
      ),
    );
  }
}
