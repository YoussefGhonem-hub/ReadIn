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
import '../../features/article/data/datasources/article_offline_store.dart'
    as _i1010;
import '../../features/article/data/repositories/article_repository_impl.dart'
    as _i473;
import '../../features/article/domain/repositories/article_repository.dart'
    as _i904;
import '../../features/article/domain/usecases/get_article.dart' as _i904;
import '../../features/article/domain/usecases/get_related_articles.dart'
    as _i938;
import '../../features/article/presentation/cubit/article_cubit.dart' as _i284;
import '../../features/article/presentation/cubit/article_live_cubit.dart'
    as _i172;
import '../../features/article/presentation/cubit/attachment_viewer_cubit.dart'
    as _i189;
import '../../features/article/presentation/cubit/engagement_cubit.dart'
    as _i226;
import '../../features/article/presentation/cubit/related_articles_cubit.dart'
    as _i692;
import '../../features/auth/data/auth_module.dart' as _i360;
import '../../features/auth/data/datasources/account_api.dart' as _i506;
import '../../features/auth/data/datasources/account_device_data.dart' as _i881;
import '../../features/auth/data/datasources/apple_sign_in_data_source.dart'
    as _i815;
import '../../features/auth/data/datasources/auth_api.dart' as _i367;
import '../../features/auth/data/datasources/auth_session_store.dart' as _i348;
import '../../features/auth/data/datasources/google_sign_in_data_source.dart'
    as _i811;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/data/repositories/external_identity_repository_impl.dart'
    as _i470;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/repositories/external_identity_repository.dart'
    as _i62;
import '../../features/auth/domain/usecases/auth_usecases.dart' as _i46;
import '../../features/auth/presentation/cubit/account_security_cubits.dart'
    as _i1021;
import '../../features/auth/presentation/cubit/complete_profile_cubit.dart'
    as _i245;
import '../../features/auth/presentation/cubit/delete_account_cubit.dart'
    as _i460;
import '../../features/auth/presentation/cubit/external_sign_in_cubit.dart'
    as _i34;
import '../../features/auth/presentation/cubit/forgot_password_cubit.dart'
    as _i104;
import '../../features/auth/presentation/cubit/linked_accounts_cubit.dart'
    as _i77;
import '../../features/auth/presentation/cubit/sign_in_cubit.dart' as _i329;
import '../../features/auth/presentation/cubit/sign_up_cubit.dart' as _i102;
import '../../features/auth/presentation/session/session_cubit.dart' as _i371;
import '../../features/comments/data/datasources/comments_api.dart' as _i1070;
import '../../features/comments/data/repositories/comments_repository_impl.dart'
    as _i589;
import '../../features/comments/domain/repositories/comments_repository.dart'
    as _i670;
import '../../features/comments/domain/usecases/comment_usecases.dart' as _i788;
import '../../features/comments/presentation/cubit/comments_cubit.dart'
    as _i921;
import '../../features/comments/presentation/cubit/mention_suggestions_cubit.dart'
    as _i360;
import '../../features/editor/data/datasources/article_editor_api.dart'
    as _i880;
import '../../features/editor/data/datasources/editor_backup_store.dart'
    as _i853;
import '../../features/editor/data/repositories/article_editor_repository_impl.dart'
    as _i303;
import '../../features/editor/domain/repositories/article_editor_repository.dart'
    as _i413;
import '../../features/editor/domain/usecases/editor_usecases.dart' as _i866;
import '../../features/editor/presentation/cubit/article_editor_cubit.dart'
    as _i840;
import '../../features/editor/presentation/cubit/my_articles_cubit.dart'
    as _i700;
import '../../features/editor/presentation/cubit/revisions_cubit.dart' as _i836;
import '../../features/editor/presentation/cubit/tag_suggestions_cubit.dart'
    as _i655;
import '../../features/follow/data/datasources/follow_api.dart' as _i73;
import '../../features/follow/data/repositories/follow_repository_impl.dart'
    as _i299;
import '../../features/follow/domain/repositories/follow_repository.dart'
    as _i760;
import '../../features/follow/domain/usecases/follow_usecases.dart' as _i537;
import '../../features/follow/presentation/cubit/follows_cubit.dart' as _i509;
import '../../features/follow/presentation/cubit/suggested_writers_cubit.dart'
    as _i382;
import '../../features/glossary/data/datasources/glossary_api.dart' as _i234;
import '../../features/glossary/data/repositories/glossary_repository_impl.dart'
    as _i730;
import '../../features/glossary/domain/repositories/glossary_repository.dart'
    as _i268;
import '../../features/glossary/domain/usecases/get_glossary_term.dart' as _i86;
import '../../features/glossary/domain/usecases/search_glossary_terms.dart'
    as _i97;
import '../../features/glossary/presentation/cubit/glossary_search_cubit.dart'
    as _i463;
import '../../features/glossary/presentation/cubit/glossary_term_cubit.dart'
    as _i520;
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
import '../../features/moderation/data/datasources/moderation_api.dart'
    as _i320;
import '../../features/moderation/data/repositories/moderation_repository_impl.dart'
    as _i378;
import '../../features/moderation/domain/entities/moderation.dart' as _i662;
import '../../features/moderation/domain/repositories/moderation_repository.dart'
    as _i106;
import '../../features/moderation/domain/usecases/moderation_usecases.dart'
    as _i130;
import '../../features/moderation/presentation/cubit/moderation_action_cubit.dart'
    as _i100;
import '../../features/moderation/presentation/cubit/moderation_case_cubit.dart'
    as _i151;
import '../../features/moderation/presentation/cubit/moderation_list_cubit.dart'
    as _i437;
import '../../features/moderation/presentation/cubit/moderation_notices_cubit.dart'
    as _i564;
