// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _providerKeyMeta =
      const VerificationMeta('providerKey');
  @override
  late final GeneratedColumn<String> providerKey = GeneratedColumn<String>(
      'provider_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _openingMinorMeta =
      const VerificationMeta('openingMinor');
  @override
  late final GeneratedColumn<int> openingMinor = GeneratedColumn<int>(
      'opening_minor', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statementDayMeta =
      const VerificationMeta('statementDay');
  @override
  late final GeneratedColumn<int> statementDay = GeneratedColumn<int>(
      'statement_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
      'due_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _creditLimitMinorMeta =
      const VerificationMeta('creditLimitMinor');
  @override
  late final GeneratedColumn<int> creditLimitMinor = GeneratedColumn<int>(
      'credit_limit_minor', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
      'archived_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _visibilityMeta =
      const VerificationMeta('visibility');
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
      'visibility', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('private'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        type,
        providerKey,
        currency,
        openingMinor,
        statementDay,
        dueDay,
        creditLimitMinor,
        archivedAt,
        householdId,
        visibility,
        updatedAt,
        deletedAt,
        deviceId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(Insertable<Account> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('provider_key')) {
      context.handle(
          _providerKeyMeta,
          providerKey.isAcceptableOrUnknown(
              data['provider_key']!, _providerKeyMeta));
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('opening_minor')) {
      context.handle(
          _openingMinorMeta,
          openingMinor.isAcceptableOrUnknown(
              data['opening_minor']!, _openingMinorMeta));
    }
    if (data.containsKey('statement_day')) {
      context.handle(
          _statementDayMeta,
          statementDay.isAcceptableOrUnknown(
              data['statement_day']!, _statementDayMeta));
    }
    if (data.containsKey('due_day')) {
      context.handle(_dueDayMeta,
          dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta));
    }
    if (data.containsKey('credit_limit_minor')) {
      context.handle(
          _creditLimitMinorMeta,
          creditLimitMinor.isAcceptableOrUnknown(
              data['credit_limit_minor']!, _creditLimitMinorMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    }
    if (data.containsKey('visibility')) {
      context.handle(
          _visibilityMeta,
          visibility.isAcceptableOrUnknown(
              data['visibility']!, _visibilityMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      providerKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}provider_key']),
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      openingMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}opening_minor'])!,
      statementDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}statement_day']),
      dueDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}due_day']),
      creditLimitMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}credit_limit_minor']),
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}archived_at']),
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      visibility: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}visibility'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id']),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String name;
  final String type;
  final String? providerKey;
  final String currency;
  final int openingMinor;
  final int? statementDay;
  final int? dueDay;
  final int? creditLimitMinor;
  final int? archivedAt;
  final String? householdId;
  final String visibility;
  final int updatedAt;
  final int? deletedAt;
  final String? deviceId;
  const Account(
      {required this.id,
      required this.name,
      required this.type,
      this.providerKey,
      required this.currency,
      required this.openingMinor,
      this.statementDay,
      this.dueDay,
      this.creditLimitMinor,
      this.archivedAt,
      this.householdId,
      required this.visibility,
      required this.updatedAt,
      this.deletedAt,
      this.deviceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || providerKey != null) {
      map['provider_key'] = Variable<String>(providerKey);
    }
    map['currency'] = Variable<String>(currency);
    map['opening_minor'] = Variable<int>(openingMinor);
    if (!nullToAbsent || statementDay != null) {
      map['statement_day'] = Variable<int>(statementDay);
    }
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<int>(dueDay);
    }
    if (!nullToAbsent || creditLimitMinor != null) {
      map['credit_limit_minor'] = Variable<int>(creditLimitMinor);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(archivedAt);
    }
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    map['visibility'] = Variable<String>(visibility);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      providerKey: providerKey == null && nullToAbsent
          ? const Value.absent()
          : Value(providerKey),
      currency: Value(currency),
      openingMinor: Value(openingMinor),
      statementDay: statementDay == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDay),
      dueDay:
          dueDay == null && nullToAbsent ? const Value.absent() : Value(dueDay),
      creditLimitMinor: creditLimitMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimitMinor),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      visibility: Value(visibility),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      providerKey: serializer.fromJson<String?>(json['providerKey']),
      currency: serializer.fromJson<String>(json['currency']),
      openingMinor: serializer.fromJson<int>(json['openingMinor']),
      statementDay: serializer.fromJson<int?>(json['statementDay']),
      dueDay: serializer.fromJson<int?>(json['dueDay']),
      creditLimitMinor: serializer.fromJson<int?>(json['creditLimitMinor']),
      archivedAt: serializer.fromJson<int?>(json['archivedAt']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      visibility: serializer.fromJson<String>(json['visibility']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'providerKey': serializer.toJson<String?>(providerKey),
      'currency': serializer.toJson<String>(currency),
      'openingMinor': serializer.toJson<int>(openingMinor),
      'statementDay': serializer.toJson<int?>(statementDay),
      'dueDay': serializer.toJson<int?>(dueDay),
      'creditLimitMinor': serializer.toJson<int?>(creditLimitMinor),
      'archivedAt': serializer.toJson<int?>(archivedAt),
      'householdId': serializer.toJson<String?>(householdId),
      'visibility': serializer.toJson<String>(visibility),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
    };
  }

  Account copyWith(
          {String? id,
          String? name,
          String? type,
          Value<String?> providerKey = const Value.absent(),
          String? currency,
          int? openingMinor,
          Value<int?> statementDay = const Value.absent(),
          Value<int?> dueDay = const Value.absent(),
          Value<int?> creditLimitMinor = const Value.absent(),
          Value<int?> archivedAt = const Value.absent(),
          Value<String?> householdId = const Value.absent(),
          String? visibility,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent(),
          Value<String?> deviceId = const Value.absent()}) =>
      Account(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        providerKey: providerKey.present ? providerKey.value : this.providerKey,
        currency: currency ?? this.currency,
        openingMinor: openingMinor ?? this.openingMinor,
        statementDay:
            statementDay.present ? statementDay.value : this.statementDay,
        dueDay: dueDay.present ? dueDay.value : this.dueDay,
        creditLimitMinor: creditLimitMinor.present
            ? creditLimitMinor.value
            : this.creditLimitMinor,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
        householdId: householdId.present ? householdId.value : this.householdId,
        visibility: visibility ?? this.visibility,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        deviceId: deviceId.present ? deviceId.value : this.deviceId,
      );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      providerKey:
          data.providerKey.present ? data.providerKey.value : this.providerKey,
      currency: data.currency.present ? data.currency.value : this.currency,
      openingMinor: data.openingMinor.present
          ? data.openingMinor.value
          : this.openingMinor,
      statementDay: data.statementDay.present
          ? data.statementDay.value
          : this.statementDay,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      creditLimitMinor: data.creditLimitMinor.present
          ? data.creditLimitMinor.value
          : this.creditLimitMinor,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      visibility:
          data.visibility.present ? data.visibility.value : this.visibility,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('providerKey: $providerKey, ')
          ..write('currency: $currency, ')
          ..write('openingMinor: $openingMinor, ')
          ..write('statementDay: $statementDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('creditLimitMinor: $creditLimitMinor, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('householdId: $householdId, ')
          ..write('visibility: $visibility, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      type,
      providerKey,
      currency,
      openingMinor,
      statementDay,
      dueDay,
      creditLimitMinor,
      archivedAt,
      householdId,
      visibility,
      updatedAt,
      deletedAt,
      deviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.providerKey == this.providerKey &&
          other.currency == this.currency &&
          other.openingMinor == this.openingMinor &&
          other.statementDay == this.statementDay &&
          other.dueDay == this.dueDay &&
          other.creditLimitMinor == this.creditLimitMinor &&
          other.archivedAt == this.archivedAt &&
          other.householdId == this.householdId &&
          other.visibility == this.visibility &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> providerKey;
  final Value<String> currency;
  final Value<int> openingMinor;
  final Value<int?> statementDay;
  final Value<int?> dueDay;
  final Value<int?> creditLimitMinor;
  final Value<int?> archivedAt;
  final Value<String?> householdId;
  final Value<String> visibility;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String?> deviceId;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.providerKey = const Value.absent(),
    this.currency = const Value.absent(),
    this.openingMinor = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.creditLimitMinor = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.householdId = const Value.absent(),
    this.visibility = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String name,
    required String type,
    this.providerKey = const Value.absent(),
    required String currency,
    this.openingMinor = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.creditLimitMinor = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.householdId = const Value.absent(),
    this.visibility = const Value.absent(),
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        type = Value(type),
        currency = Value(currency),
        updatedAt = Value(updatedAt);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? providerKey,
    Expression<String>? currency,
    Expression<int>? openingMinor,
    Expression<int>? statementDay,
    Expression<int>? dueDay,
    Expression<int>? creditLimitMinor,
    Expression<int>? archivedAt,
    Expression<String>? householdId,
    Expression<String>? visibility,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (providerKey != null) 'provider_key': providerKey,
      if (currency != null) 'currency': currency,
      if (openingMinor != null) 'opening_minor': openingMinor,
      if (statementDay != null) 'statement_day': statementDay,
      if (dueDay != null) 'due_day': dueDay,
      if (creditLimitMinor != null) 'credit_limit_minor': creditLimitMinor,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (householdId != null) 'household_id': householdId,
      if (visibility != null) 'visibility': visibility,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? type,
      Value<String?>? providerKey,
      Value<String>? currency,
      Value<int>? openingMinor,
      Value<int?>? statementDay,
      Value<int?>? dueDay,
      Value<int?>? creditLimitMinor,
      Value<int?>? archivedAt,
      Value<String?>? householdId,
      Value<String>? visibility,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<String?>? deviceId,
      Value<int>? rowid}) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      providerKey: providerKey ?? this.providerKey,
      currency: currency ?? this.currency,
      openingMinor: openingMinor ?? this.openingMinor,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      creditLimitMinor: creditLimitMinor ?? this.creditLimitMinor,
      archivedAt: archivedAt ?? this.archivedAt,
      householdId: householdId ?? this.householdId,
      visibility: visibility ?? this.visibility,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (providerKey.present) {
      map['provider_key'] = Variable<String>(providerKey.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (openingMinor.present) {
      map['opening_minor'] = Variable<int>(openingMinor.value);
    }
    if (statementDay.present) {
      map['statement_day'] = Variable<int>(statementDay.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (creditLimitMinor.present) {
      map['credit_limit_minor'] = Variable<int>(creditLimitMinor.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(archivedAt.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('providerKey: $providerKey, ')
          ..write('currency: $currency, ')
          ..write('openingMinor: $openingMinor, ')
          ..write('statementDay: $statementDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('creditLimitMinor: $creditLimitMinor, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('householdId: $householdId, ')
          ..write('visibility: $visibility, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconKeyMeta =
      const VerificationMeta('iconKey');
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
      'icon_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _hueIndexMeta =
      const VerificationMeta('hueIndex');
  @override
  late final GeneratedColumn<int> hueIndex = GeneratedColumn<int>(
      'hue_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isIrregularMeta =
      const VerificationMeta('isIrregular');
  @override
  late final GeneratedColumn<bool> isIrregular = GeneratedColumn<bool>(
      'is_irregular', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_irregular" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        parentId,
        name,
        kind,
        iconKey,
        hueIndex,
        isIrregular,
        sortOrder,
        updatedAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(_iconKeyMeta,
          iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta));
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('hue_index')) {
      context.handle(_hueIndexMeta,
          hueIndex.isAcceptableOrUnknown(data['hue_index']!, _hueIndexMeta));
    } else if (isInserting) {
      context.missing(_hueIndexMeta);
    }
    if (data.containsKey('is_irregular')) {
      context.handle(
          _isIrregularMeta,
          isIrregular.isAcceptableOrUnknown(
              data['is_irregular']!, _isIrregularMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      iconKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_key'])!,
      hueIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}hue_index'])!,
      isIrregular: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_irregular'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String? parentId;
  final String name;
  final String kind;
  final String iconKey;
  final int hueIndex;
  final bool isIrregular;
  final int sortOrder;
  final int updatedAt;
  final int? deletedAt;
  const Category(
      {required this.id,
      this.parentId,
      required this.name,
      required this.kind,
      required this.iconKey,
      required this.hueIndex,
      required this.isIrregular,
      required this.sortOrder,
      required this.updatedAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['icon_key'] = Variable<String>(iconKey);
    map['hue_index'] = Variable<int>(hueIndex);
    map['is_irregular'] = Variable<bool>(isIrregular);
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      name: Value(name),
      kind: Value(kind),
      iconKey: Value(iconKey),
      hueIndex: Value(hueIndex),
      isIrregular: Value(isIrregular),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      hueIndex: serializer.fromJson<int>(json['hueIndex']),
      isIrregular: serializer.fromJson<bool>(json['isIrregular']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'iconKey': serializer.toJson<String>(iconKey),
      'hueIndex': serializer.toJson<int>(hueIndex),
      'isIrregular': serializer.toJson<bool>(isIrregular),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  Category copyWith(
          {String? id,
          Value<String?> parentId = const Value.absent(),
          String? name,
          String? kind,
          String? iconKey,
          int? hueIndex,
          bool? isIrregular,
          int? sortOrder,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent()}) =>
      Category(
        id: id ?? this.id,
        parentId: parentId.present ? parentId.value : this.parentId,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        iconKey: iconKey ?? this.iconKey,
        hueIndex: hueIndex ?? this.hueIndex,
        isIrregular: isIrregular ?? this.isIrregular,
        sortOrder: sortOrder ?? this.sortOrder,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      hueIndex: data.hueIndex.present ? data.hueIndex.value : this.hueIndex,
      isIrregular:
          data.isIrregular.present ? data.isIrregular.value : this.isIrregular,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('iconKey: $iconKey, ')
          ..write('hueIndex: $hueIndex, ')
          ..write('isIrregular: $isIrregular, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, parentId, name, kind, iconKey, hueIndex,
      isIrregular, sortOrder, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.iconKey == this.iconKey &&
          other.hueIndex == this.hueIndex &&
          other.isIrregular == this.isIrregular &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> iconKey;
  final Value<int> hueIndex;
  final Value<bool> isIrregular;
  final Value<int> sortOrder;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.hueIndex = const Value.absent(),
    this.isIrregular = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String name,
    required String kind,
    required String iconKey,
    required int hueIndex,
    this.isIrregular = const Value.absent(),
    required int sortOrder,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        kind = Value(kind),
        iconKey = Value(iconKey),
        hueIndex = Value(hueIndex),
        sortOrder = Value(sortOrder),
        updatedAt = Value(updatedAt);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? iconKey,
    Expression<int>? hueIndex,
    Expression<bool>? isIrregular,
    Expression<int>? sortOrder,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (iconKey != null) 'icon_key': iconKey,
      if (hueIndex != null) 'hue_index': hueIndex,
      if (isIrregular != null) 'is_irregular': isIrregular,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith(
      {Value<String>? id,
      Value<String?>? parentId,
      Value<String>? name,
      Value<String>? kind,
      Value<String>? iconKey,
      Value<int>? hueIndex,
      Value<bool>? isIrregular,
      Value<int>? sortOrder,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      iconKey: iconKey ?? this.iconKey,
      hueIndex: hueIndex ?? this.hueIndex,
      isIrregular: isIrregular ?? this.isIrregular,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (hueIndex.present) {
      map['hue_index'] = Variable<int>(hueIndex.value);
    }
    if (isIrregular.present) {
      map['is_irregular'] = Variable<bool>(isIrregular.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('iconKey: $iconKey, ')
          ..write('hueIndex: $hueIndex, ')
          ..write('isIrregular: $isIrregular, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _tzOffsetMinutesMeta =
      const VerificationMeta('tzOffsetMinutes');
  @override
  late final GeneratedColumn<int> tzOffsetMinutes = GeneratedColumn<int>(
      'tz_offset_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _photoPathMeta =
      const VerificationMeta('photoPath');
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
      'photo_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _recurrenceIdMeta =
      const VerificationMeta('recurrenceId');
  @override
  late final GeneratedColumn<String> recurrenceId = GeneratedColumn<String>(
      'recurrence_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isProjectedMeta =
      const VerificationMeta('isProjected');
  @override
  late final GeneratedColumn<bool> isProjected = GeneratedColumn<bool>(
      'is_projected', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_projected" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _householdIdMeta =
      const VerificationMeta('householdId');
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
      'household_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _visibilityMeta =
      const VerificationMeta('visibility');
  @override
  late final GeneratedColumn<String> visibility = GeneratedColumn<String>(
      'visibility', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('private'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deviceIdMeta =
      const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
      'device_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kind,
        occurredAt,
        tzOffsetMinutes,
        title,
        note,
        photoPath,
        recurrenceId,
        isProjected,
        lat,
        lon,
        householdId,
        visibility,
        updatedAt,
        deletedAt,
        deviceId
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<Transaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('tz_offset_minutes')) {
      context.handle(
          _tzOffsetMinutesMeta,
          tzOffsetMinutes.isAcceptableOrUnknown(
              data['tz_offset_minutes']!, _tzOffsetMinutesMeta));
    } else if (isInserting) {
      context.missing(_tzOffsetMinutesMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('photo_path')) {
      context.handle(_photoPathMeta,
          photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta));
    }
    if (data.containsKey('recurrence_id')) {
      context.handle(
          _recurrenceIdMeta,
          recurrenceId.isAcceptableOrUnknown(
              data['recurrence_id']!, _recurrenceIdMeta));
    }
    if (data.containsKey('is_projected')) {
      context.handle(
          _isProjectedMeta,
          isProjected.isAcceptableOrUnknown(
              data['is_projected']!, _isProjectedMeta));
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    }
    if (data.containsKey('household_id')) {
      context.handle(
          _householdIdMeta,
          householdId.isAcceptableOrUnknown(
              data['household_id']!, _householdIdMeta));
    }
    if (data.containsKey('visibility')) {
      context.handle(
          _visibilityMeta,
          visibility.isAcceptableOrUnknown(
              data['visibility']!, _visibilityMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta,
          deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}occurred_at'])!,
      tzOffsetMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tz_offset_minutes'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      photoPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_path']),
      recurrenceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recurrence_id']),
      isProjected: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_projected'])!,
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat']),
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon']),
      householdId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}household_id']),
      visibility: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}visibility'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
      deviceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_id']),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String kind;
  final int occurredAt;
  final int tzOffsetMinutes;
  final String? title;
  final String? note;
  final String? photoPath;
  final String? recurrenceId;
  final bool isProjected;
  final double? lat;
  final double? lon;
  final String? householdId;
  final String visibility;
  final int updatedAt;
  final int? deletedAt;
  final String? deviceId;
  const Transaction(
      {required this.id,
      required this.kind,
      required this.occurredAt,
      required this.tzOffsetMinutes,
      this.title,
      this.note,
      this.photoPath,
      this.recurrenceId,
      required this.isProjected,
      this.lat,
      this.lon,
      this.householdId,
      required this.visibility,
      required this.updatedAt,
      this.deletedAt,
      this.deviceId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['occurred_at'] = Variable<int>(occurredAt);
    map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || recurrenceId != null) {
      map['recurrence_id'] = Variable<String>(recurrenceId);
    }
    map['is_projected'] = Variable<bool>(isProjected);
    if (!nullToAbsent || lat != null) {
      map['lat'] = Variable<double>(lat);
    }
    if (!nullToAbsent || lon != null) {
      map['lon'] = Variable<double>(lon);
    }
    if (!nullToAbsent || householdId != null) {
      map['household_id'] = Variable<String>(householdId);
    }
    map['visibility'] = Variable<String>(visibility);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      kind: Value(kind),
      occurredAt: Value(occurredAt),
      tzOffsetMinutes: Value(tzOffsetMinutes),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      recurrenceId: recurrenceId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceId),
      isProjected: Value(isProjected),
      lat: lat == null && nullToAbsent ? const Value.absent() : Value(lat),
      lon: lon == null && nullToAbsent ? const Value.absent() : Value(lon),
      householdId: householdId == null && nullToAbsent
          ? const Value.absent()
          : Value(householdId),
      visibility: Value(visibility),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
      tzOffsetMinutes: serializer.fromJson<int>(json['tzOffsetMinutes']),
      title: serializer.fromJson<String?>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      recurrenceId: serializer.fromJson<String?>(json['recurrenceId']),
      isProjected: serializer.fromJson<bool>(json['isProjected']),
      lat: serializer.fromJson<double?>(json['lat']),
      lon: serializer.fromJson<double?>(json['lon']),
      householdId: serializer.fromJson<String?>(json['householdId']),
      visibility: serializer.fromJson<String>(json['visibility']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'occurredAt': serializer.toJson<int>(occurredAt),
      'tzOffsetMinutes': serializer.toJson<int>(tzOffsetMinutes),
      'title': serializer.toJson<String?>(title),
      'note': serializer.toJson<String?>(note),
      'photoPath': serializer.toJson<String?>(photoPath),
      'recurrenceId': serializer.toJson<String?>(recurrenceId),
      'isProjected': serializer.toJson<bool>(isProjected),
      'lat': serializer.toJson<double?>(lat),
      'lon': serializer.toJson<double?>(lon),
      'householdId': serializer.toJson<String?>(householdId),
      'visibility': serializer.toJson<String>(visibility),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
    };
  }

  Transaction copyWith(
          {String? id,
          String? kind,
          int? occurredAt,
          int? tzOffsetMinutes,
          Value<String?> title = const Value.absent(),
          Value<String?> note = const Value.absent(),
          Value<String?> photoPath = const Value.absent(),
          Value<String?> recurrenceId = const Value.absent(),
          bool? isProjected,
          Value<double?> lat = const Value.absent(),
          Value<double?> lon = const Value.absent(),
          Value<String?> householdId = const Value.absent(),
          String? visibility,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent(),
          Value<String?> deviceId = const Value.absent()}) =>
      Transaction(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        occurredAt: occurredAt ?? this.occurredAt,
        tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
        title: title.present ? title.value : this.title,
        note: note.present ? note.value : this.note,
        photoPath: photoPath.present ? photoPath.value : this.photoPath,
        recurrenceId:
            recurrenceId.present ? recurrenceId.value : this.recurrenceId,
        isProjected: isProjected ?? this.isProjected,
        lat: lat.present ? lat.value : this.lat,
        lon: lon.present ? lon.value : this.lon,
        householdId: householdId.present ? householdId.value : this.householdId,
        visibility: visibility ?? this.visibility,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        deviceId: deviceId.present ? deviceId.value : this.deviceId,
      );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
      tzOffsetMinutes: data.tzOffsetMinutes.present
          ? data.tzOffsetMinutes.value
          : this.tzOffsetMinutes,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      recurrenceId: data.recurrenceId.present
          ? data.recurrenceId.value
          : this.recurrenceId,
      isProjected:
          data.isProjected.present ? data.isProjected.value : this.isProjected,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      householdId:
          data.householdId.present ? data.householdId.value : this.householdId,
      visibility:
          data.visibility.present ? data.visibility.value : this.visibility,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('photoPath: $photoPath, ')
          ..write('recurrenceId: $recurrenceId, ')
          ..write('isProjected: $isProjected, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('householdId: $householdId, ')
          ..write('visibility: $visibility, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      kind,
      occurredAt,
      tzOffsetMinutes,
      title,
      note,
      photoPath,
      recurrenceId,
      isProjected,
      lat,
      lon,
      householdId,
      visibility,
      updatedAt,
      deletedAt,
      deviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.occurredAt == this.occurredAt &&
          other.tzOffsetMinutes == this.tzOffsetMinutes &&
          other.title == this.title &&
          other.note == this.note &&
          other.photoPath == this.photoPath &&
          other.recurrenceId == this.recurrenceId &&
          other.isProjected == this.isProjected &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.householdId == this.householdId &&
          other.visibility == this.visibility &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.deviceId == this.deviceId);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> kind;
  final Value<int> occurredAt;
  final Value<int> tzOffsetMinutes;
  final Value<String?> title;
  final Value<String?> note;
  final Value<String?> photoPath;
  final Value<String?> recurrenceId;
  final Value<bool> isProjected;
  final Value<double?> lat;
  final Value<double?> lon;
  final Value<String?> householdId;
  final Value<String> visibility;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String?> deviceId;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.tzOffsetMinutes = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.recurrenceId = const Value.absent(),
    this.isProjected = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.householdId = const Value.absent(),
    this.visibility = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String kind,
    required int occurredAt,
    required int tzOffsetMinutes,
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.recurrenceId = const Value.absent(),
    this.isProjected = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.householdId = const Value.absent(),
    this.visibility = const Value.absent(),
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        occurredAt = Value(occurredAt),
        tzOffsetMinutes = Value(tzOffsetMinutes),
        updatedAt = Value(updatedAt);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<int>? occurredAt,
    Expression<int>? tzOffsetMinutes,
    Expression<String>? title,
    Expression<String>? note,
    Expression<String>? photoPath,
    Expression<String>? recurrenceId,
    Expression<bool>? isProjected,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? householdId,
    Expression<String>? visibility,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (tzOffsetMinutes != null) 'tz_offset_minutes': tzOffsetMinutes,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (photoPath != null) 'photo_path': photoPath,
      if (recurrenceId != null) 'recurrence_id': recurrenceId,
      if (isProjected != null) 'is_projected': isProjected,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (householdId != null) 'household_id': householdId,
      if (visibility != null) 'visibility': visibility,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? kind,
      Value<int>? occurredAt,
      Value<int>? tzOffsetMinutes,
      Value<String?>? title,
      Value<String?>? note,
      Value<String?>? photoPath,
      Value<String?>? recurrenceId,
      Value<bool>? isProjected,
      Value<double?>? lat,
      Value<double?>? lon,
      Value<String?>? householdId,
      Value<String>? visibility,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<String?>? deviceId,
      Value<int>? rowid}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      occurredAt: occurredAt ?? this.occurredAt,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      title: title ?? this.title,
      note: note ?? this.note,
      photoPath: photoPath ?? this.photoPath,
      recurrenceId: recurrenceId ?? this.recurrenceId,
      isProjected: isProjected ?? this.isProjected,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      householdId: householdId ?? this.householdId,
      visibility: visibility ?? this.visibility,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (tzOffsetMinutes.present) {
      map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (recurrenceId.present) {
      map['recurrence_id'] = Variable<String>(recurrenceId.value);
    }
    if (isProjected.present) {
      map['is_projected'] = Variable<bool>(isProjected.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (visibility.present) {
      map['visibility'] = Variable<String>(visibility.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('photoPath: $photoPath, ')
          ..write('recurrenceId: $recurrenceId, ')
          ..write('isProjected: $isProjected, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('householdId: $householdId, ')
          ..write('visibility: $visibility, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PostingsTable extends Postings with TableInfo<$PostingsTable, Posting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _transactionIdMeta =
      const VerificationMeta('transactionId');
  @override
  late final GeneratedColumn<String> transactionId = GeneratedColumn<String>(
      'transaction_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES transactions (id)'));
  static const VerificationMeta _accountIdMeta =
      const VerificationMeta('accountId');
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
      'account_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES accounts (id)'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _amountMinorMeta =
      const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
      'amount_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _currencyMeta =
      const VerificationMeta('currency');
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
      'currency', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _rateToBaseMeta =
      const VerificationMeta('rateToBase');
  @override
  late final GeneratedColumn<double> rateToBase = GeneratedColumn<double>(
      'rate_to_base', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _baseAmountMinorMeta =
      const VerificationMeta('baseAmountMinor');
  @override
  late final GeneratedColumn<int> baseAmountMinor = GeneratedColumn<int>(
      'base_amount_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        transactionId,
        accountId,
        categoryId,
        amountMinor,
        currency,
        rateToBase,
        baseAmountMinor
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'postings';
  @override
  VerificationContext validateIntegrity(Insertable<Posting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
          _transactionIdMeta,
          transactionId.isAcceptableOrUnknown(
              data['transaction_id']!, _transactionIdMeta));
    } else if (isInserting) {
      context.missing(_transactionIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(_accountIdMeta,
          accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
          _amountMinorMeta,
          amountMinor.isAcceptableOrUnknown(
              data['amount_minor']!, _amountMinorMeta));
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(_currencyMeta,
          currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta));
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('rate_to_base')) {
      context.handle(
          _rateToBaseMeta,
          rateToBase.isAcceptableOrUnknown(
              data['rate_to_base']!, _rateToBaseMeta));
    }
    if (data.containsKey('base_amount_minor')) {
      context.handle(
          _baseAmountMinorMeta,
          baseAmountMinor.isAcceptableOrUnknown(
              data['base_amount_minor']!, _baseAmountMinorMeta));
    } else if (isInserting) {
      context.missing(_baseAmountMinorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Posting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Posting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      transactionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transaction_id'])!,
      accountId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}account_id']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id']),
      amountMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_minor'])!,
      currency: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}currency'])!,
      rateToBase: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rate_to_base'])!,
      baseAmountMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}base_amount_minor'])!,
    );
  }

  @override
  $PostingsTable createAlias(String alias) {
    return $PostingsTable(attachedDatabase, alias);
  }
}

class Posting extends DataClass implements Insertable<Posting> {
  final String id;
  final String transactionId;
  final String? accountId;
  final String? categoryId;
  final int amountMinor;
  final String currency;
  final double rateToBase;
  final int baseAmountMinor;
  const Posting(
      {required this.id,
      required this.transactionId,
      this.accountId,
      this.categoryId,
      required this.amountMinor,
      required this.currency,
      required this.rateToBase,
      required this.baseAmountMinor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['transaction_id'] = Variable<String>(transactionId);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency'] = Variable<String>(currency);
    map['rate_to_base'] = Variable<double>(rateToBase);
    map['base_amount_minor'] = Variable<int>(baseAmountMinor);
    return map;
  }

  PostingsCompanion toCompanion(bool nullToAbsent) {
    return PostingsCompanion(
      id: Value(id),
      transactionId: Value(transactionId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amountMinor: Value(amountMinor),
      currency: Value(currency),
      rateToBase: Value(rateToBase),
      baseAmountMinor: Value(baseAmountMinor),
    );
  }

  factory Posting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Posting(
      id: serializer.fromJson<String>(json['id']),
      transactionId: serializer.fromJson<String>(json['transactionId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currency: serializer.fromJson<String>(json['currency']),
      rateToBase: serializer.fromJson<double>(json['rateToBase']),
      baseAmountMinor: serializer.fromJson<int>(json['baseAmountMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'transactionId': serializer.toJson<String>(transactionId),
      'accountId': serializer.toJson<String?>(accountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currency': serializer.toJson<String>(currency),
      'rateToBase': serializer.toJson<double>(rateToBase),
      'baseAmountMinor': serializer.toJson<int>(baseAmountMinor),
    };
  }

  Posting copyWith(
          {String? id,
          String? transactionId,
          Value<String?> accountId = const Value.absent(),
          Value<String?> categoryId = const Value.absent(),
          int? amountMinor,
          String? currency,
          double? rateToBase,
          int? baseAmountMinor}) =>
      Posting(
        id: id ?? this.id,
        transactionId: transactionId ?? this.transactionId,
        accountId: accountId.present ? accountId.value : this.accountId,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        amountMinor: amountMinor ?? this.amountMinor,
        currency: currency ?? this.currency,
        rateToBase: rateToBase ?? this.rateToBase,
        baseAmountMinor: baseAmountMinor ?? this.baseAmountMinor,
      );
  Posting copyWithCompanion(PostingsCompanion data) {
    return Posting(
      id: data.id.present ? data.id.value : this.id,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      amountMinor:
          data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
      currency: data.currency.present ? data.currency.value : this.currency,
      rateToBase:
          data.rateToBase.present ? data.rateToBase.value : this.rateToBase,
      baseAmountMinor: data.baseAmountMinor.present
          ? data.baseAmountMinor.value
          : this.baseAmountMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Posting(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('rateToBase: $rateToBase, ')
          ..write('baseAmountMinor: $baseAmountMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, transactionId, accountId, categoryId,
      amountMinor, currency, rateToBase, baseAmountMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Posting &&
          other.id == this.id &&
          other.transactionId == this.transactionId &&
          other.accountId == this.accountId &&
          other.categoryId == this.categoryId &&
          other.amountMinor == this.amountMinor &&
          other.currency == this.currency &&
          other.rateToBase == this.rateToBase &&
          other.baseAmountMinor == this.baseAmountMinor);
}

class PostingsCompanion extends UpdateCompanion<Posting> {
  final Value<String> id;
  final Value<String> transactionId;
  final Value<String?> accountId;
  final Value<String?> categoryId;
  final Value<int> amountMinor;
  final Value<String> currency;
  final Value<double> rateToBase;
  final Value<int> baseAmountMinor;
  final Value<int> rowid;
  const PostingsCompanion({
    this.id = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currency = const Value.absent(),
    this.rateToBase = const Value.absent(),
    this.baseAmountMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PostingsCompanion.insert({
    required String id,
    required String transactionId,
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    required int amountMinor,
    required String currency,
    this.rateToBase = const Value.absent(),
    required int baseAmountMinor,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        transactionId = Value(transactionId),
        amountMinor = Value(amountMinor),
        currency = Value(currency),
        baseAmountMinor = Value(baseAmountMinor);
  static Insertable<Posting> custom({
    Expression<String>? id,
    Expression<String>? transactionId,
    Expression<String>? accountId,
    Expression<String>? categoryId,
    Expression<int>? amountMinor,
    Expression<String>? currency,
    Expression<double>? rateToBase,
    Expression<int>? baseAmountMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (transactionId != null) 'transaction_id': transactionId,
      if (accountId != null) 'account_id': accountId,
      if (categoryId != null) 'category_id': categoryId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currency != null) 'currency': currency,
      if (rateToBase != null) 'rate_to_base': rateToBase,
      if (baseAmountMinor != null) 'base_amount_minor': baseAmountMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PostingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? transactionId,
      Value<String?>? accountId,
      Value<String?>? categoryId,
      Value<int>? amountMinor,
      Value<String>? currency,
      Value<double>? rateToBase,
      Value<int>? baseAmountMinor,
      Value<int>? rowid}) {
    return PostingsCompanion(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      amountMinor: amountMinor ?? this.amountMinor,
      currency: currency ?? this.currency,
      rateToBase: rateToBase ?? this.rateToBase,
      baseAmountMinor: baseAmountMinor ?? this.baseAmountMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<String>(transactionId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (rateToBase.present) {
      map['rate_to_base'] = Variable<double>(rateToBase.value);
    }
    if (baseAmountMinor.present) {
      map['base_amount_minor'] = Variable<int>(baseAmountMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostingsCompanion(')
          ..write('id: $id, ')
          ..write('transactionId: $transactionId, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currency: $currency, ')
          ..write('rateToBase: $rateToBase, ')
          ..write('baseAmountMinor: $baseAmountMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyTotalsTable extends DailyTotals
    with TableInfo<$DailyTotalsTable, DailyTotal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyTotalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<int> day = GeneratedColumn<int>(
      'day', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _netMinorMeta =
      const VerificationMeta('netMinor');
  @override
  late final GeneratedColumn<int> netMinor = GeneratedColumn<int>(
      'net_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [day, netMinor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_totals';
  @override
  VerificationContext validateIntegrity(Insertable<DailyTotal> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
          _dayMeta, day.isAcceptableOrUnknown(data['day']!, _dayMeta));
    }
    if (data.containsKey('net_minor')) {
      context.handle(_netMinorMeta,
          netMinor.isAcceptableOrUnknown(data['net_minor']!, _netMinorMeta));
    } else if (isInserting) {
      context.missing(_netMinorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  DailyTotal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyTotal(
      day: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}day'])!,
      netMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}net_minor'])!,
    );
  }

  @override
  $DailyTotalsTable createAlias(String alias) {
    return $DailyTotalsTable(attachedDatabase, alias);
  }
}

class DailyTotal extends DataClass implements Insertable<DailyTotal> {
  final int day;
  final int netMinor;
  const DailyTotal({required this.day, required this.netMinor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<int>(day);
    map['net_minor'] = Variable<int>(netMinor);
    return map;
  }

  DailyTotalsCompanion toCompanion(bool nullToAbsent) {
    return DailyTotalsCompanion(
      day: Value(day),
      netMinor: Value(netMinor),
    );
  }

  factory DailyTotal.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyTotal(
      day: serializer.fromJson<int>(json['day']),
      netMinor: serializer.fromJson<int>(json['netMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'day': serializer.toJson<int>(day),
      'netMinor': serializer.toJson<int>(netMinor),
    };
  }

  DailyTotal copyWith({int? day, int? netMinor}) => DailyTotal(
        day: day ?? this.day,
        netMinor: netMinor ?? this.netMinor,
      );
  DailyTotal copyWithCompanion(DailyTotalsCompanion data) {
    return DailyTotal(
      day: data.day.present ? data.day.value : this.day,
      netMinor: data.netMinor.present ? data.netMinor.value : this.netMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyTotal(')
          ..write('day: $day, ')
          ..write('netMinor: $netMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(day, netMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyTotal &&
          other.day == this.day &&
          other.netMinor == this.netMinor);
}

class DailyTotalsCompanion extends UpdateCompanion<DailyTotal> {
  final Value<int> day;
  final Value<int> netMinor;
  const DailyTotalsCompanion({
    this.day = const Value.absent(),
    this.netMinor = const Value.absent(),
  });
  DailyTotalsCompanion.insert({
    this.day = const Value.absent(),
    required int netMinor,
  }) : netMinor = Value(netMinor);
  static Insertable<DailyTotal> custom({
    Expression<int>? day,
    Expression<int>? netMinor,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (netMinor != null) 'net_minor': netMinor,
    });
  }

  DailyTotalsCompanion copyWith({Value<int>? day, Value<int>? netMinor}) {
    return DailyTotalsCompanion(
      day: day ?? this.day,
      netMinor: netMinor ?? this.netMinor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<int>(day.value);
    }
    if (netMinor.present) {
      map['net_minor'] = Variable<int>(netMinor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyTotalsCompanion(')
          ..write('day: $day, ')
          ..write('netMinor: $netMinor')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _periodStartDayMeta =
      const VerificationMeta('periodStartDay');
  @override
  late final GeneratedColumn<int> periodStartDay = GeneratedColumn<int>(
      'period_start_day', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _lastAcknowledgedPeriodCloseMeta =
      const VerificationMeta('lastAcknowledgedPeriodClose');
  @override
  late final GeneratedColumn<int> lastAcknowledgedPeriodClose =
      GeneratedColumn<int>('last_acknowledged_period_close', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, periodStartDay, lastAcknowledgedPeriodClose];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('period_start_day')) {
      context.handle(
          _periodStartDayMeta,
          periodStartDay.isAcceptableOrUnknown(
              data['period_start_day']!, _periodStartDayMeta));
    }
    if (data.containsKey('last_acknowledged_period_close')) {
      context.handle(
          _lastAcknowledgedPeriodCloseMeta,
          lastAcknowledgedPeriodClose.isAcceptableOrUnknown(
              data['last_acknowledged_period_close']!,
              _lastAcknowledgedPeriodCloseMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      periodStartDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}period_start_day'])!,
      lastAcknowledgedPeriodClose: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}last_acknowledged_period_close']),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final int id;
  final int periodStartDay;

  /// The start day (day bucket) of the most recent period the user has
  /// dismissed the period-close ritual for — null means none yet. See
  /// plan/05-sprints.md Sprint 14, "fires once per period boundary,
  /// dismissible".
  final int? lastAcknowledgedPeriodClose;
  const AppSetting(
      {required this.id,
      required this.periodStartDay,
      this.lastAcknowledgedPeriodClose});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['period_start_day'] = Variable<int>(periodStartDay);
    if (!nullToAbsent || lastAcknowledgedPeriodClose != null) {
      map['last_acknowledged_period_close'] =
          Variable<int>(lastAcknowledgedPeriodClose);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      periodStartDay: Value(periodStartDay),
      lastAcknowledgedPeriodClose:
          lastAcknowledgedPeriodClose == null && nullToAbsent
              ? const Value.absent()
              : Value(lastAcknowledgedPeriodClose),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      id: serializer.fromJson<int>(json['id']),
      periodStartDay: serializer.fromJson<int>(json['periodStartDay']),
      lastAcknowledgedPeriodClose:
          serializer.fromJson<int?>(json['lastAcknowledgedPeriodClose']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'periodStartDay': serializer.toJson<int>(periodStartDay),
      'lastAcknowledgedPeriodClose':
          serializer.toJson<int?>(lastAcknowledgedPeriodClose),
    };
  }

  AppSetting copyWith(
          {int? id,
          int? periodStartDay,
          Value<int?> lastAcknowledgedPeriodClose = const Value.absent()}) =>
      AppSetting(
        id: id ?? this.id,
        periodStartDay: periodStartDay ?? this.periodStartDay,
        lastAcknowledgedPeriodClose: lastAcknowledgedPeriodClose.present
            ? lastAcknowledgedPeriodClose.value
            : this.lastAcknowledgedPeriodClose,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      id: data.id.present ? data.id.value : this.id,
      periodStartDay: data.periodStartDay.present
          ? data.periodStartDay.value
          : this.periodStartDay,
      lastAcknowledgedPeriodClose: data.lastAcknowledgedPeriodClose.present
          ? data.lastAcknowledgedPeriodClose.value
          : this.lastAcknowledgedPeriodClose,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('id: $id, ')
          ..write('periodStartDay: $periodStartDay, ')
          ..write('lastAcknowledgedPeriodClose: $lastAcknowledgedPeriodClose')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, periodStartDay, lastAcknowledgedPeriodClose);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.id == this.id &&
          other.periodStartDay == this.periodStartDay &&
          other.lastAcknowledgedPeriodClose ==
              this.lastAcknowledgedPeriodClose);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<int> id;
  final Value<int> periodStartDay;
  final Value<int?> lastAcknowledgedPeriodClose;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.periodStartDay = const Value.absent(),
    this.lastAcknowledgedPeriodClose = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.periodStartDay = const Value.absent(),
    this.lastAcknowledgedPeriodClose = const Value.absent(),
  });
  static Insertable<AppSetting> custom({
    Expression<int>? id,
    Expression<int>? periodStartDay,
    Expression<int>? lastAcknowledgedPeriodClose,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (periodStartDay != null) 'period_start_day': periodStartDay,
      if (lastAcknowledgedPeriodClose != null)
        'last_acknowledged_period_close': lastAcknowledgedPeriodClose,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<int>? id,
      Value<int>? periodStartDay,
      Value<int?>? lastAcknowledgedPeriodClose}) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      periodStartDay: periodStartDay ?? this.periodStartDay,
      lastAcknowledgedPeriodClose:
          lastAcknowledgedPeriodClose ?? this.lastAcknowledgedPeriodClose,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (periodStartDay.present) {
      map['period_start_day'] = Variable<int>(periodStartDay.value);
    }
    if (lastAcknowledgedPeriodClose.present) {
      map['last_acknowledged_period_close'] =
          Variable<int>(lastAcknowledgedPeriodClose.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('periodStartDay: $periodStartDay, ')
          ..write('lastAcknowledgedPeriodClose: $lastAcknowledgedPeriodClose')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _amountMinorMeta =
      const VerificationMeta('amountMinor');
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
      'amount_minor', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, amountMinor, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(Insertable<Budget> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
          _amountMinorMeta,
          amountMinor.isAcceptableOrUnknown(
              data['amount_minor']!, _amountMinorMeta));
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      amountMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}amount_minor'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final String key;
  final int amountMinor;
  final int updatedAt;
  const Budget(
      {required this.key, required this.amountMinor, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      key: Value(key),
      amountMinor: Value(amountMinor),
      updatedAt: Value(updatedAt),
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      key: serializer.fromJson<String>(json['key']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Budget copyWith({String? key, int? amountMinor, int? updatedAt}) => Budget(
        key: key ?? this.key,
        amountMinor: amountMinor ?? this.amountMinor,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      key: data.key.present ? data.key.value : this.key,
      amountMinor:
          data.amountMinor.present ? data.amountMinor.value : this.amountMinor,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('key: $key, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, amountMinor, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.key == this.key &&
          other.amountMinor == this.amountMinor &&
          other.updatedAt == this.updatedAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> key;
  final Value<int> amountMinor;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.key = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String key,
    required int amountMinor,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        amountMinor = Value(amountMinor),
        updatedAt = Value(updatedAt);
  static Insertable<Budget> custom({
    Expression<String>? key,
    Expression<int>? amountMinor,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith(
      {Value<String>? key,
      Value<int>? amountMinor,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return BudgetsCompanion(
      key: key ?? this.key,
      amountMinor: amountMinor ?? this.amountMinor,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('key: $key, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeatureFlagsTable extends FeatureFlags
    with TableInfo<$FeatureFlagsTable, FeatureFlag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeatureFlagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<bool> value = GeneratedColumn<bool>(
      'value', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("value" IN (0, 1))'));
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feature_flags';
  @override
  VerificationContext validateIntegrity(Insertable<FeatureFlag> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  FeatureFlag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeatureFlag(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $FeatureFlagsTable createAlias(String alias) {
    return $FeatureFlagsTable(attachedDatabase, alias);
  }
}

class FeatureFlag extends DataClass implements Insertable<FeatureFlag> {
  final String key;
  final bool value;
  const FeatureFlag({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<bool>(value);
    return map;
  }

  FeatureFlagsCompanion toCompanion(bool nullToAbsent) {
    return FeatureFlagsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory FeatureFlag.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeatureFlag(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<bool>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<bool>(value),
    };
  }

  FeatureFlag copyWith({String? key, bool? value}) => FeatureFlag(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  FeatureFlag copyWithCompanion(FeatureFlagsCompanion data) {
    return FeatureFlag(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeatureFlag(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeatureFlag &&
          other.key == this.key &&
          other.value == this.value);
}

class FeatureFlagsCompanion extends UpdateCompanion<FeatureFlag> {
  final Value<String> key;
  final Value<bool> value;
  final Value<int> rowid;
  const FeatureFlagsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeatureFlagsCompanion.insert({
    required String key,
    required bool value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<FeatureFlag> custom({
    Expression<String>? key,
    Expression<bool>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeatureFlagsCompanion copyWith(
      {Value<String>? key, Value<bool>? value, Value<int>? rowid}) {
    return FeatureFlagsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<bool>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeatureFlagsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnalyticsEventsTable extends AnalyticsEvents
    with TableInfo<$AnalyticsEventsTable, AnalyticsEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalyticsEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _propsJsonMeta =
      const VerificationMeta('propsJson');
  @override
  late final GeneratedColumn<String> propsJson = GeneratedColumn<String>(
      'props_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _occurredAtMeta =
      const VerificationMeta('occurredAt');
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
      'occurred_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, propsJson, occurredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analytics_events';
  @override
  VerificationContext validateIntegrity(Insertable<AnalyticsEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('props_json')) {
      context.handle(_propsJsonMeta,
          propsJson.isAcceptableOrUnknown(data['props_json']!, _propsJsonMeta));
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
          _occurredAtMeta,
          occurredAt.isAcceptableOrUnknown(
              data['occurred_at']!, _occurredAtMeta));
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnalyticsEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnalyticsEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      propsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}props_json']),
      occurredAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}occurred_at'])!,
    );
  }

  @override
  $AnalyticsEventsTable createAlias(String alias) {
    return $AnalyticsEventsTable(attachedDatabase, alias);
  }
}

class AnalyticsEvent extends DataClass implements Insertable<AnalyticsEvent> {
  final String id;
  final String name;
  final String? propsJson;
  final int occurredAt;
  const AnalyticsEvent(
      {required this.id,
      required this.name,
      this.propsJson,
      required this.occurredAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || propsJson != null) {
      map['props_json'] = Variable<String>(propsJson);
    }
    map['occurred_at'] = Variable<int>(occurredAt);
    return map;
  }

  AnalyticsEventsCompanion toCompanion(bool nullToAbsent) {
    return AnalyticsEventsCompanion(
      id: Value(id),
      name: Value(name),
      propsJson: propsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(propsJson),
      occurredAt: Value(occurredAt),
    );
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnalyticsEvent(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      propsJson: serializer.fromJson<String?>(json['propsJson']),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'propsJson': serializer.toJson<String?>(propsJson),
      'occurredAt': serializer.toJson<int>(occurredAt),
    };
  }

  AnalyticsEvent copyWith(
          {String? id,
          String? name,
          Value<String?> propsJson = const Value.absent(),
          int? occurredAt}) =>
      AnalyticsEvent(
        id: id ?? this.id,
        name: name ?? this.name,
        propsJson: propsJson.present ? propsJson.value : this.propsJson,
        occurredAt: occurredAt ?? this.occurredAt,
      );
  AnalyticsEvent copyWithCompanion(AnalyticsEventsCompanion data) {
    return AnalyticsEvent(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      propsJson: data.propsJson.present ? data.propsJson.value : this.propsJson,
      occurredAt:
          data.occurredAt.present ? data.occurredAt.value : this.occurredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnalyticsEvent(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('propsJson: $propsJson, ')
          ..write('occurredAt: $occurredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, propsJson, occurredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalyticsEvent &&
          other.id == this.id &&
          other.name == this.name &&
          other.propsJson == this.propsJson &&
          other.occurredAt == this.occurredAt);
}

class AnalyticsEventsCompanion extends UpdateCompanion<AnalyticsEvent> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> propsJson;
  final Value<int> occurredAt;
  final Value<int> rowid;
  const AnalyticsEventsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.propsJson = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnalyticsEventsCompanion.insert({
    required String id,
    required String name,
    this.propsJson = const Value.absent(),
    required int occurredAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        occurredAt = Value(occurredAt);
  static Insertable<AnalyticsEvent> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? propsJson,
    Expression<int>? occurredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (propsJson != null) 'props_json': propsJson,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnalyticsEventsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? propsJson,
      Value<int>? occurredAt,
      Value<int>? rowid}) {
    return AnalyticsEventsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      propsJson: propsJson ?? this.propsJson,
      occurredAt: occurredAt ?? this.occurredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (propsJson.present) {
      map['props_json'] = Variable<String>(propsJson.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalyticsEventsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('propsJson: $propsJson, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurrencesTable extends Recurrences
    with TableInfo<$RecurrencesTable, Recurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _templateJsonMeta =
      const VerificationMeta('templateJson');
  @override
  late final GeneratedColumn<String> templateJson = GeneratedColumn<String>(
      'template_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _freqMeta = const VerificationMeta('freq');
  @override
  late final GeneratedColumn<String> freq = GeneratedColumn<String>(
      'freq', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _intervalNMeta =
      const VerificationMeta('intervalN');
  @override
  late final GeneratedColumn<int> intervalN = GeneratedColumn<int>(
      'interval_n', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _byMonthDayMeta =
      const VerificationMeta('byMonthDay');
  @override
  late final GeneratedColumn<int> byMonthDay = GeneratedColumn<int>(
      'by_month_day', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _byWeekdayMeta =
      const VerificationMeta('byWeekday');
  @override
  late final GeneratedColumn<int> byWeekday = GeneratedColumn<int>(
      'by_weekday', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _weekendRuleMeta =
      const VerificationMeta('weekendRule');
  @override
  late final GeneratedColumn<String> weekendRule = GeneratedColumn<String>(
      'weekend_rule', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('none'));
  static const VerificationMeta _amountModeMeta =
      const VerificationMeta('amountMode');
  @override
  late final GeneratedColumn<String> amountMode = GeneratedColumn<String>(
      'amount_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('fixed'));
  static const VerificationMeta _expectedMinMinorMeta =
      const VerificationMeta('expectedMinMinor');
  @override
  late final GeneratedColumn<int> expectedMinMinor = GeneratedColumn<int>(
      'expected_min_minor', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _expectedMaxMinorMeta =
      const VerificationMeta('expectedMaxMinor');
  @override
  late final GeneratedColumn<int> expectedMaxMinor = GeneratedColumn<int>(
      'expected_max_minor', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _startsOnMeta =
      const VerificationMeta('startsOn');
  @override
  late final GeneratedColumn<int> startsOn = GeneratedColumn<int>(
      'starts_on', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endsOnMeta = const VerificationMeta('endsOn');
  @override
  late final GeneratedColumn<int> endsOn = GeneratedColumn<int>(
      'ends_on', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _generatedUntilMeta =
      const VerificationMeta('generatedUntil');
  @override
  late final GeneratedColumn<int> generatedUntil = GeneratedColumn<int>(
      'generated_until', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _lastGenerationErrorMeta =
      const VerificationMeta('lastGenerationError');
  @override
  late final GeneratedColumn<String> lastGenerationError =
      GeneratedColumn<String>('last_generation_error', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        templateJson,
        freq,
        intervalN,
        byMonthDay,
        byWeekday,
        weekendRule,
        amountMode,
        expectedMinMinor,
        expectedMaxMinor,
        startsOn,
        endsOn,
        generatedUntil,
        updatedAt,
        deletedAt,
        lastGenerationError
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrences';
  @override
  VerificationContext validateIntegrity(Insertable<Recurrence> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_json')) {
      context.handle(
          _templateJsonMeta,
          templateJson.isAcceptableOrUnknown(
              data['template_json']!, _templateJsonMeta));
    } else if (isInserting) {
      context.missing(_templateJsonMeta);
    }
    if (data.containsKey('freq')) {
      context.handle(
          _freqMeta, freq.isAcceptableOrUnknown(data['freq']!, _freqMeta));
    } else if (isInserting) {
      context.missing(_freqMeta);
    }
    if (data.containsKey('interval_n')) {
      context.handle(_intervalNMeta,
          intervalN.isAcceptableOrUnknown(data['interval_n']!, _intervalNMeta));
    }
    if (data.containsKey('by_month_day')) {
      context.handle(
          _byMonthDayMeta,
          byMonthDay.isAcceptableOrUnknown(
              data['by_month_day']!, _byMonthDayMeta));
    }
    if (data.containsKey('by_weekday')) {
      context.handle(_byWeekdayMeta,
          byWeekday.isAcceptableOrUnknown(data['by_weekday']!, _byWeekdayMeta));
    }
    if (data.containsKey('weekend_rule')) {
      context.handle(
          _weekendRuleMeta,
          weekendRule.isAcceptableOrUnknown(
              data['weekend_rule']!, _weekendRuleMeta));
    }
    if (data.containsKey('amount_mode')) {
      context.handle(
          _amountModeMeta,
          amountMode.isAcceptableOrUnknown(
              data['amount_mode']!, _amountModeMeta));
    }
    if (data.containsKey('expected_min_minor')) {
      context.handle(
          _expectedMinMinorMeta,
          expectedMinMinor.isAcceptableOrUnknown(
              data['expected_min_minor']!, _expectedMinMinorMeta));
    }
    if (data.containsKey('expected_max_minor')) {
      context.handle(
          _expectedMaxMinorMeta,
          expectedMaxMinor.isAcceptableOrUnknown(
              data['expected_max_minor']!, _expectedMaxMinorMeta));
    }
    if (data.containsKey('starts_on')) {
      context.handle(_startsOnMeta,
          startsOn.isAcceptableOrUnknown(data['starts_on']!, _startsOnMeta));
    } else if (isInserting) {
      context.missing(_startsOnMeta);
    }
    if (data.containsKey('ends_on')) {
      context.handle(_endsOnMeta,
          endsOn.isAcceptableOrUnknown(data['ends_on']!, _endsOnMeta));
    }
    if (data.containsKey('generated_until')) {
      context.handle(
          _generatedUntilMeta,
          generatedUntil.isAcceptableOrUnknown(
              data['generated_until']!, _generatedUntilMeta));
    } else if (isInserting) {
      context.missing(_generatedUntilMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('last_generation_error')) {
      context.handle(
          _lastGenerationErrorMeta,
          lastGenerationError.isAcceptableOrUnknown(
              data['last_generation_error']!, _lastGenerationErrorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recurrence(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      templateJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}template_json'])!,
      freq: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}freq'])!,
      intervalN: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}interval_n'])!,
      byMonthDay: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}by_month_day']),
      byWeekday: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}by_weekday']),
      weekendRule: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}weekend_rule'])!,
      amountMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}amount_mode'])!,
      expectedMinMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expected_min_minor']),
      expectedMaxMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}expected_max_minor']),
      startsOn: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}starts_on'])!,
      endsOn: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ends_on']),
      generatedUntil: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}generated_until'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
      lastGenerationError: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}last_generation_error']),
    );
  }

  @override
  $RecurrencesTable createAlias(String alias) {
    return $RecurrencesTable(attachedDatabase, alias);
  }
}

class Recurrence extends DataClass implements Insertable<Recurrence> {
  final String id;
  final String templateJson;
  final String freq;
  final int intervalN;
  final int? byMonthDay;
  final int? byWeekday;
  final String weekendRule;
  final String amountMode;
  final int? expectedMinMinor;
  final int? expectedMaxMinor;
  final int startsOn;
  final int? endsOn;
  final int generatedUntil;
  final int updatedAt;
  final int? deletedAt;

  /// Set when the last materialisation attempt for this rule threw,
  /// cleared on the next successful attempt — plan/04-ux-design.md's
  /// states table: "Recurring... Failed generation flagged in the row
  /// with the reason."
  final String? lastGenerationError;
  const Recurrence(
      {required this.id,
      required this.templateJson,
      required this.freq,
      required this.intervalN,
      this.byMonthDay,
      this.byWeekday,
      required this.weekendRule,
      required this.amountMode,
      this.expectedMinMinor,
      this.expectedMaxMinor,
      required this.startsOn,
      this.endsOn,
      required this.generatedUntil,
      required this.updatedAt,
      this.deletedAt,
      this.lastGenerationError});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_json'] = Variable<String>(templateJson);
    map['freq'] = Variable<String>(freq);
    map['interval_n'] = Variable<int>(intervalN);
    if (!nullToAbsent || byMonthDay != null) {
      map['by_month_day'] = Variable<int>(byMonthDay);
    }
    if (!nullToAbsent || byWeekday != null) {
      map['by_weekday'] = Variable<int>(byWeekday);
    }
    map['weekend_rule'] = Variable<String>(weekendRule);
    map['amount_mode'] = Variable<String>(amountMode);
    if (!nullToAbsent || expectedMinMinor != null) {
      map['expected_min_minor'] = Variable<int>(expectedMinMinor);
    }
    if (!nullToAbsent || expectedMaxMinor != null) {
      map['expected_max_minor'] = Variable<int>(expectedMaxMinor);
    }
    map['starts_on'] = Variable<int>(startsOn);
    if (!nullToAbsent || endsOn != null) {
      map['ends_on'] = Variable<int>(endsOn);
    }
    map['generated_until'] = Variable<int>(generatedUntil);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || lastGenerationError != null) {
      map['last_generation_error'] = Variable<String>(lastGenerationError);
    }
    return map;
  }

  RecurrencesCompanion toCompanion(bool nullToAbsent) {
    return RecurrencesCompanion(
      id: Value(id),
      templateJson: Value(templateJson),
      freq: Value(freq),
      intervalN: Value(intervalN),
      byMonthDay: byMonthDay == null && nullToAbsent
          ? const Value.absent()
          : Value(byMonthDay),
      byWeekday: byWeekday == null && nullToAbsent
          ? const Value.absent()
          : Value(byWeekday),
      weekendRule: Value(weekendRule),
      amountMode: Value(amountMode),
      expectedMinMinor: expectedMinMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedMinMinor),
      expectedMaxMinor: expectedMaxMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedMaxMinor),
      startsOn: Value(startsOn),
      endsOn:
          endsOn == null && nullToAbsent ? const Value.absent() : Value(endsOn),
      generatedUntil: Value(generatedUntil),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      lastGenerationError: lastGenerationError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastGenerationError),
    );
  }

  factory Recurrence.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recurrence(
      id: serializer.fromJson<String>(json['id']),
      templateJson: serializer.fromJson<String>(json['templateJson']),
      freq: serializer.fromJson<String>(json['freq']),
      intervalN: serializer.fromJson<int>(json['intervalN']),
      byMonthDay: serializer.fromJson<int?>(json['byMonthDay']),
      byWeekday: serializer.fromJson<int?>(json['byWeekday']),
      weekendRule: serializer.fromJson<String>(json['weekendRule']),
      amountMode: serializer.fromJson<String>(json['amountMode']),
      expectedMinMinor: serializer.fromJson<int?>(json['expectedMinMinor']),
      expectedMaxMinor: serializer.fromJson<int?>(json['expectedMaxMinor']),
      startsOn: serializer.fromJson<int>(json['startsOn']),
      endsOn: serializer.fromJson<int?>(json['endsOn']),
      generatedUntil: serializer.fromJson<int>(json['generatedUntil']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      lastGenerationError:
          serializer.fromJson<String?>(json['lastGenerationError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateJson': serializer.toJson<String>(templateJson),
      'freq': serializer.toJson<String>(freq),
      'intervalN': serializer.toJson<int>(intervalN),
      'byMonthDay': serializer.toJson<int?>(byMonthDay),
      'byWeekday': serializer.toJson<int?>(byWeekday),
      'weekendRule': serializer.toJson<String>(weekendRule),
      'amountMode': serializer.toJson<String>(amountMode),
      'expectedMinMinor': serializer.toJson<int?>(expectedMinMinor),
      'expectedMaxMinor': serializer.toJson<int?>(expectedMaxMinor),
      'startsOn': serializer.toJson<int>(startsOn),
      'endsOn': serializer.toJson<int?>(endsOn),
      'generatedUntil': serializer.toJson<int>(generatedUntil),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'lastGenerationError': serializer.toJson<String?>(lastGenerationError),
    };
  }

  Recurrence copyWith(
          {String? id,
          String? templateJson,
          String? freq,
          int? intervalN,
          Value<int?> byMonthDay = const Value.absent(),
          Value<int?> byWeekday = const Value.absent(),
          String? weekendRule,
          String? amountMode,
          Value<int?> expectedMinMinor = const Value.absent(),
          Value<int?> expectedMaxMinor = const Value.absent(),
          int? startsOn,
          Value<int?> endsOn = const Value.absent(),
          int? generatedUntil,
          int? updatedAt,
          Value<int?> deletedAt = const Value.absent(),
          Value<String?> lastGenerationError = const Value.absent()}) =>
      Recurrence(
        id: id ?? this.id,
        templateJson: templateJson ?? this.templateJson,
        freq: freq ?? this.freq,
        intervalN: intervalN ?? this.intervalN,
        byMonthDay: byMonthDay.present ? byMonthDay.value : this.byMonthDay,
        byWeekday: byWeekday.present ? byWeekday.value : this.byWeekday,
        weekendRule: weekendRule ?? this.weekendRule,
        amountMode: amountMode ?? this.amountMode,
        expectedMinMinor: expectedMinMinor.present
            ? expectedMinMinor.value
            : this.expectedMinMinor,
        expectedMaxMinor: expectedMaxMinor.present
            ? expectedMaxMinor.value
            : this.expectedMaxMinor,
        startsOn: startsOn ?? this.startsOn,
        endsOn: endsOn.present ? endsOn.value : this.endsOn,
        generatedUntil: generatedUntil ?? this.generatedUntil,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
        lastGenerationError: lastGenerationError.present
            ? lastGenerationError.value
            : this.lastGenerationError,
      );
  Recurrence copyWithCompanion(RecurrencesCompanion data) {
    return Recurrence(
      id: data.id.present ? data.id.value : this.id,
      templateJson: data.templateJson.present
          ? data.templateJson.value
          : this.templateJson,
      freq: data.freq.present ? data.freq.value : this.freq,
      intervalN: data.intervalN.present ? data.intervalN.value : this.intervalN,
      byMonthDay:
          data.byMonthDay.present ? data.byMonthDay.value : this.byMonthDay,
      byWeekday: data.byWeekday.present ? data.byWeekday.value : this.byWeekday,
      weekendRule:
          data.weekendRule.present ? data.weekendRule.value : this.weekendRule,
      amountMode:
          data.amountMode.present ? data.amountMode.value : this.amountMode,
      expectedMinMinor: data.expectedMinMinor.present
          ? data.expectedMinMinor.value
          : this.expectedMinMinor,
      expectedMaxMinor: data.expectedMaxMinor.present
          ? data.expectedMaxMinor.value
          : this.expectedMaxMinor,
      startsOn: data.startsOn.present ? data.startsOn.value : this.startsOn,
      endsOn: data.endsOn.present ? data.endsOn.value : this.endsOn,
      generatedUntil: data.generatedUntil.present
          ? data.generatedUntil.value
          : this.generatedUntil,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      lastGenerationError: data.lastGenerationError.present
          ? data.lastGenerationError.value
          : this.lastGenerationError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recurrence(')
          ..write('id: $id, ')
          ..write('templateJson: $templateJson, ')
          ..write('freq: $freq, ')
          ..write('intervalN: $intervalN, ')
          ..write('byMonthDay: $byMonthDay, ')
          ..write('byWeekday: $byWeekday, ')
          ..write('weekendRule: $weekendRule, ')
          ..write('amountMode: $amountMode, ')
          ..write('expectedMinMinor: $expectedMinMinor, ')
          ..write('expectedMaxMinor: $expectedMaxMinor, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('generatedUntil: $generatedUntil, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastGenerationError: $lastGenerationError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      templateJson,
      freq,
      intervalN,
      byMonthDay,
      byWeekday,
      weekendRule,
      amountMode,
      expectedMinMinor,
      expectedMaxMinor,
      startsOn,
      endsOn,
      generatedUntil,
      updatedAt,
      deletedAt,
      lastGenerationError);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recurrence &&
          other.id == this.id &&
          other.templateJson == this.templateJson &&
          other.freq == this.freq &&
          other.intervalN == this.intervalN &&
          other.byMonthDay == this.byMonthDay &&
          other.byWeekday == this.byWeekday &&
          other.weekendRule == this.weekendRule &&
          other.amountMode == this.amountMode &&
          other.expectedMinMinor == this.expectedMinMinor &&
          other.expectedMaxMinor == this.expectedMaxMinor &&
          other.startsOn == this.startsOn &&
          other.endsOn == this.endsOn &&
          other.generatedUntil == this.generatedUntil &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.lastGenerationError == this.lastGenerationError);
}

class RecurrencesCompanion extends UpdateCompanion<Recurrence> {
  final Value<String> id;
  final Value<String> templateJson;
  final Value<String> freq;
  final Value<int> intervalN;
  final Value<int?> byMonthDay;
  final Value<int?> byWeekday;
  final Value<String> weekendRule;
  final Value<String> amountMode;
  final Value<int?> expectedMinMinor;
  final Value<int?> expectedMaxMinor;
  final Value<int> startsOn;
  final Value<int?> endsOn;
  final Value<int> generatedUntil;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String?> lastGenerationError;
  final Value<int> rowid;
  const RecurrencesCompanion({
    this.id = const Value.absent(),
    this.templateJson = const Value.absent(),
    this.freq = const Value.absent(),
    this.intervalN = const Value.absent(),
    this.byMonthDay = const Value.absent(),
    this.byWeekday = const Value.absent(),
    this.weekendRule = const Value.absent(),
    this.amountMode = const Value.absent(),
    this.expectedMinMinor = const Value.absent(),
    this.expectedMaxMinor = const Value.absent(),
    this.startsOn = const Value.absent(),
    this.endsOn = const Value.absent(),
    this.generatedUntil = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.lastGenerationError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurrencesCompanion.insert({
    required String id,
    required String templateJson,
    required String freq,
    this.intervalN = const Value.absent(),
    this.byMonthDay = const Value.absent(),
    this.byWeekday = const Value.absent(),
    this.weekendRule = const Value.absent(),
    this.amountMode = const Value.absent(),
    this.expectedMinMinor = const Value.absent(),
    this.expectedMaxMinor = const Value.absent(),
    required int startsOn,
    this.endsOn = const Value.absent(),
    required int generatedUntil,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    this.lastGenerationError = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        templateJson = Value(templateJson),
        freq = Value(freq),
        startsOn = Value(startsOn),
        generatedUntil = Value(generatedUntil),
        updatedAt = Value(updatedAt);
  static Insertable<Recurrence> custom({
    Expression<String>? id,
    Expression<String>? templateJson,
    Expression<String>? freq,
    Expression<int>? intervalN,
    Expression<int>? byMonthDay,
    Expression<int>? byWeekday,
    Expression<String>? weekendRule,
    Expression<String>? amountMode,
    Expression<int>? expectedMinMinor,
    Expression<int>? expectedMaxMinor,
    Expression<int>? startsOn,
    Expression<int>? endsOn,
    Expression<int>? generatedUntil,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? lastGenerationError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateJson != null) 'template_json': templateJson,
      if (freq != null) 'freq': freq,
      if (intervalN != null) 'interval_n': intervalN,
      if (byMonthDay != null) 'by_month_day': byMonthDay,
      if (byWeekday != null) 'by_weekday': byWeekday,
      if (weekendRule != null) 'weekend_rule': weekendRule,
      if (amountMode != null) 'amount_mode': amountMode,
      if (expectedMinMinor != null) 'expected_min_minor': expectedMinMinor,
      if (expectedMaxMinor != null) 'expected_max_minor': expectedMaxMinor,
      if (startsOn != null) 'starts_on': startsOn,
      if (endsOn != null) 'ends_on': endsOn,
      if (generatedUntil != null) 'generated_until': generatedUntil,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (lastGenerationError != null)
        'last_generation_error': lastGenerationError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurrencesCompanion copyWith(
      {Value<String>? id,
      Value<String>? templateJson,
      Value<String>? freq,
      Value<int>? intervalN,
      Value<int?>? byMonthDay,
      Value<int?>? byWeekday,
      Value<String>? weekendRule,
      Value<String>? amountMode,
      Value<int?>? expectedMinMinor,
      Value<int?>? expectedMaxMinor,
      Value<int>? startsOn,
      Value<int?>? endsOn,
      Value<int>? generatedUntil,
      Value<int>? updatedAt,
      Value<int?>? deletedAt,
      Value<String?>? lastGenerationError,
      Value<int>? rowid}) {
    return RecurrencesCompanion(
      id: id ?? this.id,
      templateJson: templateJson ?? this.templateJson,
      freq: freq ?? this.freq,
      intervalN: intervalN ?? this.intervalN,
      byMonthDay: byMonthDay ?? this.byMonthDay,
      byWeekday: byWeekday ?? this.byWeekday,
      weekendRule: weekendRule ?? this.weekendRule,
      amountMode: amountMode ?? this.amountMode,
      expectedMinMinor: expectedMinMinor ?? this.expectedMinMinor,
      expectedMaxMinor: expectedMaxMinor ?? this.expectedMaxMinor,
      startsOn: startsOn ?? this.startsOn,
      endsOn: endsOn ?? this.endsOn,
      generatedUntil: generatedUntil ?? this.generatedUntil,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      lastGenerationError: lastGenerationError ?? this.lastGenerationError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (templateJson.present) {
      map['template_json'] = Variable<String>(templateJson.value);
    }
    if (freq.present) {
      map['freq'] = Variable<String>(freq.value);
    }
    if (intervalN.present) {
      map['interval_n'] = Variable<int>(intervalN.value);
    }
    if (byMonthDay.present) {
      map['by_month_day'] = Variable<int>(byMonthDay.value);
    }
    if (byWeekday.present) {
      map['by_weekday'] = Variable<int>(byWeekday.value);
    }
    if (weekendRule.present) {
      map['weekend_rule'] = Variable<String>(weekendRule.value);
    }
    if (amountMode.present) {
      map['amount_mode'] = Variable<String>(amountMode.value);
    }
    if (expectedMinMinor.present) {
      map['expected_min_minor'] = Variable<int>(expectedMinMinor.value);
    }
    if (expectedMaxMinor.present) {
      map['expected_max_minor'] = Variable<int>(expectedMaxMinor.value);
    }
    if (startsOn.present) {
      map['starts_on'] = Variable<int>(startsOn.value);
    }
    if (endsOn.present) {
      map['ends_on'] = Variable<int>(endsOn.value);
    }
    if (generatedUntil.present) {
      map['generated_until'] = Variable<int>(generatedUntil.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (lastGenerationError.present) {
      map['last_generation_error'] =
          Variable<String>(lastGenerationError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurrencesCompanion(')
          ..write('id: $id, ')
          ..write('templateJson: $templateJson, ')
          ..write('freq: $freq, ')
          ..write('intervalN: $intervalN, ')
          ..write('byMonthDay: $byMonthDay, ')
          ..write('byWeekday: $byWeekday, ')
          ..write('weekendRule: $weekendRule, ')
          ..write('amountMode: $amountMode, ')
          ..write('expectedMinMinor: $expectedMinMinor, ')
          ..write('expectedMaxMinor: $expectedMaxMinor, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('generatedUntil: $generatedUntil, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('lastGenerationError: $lastGenerationError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurrenceOverridesTable extends RecurrenceOverrides
    with TableInfo<$RecurrenceOverridesTable, RecurrenceOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurrenceOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recurrenceIdMeta =
      const VerificationMeta('recurrenceId');
  @override
  late final GeneratedColumn<String> recurrenceId = GeneratedColumn<String>(
      'recurrence_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _instanceDateMeta =
      const VerificationMeta('instanceDate');
  @override
  late final GeneratedColumn<int> instanceDate = GeneratedColumn<int>(
      'instance_date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _newDateMeta =
      const VerificationMeta('newDate');
  @override
  late final GeneratedColumn<int> newDate = GeneratedColumn<int>(
      'new_date', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _newAmountMinorMeta =
      const VerificationMeta('newAmountMinor');
  @override
  late final GeneratedColumn<int> newAmountMinor = GeneratedColumn<int>(
      'new_amount_minor', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [recurrenceId, instanceDate, action, newDate, newAmountMinor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurrence_overrides';
  @override
  VerificationContext validateIntegrity(Insertable<RecurrenceOverride> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recurrence_id')) {
      context.handle(
          _recurrenceIdMeta,
          recurrenceId.isAcceptableOrUnknown(
              data['recurrence_id']!, _recurrenceIdMeta));
    } else if (isInserting) {
      context.missing(_recurrenceIdMeta);
    }
    if (data.containsKey('instance_date')) {
      context.handle(
          _instanceDateMeta,
          instanceDate.isAcceptableOrUnknown(
              data['instance_date']!, _instanceDateMeta));
    } else if (isInserting) {
      context.missing(_instanceDateMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('new_date')) {
      context.handle(_newDateMeta,
          newDate.isAcceptableOrUnknown(data['new_date']!, _newDateMeta));
    }
    if (data.containsKey('new_amount_minor')) {
      context.handle(
          _newAmountMinorMeta,
          newAmountMinor.isAcceptableOrUnknown(
              data['new_amount_minor']!, _newAmountMinorMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recurrenceId, instanceDate};
  @override
  RecurrenceOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurrenceOverride(
      recurrenceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}recurrence_id'])!,
      instanceDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}instance_date'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      newDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}new_date']),
      newAmountMinor: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}new_amount_minor']),
    );
  }

  @override
  $RecurrenceOverridesTable createAlias(String alias) {
    return $RecurrenceOverridesTable(attachedDatabase, alias);
  }
}

class RecurrenceOverride extends DataClass
    implements Insertable<RecurrenceOverride> {
  final String recurrenceId;
  final int instanceDate;
  final String action;
  final int? newDate;
  final int? newAmountMinor;
  const RecurrenceOverride(
      {required this.recurrenceId,
      required this.instanceDate,
      required this.action,
      this.newDate,
      this.newAmountMinor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recurrence_id'] = Variable<String>(recurrenceId);
    map['instance_date'] = Variable<int>(instanceDate);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || newDate != null) {
      map['new_date'] = Variable<int>(newDate);
    }
    if (!nullToAbsent || newAmountMinor != null) {
      map['new_amount_minor'] = Variable<int>(newAmountMinor);
    }
    return map;
  }

  RecurrenceOverridesCompanion toCompanion(bool nullToAbsent) {
    return RecurrenceOverridesCompanion(
      recurrenceId: Value(recurrenceId),
      instanceDate: Value(instanceDate),
      action: Value(action),
      newDate: newDate == null && nullToAbsent
          ? const Value.absent()
          : Value(newDate),
      newAmountMinor: newAmountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(newAmountMinor),
    );
  }

  factory RecurrenceOverride.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurrenceOverride(
      recurrenceId: serializer.fromJson<String>(json['recurrenceId']),
      instanceDate: serializer.fromJson<int>(json['instanceDate']),
      action: serializer.fromJson<String>(json['action']),
      newDate: serializer.fromJson<int?>(json['newDate']),
      newAmountMinor: serializer.fromJson<int?>(json['newAmountMinor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recurrenceId': serializer.toJson<String>(recurrenceId),
      'instanceDate': serializer.toJson<int>(instanceDate),
      'action': serializer.toJson<String>(action),
      'newDate': serializer.toJson<int?>(newDate),
      'newAmountMinor': serializer.toJson<int?>(newAmountMinor),
    };
  }

  RecurrenceOverride copyWith(
          {String? recurrenceId,
          int? instanceDate,
          String? action,
          Value<int?> newDate = const Value.absent(),
          Value<int?> newAmountMinor = const Value.absent()}) =>
      RecurrenceOverride(
        recurrenceId: recurrenceId ?? this.recurrenceId,
        instanceDate: instanceDate ?? this.instanceDate,
        action: action ?? this.action,
        newDate: newDate.present ? newDate.value : this.newDate,
        newAmountMinor:
            newAmountMinor.present ? newAmountMinor.value : this.newAmountMinor,
      );
  RecurrenceOverride copyWithCompanion(RecurrenceOverridesCompanion data) {
    return RecurrenceOverride(
      recurrenceId: data.recurrenceId.present
          ? data.recurrenceId.value
          : this.recurrenceId,
      instanceDate: data.instanceDate.present
          ? data.instanceDate.value
          : this.instanceDate,
      action: data.action.present ? data.action.value : this.action,
      newDate: data.newDate.present ? data.newDate.value : this.newDate,
      newAmountMinor: data.newAmountMinor.present
          ? data.newAmountMinor.value
          : this.newAmountMinor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceOverride(')
          ..write('recurrenceId: $recurrenceId, ')
          ..write('instanceDate: $instanceDate, ')
          ..write('action: $action, ')
          ..write('newDate: $newDate, ')
          ..write('newAmountMinor: $newAmountMinor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(recurrenceId, instanceDate, action, newDate, newAmountMinor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurrenceOverride &&
          other.recurrenceId == this.recurrenceId &&
          other.instanceDate == this.instanceDate &&
          other.action == this.action &&
          other.newDate == this.newDate &&
          other.newAmountMinor == this.newAmountMinor);
}

class RecurrenceOverridesCompanion extends UpdateCompanion<RecurrenceOverride> {
  final Value<String> recurrenceId;
  final Value<int> instanceDate;
  final Value<String> action;
  final Value<int?> newDate;
  final Value<int?> newAmountMinor;
  final Value<int> rowid;
  const RecurrenceOverridesCompanion({
    this.recurrenceId = const Value.absent(),
    this.instanceDate = const Value.absent(),
    this.action = const Value.absent(),
    this.newDate = const Value.absent(),
    this.newAmountMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurrenceOverridesCompanion.insert({
    required String recurrenceId,
    required int instanceDate,
    required String action,
    this.newDate = const Value.absent(),
    this.newAmountMinor = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : recurrenceId = Value(recurrenceId),
        instanceDate = Value(instanceDate),
        action = Value(action);
  static Insertable<RecurrenceOverride> custom({
    Expression<String>? recurrenceId,
    Expression<int>? instanceDate,
    Expression<String>? action,
    Expression<int>? newDate,
    Expression<int>? newAmountMinor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recurrenceId != null) 'recurrence_id': recurrenceId,
      if (instanceDate != null) 'instance_date': instanceDate,
      if (action != null) 'action': action,
      if (newDate != null) 'new_date': newDate,
      if (newAmountMinor != null) 'new_amount_minor': newAmountMinor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurrenceOverridesCompanion copyWith(
      {Value<String>? recurrenceId,
      Value<int>? instanceDate,
      Value<String>? action,
      Value<int?>? newDate,
      Value<int?>? newAmountMinor,
      Value<int>? rowid}) {
    return RecurrenceOverridesCompanion(
      recurrenceId: recurrenceId ?? this.recurrenceId,
      instanceDate: instanceDate ?? this.instanceDate,
      action: action ?? this.action,
      newDate: newDate ?? this.newDate,
      newAmountMinor: newAmountMinor ?? this.newAmountMinor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recurrenceId.present) {
      map['recurrence_id'] = Variable<String>(recurrenceId.value);
    }
    if (instanceDate.present) {
      map['instance_date'] = Variable<int>(instanceDate.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (newDate.present) {
      map['new_date'] = Variable<int>(newDate.value);
    }
    if (newAmountMinor.present) {
      map['new_amount_minor'] = Variable<int>(newAmountMinor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurrenceOverridesCompanion(')
          ..write('recurrenceId: $recurrenceId, ')
          ..write('instanceDate: $instanceDate, ')
          ..write('action: $action, ')
          ..write('newDate: $newDate, ')
          ..write('newAmountMinor: $newAmountMinor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$WudgetDatabase extends GeneratedDatabase {
  _$WudgetDatabase(QueryExecutor e) : super(e);
  $WudgetDatabaseManager get managers => $WudgetDatabaseManager(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $PostingsTable postings = $PostingsTable(this);
  late final $DailyTotalsTable dailyTotals = $DailyTotalsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $FeatureFlagsTable featureFlags = $FeatureFlagsTable(this);
  late final $AnalyticsEventsTable analyticsEvents =
      $AnalyticsEventsTable(this);
  late final $RecurrencesTable recurrences = $RecurrencesTable(this);
  late final $RecurrenceOverridesTable recurrenceOverrides =
      $RecurrenceOverridesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        accounts,
        categories,
        transactions,
        postings,
        dailyTotals,
        appSettings,
        budgets,
        featureFlags,
        analyticsEvents,
        recurrences,
        recurrenceOverrides
      ];
}

typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  required String id,
  required String name,
  required String type,
  Value<String?> providerKey,
  required String currency,
  Value<int> openingMinor,
  Value<int?> statementDay,
  Value<int?> dueDay,
  Value<int?> creditLimitMinor,
  Value<int?> archivedAt,
  Value<String?> householdId,
  Value<String> visibility,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<String?> deviceId,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> type,
  Value<String?> providerKey,
  Value<String> currency,
  Value<int> openingMinor,
  Value<int?> statementDay,
  Value<int?> dueDay,
  Value<int?> creditLimitMinor,
  Value<int?> archivedAt,
  Value<String?> householdId,
  Value<String> visibility,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String?> deviceId,
  Value<int> rowid,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$WudgetDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PostingsTable, List<Posting>> _postingsRefsTable(
          _$WudgetDatabase db) =>
      MultiTypedResultKey.fromTable(db.postings,
          aliasName:
              $_aliasNameGenerator(db.accounts.id, db.postings.accountId));

  $$PostingsTableProcessedTableManager get postingsRefs {
    final manager = $$PostingsTableTableManager($_db, $_db.postings)
        .filter((f) => f.accountId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_postingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$WudgetDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get providerKey => $composableBuilder(
      column: $table.providerKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get openingMinor => $composableBuilder(
      column: $table.openingMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get statementDay => $composableBuilder(
      column: $table.statementDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueDay => $composableBuilder(
      column: $table.dueDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get creditLimitMinor => $composableBuilder(
      column: $table.creditLimitMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  Expression<bool> postingsRefs(
      Expression<bool> Function($$PostingsTableFilterComposer f) f) {
    final $$PostingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.postings,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PostingsTableFilterComposer(
              $db: $db,
              $table: $db.postings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$WudgetDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get providerKey => $composableBuilder(
      column: $table.providerKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get openingMinor => $composableBuilder(
      column: $table.openingMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get statementDay => $composableBuilder(
      column: $table.statementDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueDay => $composableBuilder(
      column: $table.dueDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get creditLimitMinor => $composableBuilder(
      column: $table.creditLimitMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$WudgetDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get providerKey => $composableBuilder(
      column: $table.providerKey, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get openingMinor => $composableBuilder(
      column: $table.openingMinor, builder: (column) => column);

  GeneratedColumn<int> get statementDay => $composableBuilder(
      column: $table.statementDay, builder: (column) => column);

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<int> get creditLimitMinor => $composableBuilder(
      column: $table.creditLimitMinor, builder: (column) => column);

  GeneratedColumn<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  Expression<T> postingsRefs<T extends Object>(
      Expression<T> Function($$PostingsTableAnnotationComposer a) f) {
    final $$PostingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.postings,
        getReferencedColumn: (t) => t.accountId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PostingsTableAnnotationComposer(
              $db: $db,
              $table: $db.postings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AccountsTableTableManager extends RootTableManager<
    _$WudgetDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function({bool postingsRefs})> {
  $$AccountsTableTableManager(_$WudgetDatabase db, $AccountsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> providerKey = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<int> openingMinor = const Value.absent(),
            Value<int?> statementDay = const Value.absent(),
            Value<int?> dueDay = const Value.absent(),
            Value<int?> creditLimitMinor = const Value.absent(),
            Value<int?> archivedAt = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<String?> deviceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion(
            id: id,
            name: name,
            type: type,
            providerKey: providerKey,
            currency: currency,
            openingMinor: openingMinor,
            statementDay: statementDay,
            dueDay: dueDay,
            creditLimitMinor: creditLimitMinor,
            archivedAt: archivedAt,
            householdId: householdId,
            visibility: visibility,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            deviceId: deviceId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required String type,
            Value<String?> providerKey = const Value.absent(),
            required String currency,
            Value<int> openingMinor = const Value.absent(),
            Value<int?> statementDay = const Value.absent(),
            Value<int?> dueDay = const Value.absent(),
            Value<int?> creditLimitMinor = const Value.absent(),
            Value<int?> archivedAt = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<String?> deviceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AccountsCompanion.insert(
            id: id,
            name: name,
            type: type,
            providerKey: providerKey,
            currency: currency,
            openingMinor: openingMinor,
            statementDay: statementDay,
            dueDay: dueDay,
            creditLimitMinor: creditLimitMinor,
            archivedAt: archivedAt,
            householdId: householdId,
            visibility: visibility,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            deviceId: deviceId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$AccountsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({postingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (postingsRefs) db.postings],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (postingsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$AccountsTableReferences._postingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AccountsTableReferences(db, table, p0)
                                .postingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.accountId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AccountsTableProcessedTableManager = ProcessedTableManager<
    _$WudgetDatabase,
    $AccountsTable,
    Account,
    $$AccountsTableFilterComposer,
    $$AccountsTableOrderingComposer,
    $$AccountsTableAnnotationComposer,
    $$AccountsTableCreateCompanionBuilder,
    $$AccountsTableUpdateCompanionBuilder,
    (Account, $$AccountsTableReferences),
    Account,
    PrefetchHooks Function({bool postingsRefs})>;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  Value<String?> parentId,
  required String name,
  required String kind,
  required String iconKey,
  required int hueIndex,
  Value<bool> isIrregular,
  required int sortOrder,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String?> parentId,
  Value<String> name,
  Value<String> kind,
  Value<String> iconKey,
  Value<int> hueIndex,
  Value<bool> isIrregular,
  Value<int> sortOrder,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$WudgetDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _parentIdTable(_$WudgetDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.categories.parentId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get parentId {
    if ($_item.parentId == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.parentId!));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PostingsTable, List<Posting>> _postingsRefsTable(
          _$WudgetDatabase db) =>
      MultiTypedResultKey.fromTable(db.postings,
          aliasName:
              $_aliasNameGenerator(db.categories.id, db.postings.categoryId));

  $$PostingsTableProcessedTableManager get postingsRefs {
    final manager = $$PostingsTableTableManager($_db, $_db.postings)
        .filter((f) => f.categoryId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_postingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$WudgetDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get hueIndex => $composableBuilder(
      column: $table.hueIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isIrregular => $composableBuilder(
      column: $table.isIrregular, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get parentId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> postingsRefs(
      Expression<bool> Function($$PostingsTableFilterComposer f) f) {
    final $$PostingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.postings,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PostingsTableFilterComposer(
              $db: $db,
              $table: $db.postings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$WudgetDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get hueIndex => $composableBuilder(
      column: $table.hueIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isIrregular => $composableBuilder(
      column: $table.isIrregular, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get parentId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$WudgetDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get hueIndex =>
      $composableBuilder(column: $table.hueIndex, builder: (column) => column);

  GeneratedColumn<bool> get isIrregular => $composableBuilder(
      column: $table.isIrregular, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get parentId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.parentId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> postingsRefs<T extends Object>(
      Expression<T> Function($$PostingsTableAnnotationComposer a) f) {
    final $$PostingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.postings,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PostingsTableAnnotationComposer(
              $db: $db,
              $table: $db.postings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$WudgetDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function({bool parentId, bool postingsRefs})> {
  $$CategoriesTableTableManager(_$WudgetDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> iconKey = const Value.absent(),
            Value<int> hueIndex = const Value.absent(),
            Value<bool> isIrregular = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            parentId: parentId,
            name: name,
            kind: kind,
            iconKey: iconKey,
            hueIndex: hueIndex,
            isIrregular: isIrregular,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> parentId = const Value.absent(),
            required String name,
            required String kind,
            required String iconKey,
            required int hueIndex,
            Value<bool> isIrregular = const Value.absent(),
            required int sortOrder,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            parentId: parentId,
            name: name,
            kind: kind,
            iconKey: iconKey,
            hueIndex: hueIndex,
            isIrregular: isIrregular,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({parentId = false, postingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (postingsRefs) db.postings],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (parentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.parentId,
                    referencedTable:
                        $$CategoriesTableReferences._parentIdTable(db),
                    referencedColumn:
                        $$CategoriesTableReferences._parentIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (postingsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$CategoriesTableReferences._postingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .postingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$WudgetDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function({bool parentId, bool postingsRefs})>;
typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  required String id,
  required String kind,
  required int occurredAt,
  required int tzOffsetMinutes,
  Value<String?> title,
  Value<String?> note,
  Value<String?> photoPath,
  Value<String?> recurrenceId,
  Value<bool> isProjected,
  Value<double?> lat,
  Value<double?> lon,
  Value<String?> householdId,
  Value<String> visibility,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<String?> deviceId,
  Value<int> rowid,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<String> id,
  Value<String> kind,
  Value<int> occurredAt,
  Value<int> tzOffsetMinutes,
  Value<String?> title,
  Value<String?> note,
  Value<String?> photoPath,
  Value<String?> recurrenceId,
  Value<bool> isProjected,
  Value<double?> lat,
  Value<double?> lon,
  Value<String?> householdId,
  Value<String> visibility,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String?> deviceId,
  Value<int> rowid,
});

final class $$TransactionsTableReferences
    extends BaseReferences<_$WudgetDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PostingsTable, List<Posting>> _postingsRefsTable(
          _$WudgetDatabase db) =>
      MultiTypedResultKey.fromTable(db.postings,
          aliasName: $_aliasNameGenerator(
              db.transactions.id, db.postings.transactionId));

  $$PostingsTableProcessedTableManager get postingsRefs {
    final manager = $$PostingsTableTableManager($_db, $_db.postings)
        .filter((f) => f.transactionId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_postingsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$WudgetDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get tzOffsetMinutes => $composableBuilder(
      column: $table.tzOffsetMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get recurrenceId => $composableBuilder(
      column: $table.recurrenceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isProjected => $composableBuilder(
      column: $table.isProjected, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnFilters(column));

  Expression<bool> postingsRefs(
      Expression<bool> Function($$PostingsTableFilterComposer f) f) {
    final $$PostingsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.postings,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PostingsTableFilterComposer(
              $db: $db,
              $table: $db.postings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$WudgetDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get tzOffsetMinutes => $composableBuilder(
      column: $table.tzOffsetMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoPath => $composableBuilder(
      column: $table.photoPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get recurrenceId => $composableBuilder(
      column: $table.recurrenceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isProjected => $composableBuilder(
      column: $table.isProjected, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId => $composableBuilder(
      column: $table.deviceId, builder: (column) => ColumnOrderings(column));
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$WudgetDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);

  GeneratedColumn<int> get tzOffsetMinutes => $composableBuilder(
      column: $table.tzOffsetMinutes, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<String> get recurrenceId => $composableBuilder(
      column: $table.recurrenceId, builder: (column) => column);

  GeneratedColumn<bool> get isProjected => $composableBuilder(
      column: $table.isProjected, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<String> get householdId => $composableBuilder(
      column: $table.householdId, builder: (column) => column);

  GeneratedColumn<String> get visibility => $composableBuilder(
      column: $table.visibility, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  Expression<T> postingsRefs<T extends Object>(
      Expression<T> Function($$PostingsTableAnnotationComposer a) f) {
    final $$PostingsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.postings,
        getReferencedColumn: (t) => t.transactionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PostingsTableAnnotationComposer(
              $db: $db,
              $table: $db.postings,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$WudgetDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function({bool postingsRefs})> {
  $$TransactionsTableTableManager(_$WudgetDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<int> occurredAt = const Value.absent(),
            Value<int> tzOffsetMinutes = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<String?> recurrenceId = const Value.absent(),
            Value<bool> isProjected = const Value.absent(),
            Value<double?> lat = const Value.absent(),
            Value<double?> lon = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<String?> deviceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            kind: kind,
            occurredAt: occurredAt,
            tzOffsetMinutes: tzOffsetMinutes,
            title: title,
            note: note,
            photoPath: photoPath,
            recurrenceId: recurrenceId,
            isProjected: isProjected,
            lat: lat,
            lon: lon,
            householdId: householdId,
            visibility: visibility,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            deviceId: deviceId,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String kind,
            required int occurredAt,
            required int tzOffsetMinutes,
            Value<String?> title = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> photoPath = const Value.absent(),
            Value<String?> recurrenceId = const Value.absent(),
            Value<bool> isProjected = const Value.absent(),
            Value<double?> lat = const Value.absent(),
            Value<double?> lon = const Value.absent(),
            Value<String?> householdId = const Value.absent(),
            Value<String> visibility = const Value.absent(),
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<String?> deviceId = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TransactionsCompanion.insert(
            id: id,
            kind: kind,
            occurredAt: occurredAt,
            tzOffsetMinutes: tzOffsetMinutes,
            title: title,
            note: note,
            photoPath: photoPath,
            recurrenceId: recurrenceId,
            isProjected: isProjected,
            lat: lat,
            lon: lon,
            householdId: householdId,
            visibility: visibility,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            deviceId: deviceId,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({postingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (postingsRefs) db.postings],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (postingsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$TransactionsTableReferences
                            ._postingsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$TransactionsTableReferences(db, table, p0)
                                .postingsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.transactionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$WudgetDatabase,
    $TransactionsTable,
    Transaction,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (Transaction, $$TransactionsTableReferences),
    Transaction,
    PrefetchHooks Function({bool postingsRefs})>;
typedef $$PostingsTableCreateCompanionBuilder = PostingsCompanion Function({
  required String id,
  required String transactionId,
  Value<String?> accountId,
  Value<String?> categoryId,
  required int amountMinor,
  required String currency,
  Value<double> rateToBase,
  required int baseAmountMinor,
  Value<int> rowid,
});
typedef $$PostingsTableUpdateCompanionBuilder = PostingsCompanion Function({
  Value<String> id,
  Value<String> transactionId,
  Value<String?> accountId,
  Value<String?> categoryId,
  Value<int> amountMinor,
  Value<String> currency,
  Value<double> rateToBase,
  Value<int> baseAmountMinor,
  Value<int> rowid,
});

final class $$PostingsTableReferences
    extends BaseReferences<_$WudgetDatabase, $PostingsTable, Posting> {
  $$PostingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $TransactionsTable _transactionIdTable(_$WudgetDatabase db) =>
      db.transactions.createAlias(
          $_aliasNameGenerator(db.postings.transactionId, db.transactions.id));

  $$TransactionsTableProcessedTableManager get transactionId {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.id($_item.transactionId));
    final item = $_typedResult.readTableOrNull(_transactionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $AccountsTable _accountIdTable(_$WudgetDatabase db) => db.accounts
      .createAlias($_aliasNameGenerator(db.postings.accountId, db.accounts.id));

  $$AccountsTableProcessedTableManager? get accountId {
    if ($_item.accountId == null) return null;
    final manager = $$AccountsTableTableManager($_db, $_db.accounts)
        .filter((f) => f.id($_item.accountId!));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $CategoriesTable _categoryIdTable(_$WudgetDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.postings.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    if ($_item.categoryId == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.categoryId!));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PostingsTableFilterComposer
    extends Composer<_$WudgetDatabase, $PostingsTable> {
  $$PostingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rateToBase => $composableBuilder(
      column: $table.rateToBase, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get baseAmountMinor => $composableBuilder(
      column: $table.baseAmountMinor,
      builder: (column) => ColumnFilters(column));

  $$TransactionsTableFilterComposer get transactionId {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableFilterComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PostingsTableOrderingComposer
    extends Composer<_$WudgetDatabase, $PostingsTable> {
  $$PostingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currency => $composableBuilder(
      column: $table.currency, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rateToBase => $composableBuilder(
      column: $table.rateToBase, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get baseAmountMinor => $composableBuilder(
      column: $table.baseAmountMinor,
      builder: (column) => ColumnOrderings(column));

  $$TransactionsTableOrderingComposer get transactionId {
    final $$TransactionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableOrderingComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableOrderingComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PostingsTableAnnotationComposer
    extends Composer<_$WudgetDatabase, $PostingsTable> {
  $$PostingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<double> get rateToBase => $composableBuilder(
      column: $table.rateToBase, builder: (column) => column);

  GeneratedColumn<int> get baseAmountMinor => $composableBuilder(
      column: $table.baseAmountMinor, builder: (column) => column);

  $$TransactionsTableAnnotationComposer get transactionId {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.transactionId,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.accountId,
        referencedTable: $db.accounts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AccountsTableAnnotationComposer(
              $db: $db,
              $table: $db.accounts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PostingsTableTableManager extends RootTableManager<
    _$WudgetDatabase,
    $PostingsTable,
    Posting,
    $$PostingsTableFilterComposer,
    $$PostingsTableOrderingComposer,
    $$PostingsTableAnnotationComposer,
    $$PostingsTableCreateCompanionBuilder,
    $$PostingsTableUpdateCompanionBuilder,
    (Posting, $$PostingsTableReferences),
    Posting,
    PrefetchHooks Function(
        {bool transactionId, bool accountId, bool categoryId})> {
  $$PostingsTableTableManager(_$WudgetDatabase db, $PostingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PostingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PostingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PostingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> transactionId = const Value.absent(),
            Value<String?> accountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            Value<int> amountMinor = const Value.absent(),
            Value<String> currency = const Value.absent(),
            Value<double> rateToBase = const Value.absent(),
            Value<int> baseAmountMinor = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PostingsCompanion(
            id: id,
            transactionId: transactionId,
            accountId: accountId,
            categoryId: categoryId,
            amountMinor: amountMinor,
            currency: currency,
            rateToBase: rateToBase,
            baseAmountMinor: baseAmountMinor,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String transactionId,
            Value<String?> accountId = const Value.absent(),
            Value<String?> categoryId = const Value.absent(),
            required int amountMinor,
            required String currency,
            Value<double> rateToBase = const Value.absent(),
            required int baseAmountMinor,
            Value<int> rowid = const Value.absent(),
          }) =>
              PostingsCompanion.insert(
            id: id,
            transactionId: transactionId,
            accountId: accountId,
            categoryId: categoryId,
            amountMinor: amountMinor,
            currency: currency,
            rateToBase: rateToBase,
            baseAmountMinor: baseAmountMinor,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$PostingsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {transactionId = false, accountId = false, categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (transactionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.transactionId,
                    referencedTable:
                        $$PostingsTableReferences._transactionIdTable(db),
                    referencedColumn:
                        $$PostingsTableReferences._transactionIdTable(db).id,
                  ) as T;
                }
                if (accountId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.accountId,
                    referencedTable:
                        $$PostingsTableReferences._accountIdTable(db),
                    referencedColumn:
                        $$PostingsTableReferences._accountIdTable(db).id,
                  ) as T;
                }
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$PostingsTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$PostingsTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PostingsTableProcessedTableManager = ProcessedTableManager<
    _$WudgetDatabase,
    $PostingsTable,
    Posting,
    $$PostingsTableFilterComposer,
    $$PostingsTableOrderingComposer,
    $$PostingsTableAnnotationComposer,
    $$PostingsTableCreateCompanionBuilder,
    $$PostingsTableUpdateCompanionBuilder,
    (Posting, $$PostingsTableReferences),
    Posting,
    PrefetchHooks Function(
        {bool transactionId, bool accountId, bool categoryId})>;
typedef $$DailyTotalsTableCreateCompanionBuilder = DailyTotalsCompanion
    Function({
  Value<int> day,
  required int netMinor,
});
typedef $$DailyTotalsTableUpdateCompanionBuilder = DailyTotalsCompanion
    Function({
  Value<int> day,
  Value<int> netMinor,
});

class $$DailyTotalsTableFilterComposer
    extends Composer<_$WudgetDatabase, $DailyTotalsTable> {
  $$DailyTotalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get netMinor => $composableBuilder(
      column: $table.netMinor, builder: (column) => ColumnFilters(column));
}

class $$DailyTotalsTableOrderingComposer
    extends Composer<_$WudgetDatabase, $DailyTotalsTable> {
  $$DailyTotalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get day => $composableBuilder(
      column: $table.day, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get netMinor => $composableBuilder(
      column: $table.netMinor, builder: (column) => ColumnOrderings(column));
}

class $$DailyTotalsTableAnnotationComposer
    extends Composer<_$WudgetDatabase, $DailyTotalsTable> {
  $$DailyTotalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get netMinor =>
      $composableBuilder(column: $table.netMinor, builder: (column) => column);
}

class $$DailyTotalsTableTableManager extends RootTableManager<
    _$WudgetDatabase,
    $DailyTotalsTable,
    DailyTotal,
    $$DailyTotalsTableFilterComposer,
    $$DailyTotalsTableOrderingComposer,
    $$DailyTotalsTableAnnotationComposer,
    $$DailyTotalsTableCreateCompanionBuilder,
    $$DailyTotalsTableUpdateCompanionBuilder,
    (
      DailyTotal,
      BaseReferences<_$WudgetDatabase, $DailyTotalsTable, DailyTotal>
    ),
    DailyTotal,
    PrefetchHooks Function()> {
  $$DailyTotalsTableTableManager(_$WudgetDatabase db, $DailyTotalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyTotalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyTotalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyTotalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> day = const Value.absent(),
            Value<int> netMinor = const Value.absent(),
          }) =>
              DailyTotalsCompanion(
            day: day,
            netMinor: netMinor,
          ),
          createCompanionCallback: ({
            Value<int> day = const Value.absent(),
            required int netMinor,
          }) =>
              DailyTotalsCompanion.insert(
            day: day,
            netMinor: netMinor,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyTotalsTableProcessedTableManager = ProcessedTableManager<
    _$WudgetDatabase,
    $DailyTotalsTable,
    DailyTotal,
    $$DailyTotalsTableFilterComposer,
    $$DailyTotalsTableOrderingComposer,
    $$DailyTotalsTableAnnotationComposer,
    $$DailyTotalsTableCreateCompanionBuilder,
    $$DailyTotalsTableUpdateCompanionBuilder,
    (
      DailyTotal,
      BaseReferences<_$WudgetDatabase, $DailyTotalsTable, DailyTotal>
    ),
    DailyTotal,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  Value<int> periodStartDay,
  Value<int?> lastAcknowledgedPeriodClose,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<int> id,
  Value<int> periodStartDay,
  Value<int?> lastAcknowledgedPeriodClose,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$WudgetDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get periodStartDay => $composableBuilder(
      column: $table.periodStartDay,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastAcknowledgedPeriodClose => $composableBuilder(
      column: $table.lastAcknowledgedPeriodClose,
      builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$WudgetDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get periodStartDay => $composableBuilder(
      column: $table.periodStartDay,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastAcknowledgedPeriodClose => $composableBuilder(
      column: $table.lastAcknowledgedPeriodClose,
      builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$WudgetDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get periodStartDay => $composableBuilder(
      column: $table.periodStartDay, builder: (column) => column);

  GeneratedColumn<int> get lastAcknowledgedPeriodClose => $composableBuilder(
      column: $table.lastAcknowledgedPeriodClose, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$WudgetDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      AppSetting,
      BaseReferences<_$WudgetDatabase, $AppSettingsTable, AppSetting>
    ),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$WudgetDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> periodStartDay = const Value.absent(),
            Value<int?> lastAcknowledgedPeriodClose = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            id: id,
            periodStartDay: periodStartDay,
            lastAcknowledgedPeriodClose: lastAcknowledgedPeriodClose,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> periodStartDay = const Value.absent(),
            Value<int?> lastAcknowledgedPeriodClose = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            id: id,
            periodStartDay: periodStartDay,
            lastAcknowledgedPeriodClose: lastAcknowledgedPeriodClose,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$WudgetDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (
      AppSetting,
      BaseReferences<_$WudgetDatabase, $AppSettingsTable, AppSetting>
    ),
    AppSetting,
    PrefetchHooks Function()>;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  required String key,
  required int amountMinor,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> key,
  Value<int> amountMinor,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$BudgetsTableFilterComposer
    extends Composer<_$WudgetDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$WudgetDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$WudgetDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
      column: $table.amountMinor, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BudgetsTableTableManager extends RootTableManager<
    _$WudgetDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, BaseReferences<_$WudgetDatabase, $BudgetsTable, Budget>),
    Budget,
    PrefetchHooks Function()> {
  $$BudgetsTableTableManager(_$WudgetDatabase db, $BudgetsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<int> amountMinor = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion(
            key: key,
            amountMinor: amountMinor,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required int amountMinor,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BudgetsCompanion.insert(
            key: key,
            amountMinor: amountMinor,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BudgetsTableProcessedTableManager = ProcessedTableManager<
    _$WudgetDatabase,
    $BudgetsTable,
    Budget,
    $$BudgetsTableFilterComposer,
    $$BudgetsTableOrderingComposer,
    $$BudgetsTableAnnotationComposer,
    $$BudgetsTableCreateCompanionBuilder,
    $$BudgetsTableUpdateCompanionBuilder,
    (Budget, BaseReferences<_$WudgetDatabase, $BudgetsTable, Budget>),
    Budget,
    PrefetchHooks Function()>;
typedef $$FeatureFlagsTableCreateCompanionBuilder = FeatureFlagsCompanion
    Function({
  required String key,
  required bool value,
  Value<int> rowid,
});
typedef $$FeatureFlagsTableUpdateCompanionBuilder = FeatureFlagsCompanion
    Function({
  Value<String> key,
  Value<bool> value,
  Value<int> rowid,
});

class $$FeatureFlagsTableFilterComposer
    extends Composer<_$WudgetDatabase, $FeatureFlagsTable> {
  $$FeatureFlagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$FeatureFlagsTableOrderingComposer
    extends Composer<_$WudgetDatabase, $FeatureFlagsTable> {
  $$FeatureFlagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$FeatureFlagsTableAnnotationComposer
    extends Composer<_$WudgetDatabase, $FeatureFlagsTable> {
  $$FeatureFlagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<bool> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$FeatureFlagsTableTableManager extends RootTableManager<
    _$WudgetDatabase,
    $FeatureFlagsTable,
    FeatureFlag,
    $$FeatureFlagsTableFilterComposer,
    $$FeatureFlagsTableOrderingComposer,
    $$FeatureFlagsTableAnnotationComposer,
    $$FeatureFlagsTableCreateCompanionBuilder,
    $$FeatureFlagsTableUpdateCompanionBuilder,
    (
      FeatureFlag,
      BaseReferences<_$WudgetDatabase, $FeatureFlagsTable, FeatureFlag>
    ),
    FeatureFlag,
    PrefetchHooks Function()> {
  $$FeatureFlagsTableTableManager(_$WudgetDatabase db, $FeatureFlagsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeatureFlagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeatureFlagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeatureFlagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<bool> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              FeatureFlagsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required bool value,
            Value<int> rowid = const Value.absent(),
          }) =>
              FeatureFlagsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$FeatureFlagsTableProcessedTableManager = ProcessedTableManager<
    _$WudgetDatabase,
    $FeatureFlagsTable,
    FeatureFlag,
    $$FeatureFlagsTableFilterComposer,
    $$FeatureFlagsTableOrderingComposer,
    $$FeatureFlagsTableAnnotationComposer,
    $$FeatureFlagsTableCreateCompanionBuilder,
    $$FeatureFlagsTableUpdateCompanionBuilder,
    (
      FeatureFlag,
      BaseReferences<_$WudgetDatabase, $FeatureFlagsTable, FeatureFlag>
    ),
    FeatureFlag,
    PrefetchHooks Function()>;
typedef $$AnalyticsEventsTableCreateCompanionBuilder = AnalyticsEventsCompanion
    Function({
  required String id,
  required String name,
  Value<String?> propsJson,
  required int occurredAt,
  Value<int> rowid,
});
typedef $$AnalyticsEventsTableUpdateCompanionBuilder = AnalyticsEventsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> propsJson,
  Value<int> occurredAt,
  Value<int> rowid,
});

class $$AnalyticsEventsTableFilterComposer
    extends Composer<_$WudgetDatabase, $AnalyticsEventsTable> {
  $$AnalyticsEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get propsJson => $composableBuilder(
      column: $table.propsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnFilters(column));
}

class $$AnalyticsEventsTableOrderingComposer
    extends Composer<_$WudgetDatabase, $AnalyticsEventsTable> {
  $$AnalyticsEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get propsJson => $composableBuilder(
      column: $table.propsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => ColumnOrderings(column));
}

class $$AnalyticsEventsTableAnnotationComposer
    extends Composer<_$WudgetDatabase, $AnalyticsEventsTable> {
  $$AnalyticsEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get propsJson =>
      $composableBuilder(column: $table.propsJson, builder: (column) => column);

  GeneratedColumn<int> get occurredAt => $composableBuilder(
      column: $table.occurredAt, builder: (column) => column);
}

class $$AnalyticsEventsTableTableManager extends RootTableManager<
    _$WudgetDatabase,
    $AnalyticsEventsTable,
    AnalyticsEvent,
    $$AnalyticsEventsTableFilterComposer,
    $$AnalyticsEventsTableOrderingComposer,
    $$AnalyticsEventsTableAnnotationComposer,
    $$AnalyticsEventsTableCreateCompanionBuilder,
    $$AnalyticsEventsTableUpdateCompanionBuilder,
    (
      AnalyticsEvent,
      BaseReferences<_$WudgetDatabase, $AnalyticsEventsTable, AnalyticsEvent>
    ),
    AnalyticsEvent,
    PrefetchHooks Function()> {
  $$AnalyticsEventsTableTableManager(
      _$WudgetDatabase db, $AnalyticsEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalyticsEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalyticsEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnalyticsEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> propsJson = const Value.absent(),
            Value<int> occurredAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnalyticsEventsCompanion(
            id: id,
            name: name,
            propsJson: propsJson,
            occurredAt: occurredAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> propsJson = const Value.absent(),
            required int occurredAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AnalyticsEventsCompanion.insert(
            id: id,
            name: name,
            propsJson: propsJson,
            occurredAt: occurredAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AnalyticsEventsTableProcessedTableManager = ProcessedTableManager<
    _$WudgetDatabase,
    $AnalyticsEventsTable,
    AnalyticsEvent,
    $$AnalyticsEventsTableFilterComposer,
    $$AnalyticsEventsTableOrderingComposer,
    $$AnalyticsEventsTableAnnotationComposer,
    $$AnalyticsEventsTableCreateCompanionBuilder,
    $$AnalyticsEventsTableUpdateCompanionBuilder,
    (
      AnalyticsEvent,
      BaseReferences<_$WudgetDatabase, $AnalyticsEventsTable, AnalyticsEvent>
    ),
    AnalyticsEvent,
    PrefetchHooks Function()>;
typedef $$RecurrencesTableCreateCompanionBuilder = RecurrencesCompanion
    Function({
  required String id,
  required String templateJson,
  required String freq,
  Value<int> intervalN,
  Value<int?> byMonthDay,
  Value<int?> byWeekday,
  Value<String> weekendRule,
  Value<String> amountMode,
  Value<int?> expectedMinMinor,
  Value<int?> expectedMaxMinor,
  required int startsOn,
  Value<int?> endsOn,
  required int generatedUntil,
  required int updatedAt,
  Value<int?> deletedAt,
  Value<String?> lastGenerationError,
  Value<int> rowid,
});
typedef $$RecurrencesTableUpdateCompanionBuilder = RecurrencesCompanion
    Function({
  Value<String> id,
  Value<String> templateJson,
  Value<String> freq,
  Value<int> intervalN,
  Value<int?> byMonthDay,
  Value<int?> byWeekday,
  Value<String> weekendRule,
  Value<String> amountMode,
  Value<int?> expectedMinMinor,
  Value<int?> expectedMaxMinor,
  Value<int> startsOn,
  Value<int?> endsOn,
  Value<int> generatedUntil,
  Value<int> updatedAt,
  Value<int?> deletedAt,
  Value<String?> lastGenerationError,
  Value<int> rowid,
});

class $$RecurrencesTableFilterComposer
    extends Composer<_$WudgetDatabase, $RecurrencesTable> {
  $$RecurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get templateJson => $composableBuilder(
      column: $table.templateJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get freq => $composableBuilder(
      column: $table.freq, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get intervalN => $composableBuilder(
      column: $table.intervalN, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get byMonthDay => $composableBuilder(
      column: $table.byMonthDay, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get byWeekday => $composableBuilder(
      column: $table.byWeekday, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get weekendRule => $composableBuilder(
      column: $table.weekendRule, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get amountMode => $composableBuilder(
      column: $table.amountMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expectedMinMinor => $composableBuilder(
      column: $table.expectedMinMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get expectedMaxMinor => $composableBuilder(
      column: $table.expectedMaxMinor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startsOn => $composableBuilder(
      column: $table.startsOn, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endsOn => $composableBuilder(
      column: $table.endsOn, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get generatedUntil => $composableBuilder(
      column: $table.generatedUntil,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastGenerationError => $composableBuilder(
      column: $table.lastGenerationError,
      builder: (column) => ColumnFilters(column));
}

class $$RecurrencesTableOrderingComposer
    extends Composer<_$WudgetDatabase, $RecurrencesTable> {
  $$RecurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get templateJson => $composableBuilder(
      column: $table.templateJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get freq => $composableBuilder(
      column: $table.freq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get intervalN => $composableBuilder(
      column: $table.intervalN, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get byMonthDay => $composableBuilder(
      column: $table.byMonthDay, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get byWeekday => $composableBuilder(
      column: $table.byWeekday, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get weekendRule => $composableBuilder(
      column: $table.weekendRule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get amountMode => $composableBuilder(
      column: $table.amountMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expectedMinMinor => $composableBuilder(
      column: $table.expectedMinMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get expectedMaxMinor => $composableBuilder(
      column: $table.expectedMaxMinor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startsOn => $composableBuilder(
      column: $table.startsOn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endsOn => $composableBuilder(
      column: $table.endsOn, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get generatedUntil => $composableBuilder(
      column: $table.generatedUntil,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastGenerationError => $composableBuilder(
      column: $table.lastGenerationError,
      builder: (column) => ColumnOrderings(column));
}

class $$RecurrencesTableAnnotationComposer
    extends Composer<_$WudgetDatabase, $RecurrencesTable> {
  $$RecurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateJson => $composableBuilder(
      column: $table.templateJson, builder: (column) => column);

  GeneratedColumn<String> get freq =>
      $composableBuilder(column: $table.freq, builder: (column) => column);

  GeneratedColumn<int> get intervalN =>
      $composableBuilder(column: $table.intervalN, builder: (column) => column);

  GeneratedColumn<int> get byMonthDay => $composableBuilder(
      column: $table.byMonthDay, builder: (column) => column);

  GeneratedColumn<int> get byWeekday =>
      $composableBuilder(column: $table.byWeekday, builder: (column) => column);

  GeneratedColumn<String> get weekendRule => $composableBuilder(
      column: $table.weekendRule, builder: (column) => column);

  GeneratedColumn<String> get amountMode => $composableBuilder(
      column: $table.amountMode, builder: (column) => column);

  GeneratedColumn<int> get expectedMinMinor => $composableBuilder(
      column: $table.expectedMinMinor, builder: (column) => column);

  GeneratedColumn<int> get expectedMaxMinor => $composableBuilder(
      column: $table.expectedMaxMinor, builder: (column) => column);

  GeneratedColumn<int> get startsOn =>
      $composableBuilder(column: $table.startsOn, builder: (column) => column);

  GeneratedColumn<int> get endsOn =>
      $composableBuilder(column: $table.endsOn, builder: (column) => column);

  GeneratedColumn<int> get generatedUntil => $composableBuilder(
      column: $table.generatedUntil, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get lastGenerationError => $composableBuilder(
      column: $table.lastGenerationError, builder: (column) => column);
}

class $$RecurrencesTableTableManager extends RootTableManager<
    _$WudgetDatabase,
    $RecurrencesTable,
    Recurrence,
    $$RecurrencesTableFilterComposer,
    $$RecurrencesTableOrderingComposer,
    $$RecurrencesTableAnnotationComposer,
    $$RecurrencesTableCreateCompanionBuilder,
    $$RecurrencesTableUpdateCompanionBuilder,
    (
      Recurrence,
      BaseReferences<_$WudgetDatabase, $RecurrencesTable, Recurrence>
    ),
    Recurrence,
    PrefetchHooks Function()> {
  $$RecurrencesTableTableManager(_$WudgetDatabase db, $RecurrencesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> templateJson = const Value.absent(),
            Value<String> freq = const Value.absent(),
            Value<int> intervalN = const Value.absent(),
            Value<int?> byMonthDay = const Value.absent(),
            Value<int?> byWeekday = const Value.absent(),
            Value<String> weekendRule = const Value.absent(),
            Value<String> amountMode = const Value.absent(),
            Value<int?> expectedMinMinor = const Value.absent(),
            Value<int?> expectedMaxMinor = const Value.absent(),
            Value<int> startsOn = const Value.absent(),
            Value<int?> endsOn = const Value.absent(),
            Value<int> generatedUntil = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<String?> lastGenerationError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurrencesCompanion(
            id: id,
            templateJson: templateJson,
            freq: freq,
            intervalN: intervalN,
            byMonthDay: byMonthDay,
            byWeekday: byWeekday,
            weekendRule: weekendRule,
            amountMode: amountMode,
            expectedMinMinor: expectedMinMinor,
            expectedMaxMinor: expectedMaxMinor,
            startsOn: startsOn,
            endsOn: endsOn,
            generatedUntil: generatedUntil,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            lastGenerationError: lastGenerationError,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String templateJson,
            required String freq,
            Value<int> intervalN = const Value.absent(),
            Value<int?> byMonthDay = const Value.absent(),
            Value<int?> byWeekday = const Value.absent(),
            Value<String> weekendRule = const Value.absent(),
            Value<String> amountMode = const Value.absent(),
            Value<int?> expectedMinMinor = const Value.absent(),
            Value<int?> expectedMaxMinor = const Value.absent(),
            required int startsOn,
            Value<int?> endsOn = const Value.absent(),
            required int generatedUntil,
            required int updatedAt,
            Value<int?> deletedAt = const Value.absent(),
            Value<String?> lastGenerationError = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurrencesCompanion.insert(
            id: id,
            templateJson: templateJson,
            freq: freq,
            intervalN: intervalN,
            byMonthDay: byMonthDay,
            byWeekday: byWeekday,
            weekendRule: weekendRule,
            amountMode: amountMode,
            expectedMinMinor: expectedMinMinor,
            expectedMaxMinor: expectedMaxMinor,
            startsOn: startsOn,
            endsOn: endsOn,
            generatedUntil: generatedUntil,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            lastGenerationError: lastGenerationError,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecurrencesTableProcessedTableManager = ProcessedTableManager<
    _$WudgetDatabase,
    $RecurrencesTable,
    Recurrence,
    $$RecurrencesTableFilterComposer,
    $$RecurrencesTableOrderingComposer,
    $$RecurrencesTableAnnotationComposer,
    $$RecurrencesTableCreateCompanionBuilder,
    $$RecurrencesTableUpdateCompanionBuilder,
    (
      Recurrence,
      BaseReferences<_$WudgetDatabase, $RecurrencesTable, Recurrence>
    ),
    Recurrence,
    PrefetchHooks Function()>;
typedef $$RecurrenceOverridesTableCreateCompanionBuilder
    = RecurrenceOverridesCompanion Function({
  required String recurrenceId,
  required int instanceDate,
  required String action,
  Value<int?> newDate,
  Value<int?> newAmountMinor,
  Value<int> rowid,
});
typedef $$RecurrenceOverridesTableUpdateCompanionBuilder
    = RecurrenceOverridesCompanion Function({
  Value<String> recurrenceId,
  Value<int> instanceDate,
  Value<String> action,
  Value<int?> newDate,
  Value<int?> newAmountMinor,
  Value<int> rowid,
});

class $$RecurrenceOverridesTableFilterComposer
    extends Composer<_$WudgetDatabase, $RecurrenceOverridesTable> {
  $$RecurrenceOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recurrenceId => $composableBuilder(
      column: $table.recurrenceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get instanceDate => $composableBuilder(
      column: $table.instanceDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get newDate => $composableBuilder(
      column: $table.newDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get newAmountMinor => $composableBuilder(
      column: $table.newAmountMinor,
      builder: (column) => ColumnFilters(column));
}

class $$RecurrenceOverridesTableOrderingComposer
    extends Composer<_$WudgetDatabase, $RecurrenceOverridesTable> {
  $$RecurrenceOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recurrenceId => $composableBuilder(
      column: $table.recurrenceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get instanceDate => $composableBuilder(
      column: $table.instanceDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get newDate => $composableBuilder(
      column: $table.newDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get newAmountMinor => $composableBuilder(
      column: $table.newAmountMinor,
      builder: (column) => ColumnOrderings(column));
}

class $$RecurrenceOverridesTableAnnotationComposer
    extends Composer<_$WudgetDatabase, $RecurrenceOverridesTable> {
  $$RecurrenceOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recurrenceId => $composableBuilder(
      column: $table.recurrenceId, builder: (column) => column);

  GeneratedColumn<int> get instanceDate => $composableBuilder(
      column: $table.instanceDate, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<int> get newDate =>
      $composableBuilder(column: $table.newDate, builder: (column) => column);

  GeneratedColumn<int> get newAmountMinor => $composableBuilder(
      column: $table.newAmountMinor, builder: (column) => column);
}

class $$RecurrenceOverridesTableTableManager extends RootTableManager<
    _$WudgetDatabase,
    $RecurrenceOverridesTable,
    RecurrenceOverride,
    $$RecurrenceOverridesTableFilterComposer,
    $$RecurrenceOverridesTableOrderingComposer,
    $$RecurrenceOverridesTableAnnotationComposer,
    $$RecurrenceOverridesTableCreateCompanionBuilder,
    $$RecurrenceOverridesTableUpdateCompanionBuilder,
    (
      RecurrenceOverride,
      BaseReferences<_$WudgetDatabase, $RecurrenceOverridesTable,
          RecurrenceOverride>
    ),
    RecurrenceOverride,
    PrefetchHooks Function()> {
  $$RecurrenceOverridesTableTableManager(
      _$WudgetDatabase db, $RecurrenceOverridesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurrenceOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurrenceOverridesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurrenceOverridesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> recurrenceId = const Value.absent(),
            Value<int> instanceDate = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<int?> newDate = const Value.absent(),
            Value<int?> newAmountMinor = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurrenceOverridesCompanion(
            recurrenceId: recurrenceId,
            instanceDate: instanceDate,
            action: action,
            newDate: newDate,
            newAmountMinor: newAmountMinor,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String recurrenceId,
            required int instanceDate,
            required String action,
            Value<int?> newDate = const Value.absent(),
            Value<int?> newAmountMinor = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RecurrenceOverridesCompanion.insert(
            recurrenceId: recurrenceId,
            instanceDate: instanceDate,
            action: action,
            newDate: newDate,
            newAmountMinor: newAmountMinor,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RecurrenceOverridesTableProcessedTableManager = ProcessedTableManager<
    _$WudgetDatabase,
    $RecurrenceOverridesTable,
    RecurrenceOverride,
    $$RecurrenceOverridesTableFilterComposer,
    $$RecurrenceOverridesTableOrderingComposer,
    $$RecurrenceOverridesTableAnnotationComposer,
    $$RecurrenceOverridesTableCreateCompanionBuilder,
    $$RecurrenceOverridesTableUpdateCompanionBuilder,
    (
      RecurrenceOverride,
      BaseReferences<_$WudgetDatabase, $RecurrenceOverridesTable,
          RecurrenceOverride>
    ),
    RecurrenceOverride,
    PrefetchHooks Function()>;

class $WudgetDatabaseManager {
  final _$WudgetDatabase _db;
  $WudgetDatabaseManager(this._db);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$PostingsTableTableManager get postings =>
      $$PostingsTableTableManager(_db, _db.postings);
  $$DailyTotalsTableTableManager get dailyTotals =>
      $$DailyTotalsTableTableManager(_db, _db.dailyTotals);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$FeatureFlagsTableTableManager get featureFlags =>
      $$FeatureFlagsTableTableManager(_db, _db.featureFlags);
  $$AnalyticsEventsTableTableManager get analyticsEvents =>
      $$AnalyticsEventsTableTableManager(_db, _db.analyticsEvents);
  $$RecurrencesTableTableManager get recurrences =>
      $$RecurrencesTableTableManager(_db, _db.recurrences);
  $$RecurrenceOverridesTableTableManager get recurrenceOverrides =>
      $$RecurrenceOverridesTableTableManager(_db, _db.recurrenceOverrides);
}
