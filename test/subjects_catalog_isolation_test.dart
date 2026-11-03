import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rshd/features/subjects/data/models/subject_model.dart';
import 'package:rshd/features/subjects/data/subjects_repository.dart';
import 'package:rshd/features/subjects/presentation/subjects_controller.dart';

class _FakeRepository implements SubjectsRepository {
  @override
  Future<List<SubjectModel>> getMySubjects() async => const [
    SubjectModel(id: 1, title: 'Forensic', enrollmentStatus: 'active'),
    SubjectModel(id: 2, title: 'Radiology', enrollmentStatus: 'active'),
  ];

  @override
  Future<List<SubjectModel>> getSubjectsCatalog({String? category}) async => [
    for (var i = 10; i < 22; i++) SubjectModel(id: i, title: 'Course $i'),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('opening a department does not replace "My courses"', () async {
    final container = ProviderContainer(
      overrides: [
        subjectsRepositoryProvider.overrideWithValue(_FakeRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(subjectsListControllerProvider.notifier).load();
    final catalog = subjectsCatalogControllerProvider('medicine');
    final keepAlive = container.listen(catalog, (_, _) {});
    await container.read(catalog.notifier).load(category: 'medicine');

    expect(container.read(catalog).subjects, hasLength(12));
    expect(
      container
          .read(subjectsListControllerProvider)
          .subjects
          .map((s) => s.title),
      ['Forensic', 'Radiology'],
    );
    keepAlive.close();
  });

  test('a refresh keeps the list on screen instead of a skeleton', () async {
    final container = ProviderContainer(
      overrides: [
        subjectsRepositoryProvider.overrideWithValue(_FakeRepository()),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(subjectsListControllerProvider.notifier);

    await notifier.load();
    final pending = notifier.load(refresh: true);
    expect(
      container.read(subjectsListControllerProvider).status,
      FeatureLoadStatus.loaded,
    );
    await pending;
  });
}
