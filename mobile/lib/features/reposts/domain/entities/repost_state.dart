import 'package:equatable/equatable.dart';

/// `RepostStateDto` (F29): an article's reposts right after the viewer's change.
class RepostState extends Equatable {
  const RepostState({required this.repostCount, required this.isReposted});

  final int repostCount;
  final bool isReposted;

  @override
  List<Object?> get props => [repostCount, isReposted];
}
