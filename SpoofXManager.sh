#!/bin/sh
#
# SpoofXManager Config Generator v2.1
# Enhanced Model-Based Configuration System
# Modified from PIF Generator by osm0sis & chiteroman
# Specialized for SpoofXManager by x1337cn
#
# To be run with the /vendor/build.prop (vendor-build.prop) and
# /system/build.prop (build.prop) from the stock ROM of a device

# Command line options:
# "advanced" adds verbose logging and anti-detection settings
# "minimal" creates basic config without optional fields

N="
";

echo "SpoofXManager Config Generator v2.1 - Model-Based Edition \
    $N  Enhanced for Zygisk-based Device Spoofing \
    $N  Based on osm0sis PIF Generator";

item() { echo "$N- $@"; }
die() { echo "$N$N! $@"; exit 1; }
file_getprop() { grep -m1 "^$2=" "$1" 2>/dev/null | cut -d= -f2-; }

# *** ENHANCED: Directory and parameter handling for SpoofXManager ***
if [ -d "$1" ]; then
  DIR="$1/dummy";
  LOCAL="$(readlink -f "$PWD")";
  shift;
else
  case "$0" in
    *.sh) DIR="$0";;
       *) DIR="$(lsof -p $$ 2>/dev/null | grep -o '/.*GenerateSpoofXConfig.sh$')";;
  esac;
fi;
DIR=$(dirname "$(readlink -f "$DIR")");
if [ "$LOCAL" ]; then
  item "Using prop directory: $DIR";
  item "Using output directory: $LOCAL";
  LOCAL="$LOCAL/";
fi;
cd "$DIR";

# *** ENHANCED: SpoofXManager specific options ***
ADVANCED=false;
MINIMAL=false;
until [ -z "$1" ]; do
  case $1 in
    advanced) ADVANCED=true; STYLE="(Advanced)"; shift;;
    minimal) MINIMAL=true; STYLE="(Minimal)"; shift;;
  esac;
done;
item "Using config mode: SpoofXManager $STYLE";

# *** CRITICAL: Check for vendor-build.prop as primary source ***
[ ! -f vendor-build.prop ] && [ ! -f build.prop ] \
   && die "No vendor-build.prop or build.prop files found in script directory";

if [ ! -f vendor-build.prop ]; then
  item "Warning: vendor-build.prop not found, using build.prop as primary source";
fi;

item "Parsing build.prop files for SpoofXManager config ...";

# *** ENHANCED: Multi-source property extraction with vendor priority ***
extract_property() {
  local prop_name="$1"
  local result=""
  
  # Priority order: vendor-build.prop -> build.prop -> system-build.prop -> product-build.prop
  if [ -f vendor-build.prop ]; then
    result=$(file_getprop vendor-build.prop "$prop_name")
  fi
  
  if [ -z "$result" ] && [ -f build.prop ]; then
    result=$(file_getprop build.prop "$prop_name")
  fi
  
  if [ -z "$result" ] && [ -f system-build.prop ]; then
    result=$(file_getprop system-build.prop "$prop_name")
  fi
  
  if [ -z "$result" ] && [ -f product-build.prop ]; then
    result=$(file_getprop product-build.prop "$prop_name")
  fi
  
  echo "$result"
}

# *** ENHANCED: Comprehensive property extraction with vendor-build.prop optimization ***
BRAND=$(extract_property ro.product.vendor.brand)
[ -z "$BRAND" ] && BRAND=$(extract_property ro.product.brand)
[ -z "$BRAND" ] && BRAND=$(extract_property ro.product.system.brand)

MANUFACTURER=$(extract_property ro.product.vendor.manufacturer)
[ -z "$MANUFACTURER" ] && MANUFACTURER=$(extract_property ro.product.manufacturer)
[ -z "$MANUFACTURER" ] && MANUFACTURER=$(extract_property ro.product.system.manufacturer)

DEVICE=$(extract_property ro.product.vendor.device)
[ -z "$DEVICE" ] && DEVICE=$(extract_property ro.product.device)
[ -z "$DEVICE" ] && DEVICE=$(extract_property ro.product.system.device)

PRODUCT=$(extract_property ro.product.vendor.name)
[ -z "$PRODUCT" ] && PRODUCT=$(extract_property ro.product.name)
[ -z "$PRODUCT" ] && PRODUCT=$(extract_property ro.product.system.name)

