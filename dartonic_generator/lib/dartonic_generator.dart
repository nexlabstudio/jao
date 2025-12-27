import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/generator.dart';

/// Builder factory for dartonic code generation.
Builder dartonicBuilder(BuilderOptions options) => SharedPartBuilder([DartonicGenerator()], 'dartonic');
