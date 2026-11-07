import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../domain/entities/admin_content.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/entities/paged_list.dart';
import '../../domain/usecases/admin_usecases.dart';
import 'admin_list_cubit.dart';

/// The console's Users (F23): search, filters, sort, 50 a page.
@injectable
class AdminUsersCubit extends AdminListCubit<AdminUserRow, AdminUserQuery> {
  AdminUsersCubit(this._get) : super(const AdminUserQuery());

  final GetAdminUsers _get;

  @override
  Future<Result<PagedList<AdminUserRow>>> fetch(AdminUserQuery query, int page) => _get(query, page: page);

  @override
  Object idOf(AdminUserRow item) => item.id;
}

/// Content's articles (F23): newest first, filtered; opened from the dashboard with its period.
@injectable
class AdminArticlesCubit extends AdminListCubit<AdminArticleRow, AdminArticleQuery> {
  AdminArticlesCubit(this._get, @factoryParam AdminArticleQuery? query) : super(query ?? const AdminArticleQuery());

  final GetAdminArticles _get;

  @override
  Future<Result<PagedList<AdminArticleRow>>> fetch(AdminArticleQuery query, int page) => _get(query, page: page);

  @override
  Object idOf(AdminArticleRow item) => item.id;
}

/// "Latest comments" (F23): newest first across all articles, replies included.
@injectable
class AdminCommentsCubit extends AdminListCubit<AdminCommentRow, AdminCommentQuery> {
  AdminCommentsCubit(this._get) : super(const AdminCommentQuery());

  final GetAdminComments _get;

  @override
  Future<Result<PagedList<AdminCommentRow>>> fetch(AdminCommentQuery query, int page) => _get(query, page: page);

  @override
  Object idOf(AdminCommentRow item) => item.id;
}
