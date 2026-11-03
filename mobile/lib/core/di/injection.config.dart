// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/article/data/datasources/article_api.dart' as _i462;
import '../../features/article/data/repositories/article_repository_impl.dart'
    as _i473;
import '../../features/article/domain/repositories/article_repository.dart'
    as _i904;
import '../../features/article/domain/usecases/get_article.dart' as _i904;
import '../../features/article/presentation/cubit/article_cubit.dart' as _i284;
import '../../features/article/presentation/cubit/attachment_viewer_cubit.dart'
    as _i189;
import '../../features/auth/data/auth_module.dart' as _i360;
import '../../features/auth/data/datasources/account_api.dart' as _i506;
import '../../features/auth/data/datasources/apple_sign_in_data_source.dart'
    as _i815;
import '../../features/auth/data/datasources/auth_api.dart' as _i367;
import '../../features/auth/data/datasources/auth_session_store.dart' as _i348;
import '../../features/auth/data/datasources/google_sign_in_data_source.dart'
    as _i811;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/auth_usecases.dart' as _i46;
import '../../features/auth/presentation/cubit/account_security_cubits.dart'
    as _i1021;
import '../../features/auth/presentation/cubit/complete_profile_cubit.dart'
    as _i245;
import '../../features/auth/presentation/cubit/forgot_password_cubit.dart'
    as _i104;
import '../../features/auth/presentation/cubit/sign_in_cubit.dart' as _i329;
import '../../features/auth/presentation/cubit/sign_up_cubit.dart' as _i102;
import '../../features/auth/presentation/session/session_cubit.dart' as _i371;
import '../../features/editor/data/datasources/editor_api.dart' as _i815;
import '../../features/editor/data/repositories/editor_repository_impl.dart'
    as _i552;
import '../../features/editor/domain/repositories/editor_repository.dart'
    as _i940;
import '../../features/editor/domain/usecases/publish_usecases.dart' as _i1065;
import '../../features/editor/presentation/cubit/composer_cubit.dart' as _i485;
import '../../features/home/data/datasources/feed_api.dart' as _i931;
import '../../features/home/data/repositories/feed_repository_impl.dart'
    as _i198;
import '../../features/home/domain/repositories/feed_repository.dart' as _i954;
import '../../features/home/domain/usecases/feed_usecases.dart' as _i251;
import '../../features/home/presentation/cubit/feed_cubit.dart' as _i646;
import '../../features/home/presentation/cubit/home_cubit.dart' as _i9;
import '../../features/home/presentation/cubit/live_feed_cubit.dart' as _i136;
import '../../features/media/data/datasources/device_media_picker.dart'
    as _i434;
import '../../features/media/data/datasources/document_file_data_source.dart'
    as _i848;
import '../../features/media/data/datasources/image_compressor.dart' as _i221;
import '../../features/media/data/datasources/media_api.dart' as _i757;
import '../../features/media/data/repositories/media_repository_impl.dart'
    as _i110;
import '../../features/media/domain/repositories/media_picker.dart' as _i956;
import '../../features/media/domain/repositories/media_repository.dart'
    as _i459;
import '../../features/media/domain/usecases/media_usecases.dart' as _i504;
import '../../features/media/presentation/cubit/attachments_cubit.dart'
    as _i571;
import '../../features/notifications/presentation/cubit/unread_badge_cubit.dart'
    as _i1054;
import '../../features/onboarding/data/datasources/interests_api.dart' as _i227;
import '../../features/onboarding/data/repositories/interests_repository_impl.dart'
    as _i1032;
import '../../features/onboarding/domain/repositories/interests_repository.dart'
    as _i185;
import '../../features/onboarding/domain/usecases/save_interests.dart' as _i535;
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart'
    as _i807;
import '../../features/settings/data/datasources/preferences_api.dart' as _i741;
import '../../features/settings/data/datasources/settings_local_data_source.dart'
    as _i599;
import '../../features/settings/data/repositories/settings_repository_impl.dart'
    as _i955;
import '../../features/settings/domain/repositories/settings_repository.dart'
    as _i674;
import '../../features/settings/domain/usecases/settings_usecases.dart'
    as _i279;
import '../../features/settings/presentation/cubit/settings_cubit.dart'
    as _i792;
