import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:meu_app/firebase_options.dart';

/// Realtime Database always bound to the API root URL (no child path).
FirebaseDatabase get rtdb => FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.databaseURL,
    );
