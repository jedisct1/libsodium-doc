# Advanced

The functions detailed in this section are low-level, and implement specific
algorithms.

They are only designed to be used as building blocks for custom constructions,
or for interoperability with other libraries and applications.

As a result, using these functions directly may not be secure if not done
correctly.

Low-level functions that are not required by high-level APIs are also not
present in libsodium when compiled in minimal mode.

Unless you absolutely need these specific algorithms, use the high-level APIs
whenever possible.

Bindings for 3rd party languages are encouraged to use the high-level APIs as
well. The underlying functions they depend on is guaranteed to never change
without a major bump of the library version.
