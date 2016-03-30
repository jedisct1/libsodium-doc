# The Scrypt memory-hard function

As a conservative alternative to Argon2, Sodium provides an implementation of the scrypt password hashing function.

## Example 1: key derivation

```c
#define PASSWORD "Correct Horse Battery Staple"
#define KEY_LEN crypto_box_SEEDBYTES

unsigned char salt[crypto_pwhash_scryptsalsa208sha256_SALTBYTES];
unsigned char key[KEY_LEN];

randombytes_buf(salt, sizeof salt);

if (crypto_pwhash_scryptsalsa208sha256
    (key, sizeof key, PASSWORD, strlen(PASSWORD), salt,
     crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE,
     crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE) != 0) {
    /* out of memory */
}
```

## Example 2: password storage

```c
#define PASSWORD "Correct Horse Battery Staple"

char hashed_password[crypto_pwhash_scryptsalsa208sha256_STRBYTES];

if (crypto_pwhash_scryptsalsa208sha256_str
    (hashed_password, PASSWORD, strlen(PASSWORD),
     crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_SENSITIVE,
     crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_SENSITIVE) != 0) {
    /* out of memory */
}

if (crypto_pwhash_scryptsalsa208sha256_str_verify
    (hashed_password, PASSWORD, strlen(PASSWORD)) != 0) {
    /* wrong password */
}
```

## Key derivation

```c
int crypto_pwhash_scryptsalsa208sha256(unsigned char * const out,
                                       unsigned long long outlen,
                                       const char * const passwd,
                                       unsigned long long passwdlen,
                                       const unsigned char * const salt,
                                       unsigned long long opslimit,
                                       size_t memlimit);
```

The `crypto_pwhash_scryptsalsa208sha256()` function derives an `outlen` bytes long key from a password `passwd` whose length is `passwdlen` and a salt `salt` whose fixed length is `crypto_pwhash_scryptsalsa208sha256_SALTBYTES` bytes.

The computed key is stored into `out`.

`opslimit` represents a maximum amount of computations to perform. Raising this number will make the function require more CPU cycles to compute a key.

`memlimit` is the maximum amount of RAM that the function will use, in bytes. It is highly recommended to allow the function to use at least 16 megabytes.

For interactive, online operations, `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE` and `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE` provide a safe base line for these two parameters. However, using higher values may improve security.

For highly sensitive data, `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_SENSITIVE` and `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_SENSITIVE` can be used as an alternative. But with these parameters, deriving a key takes about 2 seconds on a 2.8 Ghz Core i7 CPU and requires up to 1 gigabyte of dedicated RAM.

The `salt` should be unpredictable. `randombytes_buf()` is the easiest way to fill the `crypto_pwhash_scryptsalsa208sha256_SALTBYTES` bytes of the salt.

Keep in mind that in order to produce the same key from the same password, the same salt, and the same values for `opslimit` and `memlimit` have to be used. Therefore, these parameters have to be stored for each user.

The function returns `0` on success, and `-1` if the computation didn't complete, usually because the operating system refused to allocate the amount of requested memory.

## Password storage

```c
int crypto_pwhash_scryptsalsa208sha256_str(char out[crypto_pwhash_scryptsalsa208sha256_STRBYTES],
                                           const char * const passwd,
                                           unsigned long long passwdlen,
                                           unsigned long long opslimit,
                                           size_t memlimit);
```

The `crypto_pwhash_scryptsalsa208sha256_str()` function puts an ASCII encoded string into `out`, which includes:
- the result of a memory-hard, CPU-intensive hash function applied to the password `passwd` of length `passwdlen`
- the automatically generated salt used for the previous computation
- the other parameters required to verify the password: `opslimit` and `memlimit`.

`crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE` and `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE` are safe baseline values to use for `opslimit` and `memlimit`.

The output string is zero-terminated, includes only ASCII characters and can be safely stored into SQL databases and other data stores. No extra information has to be stored in order to verify the password.

The function returns `0` on success and `-1` if it didn't complete successfully.

