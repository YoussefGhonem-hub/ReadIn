import '../../../../core/errors/result.dart';
import '../entities/external_credential.dart';

/// Google / Apple on this device: the provider's own sheet, which hands back an ID token for the API (ADR 0012).
abstract interface class ExternalIdentityRepository {
  /// Whether this device can offer [provider] (Apple: iOS only for now).
  bool supports(ExternalProvider provider);

  /// Shows the provider's sheet. `Ok(null)` when the person closes it.
  Future<Result<ExternalCredential?>> obtain(ExternalProvider provider);

  /// Forgets the account chosen in the provider's sheet, so the next sign in asks again.
  Future<void> forget();
}
