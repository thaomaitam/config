# Custom Instructions for SpoofXManager Project

## Project Context
SpoofXManager is an Android Zygisk module (v2.0) that leverages the Dobby hooking framework to spoof device properties and Build fields at the system level. The project targets Android 14+ (SDK 35) and supports ARM64/ARMv7 architectures. It's designed as a Magisk/KernelSU module that hooks into the Zygote process to modify device properties for specific applications based on JSON configuration.

## Technical Stack
- **Language**: C++20 with modern STL features
- **Build System**: Gradle 35.0.1 with CMake
- **Native Development**: NDK 28.0.13004108
- **Hooking Framework**: Dobby (static library)
- **Module Framework**: Zygisk API
- **JSON Parser**: nlohmann/json (header-only, no I/O, no exceptions)
- **Target Android**: SDK 26-35 (Android 14+)
- **Architectures**: arm64-v8a, armeabi-v7a
- **Java Compatibility**: Java 21

## Code Style & Conventions

### Naming Conventions
- **Namespaces**: PascalCase (e.g., `SpoofXManager`)
- **Classes**: PascalCase with descriptive names (e.g., `PropertySpoofer`, `HookManager`, `BuildFieldManager`)
- **Functions**: camelCase for methods (e.g., `installHook`, `getOverride`)
- **Static hooks**: snake_case with `hook_` prefix (e.g., `hook_property_get`)
- **Member variables**: snake_case with trailing underscore for private members
- **Constants**: UPPER_SNAKE_CASE (e.g., `PROP_VALUE_MAX`)
- **Macros**: UPPER_SNAKE_CASE for defines (e.g., `LOG_TAG`, `PRIMARY_CONFIG_PATH`)

### File Organization
```
module/
├── zygisk/          # Compiled .so files per architecture
├── module.prop      # Module metadata
src/main/
├── cpp/
│   ├── main.cpp     # Main module implementation
│   ├── zygisk.hpp   # Zygisk API header
│   ├── json.hpp     # JSON parser header
│   ├── dobby.h      # Dobby framework header
│   ├── Dobby/       # Dobby framework subdirectory
│   └── CMakeLists.txt
```

### C++ Patterns & Standards
- **Always use C++20 features** (concepts, ranges, std::optional, etc.)
- **RAII pattern mandatory** for resource management
- **Smart pointers over raw pointers** (std::unique_ptr for singletons, std::shared_ptr for shared resources)
- **Thread safety**: Use std::mutex, std::shared_mutex, std::atomic for concurrent access
- **Error handling**: Return bool/optional, avoid exceptions (JSON configured with JSON_NOEXCEPTION)
- **Memory management**: Prefer stack allocation, use std::vector for dynamic arrays

## Architecture Patterns

### Singleton Pattern Implementation
```cpp
class Manager {
private:
    static std::unique_ptr<Manager> instance;
    static std::mutex instance_mutex;
    Manager() = default;
public:
    // Friend declaration for std::make_unique access
    friend std::unique_ptr<Manager> std::make_unique<Manager>();
    
    static Manager& getInstance() {
        std::lock_guard<std::mutex> lock(instance_mutex);
        if (!instance) {
            instance = std::make_unique<Manager>();
        }
        return *instance;
    }
};
```

### Hook Function Pattern
```cpp
// Original function pointer storage
static ReturnType (*orig_function_name)(ParamTypes...) = nullptr;

// Hook implementation
static ReturnType hook_function_name(ParamTypes... params) {
    // Pre-processing
    auto& manager = Manager::getInstance();
    manager.applyAntiDetection();
    
    // Check for overrides/modifications
    if (shouldModify(params...)) {
        // Apply modifications
        return modifiedResult;
    }
    
    // Call original
    return orig_function_name ? orig_function_name(params...) : defaultValue;
}
```

### Module Class Structure
- Inherit from `zygisk::ModuleBase`
- Override: `onLoad`, `preAppSpecialize`, `postAppSpecialize`, `preServerSpecialize`
- Use `zygisk::Api` for module options
- Clean up resources in cleanup() method

## Logging Guidelines

### Log Levels (Android)
```cpp
#define LOGV(...) if (g_verbose) __android_log_print(ANDROID_LOG_VERBOSE, LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
```

