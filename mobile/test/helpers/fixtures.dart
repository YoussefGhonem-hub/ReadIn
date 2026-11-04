import 'package:readin/features/article/domain/entities/article.dart';
import 'package:readin/features/auth/domain/entities/me.dart';
import 'package:readin/features/taxonomy/domain/entities/field.dart';

const dotnetField = FieldRef(id: 'f-dotnet', slug: 'dotnet', nameAr: '.NET', nameEn: '.NET');
const aiField = FieldRef(id: 'f-ai', slug: 'ai', nameAr: 'الذكاء الاصطناعي', nameEn: 'AI');

const editorial = Author(id: 'a-1', displayName: 'ReadIn Editorial', username: 'editorial', isVerified: true);

const sampleTitles = [
  'يعني إيه Dependency Injection في .NET؟ وليه كل الناس بتتكلم عنه',
  'إزاي تختار بين Transient و Scoped في مشروعك؟',
  'الـ AI Agents هتغيّر طريقة شغلك إزاي؟',
  'EF Core: إزاي تكتب queries سريعة من غير ما توجع الـ database',
];

ArticleCard sampleCard(int i, {String language = 'ar-EG'}) => ArticleCard(
      id: 'art-$i',
      slug: 'article-$i',
      language: language,
      title: sampleTitles[i % sampleTitles.length],
      field: i.isEven ? aiField : dotnetField,
      author: editorial,
      readingTimeMinutes: 4 + i,
      publishedAt: DateTime.utc(2026, 10, 12),
      isAiAssisted: true,
      versionBadge: i.isOdd ? '.NET 10' : null,
      reactionCount: 120 - i * 7,
      commentCount: 18 - i,
    );

const sampleFields = [
  Field(id: 'f-dotnet', slug: 'dotnet', nameAr: '.NET', nameEn: '.NET', topicCount: 9),
  Field(id: 'f-ai', slug: 'ai', nameAr: 'الذكاء الاصطناعي', nameEn: 'AI', topicCount: 5),
  Field(id: 'f-frontend', slug: 'frontend', nameAr: 'Frontend', nameEn: 'Frontend', topicCount: 7),
  Field(id: 'f-mobile', slug: 'mobile', nameAr: 'موبايل', nameEn: 'Mobile', topicCount: 6),
];

const sampleMe = Me(
  id: 'u-1',
  phoneNumber: '+12025550110',
  displayName: 'Youssef Hassan',
  username: 'reader1',
  onboardingCompleted: true,
);
