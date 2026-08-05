#!/data/data/com.termux/files/usr/bin/bash

set -Eeuo pipefail

readonly SCRIPT_NAME="$(basename "$0")"

fail() {
    printf '%s: %s\n' "$SCRIPT_NAME" "$1" >&2
    exit "${2:-1}"
}

command -v git >/dev/null 2>&1 \
    || fail "Git is not installed. Run: pkg install git" 127

REPOSITORY_ROOT="$(
    git rev-parse --show-toplevel 2>/dev/null
)" || fail "Run this script from inside the Registry Studio repository."
readonly REPOSITORY_ROOT

cd "$REPOSITORY_ROOT"

command -v flutter >/dev/null 2>&1 \
    || fail "Flutter is not available in PATH." 127

command -v dart >/dev/null 2>&1 \
    || fail "Dart is not available in PATH." 127

TERMUX_OVERRIDE_CREATED=false
LOCK_BACKUP_PATH=''
NEEDS_PATH_PROVIDER_FOUNDATION_OVERRIDE=false
NEEDS_OBJECTIVE_C_OVERRIDE=false
GRADLE_PROPERTIES_BACKUP_PATH=''
GRADLE_PROPERTIES_EXISTED=false

cleanup_temporary_overrides() {
    local exit_code=$?

    trap - EXIT INT TERM

    if [[ "$TERMUX_OVERRIDE_CREATED" == true ]]; then
        rm -f -- "$REPOSITORY_ROOT/pubspec_overrides.yaml"
    fi

    if [[ -n "$LOCK_BACKUP_PATH" && -f "$LOCK_BACKUP_PATH" ]]; then
        cp -f -- "$LOCK_BACKUP_PATH" "$REPOSITORY_ROOT/pubspec.lock"
        rm -f -- "$LOCK_BACKUP_PATH"
    fi

    if [[ -n "$GRADLE_PROPERTIES_BACKUP_PATH" \
        && -f "$GRADLE_PROPERTIES_BACKUP_PATH" ]]; then
        if [[ "$GRADLE_PROPERTIES_EXISTED" == true ]]; then
            cp -f -- \
                "$GRADLE_PROPERTIES_BACKUP_PATH" \
                "$REPOSITORY_ROOT/android/gradle.properties"
        else
            rm -f -- "$REPOSITORY_ROOT/android/gradle.properties"
        fi
        rm -f -- "$GRADLE_PROPERTIES_BACKUP_PATH"
    fi

    exit "$exit_code"
}

trap cleanup_temporary_overrides EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

is_termux_android_host() {
    [[ "${PREFIX:-}" == '/data/data/com.termux/files/usr' ]] \
        || [[ "$(uname -o 2>/dev/null || true)" == 'Android' ]]
}