- Use LOGV for verbose/trace logging (controlled by g_verbose flag)
- Use LOGD for debug information
- Use LOGI for important state changes
- Use LOGW for warnings and recoverable errors
- Use LOGE for critical errors

## JNI Patterns

### Safe JNI Field Access
```cpp
auto setStringField = [this](const std::string& name, const std::string& value, bool isVersionField) {
    if (value.empty()) return;
    
    jclass targetClass = isVersionField ? version_class_global : build_class_global;
    jfieldID field = env->GetStaticFieldID(targetClass, name.c_str(), "Ljava/lang/String;");
    
    if (env->ExceptionCheck() || !field) {
        env->ExceptionClear();
        return;
    }
    
    jstring jvalue = env->NewStringUTF(value.c_str());
    if (!jvalue) return;
    
    env->SetStaticObjectField(targetClass, field, jvalue);
    
    if (!env->ExceptionCheck()) {
        LOGV("Set %s.%s = %s", isVersionField ? "Build.VERSION" : "Build", name.c_str(), value.c_str());
    } else {
        env->ExceptionClear();
    }
    
    env->DeleteLocalRef(jvalue);
};
```

### Integer Field Handling
```cpp
// Special handling for SDK_INT (integer field)
jfieldID sdkIntField = env->GetStaticFieldID(version_class_global, "SDK_INT", "I");
if (sdkIntField && !env->ExceptionCheck()) {
    try {
        int sdk_val = std::stoi(config.sdk);
        env->SetStaticIntField(version_class_global, sdkIntField, sdk_val);
    } catch (const std::exception& e) {
        LOGE("Failed to parse SDK value: %s", config.sdk.c_str());
    }
}
```

## Configuration Management

### JSON Configuration Structure
```cpp
// Use nlohmann::json with no-exception mode
#define JSON_NOEXCEPTION 1
#define JSON_NO_IO 1

// Configuration paths with fallback mechanism
#define PRIMARY_CONFIG_PATH "/data/adb/modules/SpoofXManager/config.json"
#define SECONDARY_CONFIG_PATH "/data/adb/config.json"
#define TERTIARY_CONFIG_PATH "/data/local/tmp/config.json"

// Parse safely
config_json = nlohmann::json::parse(buffer, nullptr, false);
if (config_json.is_discarded()) return false;
```

### Property Override Pattern
```cpp
// Support direct and wildcard matching
std::optional<std::string> getOverride(const std::string& name) const {
    std::shared_lock lock(map_mutex);
    
    // Direct match
    auto it = property_overrides.find(name);
    if (it != property_overrides.end()) {
        return it->second;
    }
    
    // Wildcard match (prefix with *)
    for (const auto& [key, value] : property_overrides) {
        if (key.starts_with("*") && name.ends_with(key.substr(1))) {
            return value;
        }
    }
    
    return std::nullopt;
}
```

## Dobby Hooking Framework Usage

### Hook Installation
```cpp
// Symbol resolution
void* symbol_addr = DobbySymbolResolver(nullptr, symbol);
if (!symbol_addr) {
    LOGE("Failed to resolve symbol: %s", symbol);
    return false;
}

// Install hook
if (DobbyHook(symbol_addr, 
              reinterpret_cast<void*>(hook_func),
              reinterpret_cast<void**>(backup_func)) != 0) {
    LOGE("DobbyHook failed for %s", symbol);
    return false;
}
```

### Hook Cleanup
```cpp
DobbyDestroy(hook.original_addr);
```

## Build Configuration

### CMake Settings
```cmake
cmake_minimum_required(VERSION 3.10)
project("SpoofXManager" VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Compiler flags for security and optimization
target_compile_options(${CMAKE_PROJECT_NAME} PRIVATE
    -fPIC
    -fvisibility=hidden
    -Wall
    -Wextra
    -Werror=return-type
    -Wno-unused-parameter
)

# Linker flags for release builds
target_link_options(${CMAKE_PROJECT_NAME} PRIVATE
    -Wl,--exclude-libs,ALL
    -Wl,--build-id=none
    -Wl,--strip-all
)
```

