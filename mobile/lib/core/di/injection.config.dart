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
import '../../features/auth/data/datasources/firebase_auth_data_source.dart'
    as _i492;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/auth_usecases.dart' as _i46;
import '../../features/auth/presentation/cubit/auth_form_cubit.dart' as _i0;
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
import '../platform/share_service.dart' as _i868;
import '../platform/time_zone_service.dart' as _i878;
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
    gh.lazySingleton<_i221.ImageCompressor>(() => _i221.ImageCompressor());
    gh.lazySingleton<_i271.SecureStore>(
      () => _i271.SecureStore(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i956.MediaPicker>(() => _i434.DeviceMediaPicker());
    gh.factory<_i504.PickImages>(
      () => _i504.PickImages(gh<_i956.MediaPicker>()),
    );
    gh.factory<_i504.PickPdf>(() => _i504.PickPdf(gh<_i956.MediaPicker>()));
    gh.lazySingleton<_i599.SettingsLocalDataSource>(
      () => _i599.SettingsLocalDataSource(gh<_i892.KeyValueStore>()),
    );
    await gh.singletonAsync<_i223.FirebaseStatus>(
      () => registerModule.firebase(gh<_i650.AppConfig>()),
      preResolve: true,
    );
    gh.lazySingleton<_i492.FirebaseAuthDataSource>(
      () => _i492.FirebaseAuthDataSource(gh<_i223.FirebaseStatus>()),
    );
    gh.lazySingleton<_i787.AuthRepository>(
      () => _i153.AuthRepositoryImpl(gh<_i492.FirebaseAuthDataSource>()),
    );
    gh.lazySingleton<_i194.IdTokenProvider>(
      () => authModule.idTokenProvider(gh<_i492.FirebaseAuthDataSource>()),
    );
    gh.factory<_i46.WatchAuthState>(
      () => _i46.WatchAuthState(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i46.SignInWithEmail>(
      () => _i46.SignInWithEmail(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i46.SignUpWithEmail>(
      () => _i46.SignUpWithEmail(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i46.SendPasswordReset>(
      () => _i46.SendPasswordReset(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i46.SignOut>(() => _i46.SignOut(gh<_i787.AuthRepository>()));
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.dio(
        gh<_i650.AppConfig>(),
        gh<_i194.IdTokenProvider>(),
        gh<_i1026.CurrentLocale>(),
      ),
    );
    gh.factory<_i0.AuthFormCubit>(
      () => _i0.AuthFormCubit(
        gh<_i46.SignInWithEmail>(),
        gh<_i46.SignUpWithEmail>(),
        gh<_i46.SendPasswordReset>(),
      ),
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
    gh.lazySingleton<_i848.DocumentFileDataSource>(
      () => _i848.DocumentFileDataSource(gh<_i361.Dio>()),
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
    gh.lazySingleton<_i904.ArticleRepository>(
      () => _i473.ArticleRepositoryImpl(gh<_i462.ArticleApi>()),
    );
    gh.lazySingleton<_i954.FeedRepository>(
      () => _i198.FeedRepositoryImpl(gh<_i931.FeedApi>()),
    );
    gh.lazySingleton<_i787.AccountRepository>(
      () => _i153.AccountRepositoryImpl(
        gh<_i506.AccountApi>(),
        gh<_i878.TimeZoneService>(),
      ),
    );
    gh.factory<_i904.GetArticle>(
      () => _i904.GetArticle(gh<_i904.ArticleRepository>()),
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
    gh.factory<_i279.LoadSettings>(
      () => _i279.LoadSettings(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i279.SaveSettings>(
      () => _i279.SaveSettings(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i279.SyncPreferences>(
      () => _i279.SyncPreferences(gh<_i674.SettingsRepository>()),
    );
    gh.factory<_i284.ArticleCubit>(
      () => _i284.ArticleCubit(gh<_i904.GetArticle>()),
    );
    gh.factory<_i535.SaveInterests>(
      () => _i535.SaveInterests(gh<_i185.InterestsRepository>()),
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
    gh.factory<_i189.AttachmentViewerCubit>(
      () => _i189.AttachmentViewerCubit(
        gh<_i904.GetArticle>(),
        gh<_i504.DownloadDocument>(),
        gh<_i868.ShareService>(),
      ),
    );
    gh.factory<_i46.SyncAccount>(
      () => _i46.SyncAccount(gh<_i787.AccountRepository>()),
    );
    gh.factory<_i46.GetMe>(() => _i46.GetMe(gh<_i787.AccountRepository>()));
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
    gh.lazySingleton<_i371.SessionCubit>(
      () => _i371.SessionCubit(
        gh<_i46.WatchAuthState>(),
        gh<_i46.SyncAccount>(),
        gh<_i46.GetMe>(),
        gh<_i46.SignOut>(),
        gh<_i1026.CurrentLocale>(),
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
