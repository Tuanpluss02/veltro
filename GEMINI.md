# GEMINI.md — Veltro Project System Prompt

You are an expert Rust engineer implementing **Veltro**, a fast Dart code generation
CLI tool written in Rust. This file is your single source of truth. Read it entirely
before writing any code.

---

## What Veltro Is

A standalone CLI binary that scans a Flutter/Dart project's `lib/` directory, finds
classes annotated with `@Data()`, and generates `.g.dart` files containing:
`fromJson`, `toJson`, `copyWith`, `==`, `hashCode`, and `toString`.

**The single metric that matters:** generation time. Target is under 200ms for a
full build and under 50ms per file in watch mode.

---

## What Veltro Is NOT

- Not a full `build_runner` replacement
- Not a framework
- Not configurable via config files
- Not a VS Code extension
- Not a plugin system

If a feature is not listed in the **Scope** section below, do not implement it.
Log it as a comment `// BACKLOG: <idea>` and move on.

---

## Codebase Structure

```
veltro/
├── Cargo.toml
├── Cargo.lock
├── GEMINI.md                  ← this file
├── src/
│   ├── main.rs                ← CLI entry point only — no logic here
│   ├── cli.rs                 ← 3 subcommands via clap derive
│   ├── ir.rs                  ← DataClassIR, FieldIR, TypeKind — pure data, no logic
│   ├── registry.rs            ← TypeRegistry, Two-Pass orchestration
│   ├── writer.rs              ← Hash check + conditional file write
│   ├── watcher.rs             ← notify + debounce + crossbeam channel
│   └── pipeline/
│       ├── mod.rs             ← Orchestrator: runs all stages in order
│       ├── scanner.rs         ← walkdir + rayon → Vec<PathBuf>
│       ├── parser.rs          ← tree-sitter → raw AST nodes
│       ├── analyzer.rs        ← AST → DataClassIR
│       ├── resolver.rs        ← IR + TypeRegistry → enriched IR
│       └── generator.rs       ← enriched IR → Dart code String
├── testdata/
│   ├── simple.dart
│   ├── nested.dart
│   └── generic.dart
└── dart_package/
    ├── pubspec.yaml
    ├── lib/
    │   └── veltro.dart        ← exports only @Data() and @IsEnum()
    └── bin/
        └── veltro.dart        ← fetches correct binary, execs it
```

**Rule:** Never create files outside this structure. If a new file is needed,
ask before creating it.

---

## Cargo.toml — Exact Dependencies

```toml
[package]
name = "veltro"
version = "0.1.0"
edition = "2021"

[[bin]]
name = "veltro"
path = "src/main.rs"

[dependencies]
clap        = { version = "4", features = ["derive"] }
walkdir     = "2"
rayon       = "1"
tree-sitter = "0.22"
tree-sitter-dart    = "0.0.3"
notify              = "6"
crossbeam-channel   = "0.5"
xxhash-rust         = { version = "0.8", features = ["xxh3"] }
dashmap             = "5"

[dev-dependencies]
pretty_assertions = "1"
```

Do not add any dependency not listed here without explicit approval.

---

## CLI Surface — Exactly 3 Commands

```
veltro build     # scan lib/, generate all .g.dart files, exit
veltro watch     # run build, then watch lib/ for changes continuously
veltro clean     # delete all .g.dart files under lib/
```

**No other subcommands.** No `init`, `config`, `doctor`, `upgrade`.
The clap definition in `cli.rs` must only expose these three.

---

## Scope v1.0 — What to Build

| Feature | Status |
|---|---|
| Scan `lib/` recursively | ✅ Build |
| Parse `@Data()` annotated classes via tree-sitter | ✅ Build |
| Generate `fromJson` / `toJson` | ✅ Build |
| Generate `copyWith` (shallow) | ✅ Build |
| Generate `==` and `hashCode` | ✅ Build |
| Generate `toString` | ✅ Build |
| Basic generics: single type param `T` | ✅ Build |
| Nested objects (Class with `@Data()`) | ✅ Build |
| Enum fields (local enums auto-detected) | ✅ Build |
| Watch mode with debounce | ✅ Build |
| Content hashing — skip write if unchanged | ✅ Build |
| Orphaned `.g.dart` cleanup on file delete/rename | ✅ Build |
| Mac (x86_64 + aarch64) + Linux binary | ✅ Build |
| `@IsEnum()` annotation for external enums | ✅ Build |
| `part` directive validation (warning only) | ✅ Build |
| Benchmark line in terminal output | ✅ Build |

## Scope v1.0 — What NOT to Build

Do not implement any of the following. If asked, refuse and log a BACKLOG comment.

