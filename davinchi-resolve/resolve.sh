#!/usr/bin/env bash
set -euo pipefail

# DaVinci Resolve installer for Fedora Silverblue
#
# Installs the latest FREE DaVinci Resolve into davincibox/Toolbox.
#
# Host remains clean:
#   - no rpm-ostree packages
#   - no RPM Fusion
#   - no Mesa overrides
#
# Blackmagic requires registration before providing a download URL.
# Registration data is stored ONLY locally:
#   ~/.config/davinci-installer/config
#
# Container:
#   ghcr.io/zelikos/davincibox-opencl:latest
#
# Intended for AMD/Intel GPUs.

CONTAINER="davincibox"
IMAGE="ghcr.io/zelikos/davincibox-opencl:latest"

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/davinci-installer"
CONFIG_FILE="$CONFIG_DIR/config"

WORK_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/davinci-installer"

API_BASE="https://www.blackmagicdesign.com/api"

# Generic DaVinci Resolve download-page identifier.
REFER_ID="77ef91f67a9e411bbbe299e595b4cfcc"

USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"

log() {
    printf '\n==> %s\n' "$*"
}

die() {
    printf '\nERROR: %s\n' "$*" >&2
    exit 1
}

for cmd in curl python3 toolbox podman unzip; do
    command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done

mkdir -p "$CONFIG_DIR" "$WORK_DIR"

# --------------------------------------------------------------------
# Blackmagic registration
# --------------------------------------------------------------------

create_config() {
    echo
    echo "Blackmagic requires registration data to download DaVinci Resolve."
    echo "These values will be stored only in:"
    echo "  $CONFIG_FILE"
    echo

    read -rp "First name: " FIRSTNAME
    read -rp "Last name: " LASTNAME
    read -rp "Email: " EMAIL
    read -rp "Phone: " PHONE
    read -rp "Country code (example: us, de, fr): " COUNTRY
    read -rp "State/region: " STATE
    read -rp "City: " CITY
    read -rp "Street address: " STREET

    [[ -n "$FIRSTNAME" ]] || die "First name is required"
    [[ -n "$LASTNAME"  ]] || die "Last name is required"
    [[ -n "$EMAIL"     ]] || die "Email is required"
    [[ -n "$STREET"    ]] || die "Street address is required"

    {
        printf 'firstname=%s\n' "$FIRSTNAME"
        printf 'lastname=%s\n' "$LASTNAME"
        printf 'email=%s\n' "$EMAIL"
        printf 'phone=%s\n' "$PHONE"
        printf 'country=%s\n' "$COUNTRY"
        printf 'state=%s\n' "$STATE"
        printf 'city=%s\n' "$CITY"
        printf 'street=%s\n' "$STREET"
    } > "$CONFIG_FILE"

    chmod 600 "$CONFIG_FILE"
}

[[ -f "$CONFIG_FILE" ]] || create_config

cfg() {
    grep "^$1=" "$CONFIG_FILE" | cut -d= -f2-
}

FIRSTNAME="$(cfg firstname)"
LASTNAME="$(cfg lastname)"
EMAIL="$(cfg email)"
PHONE="$(cfg phone)"
COUNTRY="$(cfg country)"
STATE="$(cfg state)"
CITY="$(cfg city)"
STREET="$(cfg street)"

# Build registration JSON safely using Python.
REG_JSON="$(
    FIRSTNAME="$FIRSTNAME" \
    LASTNAME="$LASTNAME" \
    EMAIL="$EMAIL" \
    PHONE="$PHONE" \
    COUNTRY="$COUNTRY" \
    STATE="$STATE" \
    CITY="$CITY" \
    STREET="$STREET" \
    python3 - <<'PY'
import json
import os

print(json.dumps({
    "firstname": os.environ["FIRSTNAME"],
    "lastname": os.environ["LASTNAME"],
    "email": os.environ["EMAIL"],
    "phone": os.environ["PHONE"],
    "country": os.environ["COUNTRY"],
    "state": os.environ["STATE"],
    "city": os.environ["CITY"],
    "street": os.environ["STREET"],
    "product": "DaVinci Resolve",
}))
PY
)"

# --------------------------------------------------------------------
# Find latest stable FREE Resolve for Linux
# --------------------------------------------------------------------

log "Checking latest DaVinci Resolve version..."

LATEST_JSON="$(
    curl -fsSL \
        "${API_BASE}/support/latest-stable-version/davinci-resolve/linux"
)"

read -r VERSION DOWNLOAD_ID < <(
    LATEST_JSON="$LATEST_JSON" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["LATEST_JSON"])
linux = data["linux"]

major = linux["major"]
minor = linux["minor"]
release = linux.get("releaseNum", 0)

