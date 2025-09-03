# ==========================================
# MODULE.PROP
# ==========================================
id=universal_apk_mounter
name=Universal APK Mounter
version=v1.0
versionCode=1
author=YourName
description=Universal template for mounting modified APKs over stock apps

# ==========================================
# SERVICE.SH
# ==========================================
#!/system/bin/sh

# Module paths
MODDIR=${0%/*}
LOGFILE=/cache/apk_mount.log

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOGFILE
}

log "=== APK Mount Service Started ==="

# Get Magisk environment
MAGISKTMP="$(magisk --path)" || MAGISKTMP=/sbin
MIRROR="$MAGISKTMP/.magisk/mirror"

if [ ! -d "$MIRROR" ]; then
    log "ERROR: Magisk mirror not found at $MIRROR"
    exit 1
fi

log "Magisk mirror: $MIRROR"

# Wait for system ready
log "Waiting for boot completion..."
until [ "$(getprop sys.boot_completed)" = 1 ]; do sleep 3; done
until [ -d "/sdcard/Android" ]; do sleep 1; done
log "System boot completed"

# Wait for package manager
log "Waiting for package manager..."
until pm list packages >/dev/null 2>&1; do sleep 2; done
log "Package manager ready"

# Load app configurations
CONFIG_FILE="$MODDIR/apps.conf"
if [ ! -f "$CONFIG_FILE" ]; then
    log "ERROR: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Process each app configuration
while IFS='|' read -r package_name apk_filename enabled || [ -n "$package_name" ]; do
    # Skip comments and empty lines
    case "$package_name" in
        \#*|"") continue ;;
    esac
    
    if [ "$enabled" != "1" ]; then
        log "SKIP: $package_name (disabled)"
        continue
    fi
    
    log "Processing: $package_name"
    
    # Check if package is installed
    if ! pm list packages | grep -q "package:$package_name"; then
        log "WARNING: $package_name not installed, skipping"
        continue
    fi
    
    # Unmount existing mounts for this package
    log "Cleaning up existing mounts for $package_name"
    grep "$package_name" /proc/mounts | while read -r line; do
        mount_point=$(echo "$line" | cut -d " " -f 2 | sed "s/apk.*/apk/")
        log "Unmounting: $mount_point"
        umount -l "$mount_point" 2>/dev/null
    done
    
    # Define paths
    modified_apk="$MODDIR/apks/$package_name/$apk_filename"
    
    if [ ! -f "$modified_apk" ]; then
        log "ERROR: Modified APK not found: $modified_apk"
        continue
    fi
    
    # Get stock APK path
    stock_apk=$(pm path "$package_name" | grep "base" | head -n1 | sed "s/package://g")
    if [ -z "$stock_apk" ]; then
        # Try alternative path resolution
        stock_apk=$(pm path "$package_name" | head -n1 | sed "s/package://g")
    fi
    
    if [ -z "$stock_apk" ]; then
        log "ERROR: Cannot resolve stock APK path for $package_name"
        continue
    fi
    
    log "Stock APK: $stock_apk"
    log "Modified APK: $modified_apk"
    
    # Set proper SELinux context
    chcon u:object_r:apk_data_file:s0 "$modified_apk" 2>/dev/null || {
        log "WARNING: Failed to set SELinux context for $modified_apk"
    }
    
    # Perform bind mount
    if mount -o bind "$modified_apk" "$stock_apk"; then
        log "SUCCESS: Mounted $package_name"
        
        # Force stop app to reload mounted APK
        am force-stop "$package_name" 2>/dev/null
        log "Force stopped $package_name"
        
        # Optional: Clear app cache to ensure clean state
        pm clear-cache "$package_name" 2>/dev/null
        
    else
        log "ERROR: Failed to mount $package_name"
    fi
    
done < "$CONFIG_FILE"

log "=== APK Mount Service Completed ==="

# ==========================================
# APPS.CONF (Configuration File)
# ==========================================
# Format: package_name|apk_filename|enabled(1/0)
# Lines starting with # are comments

# YouTube ReVanced
com.google.android.youtube|base.apk|1

# Instagram (example)
# com.instagram.android|base.apk|0

# TikTok (example) 
# com.zhiliaoapp.musically|base.apk|0

# Spotify (example)
# com.spotify.music|base.apk|0

# Twitter/X (example)
# com.twitter.android|base.apk|0

# ==========================================
# UNINSTALL.SH
# ==========================================
#!/system/bin/sh

LOGFILE=/cache/apk_mount_uninstall.log

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOGFILE
}