import '../../features/taxonomy/data/datasources/taxonomy_api.dart' as _i421;
import '../../features/taxonomy/data/repositories/taxonomy_repository_impl.dart'
    as _i551;
import '../../features/taxonomy/domain/repositories/taxonomy_repository.dart'
    as _i263;
import '../../features/taxonomy/domain/usecases/taxonomy_usecases.dart'
    as _i172;
import '../config/app_config.dart' as _i650;
import '../firebase/firebase_bootstrap.dart' as _i223;
import '../l10n/current_locale.dart' as _i1026;
import '../network/request_context.dart' as _i194;
import '../phone/countries.dart' as _i115;
import '../platform/device_name_service.dart' as _i1018;
import '../platform/share_service.dart' as _i868;
import '../platform/time_zone_service.dart' as _i878;
import '../push/devices_api.dart' as _i455;
import '../push/push_platform.dart' as _i709;
import '../push/push_service.dart' as _i1040;
import '../realtime/live_connection.dart' as _i887;
import '../realtime/realtime_service.dart' as _i854;
import '../realtime/realtime_token_api.dart' as _i894;
import '../storage/key_value_store.dart' as _i892;
import '../storage/secure_store.dart' as _i271;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    final authModule = _$AuthModule();
    gh.singleton<_i650.AppConfig>(() => registerModule.config);
    await gh.singletonAsync<_i892.KeyValueStore>(
      () => registerModule.keyValueStore(),
      preResolve: true,
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i1026.CurrentLocale>(() => _i1026.CurrentLocale());
    gh.lazySingleton<_i868.ShareService>(() => _i868.ShareService());
    gh.lazySingleton<_i878.TimeZoneService>(() => _i878.TimeZoneService());
    gh.lazySingleton<_i815.AppleSignInDataSource>(
      () => _i815.AppleSignInDataSource(),
    );
    gh.lazySingleton<_i811.GoogleSignInDataSource>(
      () => _i811.GoogleSignInDataSource(),
    );
    gh.lazySingleton<_i221.ImageCompressor>(() => _i221.ImageCompressor());
    gh.lazySingleton<_i194.DeviceNameProvider>(
      () => _i1018.DeviceNameService(),
    );
    gh.lazySingleton<_i271.SecureStore>(
      () => _i271.SecureStore(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i956.MediaPicker>(() => _i434.DeviceMediaPicker());
    gh.factory<_i504.PickImages>(
      () => _i504.PickImages(gh<_i956.MediaPicker>()),
    );
    gh.factory<_i504.PickPdf>(() => _i504.PickPdf(gh<_i956.MediaPicker>()));
    gh.lazySingleton<_i115.PhoneCountryMemory>(
      () => _i115.PhoneCountryMemory(gh<_i892.KeyValueStore>()),
    );
    gh.lazySingleton<_i599.SettingsLocalDataSource>(
      () => _i599.SettingsLocalDataSource(gh<_i892.KeyValueStore>()),
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.authDio(
        gh<_i650.AppConfig>(),
        gh<_i1026.CurrentLocale>(),
        gh<_i194.DeviceNameProvider>(),
      ),
      instanceName: 'authDio',
    );
    await gh.singletonAsync<_i223.FirebaseStatus>(
      () => registerModule.firebase(gh<_i650.AppConfig>()),
      preResolve: true,
    );
    gh.lazySingleton<_i367.AuthApi>(
      () => _i367.AuthApi(gh<_i361.Dio>(instanceName: 'authDio')),
    );
    gh.lazySingleton<_i709.PushPlatform>(
      () => _i709.FirebasePushPlatform(
        gh<_i650.AppConfig>(),
        gh<_i223.FirebaseStatus>(),
      ),
    );
    gh.lazySingleton<_i887.LiveConnector>(
      () => _i887.FirebaseLiveConnector(
        gh<_i650.AppConfig>(),
        gh<_i223.FirebaseStatus>(),
      ),
    );
    gh.lazySingleton<_i348.AuthSessionStore>(
      () =>
          _i348.AuthSessionStore(gh<_i367.AuthApi>(), gh<_i271.SecureStore>()),
    );
    gh.lazySingleton<_i194.SessionTokenProvider>(
      () => authModule.sessionTokens(gh<_i348.AuthSessionStore>()),
    );
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.dio(
        gh<_i650.AppConfig>(),
        gh<_i194.SessionTokenProvider>(),
        gh<_i1026.CurrentLocale>(),
        gh<_i194.DeviceNameProvider>(),
      ),
    );
    gh.lazySingleton<_i455.DevicesApi>(() => _i455.DevicesApi(gh<_i361.Dio>()));
    gh.lazySingleton<_i894.RealtimeTokenApi>(
      () => _i894.RealtimeTokenApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i462.ArticleApi>(() => _i462.ArticleApi(gh<_i361.Dio>()));
    gh.lazySingleton<_i506.AccountApi>(() => _i506.AccountApi(gh<_i361.Dio>()));
    gh.lazySingleton<_i815.EditorApi>(() => _i815.EditorApi(gh<_i361.Dio>()));
    gh.lazySingleton<_i931.FeedApi>(() => _i931.FeedApi(gh<_i361.Dio>()));
    gh.lazySingleton<_i757.MediaApi>(() => _i757.MediaApi(gh<_i361.Dio>()));
    gh.lazySingleton<_i227.InterestsApi>(
      () => _i227.InterestsApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i741.PreferencesApi>(
      () => _i741.PreferencesApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i421.TaxonomyApi>(
      () => _i421.TaxonomyApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i787.AccountRepository>(
      () => _i153.AccountRepositoryImpl(
        gh<_i506.AccountApi>(),
        gh<_i348.AuthSessionStore>(),
      ),
    );
    gh.lazySingleton<_i848.DocumentFileDataSource>(
      () => _i848.DocumentFileDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i1040.PushService>(
      () =>
          _i1040.PushService(gh<_i709.PushPlatform>(), gh<_i455.DevicesApi>()),
    );
    gh.lazySingleton<_i263.TaxonomyRepository>(
      () => _i551.TaxonomyRepositoryImpl(gh<_i421.TaxonomyApi>()),
    );
    gh.lazySingleton<_i459.MediaRepository>(
      () => _i110.MediaRepositoryImpl(
        gh<_i757.MediaApi>(),
        gh<_i221.ImageCompressor>(),
        gh<_i848.DocumentFileDataSource>(),
      ),
    );
    gh.lazySingleton<_i854.RealtimeService>(
      () => _i854.RealtimeService(
        gh<_i887.LiveConnector>(),
        gh<_i894.RealtimeTokenApi>(),
      ),
    );
    gh.lazySingleton<_i904.ArticleRepository>(
      () => _i473.ArticleRepositoryImpl(gh<_i462.ArticleApi>()),
    );
    gh.lazySingleton<_i954.FeedRepository>(
      () => _i198.FeedRepositoryImpl(gh<_i931.FeedApi>()),
    );
    gh.factory<_i46.GetMe>(() => _i46.GetMe(gh<_i787.AccountRepository>()));
    gh.factory<_i46.CheckUsername>(
      () => _i46.CheckUsername(gh<_i787.AccountRepository>()),
    );
    gh.factory<_i46.CompleteProfile>(
      () => _i46.CompleteProfile(gh<_i787.AccountRepository>()),
    );
    gh.factory<_i46.SetRecoveryPin>(
      () => _i46.SetRecoveryPin(gh<_i787.AccountRepository>()),
    );
    gh.factory<_i46.ChangeRecoveryPin>(
      () => _i46.ChangeRecoveryPin(gh<_i787.AccountRepository>()),
    );
    gh.factory<_i46.ChangePassword>(
      () => _i46.ChangePassword(gh<_i787.AccountRepository>()),
    );
    gh.factory<_i46.ChangePhoneNumber>(
      () => _i46.ChangePhoneNumber(gh<_i787.AccountRepository>()),
    );
    gh.factory<_i46.DeleteAccount>(
      () => _i46.DeleteAccount(gh<_i787.AccountRepository>()),
    );
    gh.factory<_i904.GetArticle>(
      () => _i904.GetArticle(gh<_i904.ArticleRepository>()),
    );
    gh.lazySingleton<_i787.AuthRepository>(
      () => _i153.AuthRepositoryImpl(
        gh<_i367.AuthApi>(),
        gh<_i506.AccountApi>(),
        gh<_i348.AuthSessionStore>(),
        gh<_i1040.PushService>(),
        gh<_i878.TimeZoneService>(),
      ),
    );
    gh.lazySingleton<_i185.InterestsRepository>(
      () => _i1032.InterestsRepositoryImpl(gh<_i227.InterestsApi>()),
    );
    gh.lazySingleton<_i674.SettingsRepository>(
      () => _i955.SettingsRepositoryImpl(
        gh<_i599.SettingsLocalDataSource>(),
        gh<_i741.PreferencesApi>(),
        gh<_i878.TimeZoneService>(),
      ),
    );
    gh.lazySingleton<_i940.EditorRepository>(
      () => _i552.EditorRepositoryImpl(gh<_i815.EditorApi>()),
    );
    gh.factory<_i251.GetTodayArticle>(
      () => _i251.GetTodayArticle(gh<_i954.FeedRepository>()),
    );
    gh.factory<_i251.GetForYouFeed>(
      () => _i251.GetForYouFeed(gh<_i954.FeedRepository>()),
    );
    gh.factory<_i46.WatchSession>(
      () => _i46.WatchSession(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i46.GetAuthConfig>(
      () => _i46.GetAuthConfig(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i46.RestoreSession>(
      () => _i46.RestoreSession(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i46.SignIn>(() => _i46.SignIn(gh<_i787.AuthRepository>()));
    gh.factory<_i46.Register>(() => _i46.Register(gh<_i787.AuthRepository>()));
    gh.factory<_i46.VerifyRecoveryPin>(
      () => _i46.VerifyRecoveryPin(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i46.ResetPassword>(
      () => _i46.ResetPassword(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i46.SignOut>(() => _i46.SignOut(gh<_i787.AuthRepository>()));
    gh.factory<_i46.SignOutEverywhere>(
      () => _i46.SignOutEverywhere(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i172.GetFields>(
      () => _i172.GetFields(gh<_i263.TaxonomyRepository>()),
    );
    gh.factory<_i172.GetTopics>(
      () => _i172.GetTopics(gh<_i263.TaxonomyRepository>()),
    );
    gh.factory<_i504.UploadImage>(
      () => _i504.UploadImage(gh<_i459.MediaRepository>()),
    );
    gh.factory<_i504.UploadDocument>(
      () => _i504.UploadDocument(gh<_i459.MediaRepository>()),
    );
    gh.factory<_i504.GetUpload>(
      () => _i504.GetUpload(gh<_i459.MediaRepository>()),
    );
    gh.factory<_i504.DeleteUpload>(
      () => _i504.DeleteUpload(gh<_i459.MediaRepository>()),
    );
    gh.factory<_i504.DownloadDocument>(
      () => _i504.DownloadDocument(gh<_i459.MediaRepository>()),
    );
    gh.factory<_i1065.CreateArticleDraft>(
      () => _i1065.CreateArticleDraft(gh<_i940.EditorRepository>()),
    );
    gh.factory<_i1065.SetArticleAttachments>(
      () => _i1065.SetArticleAttachments(gh<_i940.EditorRepository>()),
    );
    gh.factory<_i1065.PublishArticle>(
      () => _i1065.PublishArticle(gh<_i940.EditorRepository>()),
    );
    gh.factory<_i9.HomeCubit>(
      () => _i9.HomeCubit(gh<_i251.GetTodayArticle>(), gh<_i172.GetFields>()),
    );
    gh.lazySingleton<_i371.SessionCubit>(
      () => _i371.SessionCubit(
        gh<_i46.WatchSession>(),
        gh<_i46.RestoreSession>(),
        gh<_i46.GetMe>(),
        gh<_i46.SignOut>(),
        gh<_i46.SignOutEverywhere>(),
      ),
    );
    gh.factory<_i279.LoadSettings>(
      () => _i279.LoadSettings(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i279.SaveSettings>(
      () => _i279.SaveSettings(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i279.SyncPreferences>(
      () => _i279.SyncPreferences(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i1021.SetRecoveryPinCubit>(
      () => _i1021.SetRecoveryPinCubit(
        gh<_i46.GetAuthConfig>(),
        gh<_i46.SetRecoveryPin>(),
      ),
    );
    gh.factory<_i136.LiveFeedCubit>(
      () => _i136.LiveFeedCubit(gh<_i854.RealtimeService>()),
    );
    gh.factory<_i1054.UnreadBadgeCubit>(
      () => _i1054.UnreadBadgeCubit(gh<_i854.RealtimeService>()),
    );
    gh.factory<_i284.ArticleCubit>(
      () => _i284.ArticleCubit(gh<_i904.GetArticle>()),
    );
    gh.factory<_i535.SaveInterests>(
      () => _i535.SaveInterests(gh<_i185.InterestsRepository>()),
    );
    gh.factory<_i104.ForgotPasswordCubit>(
      () => _i104.ForgotPasswordCubit(
        gh<_i46.VerifyRecoveryPin>(),
        gh<_i46.ResetPassword>(),
        gh<_i46.GetAuthConfig>(),
      ),
    );
    gh.factory<_i329.SignInCubit>(
      () =>
          _i329.SignInCubit(gh<_i46.SignIn>(), gh<_i115.PhoneCountryMemory>()),
    );
    gh.factory<_i646.FeedCubit>(
      () => _i646.FeedCubit(gh<_i251.GetForYouFeed>()),
    );
    gh.factory<_i485.ComposerCubit>(
      () => _i485.ComposerCubit(
        gh<_i172.GetFields>(),
        gh<_i1065.CreateArticleDraft>(),
        gh<_i1065.SetArticleAttachments>(),
        gh<_i1065.PublishArticle>(),
      ),
    );
    gh.factory<_i1021.ChangeRecoveryPinCubit>(
      () => _i1021.ChangeRecoveryPinCubit(
        gh<_i46.GetAuthConfig>(),
        gh<_i46.ChangeRecoveryPin>(),
      ),
    );
    gh.factory<_i1021.ChangePhoneCubit>(
      () => _i1021.ChangePhoneCubit(
        gh<_i46.GetAuthConfig>(),
        gh<_i46.ChangePhoneNumber>(),
        gh<_i115.PhoneCountryMemory>(),
      ),
    );
    gh.factory<_i189.AttachmentViewerCubit>(
      () => _i189.AttachmentViewerCubit(
        gh<_i904.GetArticle>(),
        gh<_i504.DownloadDocument>(),
        gh<_i868.ShareService>(),
      ),
    );
    gh.factory<_i245.CompleteProfileCubit>(
      () => _i245.CompleteProfileCubit(
        gh<_i46.CompleteProfile>(),
        gh<_i46.CheckUsername>(),
        gh<_i504.PickImages>(),
        gh<_i504.UploadImage>(),
      ),
    );
    gh.factory<_i1021.DeleteAccountCubit>(
      () => _i1021.DeleteAccountCubit(
        gh<_i46.GetAuthConfig>(),
        gh<_i46.DeleteAccount>(),
      ),
    );
    gh.factory<_i102.SignUpCubit>(
      () => _i102.SignUpCubit(
        gh<_i46.Register>(),
        gh<_i46.GetAuthConfig>(),
        gh<_i1026.CurrentLocale>(),
        gh<_i115.PhoneCountryMemory>(),
      ),
    );
    gh.factory<_i571.AttachmentsCubit>(
      () => _i571.AttachmentsCubit(
        gh<_i504.PickImages>(),
        gh<_i504.PickPdf>(),
        gh<_i504.UploadImage>(),
        gh<_i504.UploadDocument>(),
        gh<_i504.GetUpload>(),
        gh<_i504.DeleteUpload>(),
      ),
    );
    gh.factory<_i1021.ChangePasswordCubit>(
      () => _i1021.ChangePasswordCubit(
        gh<_i46.GetAuthConfig>(),
        gh<_i46.ChangePassword>(),
      ),
    );
    gh.lazySingleton<_i792.SettingsCubit>(
      () => _i792.SettingsCubit(
        gh<_i279.LoadSettings>(),
        gh<_i279.SaveSettings>(),
        gh<_i279.SyncPreferences>(),
        gh<_i1026.CurrentLocale>(),
      ),
    );
    gh.factory<_i807.OnboardingCubit>(
      () => _i807.OnboardingCubit(
        gh<_i172.GetFields>(),
        gh<_i172.GetTopics>(),
        gh<_i535.SaveInterests>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}

class _$AuthModule extends _i360.AuthModule {}
