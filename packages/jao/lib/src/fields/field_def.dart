/// Field definition annotations for model definition.
///
/// These annotations are used on model class fields to define
/// database column properties. The code generator reads these
/// to produce the typed field accessors and schema information.
library;

import 'package:meta/meta.dart';

/// Base annotation for all field types.
@immutable
abstract class Field {
  /// Database column name (defaults to field name in snake_case)
  final String? column;

  /// Whether this field can be null
  final bool nullable;

  /// Whether this field has a unique constraint
  final bool unique;

  /// Whether to create a database index on this field
  final bool index;

  /// Default value for this field
  final Object? defaultValue;

  /// Help text for documentation
  final String? helpText;

  const Field({
    this.column,
    this.nullable = false,
    this.unique = false,
    this.index = false,
    this.defaultValue,
    this.helpText,
  });
}

/// String/VARCHAR field
@immutable
class CharField extends Field {
  /// Maximum length of the string
  final int maxLength;

  /// Minimum length (for validation)
  final int? minLength;

  /// Whether to trim whitespace
  final bool trim;

  const CharField({
    required this.maxLength,
    this.minLength,
    this.trim = true,
    super.column,
    super.nullable,
    super.unique,
    super.index,
    super.defaultValue,
    super.helpText,
  });
}

/// Unlimited text field (TEXT type)
@immutable
class TextField extends Field {
  const TextField({super.column, super.nullable, super.unique, super.index, super.defaultValue, super.helpText});
}

/// Email field (CharField with validation)
@immutable
class EmailField extends CharField {
  const EmailField({
    super.maxLength = 254,
    super.column,
    super.nullable,
    super.unique,
    super.index,
    super.defaultValue,
    super.helpText,
  });
}

/// URL field
@immutable
class UrlField extends CharField {
  const UrlField({
    super.maxLength = 2048,
    super.column,
    super.nullable,
    super.unique,
    super.index,
    super.defaultValue,
    super.helpText,
  });
}

/// Integer field
@immutable
class IntegerField extends Field {
  /// Minimum value (for validation)
  final int? min;

  /// Maximum value (for validation)
  final int? max;

  const IntegerField({
    this.min,
    this.max,
    super.column,
    super.nullable,
    super.unique,
    super.index,
    super.defaultValue,
    super.helpText,
  });
}

/// Small integer (-32768 to 32767)
@immutable
class SmallIntegerField extends IntegerField {
  const SmallIntegerField({
    super.min,
    super.max,
    super.column,
    super.nullable,
    super.unique,
    super.index,
    super.defaultValue,
    super.helpText,
  });
}

/// Big integer (64-bit)
@immutable
class BigIntegerField extends IntegerField {
  const BigIntegerField({
    super.min,
    super.max,
    super.column,
    super.nullable,
    super.unique,
    super.index,
    super.defaultValue,
    super.helpText,
  });
}

/// Positive integer (>= 0)
@immutable
class PositiveIntegerField extends IntegerField {
  const PositiveIntegerField({
    int? max,
    super.column,
    super.nullable,
    super.unique,
    super.index,
    super.defaultValue,
    super.helpText,
  }) : super(min: 0, max: max);
}

/// Floating point field
@immutable
class FloatField extends Field {
  final double? min;
  final double? max;

  const FloatField({
    this.min,
    this.max,
    super.column,
    super.nullable,
    super.unique,
    super.index,
    super.defaultValue,
    super.helpText,
  });
}

/// Decimal field with fixed precision
@immutable
class DecimalField extends Field {
  /// Total number of digits
  final int maxDigits;

  /// Number of decimal places
  final int decimalPlaces;

  const DecimalField({
    required this.maxDigits,
    required this.decimalPlaces,
    super.column,
    super.nullable,
    super.unique,
    super.index,
    super.defaultValue,
    super.helpText,
  });
}

/// Boolean field
@immutable
class BooleanField extends Field {
  const BooleanField({super.column, super.nullable, super.index, super.defaultValue, super.helpText});
}

