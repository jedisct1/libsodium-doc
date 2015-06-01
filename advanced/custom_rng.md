# Defining a custom random number generator

On Unix-based systems and on Windows, Sodium uses the facilities provided by the operating system when generating random numbers is required.

Other operating systems do not support `/dev/urandom` or it might not be suitable for cryptographic applications. These systems might provide a different way to gather random numbers.

And, on embedded operating systems, even if the system may no have such a facility, a hardware-based random number generator might be available.

In addition, reproducible results instead of unpredictable ones may be
required in a testing environment.

For all these scenarios, Sodium provides a way to replace the default implementations generating random numbers.

## Usage

```c
typedef struct randombytes_implementation {
    const char *(*implementation_name)(void);
    uint32_t    (*random)(void);
    void        (*stir)(void);
    uint32_t    (*uniform)(const uint32_t upper_bound);
    void        (*buf)(void * const buf, const size_t size);
    int         (*close)(void);
} randombytes_implementation;

int randombytes_set_implementation(randombytes_implementation *impl);
```

The `randombytes_set_implementation()` function defines the set of functions required by the `randombytes_*` interface.

**This function should only be called once, before `sodium_init()`.**

## Example

Sodium ships with a sample alternative `randombytes` implementation based on the Salsa20 stream cipher in `randombytes_salsa20_random.c` file.

This implementation only requires access to `/dev/urandom` or `/dev/random` (or to `RtlGenRandom()` on Windows) once, during `sodium_init()`.

It might be used instead of the default implementations in order to avoid system calls when random numbers are required.

It might also be used if a non-blocking random device is not available or not safe, but blocking would only be acceptable at initialization time.

It can be enabled with:

```
randombytes_set_implementation(&randombytes_salsa20_implementation);
```

Before calling `sodium_init()`.

However, it is not thread-safe, and was designed to be just a boilerplate for writing implementations for embedded operating systems.
`randombytes_stir()` also has to be called to rekey the generator after fork()ing.

If you are using Windows or a modern Unix-based system, you should stick to the default implementations.

## Notes

Internally, all the functions requiring random numbers use the `randombytes_*` interface.

Replacing the default implementations will affect explicit calls to `randombytes_*` functions as well as functions generating keys and nonces.

Since version 1.0.3, custom RNGs don't need to provide `randombytes_stir()` nor `randombytes_close()` if they are not required. These can be `NULL` pointers instead. `randombytes_uniform()` doesn't have to be defined either: a default implementation will be used if a `NULL` pointer is given.

