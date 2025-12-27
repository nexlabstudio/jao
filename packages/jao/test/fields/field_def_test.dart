import 'package:jao/jao.dart';
import 'package:test/test.dart';

// Test enum for EnumField
enum Status { pending, active, completed }

void main() {
  group('Field (base)', () {
    test('has default values', () {
      // Using CharField as a concrete implementation
      const field = CharField(maxLength: 100);

      expect(field.column, isNull);
      expect(field.nullable, isFalse);
      expect(field.unique, isFalse);
      expect(field.index, isFalse);
      expect(field.defaultValue, isNull);
      expect(field.helpText, isNull);
    });

    test('accepts all base options', () {
      const field = CharField(
        maxLength: 100,
        column: 'custom_name',
        nullable: true,
        unique: true,
        index: true,
        defaultValue: 'default',
        helpText: 'Help text',
      );

      expect(field.column, equals('custom_name'));
      expect(field.nullable, isTrue);
      expect(field.unique, isTrue);
      expect(field.index, isTrue);
      expect(field.defaultValue, equals('default'));
      expect(field.helpText, equals('Help text'));
    });
  });

  group('CharField', () {
    test('requires maxLength', () {
      const field = CharField(maxLength: 255);
      expect(field.maxLength, equals(255));
    });

    test('has default trim true', () {
      const field = CharField(maxLength: 100);
      expect(field.trim, isTrue);
    });

    test('accepts minLength', () {
      const field = CharField(maxLength: 100, minLength: 5);
      expect(field.minLength, equals(5));
    });

    test('accepts trim option', () {
      const field = CharField(maxLength: 100, trim: false);
      expect(field.trim, isFalse);
    });
  });

  group('TextField', () {
    test('has default values', () {
      const field = TextField();

      expect(field.nullable, isFalse);
      expect(field.unique, isFalse);
    });

    test('accepts all options', () {
      const field = TextField(column: 'content', nullable: true, defaultValue: '');

      expect(field.column, equals('content'));
      expect(field.nullable, isTrue);
      expect(field.defaultValue, equals(''));
    });
  });

  group('EmailField', () {
    test('has default maxLength of 254', () {
      const field = EmailField();
      expect(field.maxLength, equals(254));
    });

    test('accepts custom maxLength', () {
      const field = EmailField(maxLength: 100);
      expect(field.maxLength, equals(100));
    });

    test('inherits from CharField', () {
      const field = EmailField();
      expect(field, isA<CharField>());
    });
  });

  group('UrlField', () {
    test('has default maxLength of 2048', () {
      const field = UrlField();
      expect(field.maxLength, equals(2048));
    });

    test('accepts custom maxLength', () {
      const field = UrlField(maxLength: 512);
      expect(field.maxLength, equals(512));
    });

    test('inherits from CharField', () {
      const field = UrlField();
      expect(field, isA<CharField>());
    });
  });

  group('IntegerField', () {
    test('has default values', () {
      const field = IntegerField();

      expect(field.min, isNull);
      expect(field.max, isNull);
      expect(field.nullable, isFalse);
    });

    test('accepts min and max', () {
      const field = IntegerField(min: 0, max: 100);

      expect(field.min, equals(0));
      expect(field.max, equals(100));
    });

    test('accepts defaultValue', () {
      const field = IntegerField(defaultValue: 0);
      expect(field.defaultValue, equals(0));
    });
  });

  group('SmallIntegerField', () {
    test('inherits from IntegerField', () {
      const field = SmallIntegerField();
      expect(field, isA<IntegerField>());
    });

    test('accepts min and max', () {
      const field = SmallIntegerField(min: -100, max: 100);
      expect(field.min, equals(-100));
      expect(field.max, equals(100));
    });
  });

  group('BigIntegerField', () {
    test('inherits from IntegerField', () {
      const field = BigIntegerField();
      expect(field, isA<IntegerField>());
    });

    test('accepts all options', () {
      const field = BigIntegerField(min: 0, nullable: true, defaultValue: 0);

      expect(field.min, equals(0));
      expect(field.nullable, isTrue);
      expect(field.defaultValue, equals(0));
    });
  });

  group('PositiveIntegerField', () {
    test('has min of 0', () {
      const field = PositiveIntegerField();
      expect(field.min, equals(0));
    });

    test('accepts max', () {
      const field = PositiveIntegerField(max: 1000);
      expect(field.max, equals(1000));
    });

    test('inherits from IntegerField', () {
      const field = PositiveIntegerField();
      expect(field, isA<IntegerField>());
    });
  });

  group('FloatField', () {
    test('has default values', () {
      const field = FloatField();

      expect(field.min, isNull);
      expect(field.max, isNull);
    });

    test('accepts min and max', () {
      const field = FloatField(min: 0.0, max: 100.0);

      expect(field.min, equals(0.0));
      expect(field.max, equals(100.0));
    });
  });

  group('DecimalField', () {
    test('requires maxDigits and decimalPlaces', () {
      const field = DecimalField(maxDigits: 10, decimalPlaces: 2);

      expect(field.maxDigits, equals(10));
      expect(field.decimalPlaces, equals(2));
    });

    test('accepts all options', () {
      const field = DecimalField(maxDigits: 8, decimalPlaces: 4, nullable: true, defaultValue: '0.0000');

      expect(field.maxDigits, equals(8));
      expect(field.decimalPlaces, equals(4));
      expect(field.nullable, isTrue);
      expect(field.defaultValue, equals('0.0000'));
    });
  });

  group('BooleanField', () {
    test('has default values', () {
      const field = BooleanField();

      expect(field.nullable, isFalse);
      expect(field.defaultValue, isNull);
    });

    test('accepts defaultValue', () {
      const field = BooleanField(defaultValue: false);
      expect(field.defaultValue, equals(false));
    });

    test('accepts nullable', () {
      const field = BooleanField(nullable: true);
      expect(field.nullable, isTrue);
    });
  });

  group('DateField', () {
    test('has default values', () {
      const field = DateField();

      expect(field.autoNowAdd, isFalse);
      expect(field.autoNow, isFalse);
    });

    test('accepts autoNowAdd', () {
      const field = DateField(autoNowAdd: true);
      expect(field.autoNowAdd, isTrue);
    });

    test('accepts autoNow', () {
      const field = DateField(autoNow: true);
      expect(field.autoNow, isTrue);
    });

    test('accepts both auto options', () {
      const field = DateField(autoNowAdd: true, autoNow: true);

      expect(field.autoNowAdd, isTrue);
      expect(field.autoNow, isTrue);
    });
  });

  group('DateTimeField', () {
    test('has default values', () {
      const field = DateTimeField();

      expect(field.autoNowAdd, isFalse);
      expect(field.autoNow, isFalse);
      expect(field.useTimezone, isTrue);
    });

    test('accepts autoNowAdd', () {
      const field = DateTimeField(autoNowAdd: true);
      expect(field.autoNowAdd, isTrue);
    });

    test('accepts autoNow', () {
      const field = DateTimeField(autoNow: true);
      expect(field.autoNow, isTrue);
    });

    test('accepts useTimezone', () {
      const field = DateTimeField(useTimezone: false);
      expect(field.useTimezone, isFalse);
    });
  });

  group('TimeField', () {
    test('has default values', () {
      const field = TimeField();

      expect(field.nullable, isFalse);
    });

    test('accepts all options', () {
      const field = TimeField(column: 'start_time', nullable: true);

      expect(field.column, equals('start_time'));
      expect(field.nullable, isTrue);
    });
  });

  group('DurationField', () {
    test('has default values', () {
      const field = DurationField();

      expect(field.nullable, isFalse);
    });

    test('accepts all options', () {
      const field = DurationField(column: 'duration', nullable: true);

      expect(field.column, equals('duration'));
      expect(field.nullable, isTrue);
    });
  });

  group('BinaryField', () {
    test('has default values', () {
      const field = BinaryField();

      expect(field.maxLength, isNull);
      expect(field.nullable, isFalse);
    });

    test('accepts maxLength', () {
      const field = BinaryField(maxLength: 1024);
      expect(field.maxLength, equals(1024));
    });
  });

  group('UuidField', () {
    test('has default values', () {
      const field = UuidField();

      expect(field.autoGenerate, isFalse);
    });

    test('accepts autoGenerate', () {
      const field = UuidField(autoGenerate: true);
      expect(field.autoGenerate, isTrue);
    });

    test('accepts all options', () {
      const field = UuidField(autoGenerate: true, unique: true, nullable: false);

      expect(field.autoGenerate, isTrue);
      expect(field.unique, isTrue);
      expect(field.nullable, isFalse);
    });
  });

  group('JsonField', () {
    test('has default values', () {
      const field = JsonField();

      expect(field.nullable, isFalse);
    });

    test('accepts all options', () {
      const field = JsonField(column: 'data', nullable: true, defaultValue: '{}');

      expect(field.column, equals('data'));
      expect(field.nullable, isTrue);
      expect(field.defaultValue, equals('{}'));
    });
  });

  group('EnumField', () {
    test('has default values', () {
      const field = EnumField<Status>();

      expect(field.storeAsInt, isFalse);
    });

    test('accepts storeAsInt', () {
      const field = EnumField<Status>(storeAsInt: true);
      expect(field.storeAsInt, isTrue);
    });

    test('accepts defaultValue', () {
      const field = EnumField<Status>(defaultValue: Status.pending);
      expect(field.defaultValue, equals(Status.pending));
    });
  });

  group('AutoField', () {
    test('is not nullable', () {
      const field = AutoField();
      expect(field.nullable, isFalse);
    });

    test('is unique', () {
      const field = AutoField();
      expect(field.unique, isTrue);
    });

    test('accepts custom column', () {
      const field = AutoField(column: 'pk');
      expect(field.column, equals('pk'));
    });
  });

  group('BigAutoField', () {
    test('is not nullable', () {
      const field = BigAutoField();
      expect(field.nullable, isFalse);
    });

    test('is unique', () {
      const field = BigAutoField();
      expect(field.unique, isTrue);
    });
  });

  group('UuidPrimaryKey', () {
    test('auto generates', () {
      const field = UuidPrimaryKey();
      expect(field.autoGenerate, isTrue);
    });

    test('is not nullable', () {
      const field = UuidPrimaryKey();
      expect(field.nullable, isFalse);
    });

    test('is unique', () {
      const field = UuidPrimaryKey();
      expect(field.unique, isTrue);
    });

    test('inherits from UuidField', () {
      const field = UuidPrimaryKey();
      expect(field, isA<UuidField>());
    });
  });

  group('ForeignKey', () {
    test('requires target type', () {
      const field = ForeignKey(String); // Using String as a placeholder
      expect(field.to, equals(String));
    });

    test('has default onDelete cascade', () {
      const field = ForeignKey(String);
      expect(field.onDelete, equals(OnDelete.cascade));
    });

    test('has default index true', () {
      const field = ForeignKey(String);
      expect(field.index, isTrue);
    });

    test('accepts onDelete', () {
      const field = ForeignKey(String, onDelete: OnDelete.setNull);
      expect(field.onDelete, equals(OnDelete.setNull));
    });

    test('accepts relatedName', () {
      const field = ForeignKey(String, relatedName: 'posts');
      expect(field.relatedName, equals('posts'));
    });

    test('accepts nullable', () {
      const field = ForeignKey(String, nullable: true);
      expect(field.nullable, isTrue);
    });
  });

  group('OneToOneField', () {
    test('requires target type', () {
      const field = OneToOneField(String);
      expect(field.to, equals(String));
    });

    test('has index true', () {
      const field = OneToOneField(String);
      expect(field.index, isTrue);
    });

    test('inherits from ForeignKey', () {
      const field = OneToOneField(String);
      expect(field, isA<ForeignKey>());
    });

    test('accepts all options', () {
      const field = OneToOneField(String, onDelete: OnDelete.protect, relatedName: 'profile', nullable: true);

      expect(field.onDelete, equals(OnDelete.protect));
      expect(field.relatedName, equals('profile'));
      expect(field.nullable, isTrue);
    });
  });

  group('ManyToManyField', () {
    test('requires target type', () {
      const field = ManyToManyField(String);
      expect(field.to, equals(String));
    });

    test('accepts relatedName', () {
      const field = ManyToManyField(String, relatedName: 'tags');
      expect(field.relatedName, equals('tags'));
    });

    test('accepts throughTable', () {
      const field = ManyToManyField(String, throughTable: 'post_tags');
      expect(field.throughTable, equals('post_tags'));
    });

    test('accepts helpText', () {
      const field = ManyToManyField(String, helpText: 'Related tags');
      expect(field.helpText, equals('Related tags'));
    });
  });

  group('OnDelete', () {
    test('has cascade', () {
      expect(OnDelete.values, contains(OnDelete.cascade));
    });

    test('has protect', () {
      expect(OnDelete.values, contains(OnDelete.protect));
    });

    test('has setNull', () {
      expect(OnDelete.values, contains(OnDelete.setNull));
    });

    test('has setDefault', () {
      expect(OnDelete.values, contains(OnDelete.setDefault));
    });

    test('has doNothing', () {
      expect(OnDelete.values, contains(OnDelete.doNothing));
    });

    test('has 5 values', () {
      expect(OnDelete.values.length, equals(5));
    });
  });

  group('Field inheritance hierarchy', () {
    test('EmailField extends CharField', () {
      expect(const EmailField(), isA<CharField>());
      expect(const EmailField(), isA<Field>());
    });

    test('UrlField extends CharField', () {
      expect(const UrlField(), isA<CharField>());
      expect(const UrlField(), isA<Field>());
    });

    test('SmallIntegerField extends IntegerField', () {
      expect(const SmallIntegerField(), isA<IntegerField>());
      expect(const SmallIntegerField(), isA<Field>());
    });

    test('BigIntegerField extends IntegerField', () {
      expect(const BigIntegerField(), isA<IntegerField>());
      expect(const BigIntegerField(), isA<Field>());
    });

    test('PositiveIntegerField extends IntegerField', () {
      expect(const PositiveIntegerField(), isA<IntegerField>());
      expect(const PositiveIntegerField(), isA<Field>());
    });

    test('UuidPrimaryKey extends UuidField', () {
      expect(const UuidPrimaryKey(), isA<UuidField>());
      expect(const UuidPrimaryKey(), isA<Field>());
    });

    test('OneToOneField extends ForeignKey', () {
      expect(const OneToOneField(String), isA<ForeignKey>());
      expect(const OneToOneField(String), isA<Field>());
    });
  });

  group('Field const constructors', () {
    test('CharField is const', () {
      const field1 = CharField(maxLength: 100);
      const field2 = CharField(maxLength: 100);
      // Same const values should be identical
      expect(identical(field1, field2), isTrue);
    });

    test('IntegerField is const', () {
      const field1 = IntegerField();
      const field2 = IntegerField();
      expect(identical(field1, field2), isTrue);
    });

    test('BooleanField is const', () {
      const field1 = BooleanField();
      const field2 = BooleanField();
      expect(identical(field1, field2), isTrue);
    });

    test('DateTimeField is const', () {
      const field1 = DateTimeField();
      const field2 = DateTimeField();
      expect(identical(field1, field2), isTrue);
    });

    test('AutoField is const', () {
      const field1 = AutoField();
      const field2 = AutoField();
      expect(identical(field1, field2), isTrue);
    });

    test('ForeignKey is const', () {
      const field1 = ForeignKey(String);
      const field2 = ForeignKey(String);
      expect(identical(field1, field2), isTrue);
    });
  });
}
