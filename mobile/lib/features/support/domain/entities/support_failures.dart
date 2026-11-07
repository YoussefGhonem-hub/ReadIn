import '../../../../core/errors/failure.dart';

/// `429 support.limit` (F35) with which limit was reached: [daily] (5 new tickets in 24 hours) or [open] (10 tickets
/// not closed), so the form can say which. Null when the API didn't say.
enum SupportLimitKind {
  daily,
  open;

  static SupportLimitKind? fromWire(Object? wire) => values.where((kind) => kind.name == wire).firstOrNull;
}

class SupportLimitFailure extends Failure {
  const SupportLimitFailure({this.limit, super.statusCode = 429, super.message}) : super(FailureCodes.supportLimit);

  final SupportLimitKind? limit;

  @override
  List<Object?> get props => [...super.props, limit];
}