import '../../features/moderation/presentation/cubit/moderation_summary_cubit.dart'
    as _i789;
import '../../features/moderation/presentation/cubit/report_cubit.dart'
    as _i956;
import '../../features/notifications/data/datasources/notifications_api.dart'
    as _i352;
import '../../features/notifications/data/notification_push_receipts.dart'
    as _i896;
import '../../features/notifications/data/repositories/notifications_repository_impl.dart'
    as _i201;
import '../../features/notifications/domain/repositories/notifications_repository.dart'
    as _i563;
import '../../features/notifications/domain/usecases/notification_usecases.dart'
    as _i864;
import '../../features/notifications/presentation/cubit/notification_settings_cubit.dart'
    as _i894;
import '../../features/notifications/presentation/cubit/notifications_cubit.dart'
    as _i405;
import '../../features/notifications/presentation/cubit/unread_badge_cubit.dart'
    as _i1054;
import '../../features/onboarding/data/datasources/interests_api.dart' as _i227;
import '../../features/onboarding/data/repositories/interests_repository_impl.dart'
    as _i1032;
import '../../features/onboarding/domain/repositories/interests_repository.dart'
    as _i185;
import '../../features/onboarding/domain/usecases/save_interests.dart' as _i535;
import '../../features/onboarding/domain/usecases/set_interest.dart' as _i471;
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart'
    as _i807;
import '../../features/paths/data/datasources/paths_api.dart' as _i88;
import '../../features/paths/data/repositories/paths_repository_impl.dart'
    as _i904;
import '../../features/paths/domain/repositories/paths_repository.dart'
    as _i755;
import '../../features/paths/domain/usecases/path_usecases.dart' as _i924;
import '../../features/paths/presentation/cubit/article_path_cubit.dart'
    as _i512;
import '../../features/paths/presentation/cubit/path_details_cubit.dart'
    as _i745;
import '../../features/paths/presentation/cubit/path_list_cubit.dart' as _i835;
import '../../features/profile/data/datasources/profile_api.dart' as _i191;
import '../../features/profile/data/repositories/profile_repository_impl.dart'
    as _i334;
import '../../features/profile/domain/repositories/profile_repository.dart'
    as _i894;
import '../../features/profile/domain/usecases/profile_usecases.dart' as _i591;
import '../../features/profile/presentation/cubit/edit_profile_cubit.dart'
    as _i990;
import '../../features/profile/presentation/cubit/follow_list_cubit.dart'
    as _i632;
import '../../features/profile/presentation/cubit/privacy_cubit.dart' as _i977;
import '../../features/profile/presentation/cubit/profile_articles_cubit.dart'
    as _i529;
import '../../features/profile/presentation/cubit/profile_cubit.dart' as _i36;
import '../../features/reactions/data/datasources/reactions_api.dart' as _i824;
import '../../features/reactions/data/repositories/reactions_repository_impl.dart'
    as _i399;
import '../../features/reactions/domain/repositories/reactions_repository.dart'
    as _i315;
import '../../features/reactions/domain/usecases/reaction_usecases.dart'
    as _i27;
import '../../features/reactions/presentation/cubit/reactors_cubit.dart'
    as _i55;
import '../../features/reading/data/datasources/reading_api.dart' as _i597;
import '../../features/reading/data/repositories/reading_repository_impl.dart'
    as _i571;
import '../../features/reading/domain/repositories/reading_repository.dart'
    as _i634;
import '../../features/reading/domain/usecases/reading_usecases.dart' as _i892;
import '../../features/reading/presentation/cubit/reading_heatmap_cubit.dart'
    as _i321;
import '../../features/reading/presentation/cubit/reading_stats_cubit.dart'
    as _i487;
import '../../features/reading/presentation/cubit/streak_cubit.dart' as _i884;
import '../../features/saved/data/datasources/saved_api.dart' as _i693;
import '../../features/saved/data/repositories/saved_repository_impl.dart'
    as _i165;
import '../../features/saved/domain/repositories/saved_repository.dart'
    as _i105;
import '../../features/saved/domain/usecases/saved_usecases.dart' as _i724;
import '../../features/saved/presentation/cubit/collections_cubit.dart'
    as _i272;
import '../../features/saved/presentation/cubit/saved_list_cubit.dart' as _i339;
import '../../features/settings/data/datasources/preferences_api.dart' as _i741;
import '../../features/settings/data/datasources/settings_local_data_source.dart'
    as _i599;
import '../../features/settings/data/repositories/settings_repository_impl.dart'
    as _i955;
import '../../features/settings/domain/repositories/settings_repository.dart'
    as _i674;
import '../../features/settings/domain/usecases/settings_usecases.dart'
    as _i279;
import '../../features/settings/presentation/cubit/interests_cubit.dart'
    as _i280;
import '../../features/settings/presentation/cubit/settings_cubit.dart'
    as _i792;
import '../../features/taxonomy/data/datasources/taxonomy_api.dart' as _i421;
import '../../features/taxonomy/data/repositories/taxonomy_repository_impl.dart'
    as _i551;
import '../../features/taxonomy/domain/repositories/taxonomy_repository.dart'
    as _i263;
import '../../features/taxonomy/domain/usecases/taxonomy_usecases.dart'
    as _i172;
import '../../features/verification/data/datasources/device_proof_file_picker.dart'
    as _i688;
import '../../features/verification/data/datasources/verification_api.dart'
    as _i1061;
import '../../features/verification/data/repositories/verification_repository_impl.dart'
    as _i306;
import '../../features/verification/domain/repositories/verification_repository.dart'
    as _i1070;
import '../../features/verification/domain/usecases/verification_usecases.dart'
    as _i295;
