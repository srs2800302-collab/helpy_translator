import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val registryStudioReleaseSigning =
    mapOf(
        "storeFile" to System.getenv("REGISTRY_STUDIO_ANDROID_KEYSTORE_PATH"),
        "storePassword" to System.getenv("REGISTRY_STUDIO_ANDROID_STORE_PASSWORD"),
        "keyAlias" to System.getenv("REGISTRY_STUDIO_ANDROID_KEY_ALIAS"),
        "keyPassword" to System.getenv("REGISTRY_STUDIO_ANDROID_KEY_PASSWORD"),
    )

val registryStudioReleaseSigningConfigured =
    registryStudioReleaseSigning.values.all { value ->
        !value.isNullOrBlank()
    }

val registryStudioReleaseTaskRequested =
    gradle.startParameter.taskNames.any { taskName ->
        taskName.contains("Release", ignoreCase = true)
    }

if (registryStudioReleaseTaskRequested && !registryStudioReleaseSigningConfigured) {
    throw GradleException(
        "Registry Studio release signing environment variables are missing.",
    )
}

android {
    namespace = "com.example.helpy_translator"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.registry_studio"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (registryStudioReleaseSigningConfigured) {
            create("registryStudioRelease") {
                storeFile =
                    file(
                        requireNotNull(
                            registryStudioReleaseSigning["storeFile"],
                        ),
                    )
                storePassword =
                    requireNotNull(
                        registryStudioReleaseSigning["storePassword"],
                    )
                keyAlias =
                    requireNotNull(
                        registryStudioReleaseSigning["keyAlias"],
                    )
                keyPassword =
                    requireNotNull(
                        registryStudioReleaseSigning["keyPassword"],
                    )
            }
        }
    }

    buildTypes {
        release {
            if (registryStudioReleaseSigningConfigured) {
                signingConfig =
                    signingConfigs.getByName("registryStudioRelease")
            }
        }
    }
}

flutter {
    source = "../.."
}