### Gradle Configuration
```kotlin
// Always use these settings for consistency
android {
    namespace = "Spoof.X.Manager"
    compileSdk = 35
    buildToolsVersion = "35.0.1"
    ndkVersion = "28.0.13004108"
    
    defaultConfig {
        minSdk = 26
        targetSdk = 35
        versionCode = 2000
        versionName = "v2.0"
    }
    
    externalNativeBuild {
        cmake {
            abiFilters("arm64-v8a", "armeabi-v7a")
            arguments(
                "-DCMAKE_BUILD_TYPE=MinSizeRel",
                "-DANDROID_STL=c++_static"
            )
        }
    }
}
```

## Anti-Detection Techniques

### Random Delay Implementation
```cpp
std::mt19937 rng{std::random_device{}()};
std::uniform_int_distribution<> delay_dist{0, 100};

void applyAntiDetection() {
    if (!anti_detection_enabled) return;
    
    // Add random micro-delay to mimic real property access
    std::this_thread::sleep_for(
        std::chrono::microseconds(delay_dist(rng))
    );
}
```

### Module Concealment
```cpp
// Force unmount for concealment
api->setOption(zygisk::FORCE_DENYLIST_UNMOUNT);

// Self-cleanup when not needed
api->setOption(zygisk::DLCLOSE_MODULE_LIBRARY);
```

## Common Tasks

### Adding New Property Hooks
1. Add property name to DeviceConfig struct
2. Update toPropertyMap() method to include new property
3. Add vendor/system/odm variants if needed
4. Update JSON parser getString() calls

### Adding New Build Fields
1. Add field to DeviceConfig struct
2. Update BuildFieldManager::updateFields() method
3. Add to field cache in cacheFieldIds()
4. Handle type-specific setting (String vs int)

### Extending Hook Coverage
1. Define original function pointer as static member
2. Implement hook function following the pattern
3. Add to installHooks() method
4. Record in HookEntry vector

## Testing & Debugging

### Debug Build Verification
```bash
# Check module installation
ls -la /data/adb/modules/SpoofXManager/

# Verify zygisk library
file /data/adb/modules/SpoofXManager/zygisk/*.so

# Monitor logs
adb logcat -s SpoofXManager:V
```

### Configuration Testing
```json
{
  "PACKAGES_EXAMPLE": ["com.example.app"],
  "PACKAGES_EXAMPLE_DEVICE": {
    "BRAND": "google",
    "MODEL": "Pixel 8 Pro",
    "spoofProps": true,
    "spoofBuild": true,
    "verbose": true
  }
}
```

## Anti-Patterns to Avoid

1. **Never use raw new/delete** - Always use smart pointers
2. **Never ignore JNI exceptions** - Always check and clear
3. **Never use blocking I/O in hooks** - Will cause ANRs
4. **Never leak global references** - Always DeleteGlobalRef
5. **Never assume symbol availability** - Always check DobbySymbolResolver result
6. **Never use std::cout/printf** - Use Android logging macros
7. **Never throw exceptions** - Project uses no-exception mode
8. **Never modify without mutex** - All shared data needs protection

## Quick Reference

### Essential Macros
- `LOG_TAG` - "SpoofXManager"
- `PROP_VALUE_MAX` - System property value max length
- `JSON_NOEXCEPTION` - Must be defined before json.hpp

### Key Classes
- `HookManager` - Singleton Dobby hook manager
- `PropertySpoofer` - Property override system
- `BuildFieldManager` - JNI Build field modifier
- `SpoofXManagerModule` - Main Zygisk module

### Critical Files
- `/data/adb/modules/SpoofXManager/config.json` - Primary config
- `module.prop` - Module metadata (auto-updated)
- `zygisk/*.so` - Architecture-specific libraries

### Version Requirements
- Minimum SDK: 26 (Android 8.0)
- Target SDK: 35 (Android 14+)
- NDK: 28.0.13004108
- C++ Standard: C++20

## Response Guidelines for Code Assistance

When modifying or extending this codebase:

1. **Maintain the existing architecture** - Don't introduce new patterns without necessity
2. **Follow the thread-safety model** - Use appropriate mutex types for read/write patterns
3. **Respect the no-exception policy** - Use optional/bool returns instead
4. **Keep logging consistent** - Use appropriate log levels with descriptive messages
5. **Test on both architectures** - Ensure ARM64 and ARMv7 compatibility
6. **Document Vietnamese comments** - Preserve existing Vietnamese documentation
7. **Validate JSON handling** - Always check is_discarded() after parsing
8. **Maintain security posture** - Keep compiler hardening flags intact