import '../../features/verification/presentation/cubit/verification_cubit.dart'
    as _i643;
import '../../features/verification/presentation/cubit/verification_form_cubit.dart'
    as _i221;
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
import '../push/push_read_receipts.dart' as _i822;
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
    gh.lazySingleton<_i1010.ArticleOfflineStore>(
      () => _i1010.HiveArticleOfflineStore(),
    );
    gh.lazySingleton<_i271.SecureStore>(
      () => _i271.SecureStore(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i413.EditorBackupStore>(
      () => _i853.HiveEditorBackupStore(),
    );
    gh.lazySingleton<_i1070.ProofFilePicker>(
      () => _i688.DeviceProofFilePicker(),
    );
    gh.lazySingleton<_i956.MediaPicker>(() => _i434.DeviceMediaPicker());
    gh.factory<_i504.PickImages>(
      () => _i504.PickImages(gh<_i956.MediaPicker>()),
    );
    gh.factory<_i504.TakePhoto>(() => _i504.TakePhoto(gh<_i956.MediaPicker>()));
    gh.factory<_i504.PickPdf>(() => _i504.PickPdf(gh<_i956.MediaPicker>()));
    gh.factory<_i295.PickVerificationProof>(
      () => _i295.PickVerificationProof(gh<_i1070.ProofFilePicker>()),
    );
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
    gh.lazySingleton<_i62.ExternalIdentityRepository>(
      () => _i470.ExternalIdentityRepositoryImpl(
        gh<_i811.GoogleSignInDataSource>(),
        gh<_i815.AppleSignInDataSource>(),
      ),
    );
    await gh.singletonAsync<_i223.FirebaseStatus>(
      () => registerModule.firebase(gh<_i650.AppConfig>()),
      preResolve: true,
    );
    gh.factory<_i46.ObtainExternalCredential>(
      () =>
          _i46.ObtainExternalCredential(gh<_i62.ExternalIdentityRepository>()),
    );
    gh.factory<_i46.ConfirmWithLinkedProvider>(
      () =>
          _i46.ConfirmWithLinkedProvider(gh<_i62.ExternalIdentityRepository>()),
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
    gh.lazySingleton<_i1070.CommentsApi>(
      () => _i1070.CommentsApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i880.ArticleEditorApi>(
      () => _i880.ArticleEditorApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i73.FollowApi>(() => _i73.FollowApi(gh<_i361.Dio>()));
    gh.lazySingleton<_i234.GlossaryApi>(
      () => _i234.GlossaryApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i931.FeedApi>(() => _i931.FeedApi(gh<_i361.Dio>()));
    gh.lazySingleton<_i757.MediaApi>(() => _i757.MediaApi(gh<_i361.Dio>()));
    gh.lazySingleton<_i320.ModerationApi>(
      () => _i320.ModerationApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i352.NotificationsApi>(
      () => _i352.NotificationsApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i227.InterestsApi>(
      () => _i227.InterestsApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i88.PathsApi>(() => _i88.PathsApi(gh<_i361.Dio>()));
    gh.lazySingleton<_i191.ProfileApi>(() => _i191.ProfileApi(gh<_i361.Dio>()));
    gh.lazySingleton<_i824.ReactionsApi>(
      () => _i824.ReactionsApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i597.ReadingApi>(() => _i597.ReadingApi(gh<_i361.Dio>()));
    gh.lazySingleton<_i693.SavedApi>(() => _i693.SavedApi(gh<_i361.Dio>()));
    gh.lazySingleton<_i741.PreferencesApi>(
      () => _i741.PreferencesApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i421.TaxonomyApi>(
      () => _i421.TaxonomyApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i1061.VerificationApi>(
      () => _i1061.VerificationApi(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i848.DocumentFileDataSource>(
      () => _i848.DocumentFileDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i315.ReactionsRepository>(
      () => _i399.ReactionsRepositoryImpl(gh<_i824.ReactionsApi>()),
    );
    gh.lazySingleton<_i894.ProfileRepository>(
      () => _i334.ProfileRepositoryImpl(gh<_i191.ProfileApi>()),
    );
    gh.lazySingleton<_i106.ModerationRepository>(
      () => _i378.ModerationRepositoryImpl(gh<_i320.ModerationApi>()),
    );
    gh.lazySingleton<_i755.PathsRepository>(
      () => _i904.PathsRepositoryImpl(gh<_i88.PathsApi>()),
    );
    gh.lazySingleton<_i263.TaxonomyRepository>(
      () => _i551.TaxonomyRepositoryImpl(gh<_i421.TaxonomyApi>()),
    );
    gh.lazySingleton<_i105.SavedRepository>(
      () => _i165.SavedRepositoryImpl(
        gh<_i693.SavedApi>(),
        gh<_i462.ArticleApi>(),
        gh<_i1010.ArticleOfflineStore>(),
      ),
    );
    gh.lazySingleton<_i1070.VerificationRepository>(
      () => _i306.VerificationRepositoryImpl(gh<_i1061.VerificationApi>()),
    );
    gh.lazySingleton<_i459.MediaRepository>(
      () => _i110.MediaRepositoryImpl(
        gh<_i757.MediaApi>(),
        gh<_i221.ImageCompressor>(),
        gh<_i848.DocumentFileDataSource>(),
      ),
    );
    gh.factory<_i591.GetProfile>(
      () => _i591.GetProfile(gh<_i894.ProfileRepository>()),
    );
    gh.factory<_i591.GetUserArticles>(
      () => _i591.GetUserArticles(gh<_i894.ProfileRepository>()),
    );
    gh.lazySingleton<_i854.RealtimeService>(
      () => _i854.RealtimeService(
        gh<_i887.LiveConnector>(),
        gh<_i894.RealtimeTokenApi>(),
      ),
    );
    gh.lazySingleton<_i634.ReadingRepository>(
      () => _i571.ReadingRepositoryImpl(gh<_i597.ReadingApi>()),
    );
    gh.lazySingleton<_i904.ArticleRepository>(
      () => _i473.ArticleRepositoryImpl(
        gh<_i462.ArticleApi>(),
        gh<_i1010.ArticleOfflineStore>(),
      ),
    );
    gh.lazySingleton<_i670.CommentsRepository>(
      () => _i589.CommentsRepositoryImpl(gh<_i1070.CommentsApi>()),
    );
    gh.lazySingleton<_i563.NotificationsRepository>(
      () => _i201.NotificationsRepositoryImpl(gh<_i352.NotificationsApi>()),
    );
    gh.lazySingleton<_i954.FeedRepository>(
      () => _i198.FeedRepositoryImpl(gh<_i931.FeedApi>()),
    );
    gh.lazySingleton<_i760.FollowRepository>(
      () => _i299.FollowRepositoryImpl(gh<_i73.FollowApi>()),
    );
    gh.factory<_i904.GetArticle>(
      () => _i904.GetArticle(gh<_i904.ArticleRepository>()),
    );
    gh.factory<_i938.GetRelatedArticles>(
      () => _i938.GetRelatedArticles(gh<_i904.ArticleRepository>()),
    );
    gh.lazySingleton<_i185.InterestsRepository>(
      () => _i1032.InterestsRepositoryImpl(gh<_i227.InterestsApi>()),
    );
    gh.factory<_i724.SetSaved>(
      () => _i724.SetSaved(gh<_i105.SavedRepository>()),
    );
    gh.factory<_i724.GetSavedArticles>(
      () => _i724.GetSavedArticles(gh<_i105.SavedRepository>()),
    );
    gh.factory<_i724.GetCollections>(
      () => _i724.GetCollections(gh<_i105.SavedRepository>()),
    );
    gh.factory<_i724.ManageCollections>(
      () => _i724.ManageCollections(gh<_i105.SavedRepository>()),
    );
    gh.factory<_i295.GetVerificationStatus>(
      () => _i295.GetVerificationStatus(gh<_i1070.VerificationRepository>()),
    );
    gh.factory<_i295.SubmitVerificationRequest>(
      () =>
          _i295.SubmitVerificationRequest(gh<_i1070.VerificationRepository>()),
    );
    gh.factory<_i295.WithdrawVerificationRequest>(
      () => _i295.WithdrawVerificationRequest(
        gh<_i1070.VerificationRepository>(),
      ),
    );
    gh.lazySingleton<_i413.ArticleEditorRepository>(
      () => _i303.ArticleEditorRepositoryImpl(gh<_i880.ArticleEditorApi>()),
    );
    gh.lazySingleton<_i268.GlossaryRepository>(
      () => _i730.GlossaryRepositoryImpl(gh<_i234.GlossaryApi>()),
    );
    gh.lazySingleton<_i674.SettingsRepository>(
      () => _i955.SettingsRepositoryImpl(
        gh<_i599.SettingsLocalDataSource>(),
        gh<_i741.PreferencesApi>(),
        gh<_i878.TimeZoneService>(),
      ),
    );
    gh.factory<_i130.SubmitReport>(
      () => _i130.SubmitReport(gh<_i106.ModerationRepository>()),
    );
    gh.factory<_i130.GetModerationSummary>(
      () => _i130.GetModerationSummary(gh<_i106.ModerationRepository>()),
    );
    gh.factory<_i130.GetModerationQueue>(
      () => _i130.GetModerationQueue(gh<_i106.ModerationRepository>()),
    );
    gh.factory<_i130.GetModerationCase>(
      () => _i130.GetModerationCase(gh<_i106.ModerationRepository>()),
    );
    gh.factory<_i130.TakeModerationAction>(
      () => _i130.TakeModerationAction(gh<_i106.ModerationRepository>()),
    );
    gh.factory<_i130.GetModerationLog>(
      () => _i130.GetModerationLog(gh<_i106.ModerationRepository>()),
    );
    gh.factory<_i130.GetModerationNotices>(
      () => _i130.GetModerationNotices(gh<_i106.ModerationRepository>()),
    );
    gh.factory<_i130.AcknowledgeModerationNotice>(
      () => _i130.AcknowledgeModerationNotice(gh<_i106.ModerationRepository>()),
    );
    gh.factory<_i86.GetGlossaryTerm>(
      () => _i86.GetGlossaryTerm(gh<_i268.GlossaryRepository>()),
    );
    gh.factory<_i97.SearchGlossaryTerms>(
      () => _i97.SearchGlossaryTerms(gh<_i268.GlossaryRepository>()),
    );
    gh.factory<_i463.GlossarySearchCubit>(
      () => _i463.GlossarySearchCubit(gh<_i97.SearchGlossaryTerms>()),
    );
    gh.factory<_i520.GlossaryTermCubit>(
      () => _i520.GlossaryTermCubit(gh<_i86.GetGlossaryTerm>()),
    );
    gh.factory<_i788.GetComments>(
      () => _i788.GetComments(gh<_i670.CommentsRepository>()),
    );
    gh.factory<_i788.PostComment>(
      () => _i788.PostComment(gh<_i670.CommentsRepository>()),
    );
    gh.factory<_i788.EditComment>(
      () => _i788.EditComment(gh<_i670.CommentsRepository>()),
    );
    gh.factory<_i788.DeleteComment>(
      () => _i788.DeleteComment(gh<_i670.CommentsRepository>()),
    );
    gh.factory<_i788.SetCommentLiked>(
      () => _i788.SetCommentLiked(gh<_i670.CommentsRepository>()),
    );
    gh.factory<_i788.SetCommentPinned>(
      () => _i788.SetCommentPinned(gh<_i670.CommentsRepository>()),
    );
    gh.factory<_i788.SuggestMentions>(
      () => _i788.SuggestMentions(gh<_i670.CommentsRepository>()),
    );
    gh.factory<_i788.ModerateComment>(
      () => _i788.ModerateComment(gh<_i670.CommentsRepository>()),
    );
    gh.factory<_i864.MigrateDailyArticleSwitch>(
      () => _i864.MigrateDailyArticleSwitch(
        gh<_i674.SettingsRepository>(),
        gh<_i563.NotificationsRepository>(),
      ),
    );
    gh.factoryParam<_i437.ModerationQueueCubit, _i662.ReportStatus, dynamic>(
      (status, _) =>
          _i437.ModerationQueueCubit(gh<_i130.GetModerationQueue>(), status),
    );
    gh.factory<_i437.ModerationLogCubit>(
      () => _i437.ModerationLogCubit(gh<_i130.GetModerationLog>()),
    );
    gh.factory<_i864.GetNotifications>(
      () => _i864.GetNotifications(gh<_i563.NotificationsRepository>()),
    );
    gh.factory<_i864.GetUnreadNotificationCount>(
      () =>
          _i864.GetUnreadNotificationCount(gh<_i563.NotificationsRepository>()),
    );
    gh.factory<_i864.MarkNotificationsSeen>(
      () => _i864.MarkNotificationsSeen(gh<_i563.NotificationsRepository>()),
    );
    gh.factory<_i864.MarkNotificationRead>(
      () => _i864.MarkNotificationRead(gh<_i563.NotificationsRepository>()),
    );
    gh.factory<_i864.MarkAllNotificationsRead>(
      () => _i864.MarkAllNotificationsRead(gh<_i563.NotificationsRepository>()),
    );
    gh.factory<_i864.GetNotificationSettings>(
      () => _i864.GetNotificationSettings(gh<_i563.NotificationsRepository>()),
    );
    gh.factory<_i864.UpdateNotificationSettings>(
      () =>
          _i864.UpdateNotificationSettings(gh<_i563.NotificationsRepository>()),
    );
    gh.factory<_i251.GetTodayArticle>(
      () => _i251.GetTodayArticle(gh<_i954.FeedRepository>()),
    );
    gh.factory<_i251.GetForYouFeed>(
      () => _i251.GetForYouFeed(gh<_i954.FeedRepository>()),
    );
    gh.factory<_i251.GetFollowingFeed>(
      () => _i251.GetFollowingFeed(gh<_i954.FeedRepository>()),
    );
    gh.factory<_i251.GetContinueReading>(
      () => _i251.GetContinueReading(gh<_i954.FeedRepository>()),
    );
    gh.factoryParam<_i529.ProfileArticlesCubit, String, dynamic>(
      (username, _) =>
          _i529.ProfileArticlesCubit(gh<_i591.GetUserArticles>(), username),
    );
    gh.factory<_i866.GetMyArticles>(
      () => _i866.GetMyArticles(gh<_i413.ArticleEditorRepository>()),
    );
    gh.factory<_i866.CreateArticle>(
      () => _i866.CreateArticle(gh<_i413.ArticleEditorRepository>()),
    );
    gh.factory<_i866.GetArticleForEdit>(
      () => _i866.GetArticleForEdit(gh<_i413.ArticleEditorRepository>()),
    );
    gh.factory<_i866.SaveDraft>(
      () => _i866.SaveDraft(gh<_i413.ArticleEditorRepository>()),
    );
    gh.factory<_i866.DiscardChanges>(
      () => _i866.DiscardChanges(gh<_i413.ArticleEditorRepository>()),
    );
    gh.factory<_i866.PublishArticle>(
      () => _i866.PublishArticle(gh<_i413.ArticleEditorRepository>()),
    );
    gh.factory<_i866.GetRevisions>(
      () => _i866.GetRevisions(gh<_i413.ArticleEditorRepository>()),
    );
    gh.factory<_i866.GetRevision>(
      () => _i866.GetRevision(gh<_i413.ArticleEditorRepository>()),
    );
    gh.factory<_i866.RestoreRevision>(
      () => _i866.RestoreRevision(gh<_i413.ArticleEditorRepository>()),
    );
    gh.factory<_i866.DeleteArticle>(
      () => _i866.DeleteArticle(gh<_i413.ArticleEditorRepository>()),
    );
    gh.factory<_i866.SuggestTags>(
      () => _i866.SuggestTags(gh<_i413.ArticleEditorRepository>()),
    );
    gh.factory<_i892.ReportReadingProgress>(
      () => _i892.ReportReadingProgress(gh<_i634.ReadingRepository>()),
    );
    gh.factory<_i892.GetReadingStats>(
      () => _i892.GetReadingStats(gh<_i634.ReadingRepository>()),
    );
    gh.factory<_i892.GetReadingHeatmap>(
      () => _i892.GetReadingHeatmap(gh<_i634.ReadingRepository>()),
    );
    gh.factory<_i27.SetReaction>(
      () => _i27.SetReaction(gh<_i315.ReactionsRepository>()),
    );
    gh.factory<_i27.GetReactors>(
      () => _i27.GetReactors(gh<_i315.ReactionsRepository>()),
    );
    gh.factory<_i924.GetPaths>(
      () => _i924.GetPaths(gh<_i755.PathsRepository>()),
    );
    gh.factory<_i924.GetPath>(() => _i924.GetPath(gh<_i755.PathsRepository>()));
    gh.factory<_i924.GetArticlePath>(
      () => _i924.GetArticlePath(gh<_i755.PathsRepository>()),
    );
    gh.factory<_i924.GetUserPaths>(
      () => _i924.GetUserPaths(gh<_i755.PathsRepository>()),
    );
    gh.factory<_i924.GetMyPaths>(
      () => _i924.GetMyPaths(gh<_i755.PathsRepository>()),
    );
    gh.factory<_i924.GetActivePath>(
      () => _i924.GetActivePath(gh<_i755.PathsRepository>()),
    );
    gh.factory<_i924.SetPathEnrollment>(
      () => _i924.SetPathEnrollment(gh<_i755.PathsRepository>()),
    );
    gh.factory<_i921.CommentsCubit>(
      () => _i921.CommentsCubit(
        gh<_i788.GetComments>(),
        gh<_i788.PostComment>(),
        gh<_i788.EditComment>(),
        gh<_i788.DeleteComment>(),
        gh<_i788.SetCommentLiked>(),
        gh<_i788.SetCommentPinned>(),
        gh<_i788.ModerateComment>(),
        gh<_i854.RealtimeService>(),
      ),
    );
    gh.factory<_i360.MentionSuggestionsCubit>(
      () => _i360.MentionSuggestionsCubit(gh<_i788.SuggestMentions>()),
    );
    gh.factory<_i172.GetFields>(
      () => _i172.GetFields(gh<_i263.TaxonomyRepository>()),
    );
    gh.factory<_i172.GetTopics>(
      () => _i172.GetTopics(gh<_i263.TaxonomyRepository>()),
    );
    gh.factoryParam<_i836.RevisionsCubit, String, dynamic>(
      (articleId, _) => _i836.RevisionsCubit(
        gh<_i866.GetRevisions>(),
        gh<_i866.GetRevision>(),
        articleId,
      ),
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
    gh.factory<_i835.AllPathsCubit>(
      () => _i835.AllPathsCubit(gh<_i924.GetPaths>()),
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
    gh.lazySingleton<_i789.ModerationSummaryCubit>(
      () => _i789.ModerationSummaryCubit(gh<_i130.GetModerationSummary>()),
    );
    gh.factory<_i172.ArticleLiveCubit>(
      () => _i172.ArticleLiveCubit(gh<_i854.RealtimeService>()),
    );
    gh.factory<_i136.LiveFeedCubit>(
      () => _i136.LiveFeedCubit(gh<_i854.RealtimeService>()),
    );
    gh.factory<_i284.ArticleCubit>(
      () => _i284.ArticleCubit(gh<_i904.GetArticle>()),
    );
    gh.factoryParam<_i835.UserPathsCubit, String, dynamic>(
      (username, _) => _i835.UserPathsCubit(gh<_i924.GetUserPaths>(), username),
    );
    gh.factory<_i535.SaveInterests>(
      () => _i535.SaveInterests(gh<_i185.InterestsRepository>()),
    );
    gh.factory<_i745.PathDetailsCubit>(
      () => _i745.PathDetailsCubit(
        gh<_i924.GetPath>(),
        gh<_i924.SetPathEnrollment>(),
      ),
    );
    gh.factory<_i100.ModerationActionCubit>(
      () => _i100.ModerationActionCubit(
        gh<_i130.TakeModerationAction>(),
        gh<_i789.ModerationSummaryCubit>(),
      ),
    );
    gh.factory<_i646.FollowingFeedCubit>(
      () => _i646.FollowingFeedCubit(gh<_i251.GetFollowingFeed>()),
    );
    gh.factory<_i537.SetFollowing>(
      () => _i537.SetFollowing(gh<_i760.FollowRepository>()),
    );
    gh.factory<_i537.GetSuggestedWriters>(
      () => _i537.GetSuggestedWriters(gh<_i760.FollowRepository>()),
    );
    gh.factory<_i537.GetFollowLists>(
      () => _i537.GetFollowLists(gh<_i760.FollowRepository>()),
    );
    gh.factory<_i537.SetInterestFollowed>(
      () => _i537.SetInterestFollowed(gh<_i760.FollowRepository>()),
    );
    gh.lazySingleton<_i822.PushReadReceipts>(
      () => _i896.NotificationPushReceipts(gh<_i864.MarkNotificationRead>()),
    );
    gh.factory<_i646.FeedCubit>(
      () => _i646.FeedCubit(gh<_i251.GetForYouFeed>()),
    );
    gh.factory<_i189.AttachmentViewerCubit>(
      () => _i189.AttachmentViewerCubit(
        gh<_i904.GetArticle>(),
        gh<_i504.DownloadDocument>(),
        gh<_i868.ShareService>(),
      ),
    );
    gh.factory<_i321.ReadingHeatmapCubit>(
      () => _i321.ReadingHeatmapCubit(gh<_i892.GetReadingHeatmap>()),
    );
    gh.factory<_i692.RelatedArticlesCubit>(
      () => _i692.RelatedArticlesCubit(gh<_i938.GetRelatedArticles>()),
    );
    gh.factory<_i512.ArticlePathCubit>(
      () => _i512.ArticlePathCubit(
        gh<_i924.GetArticlePath>(),
        gh<_i924.SetPathEnrollment>(),
      ),
    );
    gh.factory<_i151.ModerationCaseCubit>(
      () => _i151.ModerationCaseCubit(gh<_i130.GetModerationCase>()),
    );
    gh.factory<_i221.VerificationFormCubit>(
      () => _i221.VerificationFormCubit(
        gh<_i172.GetFields>(),
        gh<_i295.PickVerificationProof>(),
        gh<_i295.SubmitVerificationRequest>(),
      ),
    );
    gh.factory<_i840.ArticleEditorCubit>(
      () => _i840.ArticleEditorCubit(
        gh<_i866.CreateArticle>(),
        gh<_i866.GetArticleForEdit>(),
        gh<_i866.SaveDraft>(),
        gh<_i866.DiscardChanges>(),
        gh<_i866.PublishArticle>(),
        gh<_i866.RestoreRevision>(),
        gh<_i866.DeleteArticle>(),
        gh<_i172.GetFields>(),
        gh<_i172.GetTopics>(),
        gh<_i504.UploadImage>(),
        gh<_i413.EditorBackupStore>(),
      ),
    );
    gh.lazySingleton<_i226.EngagementCubit>(
      () => _i226.EngagementCubit(gh<_i27.SetReaction>(), gh<_i724.SetSaved>()),
    );
    gh.factory<_i894.NotificationSettingsCubit>(
      () => _i894.NotificationSettingsCubit(
        gh<_i864.GetNotificationSettings>(),
        gh<_i864.UpdateNotificationSettings>(),
      ),
    );
    gh.factory<_i956.ReportCubit>(
      () => _i956.ReportCubit(gh<_i130.SubmitReport>()),
    );
    gh.factory<_i655.TagSuggestionsCubit>(
      () => _i655.TagSuggestionsCubit(gh<_i866.SuggestTags>()),
    );
    gh.lazySingleton<_i1040.PushService>(
      () => _i1040.PushService(
        gh<_i709.PushPlatform>(),
        gh<_i455.DevicesApi>(),
        gh<_i822.PushReadReceipts>(),
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
    gh.factory<_i835.MyPathsCubit>(
      () => _i835.MyPathsCubit(gh<_i924.GetMyPaths>()),
    );
    gh.factory<_i55.ReactorsCubit>(
      () => _i55.ReactorsCubit(gh<_i27.GetReactors>()),
    );
    gh.lazySingleton<_i509.FollowsCubit>(
      () => _i509.FollowsCubit(gh<_i537.SetFollowing>()),
    );
    gh.factory<_i700.MyArticlesCubit>(
      () => _i700.MyArticlesCubit(
        gh<_i866.GetMyArticles>(),
        gh<_i866.DeleteArticle>(),
        gh<_i413.EditorBackupStore>(),
      ),
    );
    gh.factory<_i807.OnboardingCubit>(
      () => _i807.OnboardingCubit(
        gh<_i172.GetFields>(),
        gh<_i172.GetTopics>(),
        gh<_i535.SaveInterests>(),
      ),
    );
    gh.lazySingleton<_i792.SettingsCubit>(
      () => _i792.SettingsCubit(
        gh<_i279.LoadSettings>(),
        gh<_i279.SaveSettings>(),
        gh<_i279.SyncPreferences>(),
        gh<_i1026.CurrentLocale>(),
        gh<_i864.MigrateDailyArticleSwitch>(),
      ),
    );
    gh.lazySingleton<_i272.CollectionsCubit>(
      () => _i272.CollectionsCubit(
        gh<_i724.GetCollections>(),
        gh<_i724.ManageCollections>(),
        gh<_i226.EngagementCubit>(),
      ),
    );
    gh.factoryParam<_i632.FollowListCubit, String, _i632.FollowListKind>(
      (userId, kind) => _i632.FollowListCubit(
        gh<_i537.GetFollowLists>(),
        gh<_i509.FollowsCubit>(),
        userId,
        kind,
      ),
    );
    gh.lazySingleton<_i881.AccountDeviceData>(
      () => _i881.AccountDeviceData(
        gh<_i1040.PushService>(),
        gh<_i811.GoogleSignInDataSource>(),
        gh<_i115.PhoneCountryMemory>(),
      ),
    );
    gh.factory<_i382.SuggestedWritersCubit>(
      () => _i382.SuggestedWritersCubit(
        gh<_i537.GetSuggestedWriters>(),
        gh<_i509.FollowsCubit>(),
      ),
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
    gh.factory<_i339.SavedListCubit>(
      () => _i339.SavedListCubit(
        gh<_i724.GetSavedArticles>(),
        gh<_i172.GetFields>(),
        gh<_i226.EngagementCubit>(),
        gh<_i272.CollectionsCubit>(),
      ),
    );
    gh.factory<_i36.ProfileCubit>(
      () => _i36.ProfileCubit(gh<_i591.GetProfile>(), gh<_i509.FollowsCubit>()),
    );
    gh.lazySingleton<_i787.AccountRepository>(
      () => _i153.AccountRepositoryImpl(
        gh<_i506.AccountApi>(),
        gh<_i348.AuthSessionStore>(),
        gh<_i881.AccountDeviceData>(),
      ),
    );
    gh.factory<_i46.SignOut>(
      () => _i46.SignOut(
        gh<_i787.AuthRepository>(),
        gh<_i62.ExternalIdentityRepository>(),
      ),
    );
    gh.factory<_i46.GetExternalProviders>(
      () => _i46.GetExternalProviders(
        gh<_i787.AuthRepository>(),
        gh<_i62.ExternalIdentityRepository>(),
      ),
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
    gh.factory<_i46.SignOutEverywhere>(
      () => _i46.SignOutEverywhere(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i46.SignInWithExternal>(
      () => _i46.SignInWithExternal(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i591.UpdateProfile>(
      () => _i591.UpdateProfile(
        gh<_i894.ProfileRepository>(),
        gh<_i787.AccountRepository>(),
      ),
    );
    gh.factory<_i591.SetPrivacy>(
      () => _i591.SetPrivacy(
        gh<_i894.ProfileRepository>(),
        gh<_i787.AccountRepository>(),
      ),
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
    gh.factory<_i46.LinkExternalLogin>(
      () => _i46.LinkExternalLogin(gh<_i787.AccountRepository>()),
    );
    gh.factory<_i46.UnlinkExternalLogin>(
      () => _i46.UnlinkExternalLogin(gh<_i787.AccountRepository>()),
    );
    gh.factory<_i46.AddPhoneSignIn>(
      () => _i46.AddPhoneSignIn(gh<_i787.AccountRepository>()),
    );
    gh.factory<_i34.ExternalSignInCubit>(
      () => _i34.ExternalSignInCubit(
        gh<_i46.GetExternalProviders>(),
        gh<_i46.ObtainExternalCredential>(),
        gh<_i46.SignInWithExternal>(),
        gh<_i1026.CurrentLocale>(),
        gh<_i115.PhoneCountryMemory>(),
      ),
    );
    gh.factory<_i471.SetInterest>(
      () => _i471.SetInterest(
        gh<_i185.InterestsRepository>(),
        gh<_i787.AccountRepository>(),
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
    gh.factory<_i102.SignUpCubit>(
      () => _i102.SignUpCubit(
        gh<_i46.Register>(),
        gh<_i46.GetAuthConfig>(),
        gh<_i1026.CurrentLocale>(),
        gh<_i115.PhoneCountryMemory>(),
      ),
    );
    gh.factory<_i77.LinkedAccountsCubit>(
      () => _i77.LinkedAccountsCubit(
        gh<_i46.GetExternalProviders>(),
        gh<_i46.ObtainExternalCredential>(),
        gh<_i46.ConfirmWithLinkedProvider>(),
        gh<_i46.LinkExternalLogin>(),
        gh<_i46.UnlinkExternalLogin>(),
      ),
    );
    gh.factory<_i1021.AddPhoneSignInCubit>(
      () => _i1021.AddPhoneSignInCubit(
        gh<_i46.GetAuthConfig>(),
        gh<_i46.AddPhoneSignIn>(),
        gh<_i46.ConfirmWithLinkedProvider>(),
        gh<_i115.PhoneCountryMemory>(),
      ),
    );
    gh.factory<_i990.EditProfileCubit>(
      () => _i990.EditProfileCubit(
        gh<_i591.GetProfile>(),
        gh<_i172.GetFields>(),
        gh<_i46.CheckUsername>(),
        gh<_i504.PickImages>(),
        gh<_i504.TakePhoto>(),
        gh<_i504.UploadImage>(),
        gh<_i591.UpdateProfile>(),
      ),
    );
    gh.factory<_i1021.ChangePasswordCubit>(
      () => _i1021.ChangePasswordCubit(
        gh<_i46.GetAuthConfig>(),
        gh<_i46.ChangePassword>(),
      ),
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
    gh.factory<_i1021.SetRecoveryPinCubit>(
      () => _i1021.SetRecoveryPinCubit(
        gh<_i46.GetAuthConfig>(),
        gh<_i46.SetRecoveryPin>(),
      ),
    );
    gh.factory<_i460.DeleteAccountCubit>(
      () => _i460.DeleteAccountCubit(
        gh<_i46.DeleteAccount>(),
        gh<_i46.ConfirmWithLinkedProvider>(),
      ),
    );
    gh.factory<_i9.HomeCubit>(
      () => _i9.HomeCubit(
        gh<_i251.GetTodayArticle>(),
        gh<_i172.GetFields>(),
        gh<_i251.GetContinueReading>(),
        gh<_i924.GetActivePath>(),
        gh<_i371.SessionCubit>(),
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
    gh.factory<_i977.PrivacyCubit>(
      () =>
          _i977.PrivacyCubit(gh<_i591.SetPrivacy>(), gh<_i371.SessionCubit>()),
    );
    gh.lazySingleton<_i564.ModerationNoticesCubit>(
      () => _i564.ModerationNoticesCubit(
        gh<_i130.GetModerationNotices>(),
        gh<_i130.AcknowledgeModerationNotice>(),
        gh<_i371.SessionCubit>(),
      ),
    );
    gh.lazySingleton<_i884.StreakCubit>(
      () => _i884.StreakCubit(
        gh<_i892.GetReadingStats>(),
        gh<_i371.SessionCubit>(),
      ),
    );
    gh.factory<_i643.VerificationCubit>(
      () => _i643.VerificationCubit(
        gh<_i295.GetVerificationStatus>(),
        gh<_i295.WithdrawVerificationRequest>(),
        gh<_i371.SessionCubit>(),
      ),
    );
    gh.factory<_i280.InterestsCubit>(
      () => _i280.InterestsCubit(
        gh<_i172.GetFields>(),
        gh<_i172.GetTopics>(),
        gh<_i471.SetInterest>(),
        gh<_i371.SessionCubit>(),
      ),
    );
    gh.lazySingleton<_i1054.UnreadBadgeCubit>(
      () => _i1054.UnreadBadgeCubit(
        gh<_i854.RealtimeService>(),
        gh<_i864.GetUnreadNotificationCount>(),
        gh<_i371.SessionCubit>(),
      ),
    );
    gh.factory<_i487.ReadingStatsCubit>(
      () => _i487.ReadingStatsCubit(
        gh<_i892.GetReadingStats>(),
        gh<_i884.StreakCubit>(),
      ),
    );
    gh.factory<_i405.NotificationsCubit>(
      () => _i405.NotificationsCubit(
        gh<_i864.GetNotifications>(),
        gh<_i864.MarkNotificationsSeen>(),
        gh<_i864.MarkNotificationRead>(),
        gh<_i864.MarkAllNotificationsRead>(),
        gh<_i1054.UnreadBadgeCubit>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}

class _$AuthModule extends _i360.AuthModule {}
