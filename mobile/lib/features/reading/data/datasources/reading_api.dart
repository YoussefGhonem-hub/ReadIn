import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

import '../models/reading_models.dart';

part 'reading_api.g.dart';

/// Reading & streaks (Bearer), ADR 0013.
@lazySingleton
@RestApi()
abstract class ReadingApi {
  @factoryMethod
  factory ReadingApi(Dio dio) = _ReadingApi;

  @PUT('/articles/{id}/progress')
  Future<ReadingProgressResultModel> reportProgress(@Path('id') String articleId, @Body() ReadingProgressRequestModel body);

  @GET('/me/stats')
  Future<ReadingStatsModel> getStats();

  @GET('/me/stats/heatmap')
  Future<ReadingHeatmapModel> getHeatmap(@Query('days') int days);

  /// Another user's stats on their profile (F14, guests allowed): `403 profile.stats_private` unless they made them
  /// public.
  @GET('/users/{username}/stats')
  Future<ReadingStatsModel> getUserStats(@Path('username') String username);

  @GET('/users/{username}/stats/heatmap')
  Future<ReadingHeatmapModel> getUserHeatmap(@Path('username') String username, @Query('days') int days);
}
