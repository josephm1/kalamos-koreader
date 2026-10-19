pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositories { google(); mavenCentral() } }
rootProject.name = "koreader-native-ink-review"
include(":foundation:device-api", ":devices:bigme", ":integrations:koreader:android-bridge")
