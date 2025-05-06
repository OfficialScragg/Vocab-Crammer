# Keep TypeToken classes to fix SharedPreferences issue
-keep class com.google.common.reflect.TypeToken
-keep class * extends com.google.common.reflect.TypeToken

# Keep Gson classes
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep SharedPreferences
-keep class * extends android.content.SharedPreferences
-keep class * extends android.content.SharedPreferences$Editor 