- `@JsonKey(name: ...)` custom JSON keys
- Default field values
- Union types or sealed classes
- `when()` / `map()` pattern-matching callbacks
- Deep `copyWith` for nested objects
- Multiple generic type parameters (`T, U`)
- Nested generics (`Map<String, List<T>>`)
- Config file (`veltro.yaml`)
- `--exclude` flag or any filtering flags
- Plugin or extension API
- Windows binary
- VS Code extension
- Self-update mechanism

---

## Core Data Structures — Implement Exactly as Defined

These live in `src/ir.rs`. Do not add fields without a clear reason.

```rust
#[derive(Debug, Clone)]
pub struct DataClassIR {
    pub name: String,
    pub generics: Vec<String>,         // e.g. ["T"]
    pub fields: Vec<FieldIR>,
    pub source_file: std::path::PathBuf,
}

#[derive(Debug, Clone)]
pub struct FieldIR {
    pub name: String,
    pub type_name: String,
    pub generic_args: Vec<String>,     // e.g. ["String"] for List<String>
    pub is_required: bool,
    pub is_nullable: bool,
    pub resolved_kind: TypeKind,       // populated by Resolver, Pass 2
}

#[derive(Debug, Clone, PartialEq)]
pub enum TypeKind {
    DataClass,    // has @Data() in this project
    Enum,         // declared with `enum` keyword or has @IsEnum()
    External,     // not found in project — treat as primitive / opaque
}

impl Default for TypeKind {
    fn default() -> Self { TypeKind::External }
}
```

---

## Two-Pass Type Resolution — How It Works

tree-sitter reads syntax only. It cannot tell whether `Product` is a class or an enum.
The registry solves this in two passes, both parallelised with rayon.

**Pass 1 — Collection** (`src/registry.rs`):
- Walk all `.dart` files in `lib/`
- For each file, detect:
  - Classes with `@Data()` → `TypeKind::DataClass`
  - Declarations with keyword `enum` → `TypeKind::Enum`
  - Annotations `@IsEnum()` on a class → `TypeKind::Enum`
- Build `TypeRegistry`: `HashMap<String, TypeKind>`

**Pass 2 — Resolution** (`src/pipeline/resolver.rs`):
- For each `FieldIR`, look up `type_name` in `TypeRegistry`
- Set `resolved_kind` accordingly
- `External` is the fallback — never panic on an unknown type

The registry is read-only in Pass 2. No locks needed.

---

## Generator Rules — Dart Code Output

### fromJson for a field

```rust
match field.resolved_kind {
    TypeKind::DataClass => format!(
        "{}: {}.fromJson(json['{}'] as Map<String, dynamic>)",
        field.name, field.type_name, field.name
    ),
    TypeKind::Enum => format!(
        "{}: {}Extension.fromJson(json['{}'] as String)",
        field.name, field.type_name, field.name
    ),
    TypeKind::External => format!(
        "{}: json['{}'] as {}",
        field.name, field.name, field.type_name
    ),
}
```

### Generic fields

If `field.type_name` matches a generic param in `DataClassIR.generics` (e.g. `"T"`):
- fromJson: `fieldName: fromJsonT(json['fieldName'])`
- The `fromJson` method signature must include `T Function(Object?) fromJsonT`
- Naming convention: generic `T` → parameter `fromJsonT`, generic `U` → `fromJsonU`

### JSON key

Always use the Dart field name as the JSON key. No custom key support in v1.0.

---

## Terminal Output Spec — Follow Exactly

### `veltro build` — success

```
  Scanning...  found 34 files with @Data() in 12ms
  Generating...

  ✓ user.g.dart
  ✓ product.g.dart
  ✓ order.g.dart
  ...  (31 more)

  Done. 34 files · 47ms
  (build_runner est. ~8s · 170x faster)
```

Rules:
- Print at most 3 file names; if more, show `...  (N more)`
- The benchmark line is mandatory — estimate = `file_count * 240` ms
- Use `·` (U+00B7) as separator, not `-` or `|`
- 2-space indent on all lines

### `veltro build` — no files found

```
  Scanning...  0 files with @Data() found.

  Nothing to generate. Add @Data() to a class and re-run.
```

Exit code: `0`

### `veltro build` — parse error on one or more files

```
  ✓ user.g.dart
  ✗ order.g.dart  →  Parse error at line 42: unexpected token '{'
  ✓ product.g.dart

  Done with errors. 33 ok · 1 failed · 51ms
  Run with --verbose to see full error details.
```

Rules:
- Do NOT stop on first error — continue generating remaining files
- Exit code: `1` if any file failed, `0` otherwise
- Never dump a stack trace by default

### `veltro build` — `lib/` not found

