import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  primaryColor: Colors.white,
  useMaterial3: true,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.black,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.grey,
    selectedIconTheme: IconThemeData(color: Colors.white),
  ),
  iconTheme: const IconThemeData(color: Colors.white),
  textTheme: GoogleFonts.urbanistTextTheme().apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),
  switchTheme: SwitchThemeData(
    thumbColor: MaterialStatePropertyAll(Colors.white),
    trackColor: MaterialStatePropertyAll(Color(0xFF333333)),
  ),
);

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  primaryColor: Colors.black,
  useMaterial3: true,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    elevation: 0,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: Colors.black,
    unselectedItemColor: Colors.grey,
    selectedIconTheme: IconThemeData(color: Colors.black),
  ),
  iconTheme: const IconThemeData(color: Colors.black),
  textTheme: GoogleFonts.urbanistTextTheme().apply(
    bodyColor: Colors.black,
    displayColor: Colors.black,
  ),
  switchTheme: const SwitchThemeData(
    thumbColor: MaterialStatePropertyAll(Colors.black),
    trackColor: MaterialStatePropertyAll(Color(0xFFE0E0E0)),
  ),
);