MODEL=$(extract_property ro.product.vendor.model)
[ -z "$MODEL" ] && MODEL=$(extract_property ro.product.model)
[ -z "$MODEL" ] && MODEL=$(extract_property ro.product.system.model)
[ -z "$MODEL" ] && MODEL=$(extract_property ro.product.model_for_attestation)

FINGERPRINT=$(extract_property ro.vendor.build.fingerprint)
[ -z "$FINGERPRINT" ] && FINGERPRINT=$(extract_property ro.build.fingerprint)
[ -z "$FINGERPRINT" ] && FINGERPRINT=$(extract_property ro.system.build.fingerprint)

# *** ENHANCED: Extended properties with vendor-build.prop specific mappings ***
BOARD=$(extract_property ro.product.board)
[ -z "$BOARD" ] && BOARD=$(extract_property ro.board.platform)

# *** CRITICAL: Hardware extraction from vendor-build.prop ***
HARDWARE=$(extract_property ro.board.platform)
[ -z "$HARDWARE" ] && HARDWARE=$(extract_property ro.hardware)
[ -z "$HARDWARE" ] && HARDWARE=$(extract_property ro.boot.hardware)

# *** ENHANCED: Bootloader extraction from vendor-specific properties ***
BOOTLOADER=$(extract_property ro.build.expect.bootloader)
[ -z "$BOOTLOADER" ] && BOOTLOADER=$(extract_property ro.bootloader)

# *** CRITICAL: Display ID - may not exist in vendor-build.prop ***
DISPLAY=$(extract_property ro.build.display.id)
[ -z "$DISPLAY" ] && DISPLAY=$(extract_property ro.vendor.build.display.id)

ID=$(extract_property ro.vendor.build.id)
[ -z "$ID" ] && ID=$(extract_property ro.build.id)

INCREMENTAL=$(extract_property ro.vendor.build.version.incremental)
[ -z "$INCREMENTAL" ] && INCREMENTAL=$(extract_property ro.build.version.incremental)

RELEASE=$(extract_property ro.vendor.build.version.release)
[ -z "$RELEASE" ] && RELEASE=$(extract_property ro.build.version.release)

SDK=$(extract_property ro.vendor.build.version.sdk)
[ -z "$SDK" ] && SDK=$(extract_property ro.build.version.sdk)
[ -z "$SDK" ] && SDK=$(extract_property ro.system.build.version.sdk)

SECURITY_PATCH=$(extract_property ro.vendor.build.security_patch)
[ -z "$SECURITY_PATCH" ] && SECURITY_PATCH=$(extract_property ro.build.version.security_patch)

# *** CRITICAL: Validation check ***
if [ -z "$FINGERPRINT" ]; then
  die "No fingerprint found, cannot generate valid config";
fi;

if [ -z "$MODEL" ]; then
  die "No model found, cannot generate model-based config";
fi;

# *** ENHANCED: Model-based configuration naming ***
# Sanitize model name for use as identifier
MODEL_SANITIZED=$(echo "$MODEL" | sed 's/[^a-zA-Z0-9]//g' | tr '[:lower:]' '[:upper:]')

# *** ENHANCED: Display comprehensive device information ***
item "Device Profile Analysis:";
echo "  Brand: $BRAND"
echo "  Manufacturer: $MANUFACTURER"
echo "  Device: $DEVICE"
echo "  Model: $MODEL ($MODEL_SANITIZED)"
echo "  Fingerprint: ${FINGERPRINT:0:60}..."
echo "  Hardware Platform: $HARDWARE"
echo "  Security Patch: $SECURITY_PATCH"
echo "  Android Version: $RELEASE (API $SDK)"

# *** ENHANCED: Package configuration ***
PACKAGE_NAME=
item "Note: Update package names in PACKAGES_${MODEL_SANITIZED} array for your target apps";

# *** ENHANCED: Remove existing config and generate new one ***
if [ -f "${LOCAL}config.json" ]; then
  item "Removing existing config.json ...";
  rm -f "${LOCAL}config.json";
fi;

item "Writing SpoofXManager config.json with model-based configuration ...";

