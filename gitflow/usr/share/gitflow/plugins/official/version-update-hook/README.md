# Version Update Hook

A Git hook plugin for GitFlow that automatically manages semantic versioning based on branch types and Git operations.

## Features

* Automatic version bumping based on Git operations
* Branch-specific version tracking
* Support for manual version overrides
* Automatic version tagging
* Smart version conflict resolution during merges
* Support for major version increments

## Installation

```bash
# Install the hook in your repository
gitflow --install-hook version-update-hook
```

## Version Format

The version format follows: `vA.B.C.D` where:

* A: Major version (Manual increment via MAJOR: commit message)
* B: Main/Master branch version
* C: Feature branch number
* D: Build/Commit number

## How It Works

### Pre-commit Hook

The pre-commit hook handles:

1. Version calculation based on branch type
2. Major version increments
3. Manual version overrides
4. Branch version tracking
5. Merge conflict resolution

### Post-commit Hook

The post-commit hook handles:

1. Version tagging
2. Tag pushing to remote
3. Release tagging (when specified)

## Usage

### Regular Commits

Just commit normally. The version will update automatically based on your branch:

```bash
git commit -m "feat: add new feature"
# Version updates automatically
```

### Major Version Increment

To increment the major version:

```bash
git commit -m "MAJOR: breaking changes in API
Some description here"
```

### Manual Version Override

To set a specific version:

```bash
git commit -m "VERSION=v1.2.3.4
Some description here"
```

### Creating a Release

To create a release tag:

```bash
git commit -m "RELEASE:1.0
Release description here"
```

## Version Calculation Rules

1. **Main/Master Branch**
   * Increments D on regular commits
   * Increments B on merges
   * Maintains highest C and D from merged branches

2. **Feature Branches**
   * New branch: C = parent's C + 1, D = 0
   * Regular commits: Increment D
   * Rebase: Recalculates based on target branch

3. **During Merge to Main**
   * B is incremented
   * Highest C and D from branches are preserved

4. **During Rebase**
   * Versions are recalculated based on target branch
   * Branch version components are preserved

## File Structure

```
.git/
└── version-control/
    ├── .version        # Current version
    └── .branch_versions # Branch version mapping
```

## Error Handling

* Prevents multiple hook instances from running simultaneously
* Retries tag pushing up to 3 times
* Maintains version file integrity
* Handles missing remote configurations

## Logging

The hook provides clear status messages with:
* ✅ Success messages in green
* ❌ Error messages in red
* ℹ️ Info messages in blue
* ⚠️ Warning messages in yellow

## Development

To modify or extend this hook:

1. Hook files are located in the plugin directory:
   ```
   version-update-hook/
   ├── events/
   │   ├── pre-commit/
   │   │   └── script.sh
   │   └── post-commit/
   │       └── script.sh
   ├── lib/
   │   └── functions.sh
   └── metadata.json
   ```

2. Main functions are in `lib/functions.sh`
3. Event-specific code is in respective event directories

## Troubleshooting

1. **Version not updating**
   * Check if .git/version-control/ exists
   * Verify hook installation
   * Check write permissions

2. **Tag push failing**
   * Verify remote configuration
   * Check network connection
   * Verify Git credentials

3. **Multiple versions**
   * Remove duplicate version files
   * Reinitialize with `gitflow --install-hook version-update-hook`

## License

MIT License