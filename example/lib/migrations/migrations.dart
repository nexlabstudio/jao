/// Migrations registry.
/// 
/// Import and add your migrations here in order.
library;

import 'package:dartonic/dartonic.dart';
import '20251227163156_create_tables.dart';

// Import your migrations:
// import '20241227_create_users.dart';

/// All migrations in order of execution.
final allMigrations = <Migration>[
  // Add migrations here in order, e.g.:
  // CreateUsers(),
  CreateTables(),
];
