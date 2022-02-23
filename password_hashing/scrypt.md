# The Scrypt memory-hard function

Sodium provides an implementation of the scrypt password hashing function.

However, unless you have specific reasons to use scrypt, you should instead consider the
default function, [Argon2](../password_hashing/the_argon2i_function.md).

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

The `crypto_pwhash_scryptsalsa208sha256()` function derives an `outlen` bytes
long key from a password `passwd` whose length is `passwdlen` and a salt `salt`
whose fixed length is `crypto_pwhash_scryptsalsa208sha256_SALTBYTES` bytes.

The computed key is stored into `out`. `out` (and hence `outlen`) should be at
least `crypto_pwhash_scryptsalsa208sha256_BYTES_MIN` and at most
`crypto_pwhash_scryptsalsa208sha256_BYTES_MAX` (~127 GB).

`passwd` (and hence `passwdlen`) should be at least
`crypto_pwhash_scryptsalsa208sha256_PASSWD_MIN` and at most
`crypto_pwhash_scryptsalsa208sha256_PASSWD_MAX`.

`opslimit` represents the maximum amount of computations to perform. Raising this
number will make the function require more CPU cycles to compute a key. This
number must be between `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_MIN` and
`crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_MAX`.

`memlimit` is the maximum amount of RAM in bytes that the function will use. It
is highly recommended to allow the function to use at least 16 MiB. This
number must be between `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_MIN` and
`crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_MAX`.

For interactive, online operations,
`crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE` and
`crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE` provide a safe baseline
for these two parameters. However, using higher values may improve security.

For highly sensitive data,
`crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_SENSITIVE` and
`crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_SENSITIVE` can be used as an
alternative. However, with these parameters, deriving a key takes about 2 seconds on
a 2.8 GHz Core i7 CPU and requires up to 1 GiB of dedicated RAM.

The `salt` should be unpredictable. `randombytes_buf()` is the easiest way to
fill the `crypto_pwhash_scryptsalsa208sha256_SALTBYTES` bytes of the salt.

Keep in mind that to produce the same key from the same password, the
same salt, `opslimit`, and `memlimit` values must be used.
Therefore, these parameters must be stored for each user.

The function returns `0` on success and `-1` if the computation didn't
complete, usually because the operating system refused to allocate the amount of
requested memory.

## Password storage

```c
int crypto_pwhash_scryptsalsa208sha256_str(char out[crypto_pwhash_scryptsalsa208sha256_STRBYTES],
                                           const char * const passwd,
                                           unsigned long long passwdlen,
                                           unsigned long long opslimit,
                                           size_t memlimit);
```

The `crypto_pwhash_scryptsalsa208sha256_str()` function puts an ASCII encoded
string into `out`, which includes:

* the result of a memory-hard, CPU-intensive hash function applied to the
  password `passwd` of length `passwdlen`;
* the automatically generated salt used for the previous computation;
* the other parameters required to verify the password: `opslimit` and
  `memlimit`.

`crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE` and
`crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE` are safe baseline
values to use for `opslimit` and `memlimit`.

The output string is zero-terminated, includes only ASCII characters, and can be
safely stored in SQL databases and other data stores. No extra information has
to be stored to verify the password.

The function returns `0` on success and `-1` if it didn't complete successfully.

```c
int crypto_pwhash_scryptsalsa208sha256_str_verify(const char str[crypto_pwhash_scryptsalsa208sha256_STRBYTES],
                                                  const char * const passwd,
                                                  unsigned long long passwdlen);
```

This function verifies that the password `str` is a valid password verification
string (as generated by `crypto_pwhash_scryptsalsa208sha256_str()`) for `passwd`
whose length is `passwdlen`.

`str` must be zero-terminated.

It returns `0` if the verification succeeds and `-1` on error.

## Guidelines for choosing scrypt parameters

Start by determining how much memory the scrypt function can use. What will be
the highest number of threads/processes evaluating the function simultaneously
(ideally, no more than 1 per CPU core)? How much physical memory is guaranteed
to be available?

`memlimit` should be a power of 2. Do not use anything less than 16 MiB, even for
interactive use.

Then a reasonable starting point for `opslimit` is `memlimit / 32`.

