# Generic hashing

## Single-part example without a key

```c
#define MESSAGE ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_LEN 22

unsigned char hash[crypto_generichash_BYTES];

crypto_generichash(hash, sizeof hash,
                   MESSAGE, MESSAGE_LEN,
                   NULL, 0);
```

## Single-part example with a key

```c
#define MESSAGE ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_LEN 22

unsigned char hash[crypto_generichash_BYTES];
unsigned char key[crypto_generichash_KEYBYTES];

randombytes_buf(key, sizeof key);

crypto_generichash(hash, sizeof hash,
                   MESSAGE, MESSAGE_LEN,
                   key, sizeof key);
```

## Multi-part example with a key

```c
#define MESSAGE_PART1 \
    ((const unsigned char *) "Arbitrary data to hash")
#define MESSAGE_PART1_LEN 22

#define MESSAGE_PART2 \
    ((const unsigned char *) "is longer than expected")
#define MESSAGE_PART2_LEN 23

unsigned char hash[crypto_generichash_BYTES];
unsigned char key[crypto_generichash_KEYBYTES];
crypto_generichash_state state;

randombytes_buf(key, sizeof key);

crypto_generichash_init(&state, key, sizeof key, sizeof hash);

crypto_generichash_update(&state, MESSAGE_PART1, MESSAGE_PART1_LEN);
crypto_generichash_update(&state, MESSAGE_PART2, MESSAGE_PART2_LEN);

crypto_generichash_final(&state, hash, sizeof hash);
```

## Constants

- `crypto_generichash_BYTES`
- `crypto_generichash_KEYBYTES_MIN`
- `crypto_generichash_KEYBYTES_MAX`
- `crypto_generichash_KEYBYTES`

## Algorithm details

Blake2b
