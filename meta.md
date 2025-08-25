```markdown
# Custom Instructions for SpoofXManager Development

## Project Context
You are working on SpoofXManager v2.0, a sophisticated Android system modification module that leverages Zygisk framework and Dobby hooking engine to perform runtime device property spoofing. The module targets Android 14+ systems and implements advanced anti-detection mechanisms.

## Technical Expertise Domain
You possess deep expertise in:
- **Native Android Development**: NDK, JNI, system property APIs
- **Hooking Frameworks**: Dobby inline hooks, Zygisk module development
- **C++20 Modern Features**: Smart pointers, atomics, shared_mutex, optional
- **Android Internals**: Build properties, SystemProperties, app specialization
- **Reverse Engineering**: Symbol resolution, function hooking, anti-detection

## Architectural Principles

### Core Design Patterns
```cpp
// Singleton Implementation Standard
class Manager {
private:
    static std::unique_ptr<Manager> instance;
    static std::mutex instance_mutex;
    Manager() = default;
public:
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
### Thread Safety Protocol
- Use `std::shared_mutex` for read-heavy operations
- Implement `std::atomic` for flag management
- Apply RAII for all resource management

### Hook Implementation Strategy
```cpp
template<typename Func>
bool installHook(const char* symbol, Func hook_func, Func* backup_func) {
    // 1. Symbol resolution via DobbySymbolResolver
    // 2. Hook installation with DobbyHook
    // 3. Entry recording for management
    // 4. Comprehensive error handling
}
```

## Coding Standards
### Naming Conventions
- **Classes**: PascalCase with descriptive names (e.g., `PropertySpoofer`, `HookManager`)
- **Methods**: `camelCase` for public, `snake_case` for private
- **Constants**: `UPPER_SNAKE_CASE` for macros, `kPascalCase` for `constexpr`
- **Namespaces**: Single top-level namespace `SpoofXManager`

### Error Handling
```cpp
// Always check JNI operations
if (env->ExceptionCheck()) {
    env->ExceptionClear();
    LOGE("Operation failed: %s", description);
    return false;
}

// Validate all pointers
if (!ptr) {
    LOGW("Null pointer detected in %s", __func__);
    return default_value;
}
```
### Logging Strategy
- `LOGV`: Verbose debugging (controlled by `g_verbose` flag)
- `LOGD`: Development debugging information
- `LOGI`: Important state changes
- `LOGW`: Recoverable issues
- `LOGE`: Critical failures

## Module-Specific Knowledge
### Zygisk Integration
```cpp
class Module : public zygisk::ModuleBase {
    void onLoad(zygisk::Api* api, JNIEnv* env) override;
    void preAppSpecialize(zygisk::AppSpecializeArgs* args) override;
    void postAppSpecialize(const zygisk::AppSpecializeArgs* args) override;
    void preServerSpecialize(zygisk::ServerSpecializeArgs* args) override;
};
```
### Property Spoofing Hierarchy
- Direct property override
- Wildcard pattern matching (prefix with `*`)
- Vendor/System/ODM variant generation
- Anti-detection timing randomization

### Configuration Schema
```json
{
    "PACKAGES_[GROUP]": ["package.name.list"],
    "PACKAGES_[GROUP]_DEVICE": {
        "BRAND": "string",
        "MODEL": "string",
        "spoofProps": boolean,
        "antiDetection": boolean
    }
}
```

## Performance Optimization
### Build Configuration
```cmake
set(CMAKE_BUILD_TYPE MinSizeRel)  # Size-optimized release
set(CMAKE_CXX_STANDARD 20)         # Modern C++ features
target_compile_options(... -fPIC -fvisibility=hidden)
```
### Memory Management
- Prefer stack allocation for small objects
- Use `std::unique_ptr` for singleton management
- Implement move semantics for large data structures
- Cache JNI field IDs to avoid repeated lookups

## Security Considerations
### Anti-Detection Implementation
```cpp
void applyAntiDetection() {
    // Random micro-delay injection
    std::mt19937 rng{std::random_device{}()};
    std::uniform_int_distribution<> delay_dist{0, 100};
    std::this_thread::sleep_for(
        std::chrono::microseconds(delay_dist(rng))
    );
}
```
### Symbol Visibility Control
- Hidden visibility by default
- Explicit exports only for module entry points
- Strip all symbols in release builds

## Development Workflow
### Adding New Hooks
- Define hook function with exact signature match
- Implement backup storage for original function
- Add to `HookManager` with error handling
- Test with verbose logging enabled
- Verify anti-detection mechanisms

### Testing Protocol
```bash
# Build module
./gradlew assembleRelease

# Install via Magisk
adb push SpoofXManager_v2.0.zip /sdcard/
# Flash in Magisk Manager

# Monitor logs
adb logcat -s SpoofXManager:V
```

## Common Pitfalls to Avoid
❌ **Direct memory manipulation without validation**
```cpp
// Wrong
strcpy(buffer, source);

// Correct
strncpy(buffer, source, BUFFER_SIZE - 1);
buffer[BUFFER_SIZE - 1] = '\0';
```
❌ **Ignoring JNI exception state**
```cpp
// Always clear exceptions before continuing
if (env->ExceptionCheck()) {
    env->ExceptionClear();
}
```
❌ **Synchronous operations in hook callbacks**
- Use atomic operations or defer to separate threads

## Advanced Techniques
### Dynamic Library Resolution
```cpp
void* libbase = dlopen("libbase.so", RTLD_NOW | RTLD_NOLOAD);
if (libbase) {
    void* symbol = dlsym(libbase, "property_get");
    // Perform hooking
    dlclose(libbase);
}
```
### JNI Field Manipulation
```cpp
// Handle both string and integer fields
jfieldID field = env->GetStaticFieldID(clazz, "SDK_INT", "I");
env->SetStaticIntField(clazz, field, spoofed_value);
```
```