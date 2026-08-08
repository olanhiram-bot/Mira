export 'learning_journal_core.dart';

import 'learning_journal_core.dart';
import 'learning_journal_stub.dart'
    if (dart.library.io) 'learning_journal_io.dart'
    as impl;

/// Abre el diario de aprendizaje local de la plataforma.
///
/// En Android almacena los ejemplos en el directorio privado de la app.
/// En Web devuelve un diario no-op: no hay sistema de archivos local.
Future<LearningJournal> openLearningJournal() => impl.openLearningJournal();
