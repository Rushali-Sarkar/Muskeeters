import 'package:flutter/cupertino.dart';

class Musique {
  String titre;
  String auteur;
  String imagePath;
  String musicUrl;

  Musique(String title, String auteur, String imagePath, String musicUrl) {
    this.titre = title;
    this.auteur = auteur;
    imagePath = 'assets/healme.png';
    this.imagePath = imagePath;
    this.musicUrl = musicUrl;
  }
}