Measure how long the scrypt function needs to hash a password. If this is way too
long for your application, reduce `memlimit` and adjust `opslimit` using the above formula.

If the function is so fast that you can afford it to be more computationally
intensive without any usability issues, increase `opslimit`.

For online use (e.g. logging in on a website), a 1 second computation is likely to
be the acceptable maximum.

For interactive use (e.g. a desktop application), a 5 second pause after having
entered a password is acceptable if the password doesn't need to be entered more
than once per session.

For non-interactive and infrequent use (e.g. restoring an encrypted backup),
an even slower computation can be an option.

However, the best defense against brute-force password cracking is to use strong
passwords. Libraries such as [passwdqc](http://www.openwall.com/passwdqc/) can
help enforce this.

## Low-level scrypt API

The traditional, low-level scrypt API is also available:

```c
int crypto_pwhash_scryptsalsa208sha256_ll(const uint8_t * passwd, size_t passwdlen,
                                          const uint8_t * salt, size_t saltlen,
                                          uint64_t N, uint32_t r, uint32_t p,
                                          uint8_t * buf, size_t buflen);
```

Please note that `r` is specified in kilobytes, not in bytes as in the
Sodium API.

## Constants

* `crypto_pwhash_scryptsalsa208sha256_BYTES_MIN`
* `crypto_pwhash_scryptsalsa208sha256_BYTES_MAX`
* `crypto_pwhash_scryptsalsa208sha256_PASSWD_MIN`
* `crypto_pwhash_scryptsalsa208sha256_PASSWD_MAX`
* `crypto_pwhash_scryptsalsa208sha256_SALTBYTES`
* `crypto_pwhash_scryptsalsa208sha256_STRBYTES`
* `crypto_pwhash_scryptsalsa208sha256_STRPREFIX`
* `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_MIN`
* `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_MAX`
* `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_MIN`
* `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_MAX`
* `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE`
* `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE`
* `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_SENSITIVE`
* `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_SENSITIVE`

## Notes

Do not forget to initialize the library with `sodium_init()`.
`crypto_pwhash_scryptsalsa208sha256_*` will still work without doing so but
possibly way slower.

Do not use constants (including `crypto_pwhash_cryptsalsa208sha256_OPSLIMIT_*`
and `crypto_pwhash_cryptsalsa208sha256_MEMLIMIT_*`) to verify a
password or produce a deterministic output. Save the parameters alongside the
hash instead.

By doing so, passwords can be rehashed using different parameters if required
later on.

For password verification, the recommended interface is
`crypto_pwhash_cryptsalsa208sha256_str()` and
`crypto_pwhash_cryptsalsa208sha256_str_verify()`. The string produced by
`crypto_pwhash_cryptsalsa208sha256_str()` already includes an algorithm
identifier and all the parameters, including the automatically generated
salt, that were used to hash the password. Subsequently,
`crypto_pwhash_cryptsalsa208sha256_str_verify()` automatically decodes these
parameters.

Plaintext passwords should not stay in memory longer than needed.

It is highly recommended to use `sodium_mlock()` to lock memory regions storing
plaintext passwords and to call `sodium_munlock()` right after
`crypto_pwhash_scryptsalsa208sha256_str()` and
`crypto_pwhash_scryptsalsa208sha256_str_verify()` return.

`sodium_munlock()` overwrites the region with zeros before unlocking it, so it
doesn't have to be done before calling this function.

By design, a password whose length is 65 bytes or more is reduced to
`SHA-256(password)`. This can have security implications if the password is
present in another password database using raw, unsalted SHA-256 or when
upgrading passwords previously hashed with unsalted SHA-256 to scrypt.

If this is a concern, then passwords should be pre-hashed before being hashed using
scrypt:

```c
char prehashed_password[56];
crypto_generichash((unsigned char *) prehashed_password, 56,
    (const unsigned char *) password, strlen(password), NULL, 0);
crypto_pwhash_scryptsalsa208sha256_str(out, prehashed_password, 56, ...);
...
crypto_pwhash_scryptsalsa208sha256_str_verify(str, prehashed_password, 56);
```

## Algorithm details

* [The scrypt Password-Based Key Derivation Function](https://www.rfc-editor.org/rfc/rfc7914.txt)
