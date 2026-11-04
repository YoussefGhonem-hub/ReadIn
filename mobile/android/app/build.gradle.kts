import java.net.URI
import java.util.Base64

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// App Links (SPEC F24, docs/setup/app-links.md): the web domain is the WEB_ORIGIN dart-define (config/prod.json), the
// same value the app uses for the links it shares. Flutter hands every dart-define to Gradle as base64 "KEY=value".
val dartDefines: Map<String, String> = (project.findProperty("dart-defines") as String?)
    ?.split(",")
    ?.mapNotNull { encoded ->
        val entry = String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
        val separator = entry.indexOf('=')
        if (separator > 0) entry.substring(0, separator) to entry.substring(separator + 1) else null
    }
    ?.toMap()
    ?: emptyMap()
val webOrigin: String = dartDefines["WEB_ORIGIN"]?.trim()?.trimEnd('/') ?: "https://readin.app"
val appLinkHost: String = URI(webOrigin).let { uri ->
    require(uri.scheme == "https" && !uri.host.isNullOrBlank() && uri.path.isNullOrEmpty() && uri.query == null) {
        "WEB_ORIGIN must be an https origin such as https://readin.app, without a path (got '$webOrigin')."
    }
    uri.host.lowercase()
}

android {
    namespace = "app.readin.readin"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications needs core library desugaring.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "app.readin.readin"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // The host of the App Links intent filter (AndroidManifest.xml).
        manifestPlaceholders["appLinkHost"] = appLinkHost
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
