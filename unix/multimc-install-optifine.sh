#!/bin/bash

MOD_ID="optifine.OptiFine"

declare jarpath jarfile
declare jarversion_long mcver
declare lwjar err
declare multimc_jar multimc_json
declare fake_dotmc fakever
declare jarmodpath

assert_installed() {
    if ! command -v "${1:?Missing command name.}" &>/dev/null; then
        echo "Command \"$1\" not found, please install it."
        exit 1
    fi
}
realpath() { # Cannot use built-in realpath command for symlinks
    pushd "${1:?Missing base directory.}" &>/dev/null
    echo "$PWD/$2"
    popd &>/dev/null
}
launcher_profiles_json() {
    cat <<EOF
{
  "profiles": {
    "$mcver": {
      "name": "$mcver",
      "lastVersionId": "$mcver",
      "javaArgs": "",
      "useHopperCrashService": false,
      "launcherVisibilityOnGameClose": "hide launcher and re-open when game closes"
    }
  }
}
EOF
}
launchwrapper_json() {
    if ((lw_exists)); then
        cat <<EOF
            "MMC-filename": "$lwjar",
            "MMC-hint": "local",
            "name": "net.minecraft:launchwrapper:2"
EOF
    else
        cat <<EOF
            "name": "net.minecraft:launchwrapper:1.12"
EOF
    fi
}
optifine_json() {
    cat <<EOF
{
    "+tweakers": [ "optifine.OptiFineTweaker" ],
    "formatVersion": 1,
    "libraries": [
        {
$(launchwrapper_json)
        },
        {
            "MMC-filename": "$jarmodpath",
            "MMC-hint": "local",
            "name": "optifine:OptiFine:$jarversion_long"
        }
    ],
    "mainClass": "net.minecraft.launchwrapper.Launch",
    "name": "OptiFine",
    "requires": [ { "equals": "$mcver", "uid": "net.minecraft" } ],
    "uid": "$MOD_ID",
    "version": "$jarversion_long"
}
EOF
}


# Check basics
assert_installed unzip
assert_installed java
echo "CWD: $PWD"
if [[ ! -f instance.cfg ]] || [[ ! -d .minecraft ]] || [[ ! -f mmc-pack.json ]]; then
    echo "This folder does not appear to be a valid MultiMC instance..."
    exit 1
fi
echo "Valid MultiMC instance found."


# Get information from OptiFine JAR
jarpath="${1:?Please specify OptiFine JAR.}"
if ! [[ -f "$jarpath" ]]; then
    echo "Optifine JAR not found..."
    exit 1
fi
jarfile="$(basename "$jarpath")"
if ! [[ "$jarfile" =~ ^(preview_)?OptiFine_(([0-9]+\.[0-9]+\.[0-9]+)_.*)\.jar$ ]]; then
    echo "The specified file does not appear to be a valid OptiFine JAR..."
    echo "(if it is, please keep the original file name)"
    exit 1
fi
jarversion_long="${BASH_REMATCH[2]}"
mcver="${BASH_REMATCH[3]}"
echo "Minecraft version: $mcver"
echo "OptiFine version:  $jarversion_long"


# Check if MultiMC has the right Minecraft files
multimc_jar="$(realpath "../.." "libraries/com/mojang/minecraft/$mcver/minecraft-$mcver-client.jar" 2>/dev/null)"
multimc_json="$(realpath "../.." "meta/net.minecraft/$mcver.json" 2>/dev/null)"
if [[ ! -f "$multimc_jar" ]] || [[ ! -f "$multimc_json" ]]; then
    cat <<EOF
Seems like MultiMC does not have Minecraft $mcver files...
(have you launched it at least once?)

> $multimc_jar
> $multimc_json
EOF
    exit 1
fi
echo "Valid Minecraft files found."


# Simple operations
mkdir -p libraries patches
lwjar="$(unzip -Z -1 "$jarpath" | grep -E 'launchwrapper.*\.jar')"
echo "Custom launchwrapper found, extracting..."
if [[ "$lwjar" != "" ]]; then
    unzip "$jarpath" "$lwjar"
    lw_exists=1
    mv -f "$lwjar" libraries
fi
echo "Installation: 50%"


# Though operations (fake .minecraft installation based on MultiMC files)
fake_dotmc="$(mktemp -d '/tmp/minecraft.XXXXXX')"
launcher_profiles_json >"$fake_dotmc/launcher_profiles.json"
fakever="$fake_dotmc/versions/$mcver"
mkdir -p "$fakever"
ln -s "$multimc_jar" "$fakever/$mcver.jar"
ln -s "$multimc_json" "$fakever/$mcver.json"
cat <<EOF

--------------------
NOW, if you already have extracted the mod, press [Cancel]
OTHERWISE:
     1. Choose the folder "$fake_dotmc"
     2. [Extract] and select this MultiMC instance directory
     3. [OK]
     4. Wait the success message and close it

EOF
java -jar "$jarpath"
err=$?
cat <<EOF
--------------------

EOF
rm -rf "$fake_dotmc"
if ((err)); then
    echo "The installer just returned $err, cannot contine..."
    exit 1
fi
jarmodpath="$(find . -maxdepth 1 -name "OptiFine_$mcver*MOD*.jar" | head -n1)"
if [[ "$jarmodpath" == "" ]]; then
    echo "OptiFine extracted mod not found..."
    exit 1
fi
optifine_json >./patches/"$MOD_ID".json
mv "$jarmodpath" libraries
cat <<EOF
Installation: 100% DONE!

Now go to MultiMC window:
> Edit your instance
> Version
> Reload
> Launch
EOF
