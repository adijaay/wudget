import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wudget/data/analytics_repository.dart';
import 'package:wudget/data/database.dart';

void main() {
  late WudgetDatabase db;
  late AnalyticsRepository repo;

  setUp(() {
    db = WudgetDatabase(NativeDatabase.memory());
    repo = AnalyticsRepository(db);
  });

  tearDown(() => db.close());

  test('logs an event with its props, readable back oldest first', () async {
    await repo.logEvent('pantau_viewed', props: {'variant': 'pace_first'});
    await repo.logEvent('pantau_viewed', props: {'variant': 'remaining_first'});

    final events = await repo.all();
    expect(events, hasLength(2));
    expect(events.first.name, 'pantau_viewed');
    expect(events.first.propsJson, contains('pace_first'));
    expect(events.last.propsJson, contains('remaining_first'));
  });

  test('an event with no props stores a null propsJson, not an empty fabricated object', () async {
    await repo.logEvent('app_opened');
    expect((await repo.all()).single.propsJson, isNull);
  });
}
