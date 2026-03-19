# Veltro — Full Implementation Prompt

You are implementing Veltro from scratch. Your source of truth is GEMINI.md
in this repository. Read it fully before writing a single line of code.

---

## How to work

You will implement all 12 steps in order. The rules are non-negotiable:

- **Never start a step until the previous one compiles and its tests pass**
- **Run `cargo build`, `cargo test`, and `cargo clippy` after every step**
- **If clippy reports warnings, fix them before moving on — do not `#[allow(...)]`**
- **If any step fails, stop, report the error, and wait for instructions**
- **Do not invent features. Do not add anything not specified in GEMINI.md**

After completing each step, print a single checkpoint line before continuing:

```
✓ Step N done — cargo build ✓  cargo test ✓  cargo clippy ✓
```

Only then move to the next step.

---

## Step 0 — Bootstrap

Before any code:

1. Run `cargo new veltro --bin` if the project does not already exist
2. Replace the generated `Cargo.toml` with the exact content from the
   Dependencies section of GEMINI.md — do not add or remove any crate
3. Create the full directory and file structure from the Codebase Structure
   section of GEMINI.md — empty files are fine at this stage
4. Create the three `testdata/` files as empty `.dart` files for now
5. Run `cargo build` — it must compile before you write any logic

Checkpoint: `✓ Step 0 done — project structure created, cargo build ✓`

---

## Step 1 — src/ir.rs

Implement `DataClassIR`, `FieldIR`, and `TypeKind` exactly as defined in the
Core Data Structures section of GEMINI.md.

Rules:
- No methods, no logic — structs and enums only
- Every `pub` item must have a `///` doc comment
- Derive `Debug` and `Clone` on all structs
- Implement `Default` for `TypeKind` returning `TypeKind::External`

Checkpoint: `✓ Step 1 done — cargo build ✓  cargo clippy ✓`

---

## Step 2 — src/registry.rs

Implement `TypeRegistry` as a named struct wrapping
`HashMap<String, TypeKind>`.

Expose only these methods for now — no logic yet, just signatures
with `todo!()` bodies:

```rust
impl TypeRegistry {
    pub fn new() -> Self
    pub fn insert(&mut self, name: String, kind: TypeKind)
    pub fn get(&self, name: &str) -> TypeKind
}
```

`get` must return `TypeKind::External` (not panic) when the name is not found.

Checkpoint: `✓ Step 2 done — cargo build ✓  cargo clippy ✓`

---

## Step 3 — src/cli.rs

Define exactly 3 subcommands using clap derive: `build`, `watch`, `clean`.

The only allowed flag is `--verbose` (`-v`) on `build`, which controls whether
full parse error details are printed. No other flags on any command.

```rust
#[derive(Parser)]
#[command(name = "veltro", about = "Fast Dart code generation")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Command,
}

#[derive(Subcommand)]
pub enum Command {
    Build { #[arg(short, long)] verbose: bool },
    Watch,
    Clean,
}
```

Checkpoint: `✓ Step 3 done — cargo build ✓  cargo clippy ✓`

---

## Step 4 — src/main.rs

Wire up the CLI. Each branch must:
- Parse args using `Cli::parse()`
- Match the subcommand
- Call a stub function that prints `"[TODO] veltro <command>"` and returns `Ok(())`

The binary must compile and route correctly. Verify manually:
- `cargo run -- build` prints `[TODO] veltro build`
- `cargo run -- watch` prints `[TODO] veltro watch`
- `cargo run -- clean` prints `[TODO] veltro clean`

Checkpoint: `✓ Step 4 done — cargo build ✓  cargo run -- build ✓`

---

## Step 5 — src/pipeline/scanner.rs

Implement a function with this signature:

```rust
pub fn scan(root: &Path) -> Result<Vec<PathBuf>, ScanError>
```

Behaviour:
- Returns an error immediately if `root/lib/` does not exist
- Uses `walkdir` to find all `.dart` files under `lib/`
- Filters out any file whose name ends with `.g.dart`
- Uses `rayon` to parallelise the collection into a `Vec<PathBuf>`

Write a unit test that:
- Creates a temp directory with a fake `lib/` structure
- Confirms `.g.dart` files are excluded
- Confirms the function errors when `lib/` is missing

Populate `testdata/simple.dart` with a minimal valid `@Data()` class
to use in later integration tests:

