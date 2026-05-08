# Supabase & Kotlin serialization
-keep class io.supabase.** { *; }
-keep class kotlinx.serialization.** { *; }
-keep class kotlin.** { *; }
-keep class kotlin.coroutines.** { *; }

# Prevent removal of JSON model classes
-keepclassmembers class * {
    @kotlinx.serialization.Serializable *;
}

# Prevent R8 from renaming/destructuring suspend functions
-keep class kotlinx.coroutines.** { *; }