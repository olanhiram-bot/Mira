import 'learning_journal_core.dart';

/// Diario no-op para plataformas sin sistema de archivos local (Web).
class _NoopLearningJournal implements LearningJournal {
  const _NoopLearningJournal();

  @override
  Future<void> record(LearningExample example) async {}

  @override
  Future<List<LearningExample>> readAll() async => const [];
}

Future<LearningJournal> openLearningJournal() async =>
    const _NoopLearningJournal();