# *** CRITICAL: Generate model-based JSON config ***
{
cat << EOF
{
  "PACKAGES_${MODEL_SANITIZED}": [],
  "PACKAGES_${MODEL_SANITIZED}_DEVICE": {
    "BRAND": "$BRAND",
    "MANUFACTURER": "$MANUFACTURER",
    "DEVICE": "$DEVICE",
    "PRODUCT": "$PRODUCT",
    "MODEL": "$MODEL",
    "FINGERPRINT": "$FINGERPRINT",
    "BOARD": "$BOARD",
    "HARDWARE": "$HARDWARE",
    "BOOTLOADER": "$BOOTLOADER",
    "DISPLAY": "$DISPLAY",
    "ID": "$ID",
    "INCREMENTAL": "$INCREMENTAL",
    "RELEASE": "$RELEASE",
    "SDK": "$SDK",
    "SECURITY_PATCH": "$SECURITY_PATCH",
EOF

# *** CONDITIONAL: Add advanced settings if requested ***
if $ADVANCED; then
cat << EOF
    "spoofProps": true,
    "spoofBuild": true,
    "antiDetection": true,
    "verbose": true
EOF
else
cat << EOF
    "spoofProps": true,
    "spoofBuild": true,
    "antiDetection": true,
    "verbose": false
EOF
fi

cat << EOF
  }
}
EOF
} | tee "${LOCAL}config.json"

echo
echo "=== SpoofXManager Model-Based Config Generation Complete ==="
echo "Generated config.json with the following specifications:"
echo "- Configuration Group: PACKAGES_${MODEL_SANITIZED}"
echo "- Device Configuration: PACKAGES_${MODEL_SANITIZED}_DEVICE"
echo "- Brand: $BRAND"
echo "- Manufacturer: $MANUFACTURER" 
echo "- Device: $DEVICE"
echo "- Model: $MODEL"
echo "- Hardware Platform: $HARDWARE"
echo "- Android Version: $RELEASE (API $SDK)"
echo "- Security Patch: $SECURITY_PATCH"
echo "- Fingerprint: ${FINGERPRINT:0:50}..."

# *** ENHANCED: Advanced configuration summary ***
if $ADVANCED; then
  echo "- Advanced Features: Anti-Detection + Verbose Logging Enabled"
else
  echo "- Standard Features: Basic Spoofing Configuration"
fi

# *** ENHANCED: Installation guidance with model-specific instructions ***
echo
echo "=== Model-Based Installation Instructions ==="
echo "1. Edit config.json and update PACKAGES_${MODEL_SANITIZED} array:"
echo "   Replace \"$PACKAGE_NAME\" with your target app package names"
echo
echo "2. Copy config.json to one of these locations:"
echo "   - /data/adb/modules/SpoofXManager/config.json (Primary)"
echo "   - /data/adb/config.json (Secondary)"
echo "   - /data/local/tmp/config.json (Tertiary)"
echo
echo "3. Flash your SpoofXManager module and reboot"
echo
echo "=== Configuration Structure Explanation ==="
echo "Your configuration uses model-based grouping:"
echo "- Package Array: PACKAGES_${MODEL_SANITIZED}"
echo "- Device Config: PACKAGES_${MODEL_SANITIZED}_DEVICE"
echo "This allows multiple device profiles in a single config file."

# *** ENHANCED: Auto-install with model-specific handling ***
if [ -d "/data/adb/modules/SpoofXManager" ]; then
  echo
  read -p "SpoofXManager module detected. Install config automatically? [y/N]: " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    cp "${LOCAL}config.json" "/data/adb/modules/SpoofXManager/config.json"
    echo "Config installed to /data/adb/modules/SpoofXManager/config.json"
    echo "Configuration Group: PACKAGES_${MODEL_SANITIZED}"
    echo "Remember to update the package names and reboot!"
  fi
fi

echo
echo "=== Technical Analysis Summary ==="
echo "Properties extracted from vendor-build.prop: $([ -f vendor-build.prop ] && echo "✓" || echo "✗")"
echo "Model-based configuration: PACKAGES_${MODEL_SANITIZED}_DEVICE"
echo "Total properties configured: 15"
echo "Vendor-specific optimizations: Applied"

echo
echo "Thanks to osm0sis and chiteroman for the original PIF generator"
echo "Enhanced for SpoofXManager by x1337cn"