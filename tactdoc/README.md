# Tactdoc

Tactdoc is a tool for generating documentation from Tact source files. It accepts comments as Markdown format, beginning with `///`, similar to [rustdoc](https://doc.rust-lang.org/rust-by-example/meta/doc.html).

Tactdoc generates Markdown files with links to your Github source file. [example.tact](example.tact) generates [example.md](example.md).

## Usage

- Make sure you're on a Linux system with *busybox awk*(this is the case for most modern Linux distributions) or *gawk* installed.

- Modify `github_path` and `branch` in `tactdoc.awk` to point to your repository.

- For a single file: run `awk -f tactdoc.awk ./contracts/test.tact > ./doc.md`

- For multiple files: run `awk -f tactdoc.awk ./contracts/*.tact > ./doc.md`

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
    storage_y: Int;

    /// Documentation for receive.
    /// All Markdown syntax should be supported from here.
    /// # Example
    /// ```
    /// send(...{...body: M});
    /// ```
    receive(msg: M) {
    }
}

