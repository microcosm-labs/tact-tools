//! This is a cool example using `tactdoc`!

    //! 
    //! Data Structures
    //! ---

/// Documentation for Struct
struct S {
    /// Some int a.
    some_int_a: Int;
    /// Some int b.
    some_int_b: Int;
    /// A magic address
    magic_address: Address;
}

    //! 
    //! Messages
    //! ---

/// Documentation for M
message M {
    some_int_a: Int;
    /// Some int b.  
    /// Comes with documentation.
    some_int_b: Int;
    /// Reference to [struct S](#struct-s).
    s: S;
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

    /// Documentation for [Message M](#message-m) handler.  
    /// All Markdown syntax should be supported from here.  
    /// # Example
    /// ```
    /// send(...{...body: M});
    /// ```
    receive(msg: M) {
    }

    /// Documentation for bounce.
    bounced(src: bounced<MyMessage>) {
        // ...
    }

    /// Documentation for another bounce.
    bounced(src: Slice) {
        // ...
    }

    //! 
    //! Getters
    //! ---

    /// Returns storage x.
    get fun storage_x(): Int {
        return self.storage_x;
    }
}