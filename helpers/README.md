# Helpers

## Constant-time test for equality

```c
int sodium_memcmp(const void * const b1_, const void * const b2_, size_t len);
```

When a comparison involves secret data (e.g. key, authentication tag), is it critical to use a constant-time comparison function in order to mitigate side-channel attacks.

The `sodium_memcmp()` function can be used for this purpose.

The function returns `0` if the `len` bytes pointed to by `b1_` match the `len` bytes pointed to by `b2_`. Otherwise, it returns `-1`.

**Note:** `sodium_memcmp()` is not a lexicographic comparator and is not a generic replacement for `memcmp()`.

## Hexadecimal encoding/decoding

```c
char *sodium_bin2hex(char * const hex, const size_t hex_maxlen,
                     const unsigned char * const bin, const size_t bin_len);
```

The `sodium_bin2hex()` function converts `bin_len` bytes stored at `bin` into a hexadecimal string.

The string is stored into `hex` and includes a nul byte (`\0`) terminator.

`hex_maxlen` is the maximum number of bytes that the function is allowed to write starting at `hex`. It should be at least `bin_len * 2 + 1`.

The function returns `hex` on success, or `NULL` on overflow. It evaluates in constant time for a given size.

```c
int sodium_hex2bin(unsigned char * const bin, const size_t bin_maxlen,
                   const char * const hex, const size_t hex_len,
                   const char * const ignore, size_t * const bin_len,
                   const char ** const hex_end);
```

The `sodium_hex2bin()` function parses a hexadecimal string `hex` and converts it to a byte sequence.

`hex` does not have to be nul terminated, as the number of characters to parse is supplied via the `hex_len` parameter.

`ignore` is a string of characters to skip. For example, the string `": "` allows columns and spaces to be present at any locations in the hexadecimal string. These characters will just be ignored. As a result, `"69:FC"`, `"69 FC"`, `"69 : FC"` and `"69FC"` will be valid inputs, and will produce the same output.

`ignore` can be set to `NULL` in order to disallow any non-hexadecimal character.

`bin_maxlen` is the maximum number of bytes to put into `bin`.

The parser stops when a non-hexadecimal, non-ignored character is found or when `bin_maxlen` bytes have been written.

The function returns `-1` if more than `bin_maxlen` bytes would be required to store the parsed string.
It returns `0` on success and sets `hex_end`, if it is not `NULL`, to a pointer to the character following the last parsed character.

It evaluates in constant time for a given length and format.

## Incrementing large numbers

```c
void sodium_increment(unsigned char *n, const size_t nlen);
```

The `sodium_increment()` function takes a pointer to an arbitrary-long unsigned number, and increments it.

It runs in constant-time for a given length, and considers the number to be encoded in little-endian format.

`sodium_increment()` can be used to increment nonces in constant time.

This function was introduced in libsodium 1.0.4.

## Adding large numbers

```c
void sodium_add(unsigned char *a, const unsigned char *b, const size_t len);
```

The `sodium_add()` function accepts two pointers to unsigned numbers encoded in little-endian format, `a` and `b`, both of size `len` bytes.

It computes `(a + b) mod 2^(8*len)` in constant time for a given length, and overwrites `a` with the result.

This function was introduced in libsodium 1.0.7.

## Comparing large numbers

```c
int sodium_compare(const void * const b1_, const void * const b2_, size_t len);
```

Given `b1_` and `b2_`, two `len` bytes numbers encoded in little-endian format, this function returns:
- `-1` if `b1_` is less than `b2_`
- `0` if `b1_` equals `b2_`
- `1` if `b1_` is greater than `b2_` 

The comparison is done in constant time for a given length.

This function can be used with nonces, in order to prevent replay attacks.
It was introduced in libsodium 1.0.6.
