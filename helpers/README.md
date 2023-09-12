# Helpers

## Constant-time test for equality

``` c
int sodium_memcmp(const void * const b1_, const void * const b2_, size_t len);
```

When a comparison involves secret data (e.g. a key, an authentication tag, etc), it is critical to use a constant-time comparison function. This property does not relate to computational complexity: it means the time needed to perform the comparison is the same for all data of the same size. The goal is to mitigate side-channel attacks.

The `sodium_memcmp()` function can be used for this purpose.

The function returns `0` if the `len` bytes pointed to by `b1_` match the `len` bytes pointed to by `b2_`. Otherwise, it returns `-1`.

**Note:** `sodium_memcmp()` is not a lexicographic comparator and is not a generic replacement for `memcmp()`.

## Hexadecimal encoding/decoding

``` c
char *sodium_bin2hex(char * const hex, const size_t hex_maxlen,
                     const unsigned char * const bin, const size_t bin_len);
```

The `sodium_bin2hex()` function converts `bin_len` bytes stored at `bin` into a hexadecimal string.

The string is stored into `hex` and includes a nul byte (`\0`) terminator.

`hex_maxlen` is the maximum number of bytes that the function is allowed to write starting at `hex`. It must be at least `bin_len * 2 + 1` bytes.

The function always returns `hex`. It evaluates in constant time for a given size.

``` c
int sodium_hex2bin(unsigned char * const bin, const size_t bin_maxlen,
                   const char * const hex, const size_t hex_len,
                   const char * const ignore, size_t * const bin_len,
                   const char ** const hex_end);
```

The `sodium_hex2bin()` function parses a hexadecimal string `hex` and converts it to a byte sequence.

`hex` does not have to be nul terminated, as the number of characters to parse is supplied via the `hex_len` parameter.

`ignore` is a string of characters to skip. For example, the string `": "` allows colons and spaces to be present at any location in the hexadecimal string. These characters will just be ignored. As a result, `"69:FC"`, `"69 FC"`, `"69 : FC"` and `"69FC"` will be valid inputs and produce the same output.

`ignore` can be set to `NULL` to disallow any non-hexadecimal character.

`bin_maxlen` is the maximum number of bytes to put into `bin`.

The parser stops when a non-hexadecimal, non-ignored character is found or when `bin_maxlen` bytes have been written.

If `hex_end` is not `NULL`, it will be set to the address of the first byte after the last valid parsed character.

The function returns `0` on success.

It returns `-1` if more than `bin_maxlen` bytes would be required to store the parsed string or the string couldn’t be fully parsed, but a valid pointer for `hex_end` was not provided.

It evaluates in constant time for a given length and format.

## Base64 encoding/decoding

``` c
char *sodium_bin2base64(char * const b64, const size_t b64_maxlen,
                        const unsigned char * const bin, const size_t bin_len,
                        const int variant);
```

The `sodium_bin2base64()` function encodes `bin` as a Base64 string. `variant` must be one of:

  - `sodium_base64_VARIANT_ORIGINAL`
  - `sodium_base64_VARIANT_ORIGINAL_NO_PADDING`
  - `sodium_base64_VARIANT_URLSAFE`
  - `sodium_base64_VARIANT_URLSAFE_NO_PADDING`

None of these Base64 variants provides any form of encryption; just like hex encoding, anyone can decode them.

Computing a correct size for `b64_maxlen` is not straightforward and depends on the chosen variant.

The `sodium_base64_ENCODED_LEN(BIN_LEN, VARIANT)` macro returns the minimum number of bytes required to encode `BIN_LEN` bytes using the Base64 variant `VARIANT`. The returned length includes a trailing `\0` byte.

The `sodium_base64_encoded_len(size_t bin_len, int variant)` function is also available for the same purpose.

``` c
int sodium_base642bin(unsigned char * const bin, const size_t bin_maxlen,
                      const char * const b64, const size_t b64_len,
                      const char * const ignore, size_t * const bin_len,
                      const char ** const b64_end, const int variant);
```

The `sodium_base642bin()` function decodes a Base64 string using the given variant and an optional set of characters to ignore (typically: whitespaces and newlines).

If `b64_end` is not `NULL`, it will be set to the address of the first byte after the last valid parsed character.

Base64 encodes 3 bytes as 4 characters, so the result of decoding a `b64_len` string will always be at most `b64_len / 4 * 3` bytes long.

The function returns `0` on success.

It returns `-1` if more than `bin_maxlen` bytes would be required to store the parsed string or the string couldn’t be fully parsed, but a valid pointer for `b64_end` was not provided.

## Incrementing large numbers

``` c
void sodium_increment(unsigned char *n, const size_t nlen);
```

The `sodium_increment()` function takes a pointer to an arbitrary-long unsigned number and increments it.

It runs in constant time for a given length and considers the number to be encoded in a little-endian format.

`sodium_increment()` can be used to increment nonces in constant time.

## Adding large numbers

``` c
void sodium_add(unsigned char *a, const unsigned char *b, const size_t len);
```

The `sodium_add()` function accepts two pointers to unsigned numbers encoded in little-endian format, `a` and `b`, both of size `len` bytes.

It computes `(a + b) mod 2^(8*len)` in constant time for a given length and overwrites `a` with the result.

## Subtracting large numbers

``` c
void sodium_sub(unsigned char *a, const unsigned char *b, const size_t len);
```

The `sodium_sub()` function accepts two pointers to unsigned numbers encoded in little-endian format, `a` and `b`, both of size `len` bytes.

It computes `(a - b) mod 2^(8*len)` in constant time for a given length and overwrites `a` with the result.

This function was introduced in libsodium 1.0.17.

## Comparing large numbers

``` c
int sodium_compare(const void * const b1_, const void * const b2_, size_t len);
```

Given `b1_` and `b2_`, two `len` bytes numbers encoded in little-endian format, this function returns:

  - `-1` if `b1_` is less than `b2_`
  - `0` if `b1_` equals `b2_`
  - `1` if `b1_` is greater than `b2_`

The comparison is done in constant time for a given length.

This function can be used with nonces to prevent replay attacks.

## Testing for all zeros

``` c
int sodium_is_zero(const unsigned char *n, const size_t nlen);
```

This function returns `1` if the `nlen` bytes vector pointed by `n` contains only zeros. It returns `0` if non-zero bits are found.

Its execution time is constant for a given length.

## Clearing the stack

``` c
void sodium_stackzero(const size_t len);
```

The `sodium_stackzero()` function clears `len` bytes above the current stack pointer, to overwrite sensitive values that may have been temporarily stored on the stack.

Note that these values can still be present in registers.

This function was introduced in libsodium 1.0.16.

## Notes

The `sodium_base64_VARIANT_*()` macros don’t have associated symbols. Bindings are encouraged to define specialized encoding/decoding functions instead.