prepare_termux_dependency_override_if_required() {
    local dependency_tree
    dependency_tree="$(flutter pub deps --style=compact)"

    if grep -Eq '(^|[[:space:]])path_provider_foundation([[:space:]]|$)' \
        <<< "$dependency_tree"; then
        NEEDS_PATH_PROVIDER_FOUNDATION_OVERRIDE=true
    fi

    if grep -Eq '(^|[[:space:]])objective_c([[:space:]]|$)' \
        <<< "$dependency_tree"; then
        NEEDS_OBJECTIVE_C_OVERRIDE=true
    fi

    if [[ "$NEEDS_PATH_PROVIDER_FOUNDATION_OVERRIDE" != true \
        && "$NEEDS_OBJECTIVE_C_OVERRIDE" != true ]]; then
        return
    fi

    local override_path="$REPOSITORY_ROOT/pubspec_overrides.yaml"

    if [[ -e "$override_path" ]]; then
        fail \
            "Refusing to overwrite existing pubspec_overrides.yaml. Move it aside and rerun." \
            4
    fi

    LOCK_BACKUP_PATH="$(
        mktemp "${TMPDIR:-$PREFIX/tmp}/registry-studio-pubspec-lock.XXXXXX"
    )"
    cp -f -- "$REPOSITORY_ROOT/pubspec.lock" "$LOCK_BACKUP_PATH"

    {
        printf '%s\n' '# Local Termux-only workaround.'
        printf '%s\n' 'dependency_overrides:'

        if [[ "$NEEDS_PATH_PROVIDER_FOUNDATION_OVERRIDE" == true ]]; then
            printf '%s\n' '  path_provider_foundation: 2.5.1'
        fi

        if [[ "$NEEDS_OBJECTIVE_C_OVERRIDE" == true ]]; then
            printf '%s\n' '  objective_c: 9.1.0'
        fi
    } > "$override_path"

    TERMUX_OVERRIDE_CREATED=true

    printf '\nApplied temporary Termux dependency override.\n'
    flutter pub get

    dependency_tree="$(flutter pub deps --style=compact)"

    if [[ "$NEEDS_PATH_PROVIDER_FOUNDATION_OVERRIDE" == true ]]; then
        grep -Eq '(^|[[:space:]])path_provider_foundation[[:space:]]+2\.5\.1([[:space:]]|$)' \
            <<< "$dependency_tree" \
            || fail "Termux override did not resolve path_provider_foundation 2.5.1." 5
    fi

    if [[ "$NEEDS_OBJECTIVE_C_OVERRIDE" == true ]]; then
        grep -Eq '(^|[[:space:]])objective_c[[:space:]]+9\.1\.0([[:space:]]|$)' \
            <<< "$dependency_tree" \
            || fail "Termux override did not resolve objective_c 9.1.0." 6
    fi
}

prepare_termux_android_build_override() {
    local aapt2_path
    aapt2_path="$(command -v aapt2 2>/dev/null || true)"

    [[ -n "$aapt2_path" && -x "$aapt2_path" ]] \
        || fail "ARM64 aapt2 is not installed. Run: pkg install aapt2" 7

    local gradle_properties="$REPOSITORY_ROOT/android/gradle.properties"
    GRADLE_PROPERTIES_BACKUP_PATH="$(
        mktemp "${TMPDIR:-$PREFIX/tmp}/registry-studio-gradle-properties.XXXXXX"
    )"

    if [[ -f "$gradle_properties" ]]; then
        cp -f -- "$gradle_properties" "$GRADLE_PROPERTIES_BACKUP_PATH"
        GRADLE_PROPERTIES_EXISTED=true
    else
        : > "$GRADLE_PROPERTIES_BACKUP_PATH"
    fi

    {
        printf '\n%s\n' '# Temporary Termux Android build overrides.'
        printf '%s\n' 'android.builtInKotlin=false'
        printf '%s\n' 'android.newDsl=false'
        printf 'android.aapt2FromMavenOverride=%s\n' "$aapt2_path"
    } >> "$gradle_properties"

    printf '\nApplied temporary Termux ARM64 AAPT2 override: %s\n' "$aapt2_path"
}

printf 'Repository: %s\n' "$REPOSITORY_ROOT"
printf 'Flutter:\n'
flutter --version

printf '\nResolving dependencies...\n'
flutter pub get

if is_termux_android_host; then
    prepare_termux_dependency_override_if_required
    prepare_termux_android_build_override
fi

printf '\nFormatting Translator integration sources and tests...\n'
dart format \
    lib/app/bootstrap/registry_studio_application.dart \
    lib/app/localization \
    lib/app/shell/registry_studio_shell.dart \
    lib/features/translator \
    test/app/localization \
    test/app/shell/registry_studio_shell_test.dart \
    test/features/translator

printf '\nRunning static analysis...\n'
flutter analyze

printf '\nRunning unit and widget tests...\n'
flutter test --concurrency=1

printf '\nBuilding Android debug APK...\n'
flutter build apk --debug

readonly APK_PATH="$REPOSITORY_ROOT/build/app/outputs/flutter-apk/app-debug.apk"

[[ -f "$APK_PATH" ]] \
    || fail "Flutter reported success, but the APK was not found: $APK_PATH" 3

printf '\nVerification completed successfully.\n'
printf 'APK: %s\n' "$APK_PATH"
sha256sum "$APK_PATH"
