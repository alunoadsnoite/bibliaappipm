plugins {
    id("com.android.application")
}

android {
    namespace = "br.com.valdenor.bibliaapp"
    compileSdk = 34

    defaultConfig {
        applicationId = "br.com.valdenor.bibliaapp"
        minSdk = 24
        targetSdk = 34
        versionCode = 5
        versionName = "4.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
}

dependencies {
}