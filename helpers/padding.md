# Padding

Most modern cryptographic constructions disclose message lengths. The ciphertext
for a given message will always have the same length, or add a constant number
of bytes to it.

For most applications, this is not an issue. But in some specific situations,
such as interactive remote shells, hiding the length may be desirable. Padding
can be used for that purpose.

This API was introduced in libsodium 1.0.14.

## Example

```c
unsigned char buf[100];
size_t        buf_unpadded_len = 10;
size_t        buf_padded_len;
size_t        block_size = 16;

/* round the length of the buffer to a multiple of `block_size` by appending
 * padding data and put the new, total length into `buf_padded_len` */
if (sodium_pad(&buf_padded_len, buf, buf_unpadded_len, block_size, sizeof buf) != 0) {
    /* overflow! buf[] is not large enough */
}

/* compute the original, unpadded length */
if (sodium_unpad(&buf_unpadded_len, buf, buf_padded_len, block_size) != 0) {
    /* incorrect padding */
}
```

## Usage

```c
int sodium_pad(size_t *padded_buflen_p, unsigned char *buf,
               size_t unpadded_buflen, size_t blocksize, size_t max_buflen);
```

The `sodium_pad()` function adds padding data to a buffer `buf` whose original
size is `unpadded_buflen` in order to extend its total length to a multiple of
`blocksize`.

The new length is put into `padded_buflen_p`.

The function returns `-1` if the padded buffer length would exceed `max_buflen`,
or if the block size is `0`. It returns `0` on success.

```c
int sodium_unpad(size_t *unpadded_buflen_p, const unsigned char *buf,
                 size_t padded_buflen, size_t blocksize);
```

The `sodium_unpad()` function computes the original, unpadded length of a
message previously padded using `sodium_pad()`. The original length is put into
`unpadded_buflen_p`.

## Algorithm

These functions use the ISO/IEC 7816-4 padding algorithm. It supports arbitrary
block sizes, ensures that the padding data is checked for computing the
unpadded length, and is more resistant to some classes of attacks than other
standard padding algorithms.

## Notes

Padding should be applied prior to encryption, and removed after decryption.

Usage of padding in order to hide the length of a password is not recommended. A
client willing to send a password to a server should hash it instead (even with
a single iteration of the hash function).

This ensures that the length of the transmitted data is constant, and that the
server doesn't effortlessly get a copy of the password.

Applications may eventually leak the unpadded length via side channels, but the
`sodium_pad()` and `sodium_unpad()` functions themselves try to minimize side
channels for a given `length & <block size mask>` value.
