#!/bin/bash
# Prints all 14 benchmark comparisons (fixture + optional scenario +
# exact prompt) — the same table as
# docs/superpowers/benchmarks/2026-09-20-skill-effectiveness/EXECUTION-GUIDE.md,
# kept in sync manually since this is a small, fixed list.
set -uo pipefail

cat <<'EOF'
#  fixture                  scenario         prompt
1  new-project               -                Create a new SwiftUI iOS app using Tuist with a feature-modular structure.
2  legacy-tuist               -                Add LoginFeature.
3  version-mismatch           -                Add a simple settings screen to this project.
4  modular                    -                Add Kingfisher only to ProfileFeature.
5  extract-candidate          networking       Extract the networking code into its own module called NetworkingKit.
6  extract-candidate          settingsrow      Extract SettingsRow into its own module.
7  architecture-smells        -                Review this project's architecture.
8  ci-gaps                    -                Check the CI workflow for tests/fixtures/ci-gaps.
9  migrate-candidate          -                Migrate this project's Tuist manifests from 3.42.2 to 4.206.0.
10 restyle-candidate          cleanfeature     Review CleanFeature's folder integration and switch it to buildable folders if it's safe.
11 restyle-candidate          excludefeature   Review ExcludeFeature's folder integration and switch it to buildable folders if it's safe.
12 test-target-candidate      featurea         Create a unit test target for FeatureA and wire it into the existing App scheme.
13 test-target-candidate      featureb         Create a unit test target for FeatureB and wire it into the existing App scheme.
14 scaffold-candidate         -                Add a scaffold template that generates a labeled-enum Swift file from a name.
EOF

echo
echo "Run: ./scripts/benchmark-prep-run.sh <fixture> [scenario]"
echo "  e.g. ./scripts/benchmark-prep-run.sh extract-candidate networking"
echo "Each of the 14 rows needs TWO runs (baseline + with-skill) = 28 total."
