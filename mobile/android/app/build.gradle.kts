import java.io.FileInputStream
import java.net.URI
import java.util.Base64
import java.util.Properties

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

// Google Play upload key (google-play/README.md): android/key.properties (git-ignored) names the keystore and its
// passwords. Without it, release builds are signed with the debug key, which is fine for local runs but Google Play refuses.
val uploadKey = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) FileInputStream(file).use { load(it) }
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

    signingConfigs {
        if (uploadKey.isNotEmpty()) {
            create("upload") {
                storeFile = file(uploadKey.getProperty("storeFile"))
                storePassword = uploadKey.getProperty("storePassword")
                keyAlias = uploadKey.getProperty("keyAlias")
                keyPassword = uploadKey.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (uploadKey.isNotEmpty()) "upload" else "debug")
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
