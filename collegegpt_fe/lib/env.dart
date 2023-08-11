import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'GOOGLE_API_KEY', obfuscate: true)
  static final String googleAPIKey = _Env.googleAPIKey;
}
