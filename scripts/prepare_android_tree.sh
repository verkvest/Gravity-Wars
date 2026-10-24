#!/usr/bin/env bash
# Point a love-android 11.5a checkout at Cindarc: game.love, id, icons, targetSdk 36.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TREE=${1:?love-android checkout}
LOVE_FILE=${2:?game.love}
VERSION_CODE=${3:-1}

mkdir -p "$TREE/app/src/embed/assets"
cp "$LOVE_FILE" "$TREE/app/src/embed/assets/game.love"

RES="$TREE/app/src/main/res"
for density in ldpi mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  src="$ROOT/mobile/icons/android/drawable-$density/love.png"
  dest="$RES/drawable-$density"
  mkdir -p "$dest"
  cp "$src" "$dest/love.png"
done

python3 - "$TREE" "$VERSION_CODE" <<'PY'
import pathlib, sys
tree = pathlib.Path(sys.argv[1])
version_code = sys.argv[2]
for gradle in (tree / "app" / "build.gradle", tree / "love" / "build.gradle"):
    text = gradle.read_text()
    text = text.replace("compileSdk 34", "compileSdk 36")
    text = text.replace("targetSdk 34", "targetSdk 36")
    text = text.replace(
        'arguments "-j" + Runtime.runtime.availableProcessors()',
        'arguments "-j2"',
    )
    gradle.write_text(text)
    if "targetSdk 36" not in gradle.read_text():
        sys.exit(f"failed to set targetSdk 36 in {gradle}")

props = tree / "gradle.properties"
lines = []
for line in props.read_text().splitlines():
    if line.startswith("app.name") or line.startswith("app.application_id") or line.startswith("app.orientation") or line.startswith("app.version_"):
        continue
    lines.append(line)
header = "\n".join([
    "app.name=Cindarc",
    "app.application_id=es.verkvest.cindarc",
    "app.orientation=landscape",
    f"app.version_code={version_code}",
    "app.version_name=0.1.0",
    "org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=512m -Dfile.encoding=UTF-8",
    "org.gradle.parallel=false",
])
props.write_text(header + "\n" + "\n".join(lines) + "\n")

mk = tree / "love" / "src" / "jni" / "Application.mk"
text = mk.read_text()
text = text.replace("APP_ABI := armeabi-v7a", "APP_ABI := armeabi-v7a arm64-v8a")
if "max-page-size" not in text:
    text = text.replace(
        "APP_LDFLAGS := -llog -landroid -lz -fuse-ld=lld",
        "APP_LDFLAGS := -llog -landroid -lz -fuse-ld=lld -Wl,-z,max-page-size=16384",
    )
mk.write_text(text)

app_gradle = tree / "app" / "build.gradle"
extra = """
android {
    androidResources {
        noCompress += ["love"]
    }
    signingConfigs {
        cindarcRelease {
            def store = System.getenv("CINDARC_KEYSTORE")
            if (store != null && store.length() > 0) {
                storeFile file(store)
                storePassword System.getenv("CINDARC_KEYSTORE_PASSWORD")
                keyAlias System.getenv("CINDARC_KEY_ALIAS")
                keyPassword System.getenv("CINDARC_KEY_PASSWORD")
            }
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.cindarcRelease
        }
    }
}
"""
if "cindarcRelease" not in app_gradle.read_text():
    app_gradle.write_text(app_gradle.read_text() + extra)
print("android tree prepared")
PY