```dart
import 'package:veltro/veltro.dart';
part 'simple.g.dart';

@Data()
class User {
  const factory User({
    required String id,
    required String name,
    required int age,
  }) = _User;
}
```

Checkpoint: `✓ Step 5 done — cargo test ✓  cargo clippy ✓`

---

## Step 6 — src/pipeline/parser.rs

Implement a function with this signature:

```rust
pub fn parse_file(path: &Path) -> Result<ParsedFile, ParseError>
```

Where `ParsedFile` is a struct you define holding the raw tree-sitter tree
and the source bytes.

Behaviour:
- Reads the file to a `String`
- Parses it with `tree-sitter` using the `tree-sitter-dart` grammar
- Returns a `ParseError` (with file path and line number) if the grammar
  reports any syntax errors — do NOT panic
- The returned struct must own the source bytes so later stages can
  extract text from AST nodes by byte range

Write a unit test that:
- Parses `testdata/simple.dart` successfully
- Confirms a parse error is returned for an intentionally broken Dart snippet

Checkpoint: `✓ Step 6 done — cargo test ✓  cargo clippy ✓`

---

## Step 7 — src/pipeline/analyzer.rs

Implement a function with this signature:

```rust
pub fn analyze(parsed: &ParsedFile) -> Result<Option<DataClassIR>, AnalyzeError>
```

Behaviour:
- Returns `None` if the file contains no `@Data()` annotation
- Traverses the tree-sitter AST to find the `factory` constructor of the
  annotated class
- Extracts: class name, generic type parameters, and all fields from the
  constructor parameters (name, type, nullability, required)
- Sets `resolved_kind` to `TypeKind::External` on all fields — the Resolver
  will fill this in later
- Returns an error (not a panic) if the AST structure is unexpected

Write unit tests that:
- Confirm `simple.dart` produces a `DataClassIR` with 3 fields
- Confirm a file without `@Data()` returns `None`

Populate `testdata/nested.dart`:

```dart
import 'package:veltro/veltro.dart';
part 'nested.g.dart';

@Data()
class Address {
  const factory Address({
    required String street,
    required String city,
  }) = _Address;
}

@Data()
class Person {
  const factory Person({
    required String name,
    required Address address,
  }) = _Person;
}
```

Checkpoint: `✓ Step 7 done — cargo test ✓  cargo clippy ✓`

---

## Step 8 — src/pipeline/resolver.rs + src/registry.rs (complete)

First, complete `TypeRegistry` with real logic:
- `build(ir_list: &[DataClassIR], parsed_files: &[ParsedFile]) -> TypeRegistry`
  - Pass 1: insert all `@Data()` class names as `TypeKind::DataClass`
  - Pass 1: scan for `enum` keyword declarations → `TypeKind::Enum`
  - Pass 1: scan for `@IsEnum()` annotations → `TypeKind::Enum`
  - Both scans run in parallel with `rayon`

Then implement the resolver:

```rust
pub fn resolve(ir: DataClassIR, registry: &TypeRegistry) -> DataClassIR
```

- For each field, call `registry.get(&field.type_name)` and set `resolved_kind`
- If the field's type name matches one of `ir.generics`, set
  `resolved_kind = TypeKind::External` and mark it as generic
  (add a `is_generic_param: bool` field to `FieldIR` if not already there)

Write unit tests that:
- Confirm a `Person.address` field resolves to `TypeKind::DataClass`
- Confirm an unknown type resolves to `TypeKind::External`
- Confirm a local enum field resolves to `TypeKind::Enum`

Checkpoint: `✓ Step 8 done — cargo test ✓  cargo clippy ✓`

---

## Step 9 — src/pipeline/generator.rs

This is the most critical step. Take your time.

Implement:

```rust
pub fn generate(ir: &DataClassIR) -> String
```

The output must be valid Dart 3 code. Generate in this order:

1. Header comment: `// GENERATED BY VELTRO — DO NOT EDIT`
2. `part of` directive
3. `_ClassName` concrete class with all fields as `final`
4. Constructor
5. `factory _ClassName.fromJson(Map<String, dynamic> json)` —
   use the fromJson rules from GEMINI.md exactly
6. `Map<String, dynamic> toJson()` method
7. `_ClassName copyWith({...})` method — shallow copy only
8. `@override bool operator ==(Object other)` — compare all fields
9. `@override int get hashCode` — use `Object.hash` or `Object.hashAll`
10. `@override String toString()`