```c
int crypto_pwhash_scryptsalsa208sha256_str_verify(const char str[crypto_pwhash_scryptsalsa208sha256_STRBYTES],
                                                  const char * const passwd,
                                                  unsigned long long passwdlen);
```

This function verifies that the password `str` is a valid password verification string (as generated by `crypto_pwhash_scryptsalsa208sha256_str()`) for `passwd` whose length is `passwdlen`.

`str` has to be zero-terminated.

It returns `0` if the verification succeeds, and `-1` on error.

## Guidelines for choosing scrypt parameters

Start by determining how much memory the scrypt function can use. What will be the highest number of threads/processes evaluating the function simultaneously (ideally, no more than 1 per CPU core)? How much physical memory is guaranteed to be available?

`memlimit` should be a power of 2. Do not use anything less than 16 Mb, even for interactive use.

Then, a reasonable starting point for `opslimit` is `memlimit / 32`.

Measure how long the scrypt function needs in order to hash a password. If this it is way too long for your application, reduce `memlimit` and adjust `opslimit` using the above formula.

If the function is so fast that you can afford it to be more computationally intensive without any usability issues, increase `opslimit`.

For online use (e.g. login in on a website), a 1 second computation is likely to be the acceptable maximum.

For interactive use (e.g. a desktop application), a 5 second pause after having entered a password is acceptable if the password doesn't need to be entered more than once per session.

For non-interactive use and infrequent use (e.g. restoring an encrypted backup), an even slower computation can be an option.

But the best defense against brute-force password cracking remains using strong passwords. Libraries such as [passwdqc](http://www.openwall.com/passwdqc/) can help enforce this.

## Low-level scrypt API

The traditional, low-level scrypt API is also available:

```c
int crypto_pwhash_scryptsalsa208sha256_ll(const uint8_t * passwd, size_t passwdlen,
                                          const uint8_t * salt, size_t saltlen,
                                          uint64_t N, uint32_t r, uint32_t p,
                                          uint8_t * buf, size_t buflen);
```

Please note that `r` is specified in kilobytes, and not in bytes as in the Sodium API.

## Constants

- `crypto_pwhash_scryptsalsa208sha256_SALTBYTES`
- `crypto_pwhash_scryptsalsa208sha256_STRBYTES`
- `crypto_pwhash_scryptsalsa208sha256_STRPREFIX`
- `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE`
- `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE`
- `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_SENSITIVE`
- `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_SENSITIVE`

## Notes

Do not forget to initialize the library with `sodium_init()`. `crypto_pwhash_scryptsalsa208sha256_*` will still work without doing so, but possibly way slower.

Do not use constants (including `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_*` and `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_*`) in order to verify a password. Save the parameters along with the hash instead, and use these saved parameters for the verification.

Alternatively, use `crypto_pwhash_scryptsalsa208sha256_str()` and `crypto_pwhash_scryptsalsa208sha256_str_verify()`, that automatically take care of including and extracting the parameters.

By doing so, passwords can be rehashed using different parameters if required later on.

Cleartext passwords should not stay in memory longer than needed.

It is highly recommended to use `sodium_mlock()` to lock memory regions storing cleartext passwords, and to call `sodium_munlock()` right after `crypto_pwhash_scryptsalsa208sha256_str()` and `crypto_pwhash_scryptsalsa208sha256_str_verify()` return.

`sodium_munlock()` overwrites the region with zeros before unlocking it, so it doesn't have to be done before calling this function.

By design, a password whose length is 65 bytes or more is reduced to `SHA-256(password)`.
This can have security implications if the password is present in another password database using raw, unsalted SHA-256. Or when upgrading passwords previously hashed with unsalted SHA-256 to scrypt.

If this is a concern, passwords should be pre-hashed before being hashed using scrypt:
```c
char prehashed_password[56];
crypto_generichash((unsigned char *) prehashed_password, 56,
    (const unsigned char *) password, strlen(password), NULL, 0);
crypto_pwhash_scryptsalsa208sha256_str(out, prehashed_password, 56, ...);
...
crypto_pwhash_scryptsalsa208sha256_str_verify(str, prehashed_password, 56);
```