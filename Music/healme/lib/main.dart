import 'dart:async';

import 'package:audioplayer/audioplayer.dart';
import 'package:flutter/material.dart';
import 'package:volume/volume.dart';
import 'const.dart';
import 'custom_button.dart';
import 'music.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealMe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: new AppBar(
          backgroundColor: AppColors.darkBlue,
          title: new Text("HealMe"),
        ),
        body: DetailPage(title: 'HealMe'),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DetailPage extends StatefulWidget {
  DetailPage(
      {Key key,
      this.title,
      this.sliderHeight = 48,
      this.min = 0,
      this.max = 10,
      this.fullWidth = false})
      : super(key: key);
  final String title;
  final double sliderHeight;
  final int min;
  final int max;
  final fullWidth;

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  double _value = 0;
  List<Musique> musique_list = [
    Musique('Heavy Heart', 'Kevin MacLeod', 'assets/healme.png',
        'https://ia801901.us.archive.org/0/items/kevin-mac-leod-heavy-heart/KevinMacLeod-HeavyHeart.mp3'),
    Musique('Sleep', 'Scott Buckley', 'assets/healme.png',
        'https://ia801404.us.archive.org/7/items/scott-buckley-sleep/ScottBuckley-Sleep.mp3'),
    Musique('Cherry Picking', 'Erothyme', 'assets/healme.png',
        'https://ia803201.us.archive.org/20/items/erothyme-cherry-picking/Erothyme-CherryPicking.mp3'),
    Musique('Night', 'Cloudkicker', 'assets/healme.png',
        'https://ia802803.us.archive.org/15/items/cloudkickernight/Cloudkicker_Night.mp3'),
    Musique('Shape of You', 'Ed Sheeran', 'assets/healme.png',
        'https://lliliii.lillill.li/mp3/hq/BLACKPINK_%E2%80%93_%E2%80%98Lovesick_Girls%E2%80%99_M_V.mp3')
  ];

  AudioPlayer audioPlayer;
  StreamSubscription positionSubscription;
  StreamSubscription stateSubscription;

  Musique actualMusic;
  Duration position = Duration(seconds: 0);
  Duration duree = Duration(seconds: 0);
  PlayerState status = PlayerState.STOPPED;
  int index = 0;
  bool mute = false;
  int maxVol = 0;
  int currentVol = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    actualMusic = musique_list[index];
    configAudioPlayer();
    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    double paddingFactor = .2;
    double largeur = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              left: 7,
              right: 7,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                CustomButtonWidget(
                  size: 50,
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.styleColor,
                  ),
                ),
                Text(
                  'Playing Now',
                  style: TextStyle(
                    color: AppColors.styleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CustomButtonWidget(
                  size: 50,
                  onTap: () {},
                  child: Icon(
                    Icons.menu,
                    color: AppColors.styleColor,
                  ),
                ),
              ],
            ),
          ),
          CustomButtonWidget(
            image: actualMusic.imagePath,
            size: MediaQuery.of(context).size.width * .7,
            borderWidth: 5,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DetailPage(),
                ),
              );
            },
          ),
          Text(
            actualMusic.titre,
            style: TextStyle(
              color: AppColors.styleColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 2,
            ),
          ),
          Text(
            actualMusic.auteur,
            style: TextStyle(
              color: AppColors.styleColor.withAlpha(90),
              fontSize: 16,
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 10.0, right: 10.0),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.darkBlue,
                inactiveTrackColor: AppColors.lightBlue,
                overlayColor: AppColors.lightBlue,
                activeTickMarkColor: Colors.white,
                inactiveTickMarkColor: Colors.red.withOpacity(.7),
              ),
              child: Slider(
                  value: position.inSeconds.toDouble(),
                  min: 0.0,
                  max: duree.inSeconds.toDouble(),
                  onChanged: (double d) {
                    setState(() {
                      audioPlayer.seek(d);
                    });
                  }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                CustomButtonWidget(
                  size: 80,
                  onTap: () {
                    rewind();
                  },
                  child: Icon(
                    Icons.fast_rewind,
                    color: AppColors.styleColor,
                  ),
                  borderWidth: 5,
                ),
                CustomButtonWidget(
                  size: 80,
                  onTap: (status != PlayerState.PLAYING) ? play : pause,
                  child: (status != PlayerState.PLAYING)
                      ? Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                        )
                      : Icon(
                          Icons.pause,
                          color: Colors.white,
                        ),
                  isActive: true,
                  borderWidth: 5,
                ),
                CustomButtonWidget(
                  size: 80,
                  onTap: forward,
                  child: Icon(
                    Icons.fast_forward,
                    color: AppColors.styleColor,
                  ),
                  borderWidth: 5,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 25,
          ),
        ],
      ),
    );
  }

  /// Initialialiser le volume
  Future<void> initPlatformState() async {
    await Volume.controlVolume(AudioManager.STREAM_MUSIC);
  }

  /// Gestion des texte avec style
  Text textWithStyle(String data, double scale) {
    return Text(
      data,
      textScaleFactor: scale,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.black, fontSize: 15.0),
    );
  }

  /// Gestion des boutons
  IconButton boutton(IconData icone, double taille, ActionMusic action) {
    return IconButton(
      icon: Icon(icone),
      iconSize: taille,
      color: Colors.white,
      onPressed: () {
        switch (action) {
          case ActionMusic.PLAY:
            play();
            break;
          case ActionMusic.PAUSE:
            pause();
            break;
          case ActionMusic.REWIND:
            rewind();
            break;
          case ActionMusic.FORWARD:
            forward();
            break;
          default:
            break;
        }
      },
    );
  }

  void configAudioPlayer() {
    audioPlayer = AudioPlayer();
    positionSubscription = audioPlayer.onAudioPositionChanged.listen((event) {
      setState(() {
        position = event;
      });
      if (position >= duree) {
        position = Duration(seconds: 0);
        // Passer à la musique suivante
      }
    });

    stateSubscription = audioPlayer.onPlayerStateChanged.listen((event) {
      if (event == AudioPlayerState.PLAYING) {
        setState(() {
          duree = audioPlayer.duration;
        });
      } else if (event == AudioPlayerState.STOPPED) {
        setState(() {
          status = PlayerState.STOPPED;
        });
      }
    }, onError: (message) {
      print(message);
      setState(() {
        status = PlayerState.STOPPED;
        duree = Duration(seconds: 0);
        position = Duration(seconds: 0);
      });
    });
  }

  Future play() async {
    await audioPlayer.play(actualMusic.musicUrl);
    setState(() {
      status = PlayerState.PLAYING;
    });
  }

  Future pause() async {
    await audioPlayer.pause();
    setState(() {
      status = PlayerState.PAUSED;
    });
  }

  Future muted() async {
    await audioPlayer.mute(!mute);
    setState(() {
      mute = !mute;
    });
  }

  void forward() {
    if (index == musique_list.length - 1) {
      index = 0;
    } else {
      index++;
    }
    actualMusic = musique_list[index];
    audioPlayer.stop();
    configAudioPlayer();
    play();
  }

  void rewind() {
    if (position > Duration(seconds: 3)) {
      audioPlayer.seek(0.0);
    } else {
      if (index == 0) {
        index = musique_list.length - 1;
      } else {
        index--;
      }
    }
    actualMusic = musique_list[index];
    audioPlayer.stop();
    configAudioPlayer();
    play();
  }

  String fromDuration(Duration duration) {
    return duration.toString().split('.').first;
  }
}

enum ActionMusic { PLAY, PAUSE, REWIND, FORWARD }

enum PlayerState { PLAYING, STOPPED, PAUSED }