if release:
    version = f"{major}.{minor}.{release}"
else:
    version = f"{major}.{minor}"

print(version, linux["downloadId"])
PY
)

[[ -n "$VERSION" ]] || die "Could not determine Resolve version"
[[ -n "$DOWNLOAD_ID" ]] || die "Could not determine Blackmagic download ID"

echo "Latest version: $VERSION"

ZIP="$WORK_DIR/DaVinci_Resolve_${VERSION}_Linux.zip"
RUN="$WORK_DIR/DaVinci_Resolve_${VERSION}_Linux.run"
EXTRACT_DIR="$WORK_DIR/squashfs-root"

# --------------------------------------------------------------------
# Download
# --------------------------------------------------------------------

if [[ ! -f "$ZIP" ]]; then
    log "Requesting download URL from Blackmagic..."

    DOWNLOAD_URL="$(
        curl -fsSL -X POST \
            "${API_BASE}/register/us/download/${DOWNLOAD_ID}" \
            -H "Accept: application/json, text/plain, */*" \
            -H "Origin: https://www.blackmagicdesign.com" \
            -H "User-Agent: ${USER_AGENT}" \
            -H "Content-Type: application/json;charset=UTF-8" \
            -H "Referer: https://www.blackmagicdesign.com/support/download/${REFER_ID}/Linux" \
            --data "$REG_JSON"
    )"

    [[ "$DOWNLOAD_URL" == http* ]] || {
        echo "$DOWNLOAD_URL"
        die "Blackmagic did not return a valid download URL"
    }

    log "Downloading DaVinci Resolve $VERSION..."

    curl -fL \
        --retry 3 \
        --retry-delay 3 \
        --progress-bar \
        -H "User-Agent: ${USER_AGENT}" \
        -o "$ZIP.part" \
        "$DOWNLOAD_URL"

    mv "$ZIP.part" "$ZIP"
else
    log "Using already downloaded archive:"
    echo "$ZIP"
fi

# --------------------------------------------------------------------
# Verify ZIP before extracting
# --------------------------------------------------------------------

log "Checking ZIP integrity..."

unzip -t "$ZIP" >/dev/null ||
    die "Downloaded ZIP is corrupted"

rm -f "$RUN"
rm -rf "$EXTRACT_DIR"

log "Extracting installer..."

unzip -j "$ZIP" "DaVinci_Resolve_${VERSION}_Linux.run" -d "$WORK_DIR"

[[ -f "$RUN" ]] ||
    die "DaVinci .run installer was not extracted"

# Verify that unzip actually wrote the complete file.
EXPECTED_SIZE="$(
    unzip -l "$ZIP" |
    awk '/DaVinci_Resolve_.*_Linux\.run$/ {print $1}'
)"

ACTUAL_SIZE="$(stat -c '%s' "$RUN")"

if [[ "$EXPECTED_SIZE" != "$ACTUAL_SIZE" ]]; then
    die "Extracted .run is incomplete: expected $EXPECTED_SIZE bytes, got $ACTUAL_SIZE bytes"
fi

chmod +x "$RUN"

# --------------------------------------------------------------------
# Create / update davincibox
# --------------------------------------------------------------------

if ! toolbox list --containers 2>/dev/null |
    grep -qE "(^|[[:space:]])${CONTAINER}([[:space:]]|$)"; then

    log "Creating Davincibox..."

    toolbox create \
        -i "$IMAGE" \
        -c "$CONTAINER"
else
    log "Davincibox already exists"
fi

log "Updating Davincibox packages..."

toolbox run -c "$CONTAINER" \
    sudo dnf update -y

# --------------------------------------------------------------------
# Extract Blackmagic AppImage
# --------------------------------------------------------------------

log "Extracting DaVinci installer..."

cd "$WORK_DIR"

"$RUN" --appimage-extract

[[ -x "$EXTRACT_DIR/AppRun" ]] ||
    die "AppImage extraction failed"

# --------------------------------------------------------------------
# Install Resolve
# --------------------------------------------------------------------

log "Installing DaVinci Resolve $VERSION..."

toolbox run --container "$CONTAINER" \
    setup-davinci "$EXTRACT_DIR/AppRun" toolbox

# --------------------------------------------------------------------
# Cleanup
# --------------------------------------------------------------------

rm -rf "$EXTRACT_DIR"
rm -f "$RUN"

echo
echo "============================================================"
echo " DaVinci Resolve $VERSION installation completed"
echo "============================================================"
echo
echo "Container:"
echo "  $CONTAINER"
echo
echo "Run:"
echo "  toolbox run -c $CONTAINER run-davinci"
echo
echo "Downloaded ZIP was kept in:"
echo "  $ZIP"
echo
echo "You can delete it after verifying Resolve works."
