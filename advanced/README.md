# Advanced

The functions outlined in this section are low-level and implement specific algorithms.

They are only designed to be used as building blocks for custom constructions or interoperability with other libraries and applications.

As a result, using these functions directly may not be secure if not done correctly.

The behavior and/or interface of these functions can change at any point in time.

Low-level functions that are not required by high-level APIs are also not present in libsodium when compiled in minimal mode.

Unless you need these specific algorithms, use the high-level APIs when possible.

Bindings for third-party languages are encouraged to use the high-level APIs as well. The underlying functions they depend on are guaranteed to never change without a major version bump of the library.
