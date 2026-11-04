@Tags(['golden'])
library;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readin/features/settings/presentation/cubit/interests_cubit.dart';
import 'package:readin/features/settings/presentation/pages/interests_page.dart';
import 'package:readin/features/taxonomy/domain/entities/field.dart';

import '../helpers/fixtures.dart';
import '../helpers/profile_fakes.dart';
import '../helpers/test_app.dart';

class MockInterestsCubit extends MockCubit<InterestsState> implements InterestsCubit {}

/// Settings → Your interests (F02, F12): followed fields and the topics of a followed field, one change being saved.
void main() {
  const topics = [
    Topic(id: 't-di', fieldId: 'f-dotnet', slug: 'di', nameAr: 'Dependency Injection', nameEn: 'Dependency Injection'),
    Topic(id: 't-ef', fieldId: 'f-dotnet', slug: 'ef-core', nameAr: 'EF Core', nameEn: 'EF Core'),
    Topic(id: 't-aspnet', fieldId: 'f-dotnet', slug: 'aspnet-core', nameAr: 'ASP.NET Core', nameEn: 'ASP.NET Core'),
  ];

  for (final variant in Variant.all) {
    testWidgets('your interests ${variant.name}', (tester) async {
      usePhoneSurface(tester, size: const Size(390, 640));
      await tester.pumpWidget(testApp(
        BlocProvider<InterestsCubit>.value(
          value: MockInterestsCubit()
            ..hold(const InterestsState(
              loading: false,
              fields: sampleFields,
              topics: {'f-dotnet': topics},
              fieldIds: {'f-dotnet', 'f-ai'},
              topicIds: {'t-di', 't-aspnet'},
              pending: {'t-aspnet'},
            )),
          child: const InterestsView(),
        ),
        variant: variant,
      ));
      await tester.pump();
      await expectLater(find.byType(InterestsView), matchesVariantGolden(variant, 'goldens/settings_interests_${variant.name}.png'));
    });
  }
}
