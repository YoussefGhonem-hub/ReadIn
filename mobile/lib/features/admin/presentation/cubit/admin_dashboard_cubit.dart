import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/admin_dashboard.dart';
import '../../domain/usecases/admin_usecases.dart';

enum AdminDashboardStatus { loading, ready, failure }

class AdminDashboardState extends Equatable {
  const AdminDashboardState({
    this.period = AdminPeriod.today,
    this.status = AdminDashboardStatus.loading,
    this.dashboard,
    this.failure,
  });

  final AdminPeriod period;
  final AdminDashboardStatus status;

  /// The last numbers shown; kept (dimmed) while another period loads.
  final AdminDashboard? dashboard;
  final Failure? failure;

  @override
  List<Object?> get props => [period, status, dashboard, failure];
}

/// The console's dashboard (F23): today by default; another period reloads it.
@injectable
class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this._get) : super(const AdminDashboardState());

  final GetAdminDashboard _get;
  int _version = 0;

  /// Null when it worked.
  Future<Failure?> load() async {
    final version = ++_version;
    final period = state.period;
    emit(AdminDashboardState(period: period, dashboard: state.dashboard));
    final result = await _get(period);
    if (isClosed || version != _version) return null;
    emit(result.fold(
      (failure) => AdminDashboardState(period: period, status: AdminDashboardStatus.failure, failure: failure, dashboard: state.dashboard),
      (dashboard) => AdminDashboardState(period: period, status: AdminDashboardStatus.ready, dashboard: dashboard),
    ));
    return result.failureOrNull;
  }

  Future<void> setPeriod(AdminPeriod period) async {
    if (period == state.period && state.status != AdminDashboardStatus.failure) return;
    emit(AdminDashboardState(period: period, dashboard: state.dashboard));
    await load();
  }
}
