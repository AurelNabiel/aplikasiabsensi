import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/profile.dart';
import '../data/member_repository.dart';
import 'auth_providers.dart';

final memberRepositoryProvider = Provider<MemberRepository>(
  (ref) => MemberRepository(ref.watch(supabaseClientProvider)),
);

final membersDirectoryProvider =
    FutureProvider.autoDispose<List<Profile>>((ref) {
  return ref.watch(memberRepositoryProvider).fetchMembers();
});