/// Date field (without time)
@immutable
class DateField extends Field {
  /// Automatically set to now on creation
  final bool autoNowAdd;

  /// Automatically set to now on every save
  final bool autoNow;

  const DateField({
    this.autoNowAdd = false,
    this.autoNow = false,
    super.column,
    super.nullable,
    super.index,
    super.defaultValue,
    super.helpText,
  });
}

/// DateTime field (with time)
@immutable
class DateTimeField extends Field {
  /// Automatically set to now on creation
  final bool autoNowAdd;

  /// Automatically set to now on every save
  final bool autoNow;

  /// Store as UTC
  final bool useTimezone;

  const DateTimeField({
    this.autoNowAdd = false,
    this.autoNow = false,
    this.useTimezone = true,
    super.column,
    super.nullable,
    super.index,
    super.defaultValue,
    super.helpText,
  });
}

/// Time field (without date)
@immutable
class TimeField extends Field {
  const TimeField({super.column, super.nullable, super.index, super.defaultValue, super.helpText});
}

/// Duration/interval field
@immutable
class DurationField extends Field {
  const DurationField({super.column, super.nullable, super.index, super.defaultValue, super.helpText});
}

/// Binary/blob field
@immutable
class BinaryField extends Field {
  /// Maximum size in bytes
  final int? maxLength;

  const BinaryField({this.maxLength, super.column, super.nullable, super.index, super.helpText});
}

/// UUID field
@immutable
class UuidField extends Field {
  /// Auto-generate UUID on creation
  final bool autoGenerate;

  const UuidField({
    this.autoGenerate = false,
    super.column,
    super.nullable,
    super.unique,
    super.index,
    super.defaultValue,
    super.helpText,
  });
}

/// JSON field
@immutable
class JsonField extends Field {
  const JsonField({super.column, super.nullable, super.index, super.defaultValue, super.helpText});
}

/// Enum field (stored as string or int)
@immutable
class EnumField<T extends Enum> extends Field {
  /// Store as integer ordinal instead of string
  final bool storeAsInt;

  const EnumField({
    this.storeAsInt = false,
    super.column,
    super.nullable,
    super.index,
    super.defaultValue,
    super.helpText,
  });
}

/// Auto-incrementing primary key
@immutable
class AutoField extends Field {
  const AutoField({super.column}) : super(nullable: false, unique: true);
}

/// Big auto-incrementing primary key
@immutable
class BigAutoField extends Field {
  const BigAutoField({super.column}) : super(nullable: false, unique: true);
}

/// UUID primary key
@immutable
class UuidPrimaryKey extends UuidField {
  const UuidPrimaryKey({super.column}) : super(autoGenerate: true, nullable: false, unique: true);
}

/// Foreign key relationship
@immutable
class ForeignKey extends Field {
  /// The related model type
  final Type to;

  /// What to do when the referenced object is deleted
  final OnDelete onDelete;

  /// Related name for reverse access (default: modelname_set)
  final String? relatedName;

  const ForeignKey(
    this.to, {
    this.onDelete = OnDelete.cascade,
    this.relatedName,
    super.column,
    super.nullable,
    super.index = true,
    super.helpText,
  });
}

/// One-to-one relationship
@immutable
class OneToOneField extends ForeignKey {
  const OneToOneField(super.to, {super.onDelete, super.relatedName, super.column, super.nullable, super.helpText})
      : super(index: true);
}

/// Many-to-many relationship
@immutable
class ManyToManyField extends Field {
  /// The related model type
  final Type to;

  /// Related name for reverse access
  final String? relatedName;

  /// Custom through table name
  final String? throughTable;

  const ManyToManyField(this.to, {this.relatedName, this.throughTable, super.helpText});
}

/// OnDelete behavior for foreign keys
enum OnDelete {
  /// Delete related objects (default)
  cascade,

  /// Prevent deletion if related objects exist
  protect,

  /// Set to null (requires nullable=true)
  setNull,

  /// Set to default value
  setDefault,

  /// Do nothing (database may reject)
  doNothing,
}
