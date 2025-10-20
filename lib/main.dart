import 'package:fast_mobo/Login.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Login(),
      theme: ThemeData(
        primaryColor: Colors.lightGreen,
      ),
      //debugShowCheckedModeBanner: false,
    )
  );
}