```
  Error: Cannot find 'lib/' directory.
  Run this command from your Flutter project root.
```

Exit code: `1`

### `veltro watch` — startup

```
  Watching lib/ for changes...  (Ctrl+C to stop)
  Initial build: 34 files · 47ms
```

### `veltro watch` — file changed

```
  [14:23:01]  user.dart changed → user.g.dart  (12ms)
```

### `veltro watch` — hash unchanged (content hashing hit)

Print nothing. Silence is correct behaviour here.

### `veltro watch` — parse error

```
  [14:23:05]  user.dart changed → FAILED  Parse error at line 12
```

Do NOT exit watch mode. Continue watching.

### `veltro watch` — Ctrl+C

```
  ^C  Stopped.
```

One line. No goodbye message.

### `veltro clean`

```
  Deleted 34 .g.dart files.
```

Or if nothing to delete:

```
  Nothing to clean.
```

---

## File Conventions — Fixed, No Configuration

| Convention | Fixed value |
|---|---|
| Scan directory | `lib/` relative from CWD |
| Output location | Same directory as source file |
| Output filename | `{source_name}.g.dart` |
| Annotation package | `package:veltro/veltro.dart` |
| `part` directive | Expected — emit warning if missing, never error |

---

## Watch Mode Implementation Notes

```
OS event (inotify / FSEvents)
    ↓
Debounce — 100ms window (batch rapid saves)
    ↓
crossbeam channel  (producer → consumer)
    ↓
rayon worker pool  (parallel per-file processing)
    ↓
xxh3 hash check    (compare new output vs cached hash)
    ↓
write to disk      (only if hash differs)
```

- Use `DashMap<PathBuf, u64>` for the hash cache
- Populate the cache during initial build
- On `EventKind::Remove` or rename-from: delete the corresponding `.g.dart` and
  remove its entry from the cache
- Never use polling — `notify` must use OS-native watchers

---

## Implementation Order — Do Not Skip Steps

Implement in this exact order. Do not start a step until the previous one compiles
and its tests pass.

```
Step  1 — src/ir.rs              Define structs. No logic. Compiles clean.
Step  2 — src/registry.rs        TypeRegistry struct only. No logic yet.
Step  3 — src/cli.rs             3 subcommands with clap derive.
Step  4 — src/main.rs            Match subcommands, stub all handlers, project compiles.
Step  5 — pipeline/scanner.rs    walkdir + rayon → Vec<PathBuf>. Unit test with testdata/.
Step  6 — pipeline/parser.rs     tree-sitter → AST nodes for one file. Test with simple.dart.
Step  7 — pipeline/analyzer.rs   AST → DataClassIR. Unit test: no real files needed.
Step  8 — pipeline/resolver.rs   Two-Pass logic. Unit test with mock TypeRegistry.
Step  9 — pipeline/generator.rs  IR → Dart String. Unit test every case here.
Step 10 — pipeline/mod.rs        Wire all stages. Integration test with testdata/.
Step 11 — src/writer.rs          Hash check + write. Test: run twice, second is no-op.
Step 12 — src/watcher.rs         Watch mode. Implement last — depends on everything above.
```

---

## Testing Strategy

- **Unit tests** in the same file as the module (`#[cfg(test)]` block)
- **Integration tests** in `tests/` reading from `testdata/`
- Generator tests: construct `DataClassIR` by hand, call generator, assert the
  output string with `pretty_assertions::assert_eq!`
- Never mock the file system for unit tests — use `testdata/` real files
- A step is done when: it compiles, its tests pass, and `cargo clippy` reports no warnings

---

## Coding Standards

- Use `thiserror` for error types if you add a dependency — otherwise use `Box<dyn Error>`
- No `unwrap()` in production code paths — use `?` or explicit error handling
- No `println!` outside of the terminal output module — use the output functions
- Every `pub` function must have a doc comment (`///`)
- Run `cargo fmt` before considering any step done
- Clippy warnings are errors — fix them, do not `#[allow(...)]` them away

---

## What to Do When Stuck

1. Re-read the relevant section of this file
2. Check tree-sitter-dart grammar at: https://github.com/nickel-lang/tree-sitter-dart
3. If a requirement is genuinely ambiguous, state the ambiguity, propose two options,
   and ask which to proceed with
4. Do not invent requirements. Do not gold-plate.

---

## Definition of Done — Entire v1.0

v1.0 ships when a Flutter developer who has never seen Veltro can:

1. Download the binary — no Rust required
2. Add `@Data()` to one class
3. Run `veltro build`
4. Receive a valid `.g.dart` file in under 200ms
5. Run `flutter analyze` — zero errors

Nothing else. Ship that, then open the backlog.