log "=== APK Mount Module Uninstall ==="

# Unmount all mounted APKs
MODDIR=${0%/*}
CONFIG_FILE="$MODDIR/apps.conf"

if [ -f "$CONFIG_FILE" ]; then
    while IFS='|' read -r package_name apk_filename enabled || [ -n "$package_name" ]; do
        case "$package_name" in
            \#*|"") continue ;;
        esac
        
        log "Unmounting $package_name"
        grep "$package_name" /proc/mounts | while read -r line; do
            mount_point=$(echo "$line" | cut -d " " -f 2 | sed "s/apk.*/apk/")
            umount -l "$mount_point" 2>/dev/null && log "Unmounted: $mount_point"
        done
        
        # Restart app to load original APK
        am force-stop "$package_name" 2>/dev/null
        
    done < "$CONFIG_FILE"
fi

log "=== Uninstall Completed ==="

# ==========================================
# INSTALL.SH (Optional - for advanced setup)
# ==========================================
#!/system/bin/sh

# Advanced install script with device compatibility checks
MODPATH=$MODPATH
LOGFILE=/cache/apk_mount_install.log

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOGFILE
}

log "=== APK Mount Module Install ==="

# Check Magisk version
MAGISK_VER=$(magisk -c | sed 's/:.*//')
if [ "$MAGISK_VER" -lt 20400 ]; then
    log "ERROR: Magisk 20.4+ required, found: $MAGISK_VER"
    exit 1
fi

# Check Android version
ANDROID_SDK=$(getprop ro.build.version.sdk)
if [ "$ANDROID_SDK" -lt 21 ]; then
    log "ERROR: Android 5.0+ required, found SDK: $ANDROID_SDK"
    exit 1
fi

# Create directory structure
mkdir -p "$MODPATH/apks"

# Example structure creation
for pkg in "com.google.android.youtube" "com.instagram.android" "com.spotify.music"; do
    mkdir -p "$MODPATH/apks/$pkg"
    log "Created directory: $MODPATH/apks/$pkg"
done

# Set permissions
chmod 755 "$MODPATH/service.sh"
chmod 644 "$MODPATH/apps.conf"

log "=== Install Completed ==="

# ==========================================
# DIRECTORY STRUCTURE
# ==========================================
# universal_apk_mounter/
# ├── META-INF/
# │   └── com/
# │       └── google/
# │           └── android/
# │               ├── update-binary
# │               └── updater-script
# ├── module.prop
# ├── service.sh
# ├── uninstall.sh
# ├── install.sh (optional)
# ├── apps.conf
# └── apks/
#     ├── com.google.android.youtube/
#     │   └── base.apk
#     ├── com.instagram.android/
#     │   └── base.apk
#     └── com.spotify.music/
#         └── base.apk

# ==========================================
# USAGE INSTRUCTIONS
# ==========================================

## Setup Steps:
# 1. Copy your modified APKs to respective directories in apks/
# 2. Edit apps.conf to enable/disable specific apps
# 3. Install module through Magisk Manager
# 4. Reboot device

## Adding New Apps:
# 1. Create directory: mkdir -p apks/com.example.app/
# 2. Copy modified APK: cp modified.apk apks/com.example.app/base.apk
# 3. Add entry to apps.conf: com.example.app|base.apk|1
# 4. Reboot or restart module service

## Debugging:
# Check logs: cat /cache/apk_mount.log
# Check mounts: grep "package_name" /proc/mounts
# Manual mount test: mount -o bind /path/to/modified.apk /path/to/stock.apk

## Integration with LSPosed:
# This mount method works seamlessly with LSPosed hooks
# Mount happens before app load, hooks apply during runtime
# Combined approach allows both static and dynamic modifications

# ==========================================
# ADVANCED CUSTOMIZATION OPTIONS
# ==========================================

# Multiple APK support (for split APKs):
# Modify script to handle split APKs in apps with multiple components
# Example: YouTube has base.apk, config.*.apk, split_*.apk

# Conditional mounting:
# Add device/ROM specific conditions
# Mount different APK variants based on device properties

# Version checking:
# Compare installed vs modified APK versions
# Prevent mounting incompatible versions

# Backup integration:
# Automatically backup original APKs before first mount
# Restore capability for easy rollback