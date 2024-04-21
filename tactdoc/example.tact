/// Documentation for M
message M {
    some_int_a: Int;
    /// Some int b.  
    /// Comes with documentation.
    some_int_b: Int;
}

/// Comments for my contract.  
/// Multi-line comments are supported.
contract A {
    storage_x: Int = 0;
    /// Documentation for storage slot y.
    storage_y: Int;

    /// Initializes y only.
    init(y: Int) {
        self.storage_y = y;
    }

    /// Documentation for receive.  
    /// All Markdown syntax should be supported from here.  
    /// # Example
    /// ```
    /// send(...{...body: M});
    /// ```
    receive(msg: M) {
    }

    /// Returns storage x.
    get fun storage_x(): Int {
        return self.storage_x;
    }
}