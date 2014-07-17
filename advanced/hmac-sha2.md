# HMAC-SHA-2

Keyed message authentication using HMAC-SHA256, HMAC-SHA512 and HMAC-SHA512256 (truncated HMAC-SHA512) are provided.

If required, a streaming API is  available to process a message as a sequence of multiple chunks.

## Single-part example

```c
#define MESSAGE ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_LEN 22

unsigned char hash[crypto_auth_hmacsha512_BYTES];
unsigned char key[crypto_auth_hmacsha512_KEYBYTES];

randombytes_buf(key, sizeof key);
crypto_auth_hmacsha512(hash, MESSAGE, MESSAGE_LEN, key);
```

## Multi-part example

```c
#define MESSAGE_PART1 \
    ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_PART1_LEN 22

#define MESSAGE_PART2 \
    ((const unsigned char *) "is longer than expected")
#define MESSAGE_PART2_LEN 23

unsigned char hash[crypto_auth_hmacsha512_BYTES];
unsigned char key[crypto_auth_hmacsha512_KEYBYTES];
crypto_hash_sha512_state state;

randombytes_buf(key, sizeof key);

crypto_hash_sha512_init(&state);

crypto_hash_sha512_update(&state, MESSAGE_PART1, MESSAGE_PART1_LEN);
crypto_hash_sha512_update(&state, MESSAGE_PART2, MESSAGE_PART2_LEN);

crypto_hash_sha512_final(&state, hash);
```
