import 'package:flutter_riverpod/legacy.dart';

final checkConnectionProvider = StateProvider.autoDispose<bool>((ref) => false);
