/// Usage examples for dartonic ORM.
///
/// This file demonstrates the Django-inspired query API.
library;

import 'models.dart';
import 'package:dartonic/dartonic.dart';

/// Examples demonstrating the dartonic query API.
///
/// Note: These examples won't actually run without a database connection,
/// but they show the API design.
void main() async {
  // ============================================
  // BASIC QUERIES
  // ============================================

  // Get all authors
  final allAuthors = await AuthorDartonic.objects.all().toList();

  // Get author by primary key
  final author = await AuthorDartonic.objects.get(1);

  // Get first author
  final firstAuthor = await AuthorDartonic.objects.first();

  // Check if any authors exist
  final hasAuthors = await AuthorDartonic.objects.exists();

  // Count authors
  final authorCount = await AuthorDartonic.objects.count();

  // ============================================
  // FILTERING - Django-style typed lookups
  // ============================================

  // Exact match
  final johnAuthors = await AuthorDartonic.objects.filter(AuthorDartonic.$.name.eq('John')).toList();

  // Comparison operators
  final adults = await AuthorDartonic.objects.filter(AuthorDartonic.$.age.gte(18)).toList();

  final seniors = await AuthorDartonic.objects.filter(AuthorDartonic.$.age.between(60, 100)).toList();

  // String lookups
  final johnLikes = await AuthorDartonic.objects.filter(AuthorDartonic.$.name.contains('John')).toList();

  final gmailUsers = await AuthorDartonic.objects.filter(AuthorDartonic.$.email.endsWith('@gmail.com')).toList();

  // Case-insensitive
  final caseInsensitive = await AuthorDartonic.objects.filter(AuthorDartonic.$.name.iContains('john')).toList();

  // Null checks
  final hasBio = await AuthorDartonic.objects.filter(AuthorDartonic.$.bio.isNotNull()).toList();

  // In list
  final specificAuthors = await AuthorDartonic.objects
      .filter(AuthorDartonic.$.name.inList(['John', 'Jane', 'Bob']))
      .toList();

  // ============================================
  // COMPLEX QUERIES WITH Q OBJECTS
  // ============================================

  // AND conditions (default when chaining filters)
  final activeAdults = await AuthorDartonic.objects
      .filter(AuthorDartonic.$.age.gte(18))
      .filter(AuthorDartonic.$.isActive.eq(true))
      .toList();

  // Same as above, using & operator
  final activeAdults2 = await AuthorDartonic.objects
      .filter(AuthorDartonic.$.age.gte(18) & AuthorDartonic.$.isActive.eq(true))
      .toList();

  // OR conditions
  final youngOrOld = await AuthorDartonic.objects
      .filter(AuthorDartonic.$.age.lt(18) | AuthorDartonic.$.age.gte(65))
      .toList();

  // NOT conditions
  final notJohn = await AuthorDartonic.objects.filter(~AuthorDartonic.$.name.eq('John')).toList();

  // Complex nested conditions
  final complex = await AuthorDartonic.objects
      .filter(
        (AuthorDartonic.$.age.gte(18) & AuthorDartonic.$.isActive.eq(true)) |
            (AuthorDartonic.$.email.endsWith('@company.com')),
      )
      .toList();

  // Exclude (opposite of filter)
  final notGmail = await AuthorDartonic.objects.exclude(AuthorDartonic.$.email.endsWith('@gmail.com')).toList();

  // ============================================
  // ORDERING
  // ============================================

  // Ascending
  final byName = await AuthorDartonic.objects.orderBy(AuthorDartonic.$.name.asc()).toList();

  // Descending
  final newestFirst = await AuthorDartonic.objects.orderBy(AuthorDartonic.$.createdAt.desc()).toList();

  // Multiple ordering
  final multiSort = await AuthorDartonic.objects
      .orderBy(AuthorDartonic.$.isActive.desc(), AuthorDartonic.$.name.asc())
      .toList();

  // ============================================
  // SLICING AND PAGINATION
  // ============================================

  // Limit results
  final topTen = await AuthorDartonic.objects.orderBy(AuthorDartonic.$.createdAt.desc()).limit(10).toList();

  // Offset for pagination
  final page2 = await AuthorDartonic.objects.orderBy(AuthorDartonic.$.id.asc()).offset(20).limit(10).toList();

  // Slice syntax
  final slice = await AuthorDartonic.objects.orderBy(AuthorDartonic.$.id.asc()).slice(10, 20).toList();

  // ============================================
  // FIELD SELECTION (Performance)
  // ============================================

  // Only load specific fields (deferred loading for others)
  final namesOnly = await AuthorDartonic.objects.only(['name', 'email']).toList();

  // Defer loading of large fields
  final noBio = await AuthorDartonic.objects.defer(['bio']).toList();

  // ============================================
  // AGGREGATIONS
  // ============================================

  // Single aggregation
  final avgAge = await AuthorDartonic.objects.aggregate({'average_age': Avg(AuthorDartonic.$.age.col)});
  print('Average age: ${avgAge['average_age']}');

  // Multiple aggregations
  final stats = await AuthorDartonic.objects.aggregate({
    'count': Count.all(),
    'avg_age': Avg(AuthorDartonic.$.age.col),
    'max_age': Max(AuthorDartonic.$.age.col),
    'min_age': Min(AuthorDartonic.$.age.col),
  });

  // Filtered aggregation
  final activeStats = await AuthorDartonic.objects.filter(AuthorDartonic.$.isActive.eq(true)).aggregate({
    'count': Count.all(),
  });

  // ============================================
  // ANNOTATIONS (Calculated fields)
  // ============================================

  // Add calculated field to each result
  // final authorsWithPostCount = await AuthorDartonic.objects
  //   .annotate({
  //     'post_count': Count(PostDartonic.$.id.col),
  //   })
  //   .toList();

  // ============================================
  // CHAINING (Composable queries)
  // ============================================

  // Build up queries programmatically
  var query = AuthorDartonic.objects.all();

  // Conditionally add filters
  final bool onlyActive = true;
  if (onlyActive) {
    query = query.filter(AuthorDartonic.$.isActive.eq(true));
  }

  final int? minAge = 18;
  if (minAge != null) {
    query = query.filter(AuthorDartonic.$.age.gte(minAge));
  }

  final results = await query.orderBy(AuthorDartonic.$.name.asc()).toList();

  // ============================================
  // F EXPRESSIONS (Field comparisons)
  // ============================================

  // Compare two fields
  // final recentlyUpdated = await AuthorDartonic.objects
  //   .filter(AuthorDartonic.$.updatedAt.gtF(F('createdAt')))
  //   .toList();

  // Arithmetic with fields
  // final discounted = await ProductDartonic.objects
  //   .filter(Product.$.salePrice.ltF(F('regularPrice') * 0.8))
  //   .toList();

  // ============================================
  // STREAMING (Memory efficient)
  // ============================================

  // Stream results for large datasets
  await for (final author in AuthorDartonic.objects.all().stream()) {
    print(author);
  }

  // Process in chunks
  await for (final chunk in AuthorDartonic.objects.all().chunked(100)) {
    print('Processing ${chunk.length} authors');
  }

  // ============================================
  // MUTATIONS
  // ============================================

  // Create
  final newAuthor = await AuthorDartonic.objects.create({'name': 'New Author', 'email': 'new@example.com', 'age': 25});

  // Bulk create
  final newAuthors = await AuthorDartonic.objects.bulkCreate([
    {'name': 'Author 1', 'email': 'a1@example.com', 'age': 30},
    {'name': 'Author 2', 'email': 'a2@example.com', 'age': 35},
  ]);

  // Update matching objects
  final updatedCount = await AuthorDartonic.objects.filter(AuthorDartonic.$.isActive.eq(false)).update({
    'isActive': true,
  });

  // Delete matching objects
  final deletedCount = await AuthorDartonic.objects.filter(AuthorDartonic.$.email.endsWith('@spam.com')).delete();

  // Get or create
  final (existingOrNew, wasCreated) = await AuthorDartonic.objects.getOrCreate(
    condition: AuthorDartonic.$.email.eq('john@example.com'),
    defaults: {'name': 'John', 'age': 30},
  );

  print('All examples completed!');
}
