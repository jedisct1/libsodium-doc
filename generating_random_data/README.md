# Generating random data

The library provides a set of functions to generate unpredictable data, suitable
for creating secret keys.

* On Windows systems, the `RtlGenRandom()` function is used
* On OpenBSD and Bitrig, the `arc4random()` function is used
* On recent FreeBSD and Linux kernels, the `getrandom` system call is used
* On other Unices, the `/dev/urandom` device is used
* If none of these options can safely be used, custom implementations can easily
  be hooked.

## Usage

```c
uint32_t randombytes_random(void);
```

The `randombytes_random()` function returns an unpredictable value between `0`
and `0xffffffff` (included).

```c
uint32_t randombytes_uniform(const uint32_t upper_bound);
```

The `randombytes_uniform()` function returns an unpredictable value between `0`
and `upper_bound` (excluded). Unlike `randombytes_random() % upper_bound`, it
guarantees a uniform distribution of the possible output values even when
`upper_bound` is not a power of 2. Note that an `upper_bound < 2` leaves only
a single element to be chosen, namely `0`

```c
void randombytes_buf(void * const buf, const size_t size);
```

The `randombytes_buf()` function fills `size` bytes starting at `buf` with an
unpredictable sequence of bytes.

```c
void randombytes_buf_deterministic(void * const buf, const size_t size,
                                   const unsigned char seed[randombytes_SEEDBYTES]);
```

The `randombytes_buf_deterministic` function stores `size` bytes into `buf`
indistinguishable from random bytes without knowing `seed`.

For a given `seed`, this function will always output the same sequence. `size`
can be up to 2^38 (256 GB).

`seed` is `randombytes_SEEDBYTES` bytes long.

This function is mainly useful for writing tests, and was introduced in
libsodium 1.0.12. Under the hood, it uses the ChaCha20 stream cipher.

Up to 256 GB can be produced with a single seed.

```c
int randombytes_close(void);
```

This deallocates the global resources used by the pseudo-random number
generator. More specifically, when the `/dev/urandom` device is used, it closes
the descriptor. Explicitly calling this function is almost never required.

```c
void randombytes_stir(void);
```

The `randombytes_stir()` function reseeds the pseudo-random number generator, if
it supports this operation. Calling this function is not required with the
default generator, even after a `fork()` call, unless the descriptor for
`/dev/urandom` was closed using `randombytes_close()`.

If a non-default implementation is being used (see
`randombytes_set_implementation()`), `randombytes_stir()` must be called by the
child after a `fork()` call.

## Note

If this is used in an application inside a VM, and the VM is snapshotted and
restored, then the above functions may produce the same output.
