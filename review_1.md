# Veltro — Fix Prompt v2

Apply the following rules for this entire session, then execute the 3 fixes in order.

---

## Ground Rules (apply to everything below)

1. **Always use the latest stable version** of every crate and package.
   Before writing any version string, check crates.io or pub.dev for the
   current latest. Never pin to an old version without a documented reason.

2. **Additional utility dependencies are allowed** if they make the code
   faster to write, more concise, or eliminate boilerplate — provided they
   are well-maintained crates with >1M downloads or strong community adoption.
   Good candidates: `anyhow`, `thiserror`, `tracing`, `once_cell`, `itertools`,
   `regex`, `serde`, `strum`, etc.
   When you add one, add a comment in Cargo.toml explaining why:
   `# added for ergonomic error handling`

3. After each fix, run `cargo build` and `cargo clippy -- -D warnings`.
   Both must pass before moving to the next fix.

4. Do not change anything outside the scope of each fix.

---

## FIX 1 — Remove unsafe transmute in src/pipeline/parser.rs

The current code uses `unsafe { std::mem::transmute(...) }` to cast the
tree-sitter-dart language due to a version mismatch. This is undefined
behavior and will crash at runtime.

Steps:
1. Check crates.io for the **latest stable versions** of both
   `tree-sitter` and `tree-sitter-dart`.
2. Update Cargo.toml to use versions that are mutually compatible —
   no transmute required. If the latest `tree-sitter-dart` does not yet
   support the latest `tree-sitter`, use the latest version of
   `tree-sitter` that `tree-sitter-dart` officially supports.
3. Rewrite the language initialisation in parser.rs to:

   ```rust
   let language = tree_sitter_dart::language();
   parser.set_language(&language).map_err(|_| ParseError::LanguageError)?;
   ```

4. Remove every `unsafe` block from parser.rs.

Done when:
- `cargo build` passes
- Zero `unsafe` blocks remain in parser.rs
- `cargo clippy -- -D warnings` passes

---

## FIX 2 — Create dart_package/ using dart create

The dart_package/ directory currently has empty files. Rebuild it properly.

Steps:

1. Delete the current dart_package/ directory entirely.

2. From the repo root, run:
   ```
   dart create --template=package dart_package
   ```

3. Replace dart_package/pubspec.yaml with the following.
   Use the **latest stable Dart SDK constraint**:

   ```yaml
   name: veltro
   description: >-
     Annotations for Veltro — the fast Rust-powered Dart code generator.
     Add @Data() to a class and run `veltro build`.
   version: 0.1.0
   repository: https://github.com/your-username/veltro

   environment:
     sdk: ">=3.4.0 <4.0.0"
   ```

4. Delete everything inside dart_package/lib/ and create a single file
   dart_package/lib/veltro.dart:

   ```dart
   /// Marks a class for Veltro code generation.
   ///
   /// Veltro will generate: `fromJson`, `toJson`, `copyWith`,
   /// `==`, `hashCode`, and `toString` for the annotated class.
   ///
   /// Example:
   /// ```dart
   /// @Data()
   /// class User {
   ///   const factory User({
   ///     required String id,
   ///     required String name,
   ///   }) = _User;
   /// }
   /// ```
   class Data {
     const Data();
   }

   /// Marks an external enum for Veltro type resolution.
   ///
   /// Use this when an enum is imported from another package and
   /// Veltro cannot detect it via the `enum` keyword in your source.
   ///
   /// Example:
   /// ```dart
   /// @IsEnum()
   /// class Status { ... }
   /// ```
   class IsEnum {
     const IsEnum();
   }
   ```

5. Delete dart_package/test/ — not needed for an annotation-only package.

6. Run `dart analyze dart_package/` — must pass with zero issues.

---

## FIX 3 — Three correctness bugs in generator and analyzer

Fix all three in a single pass. They are small and related.

### 3a — Enum toJson generates invalid Dart

In src/pipeline/generator.rs, the toJson block emits `.toJson()` for Enum
fields. Dart enums do not have a `.toJson()` method — this produces code
that will not compile.

Change the Enum branch in the toJson generation block to:

```rust
TypeKind::Enum => format!("{}.name", field.name),
```

Dart 3 enums have a built-in `.name` getter that returns the value as a
String. No extension needed.

### 3b — Annotation detection is too loose in analyzer.rs

The current check:
```rust
if text.contains("Data") { return true; }
```

This false-positives on `@ValidatedData`, `@MetaData`, `@BigData`, etc.

Replace with an exact match:
```rust
if text.trim() == "@Data()" { return true; }
```

### 3c — Same loose check for @IsEnum in registry.rs

Replace:
```rust
text.contains("IsEnum")
```
With:
```rust
text.trim() == "@IsEnum()"
```

---

## Final verification

After all 3 fixes are applied:

```bash
cargo build
cargo test
cargo clippy -- -D warnings
dart analyze dart_package/
```

All four commands must exit with zero errors and zero warnings.

Report the terminal output of each command.