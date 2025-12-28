import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

export 'src/generator.dart' show JaoGenerator;

/// Builder factory for jao code generation.
Builder jaoBuilder(BuilderOptions options) => SharedPartBuilder([JaoGenerator()], 'jao');
