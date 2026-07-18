import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App-wide theme mode. In-memory for the MVP like the mock repositories;
/// persist it once real storage lands.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
