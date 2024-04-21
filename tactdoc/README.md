# Tactdoc

Tactdoc is a tool for generating documentation from Tact source files. It accepts comments as Markdown format, beginning with `///`, similar to `rustdoc`.

## Usage

Make sure you're on a Linux system with *busybox awk* installed.

Modify `github_path` and `branch` in `tactdoc.awk` to point to your directory.

For a single file:

`awk -f tactdoc.awk ./contracts/test.tact > ./doc.md`

For multiple files:

`awk -f tactdoc.awk ./contracts/*.tact > ./doc.md`

## Syntax

```kotlin
/// Documentation for M
message M {
    a: Int;
    /// Some int b
    b: Int;
}

/// Comments for my contract.
/// Multi-line comments are supported.
contract A {
    storage_x: Int;
    /// Documentation for storage slot y.
    storage y: Int;

    /// Documentation for receive.
    /// All Markdown syntax should be supported from here.
    /// # Example
    /// ```
    /// send(...{...body: M});
    /// ```
    receive(msg: M) {
    }
}

