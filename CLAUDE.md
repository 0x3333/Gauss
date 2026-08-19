# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gauss is a native macOS menu bar calculator app (Swift 5.9, macOS 14.0+). It features multi-line expressions, variables, unit/currency conversion, color conversion, base64, date math, and syntax highlighting with autocomplete.

## Build & Run

The project uses **XCodeGen** to generate the Xcode project from `project.yml`.

```bash
# Generate Xcode project (required after modifying project.yml)
xcodegen generate

# Build
xcodebuild -scheme Gauss -configuration Debug build

# Run engine tests (the main test suite)
cd GaussEngine && swift test

# Run app-level tests
xcodebuild -scheme Gauss -configuration Debug test

# Release (see RELEASING.md for prerequisites)
./scripts/release.sh <version> <build_number>
```

## Architecture

The app has two main modules:

### GaussEngine (SPM library, `GaussEngine/`)
The calculation engine, independent of AppKit/UI. Pipeline: **input → Tokenizer → Matcher (parser) → Evaluator → Value**.

- `Core/Tokenizer.swift` — Lexes input into `Token` enum values
- `Core/Matcher.swift` — Parses tokens into `Expression` AST nodes
- `Core/Evaluator.swift` — Evaluates AST against a `Context` (variables, line results)
- `Core/Context.swift` — Holds variables and per-line results for cross-line references
- `Core/CompletionProvider.swift` — Autocomplete suggestions
- `Types/Value.swift` — Result types: number, currency, date, color, percentage, etc.
- `Converters/` — Unit, currency (frankfurter.app API), color (hex/rgb/hsl), base64, timestamp
- `Resources/definitions/` — JSON data files for units, currencies, functions, operators, prefixes, scales
- `Formatting/ValueFormatter.swift` — Formats `Value` for display

Public API is `GaussEngine.swift`: `evaluateLine(_:lineIndex:)` and `evaluateDocument(_:)`.

### Gauss App (`Gauss/`)
macOS app with AppKit + SwiftUI hybrid UI.

- `App/AppDelegate.swift` — Lifecycle, window management
- `App/MenuBarController.swift` — Menu bar status item
- `Views/CalculatorWindow.swift` — Main floating calculator window
- `Views/CalcTextView.swift` — NSTextView subclass with syntax highlighting and ghost-text autocomplete
- `Views/ResultView.swift` — Per-line result display alongside the editor
- `Controllers/Settings.swift` — UserDefaults-backed preferences
- `Controllers/CurrencyUpdater.swift` — Periodic FX rate refresh
- `Controllers/SyntaxHighlighter.swift` — Token-based syntax coloring

### Dependencies (SPM, declared in `project.yml`)
- **KeyboardShortcuts** — Global hotkey (Ctrl+Space)
- **Sparkle** — Auto-update framework with EdDSA signing
- **GaussEngine** — Local package

## Distribution

Gauss is **free and open source (MIT)**. There is no licensing, trial, or
payment code. Releases are built, signed (Developer ID), notarized, and
published by GitHub Actions on tag push (`.github/workflows/build-release.yml`).
Binaries are hosted on GitHub Releases; the Sparkle appcast is served from the
`gh-pages` branch via GitHub Pages. See `RELEASING.md`.

## Key Patterns

- Localizations: English (`en`) and Simplified Chinese (`zh-Hans`)
- Variable names are case-insensitive (`Price` = `price`)
- The engine evaluates documents line-by-line; lines can reference previous line results (`@1` is 1-based), `prev`, and variables
- Percentage operations support "of", "on", "off" modifiers (e.g., "tax on price")
- `sum` aggregates numeric results; percentage values are excluded from sum
- Results use `Value` enum — always check which case before formatting/comparing
- The app uses hardened runtime (no sandbox) with Developer ID signing