For generic classes, `fromJson` must accept
`T Function(Object?) fromJsonT` as an extra parameter.

Write unit tests using `pretty_assertions::assert_eq!` that verify the
**exact string output** for:
- A simple class (3 primitive fields)
- A class with a nested `@Data()` field
- A class with an enum field
- A class with a single generic param `T`

Do not move on until all 4 test cases pass exactly.

Populate `testdata/generic.dart`:

```dart
import 'package:veltro/veltro.dart';
part 'generic.g.dart';

@Data()
class ApiResponse<T> {
  const factory ApiResponse({
    required bool success,
    required T data,
  }) = _ApiResponse;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);
}
```

Checkpoint: `✓ Step 9 done — cargo test ✓  cargo clippy ✓  all 4 generator cases pass`

---

## Step 10 — src/pipeline/mod.rs

Wire all pipeline stages into a single orchestrating function:

```rust
pub fn run(root: &Path, verbose: bool) -> Result<BuildResult, PipelineError>
```

Where `BuildResult` holds: files generated count, files failed count,
duration in ms, and a list of errors.

Behaviour — in order:
1. `scanner::scan(root)` → file list
2. Parse all files in parallel with `rayon`
3. Analyze all parsed files in parallel
4. Build `TypeRegistry` from all IR (Pass 1)
5. Resolve all IR in parallel (Pass 2)
6. Generate code for each IR
7. Collect results — do not stop on single-file errors

Replace the stub in `main.rs` `build` handler with a call to `pipeline::run`.
Print output according to the Terminal Output Spec in GEMINI.md exactly —
including the benchmark line.

Write an integration test that:
- Runs the full pipeline on `testdata/`
- Confirms 3 `.g.dart` files are generated
- Confirms `flutter analyze` would not reject the output
  (you can validate this by checking generated code compiles as valid Dart syntax
  using tree-sitter, or simply assert the string contains expected markers)

Checkpoint: `✓ Step 10 done — cargo test ✓  integration test ✓  cargo clippy ✓`

---

## Step 11 — src/writer.rs

Implement:

```rust
pub fn write_if_changed(
    path: &Path,
    content: &str,
    cache: &DashMap<PathBuf, u64>,
) -> WriteResult
```

Where `WriteResult` is an enum: `Written`, `Skipped`, `Error(io::Error)`.

Behaviour:
- Hash `content` with `xxh3_64`
- Check cache for existing hash at `path`
- If hash matches: return `Skipped` — do not touch the file
- If hash differs (or not in cache): write file, update cache, return `Written`

Wire `writer::write_if_changed` into the pipeline in `mod.rs`.

Write a unit test that:
- Writes a file once → `Written`
- Writes the same content again → `Skipped` (file's mtime must not change)
- Writes different content → `Written`

Checkpoint: `✓ Step 11 done — cargo test ✓  cargo clippy ✓`

---

## Step 12 — src/watcher.rs

Implement watch mode following the architecture in GEMINI.md exactly:

```
OS event → debounce (100ms) → crossbeam channel → rayon worker → hash check → write
```

Implement:

```rust
pub fn watch(root: &Path) -> Result<(), WatchError>
```

Behaviour:
- Run an initial `pipeline::run` and print the startup output from GEMINI.md
- Set up a `notify` watcher on `lib/` — must use OS-native events, not polling
- Debounce events with a 100ms window
- On `EventKind::Modify`: re-run the pipeline for the changed file only,
  print the single-line output from GEMINI.md
- On `EventKind::Remove` or rename-from: delete the corresponding `.g.dart`,
  remove from hash cache, print nothing
- On parse error: print the error line, do NOT exit — continue watching
- On `Ctrl+C` (SIGINT): print `^C  Stopped.` and exit cleanly

Wire this into the `watch` handler in `main.rs`.

Checkpoint: `✓ Step 12 done — cargo build ✓  cargo clippy ✓  manual watch test ✓`

---

## Final Verification

After Step 12 passes, run the full suite:

```bash
cargo build --release
cargo test
cargo clippy -- -D warnings
```

Then verify end-to-end manually:
1. Copy `testdata/simple.dart` into a temp Flutter project under `lib/`
2. Run `./target/release/veltro build`
3. Confirm `simple.g.dart` is generated
4. Confirm the output includes the benchmark line
5. Run `veltro watch`, edit `simple.dart`, confirm the file updates in < 100ms

Report the result of each check. Only mark the project complete when all
5 checks pass.
