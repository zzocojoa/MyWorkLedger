import java.io.File
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningPropertiesFile: File = rootProject.file("key.properties")
val releaseSigningProperties: Properties = Properties()
if (releaseSigningPropertiesFile.isFile) {
    releaseSigningPropertiesFile.inputStream().use { inputStream ->
        releaseSigningProperties.load(inputStream)
    }
}

fun isReleaseTask(taskName: String): Boolean {
    val normalizedTaskName: String = taskName.lowercase()
    return normalizedTaskName.contains("release")
}

val isReleaseBuildRequested: Boolean = gradle.startParameter.taskNames.any(::isReleaseTask)

fun requiredReleaseSigningValue(name: String): String {
    val propertyValue: String? = releaseSigningProperties.getProperty(name)
    if (!propertyValue.isNullOrBlank()) {
        return propertyValue
    }

    val environmentValue: String? = providers.environmentVariable(name).orNull
    if (!environmentValue.isNullOrBlank()) {
        return environmentValue
    }

    throw GradleException(
        "Missing Android release signing value: name=$name sources=android/key.properties,environment",
    )
}

fun requiredReleaseSigningFile(name: String): File {
    val path: String = requiredReleaseSigningValue(name)
    val signingFile: File = file(path)
    if (!signingFile.isFile) {
        throw GradleException(
            "Android release signing file not found: name=$name path=${signingFile.absolutePath}",
        )
    }

    return signingFile
}

android {
    namespace = "com.workledger.workledger"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.workledger.workledger"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (isReleaseBuildRequested) {
                storeFile = requiredReleaseSigningFile("WORKLEDGER_RELEASE_STORE_FILE")
                storePassword = requiredReleaseSigningValue("WORKLEDGER_RELEASE_STORE_PASSWORD")
                keyAlias = requiredReleaseSigningValue("WORKLEDGER_RELEASE_KEY_ALIAS")
                keyPassword = requiredReleaseSigningValue("WORKLEDGER_RELEASE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
