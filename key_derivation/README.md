# Password hashing

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

## Purpose

Secret keys used to encrypt or sign confidential data have to be chosen from a very large keyspace. However, passwords are usually short, human-generated strings, making dictionary attacks practical.

The `pwhash` operation derives a secret key of any size from a password and a salt.

- The generated key has the size defined by the application, no matter what the password length is.
- The same password hashed with same parameters will always produce the same key.
- The same password hashed with different salts will produce different keys.
- The function deriving a key from a password and a salt is CPU intensive and intentionally requires a fair amount of memory. Therefore, it mitigates brute-force attacks by requiring a significant effort to verify each password.

Common use cases:
- Protecting an on-disk secret key with a password,
- Password storage, or rather: storing what it takes to verify a password without having to store the actual password.

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

`memlimit` is the maximum amount of RAM that the function will use, in bytes. It is recommended to allow the function to use at least 16 megabytes.

For interactive sessions, `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE` and `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE` provide a safe base line for these two parameters. However, using higher values may improve security.

For highly sensitive data, `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_SENSITIVE` and `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_SENSITIVE` can be used as an alternative. But with these parameters, deriving a key takes more than 10 seconds on a 2.8 Ghz Core i7 CPU and requires up to 1 gigabyte of dedicated RAM.

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

The output string is zero-terminated, includes only ASCII characters and can be conveniently stored into SQL databases and other data stores. No additional information has to be stored in order to verify the password.

The function returns `0` on success and `-1` if it didn't complete successfully.

```c
int crypto_pwhash_scryptsalsa208sha256_str_verify(const char str[crypto_pwhash_scryptsalsa208sha256_STRBYTES],
                                                  const char * const passwd,
                                                  unsigned long long passwdlen);
```

This function verifies that the password `str` is a valid password verification string (as generated by `crypto_pwhash_scryptsalsa208sha256_str()`) for `passwd` whose length is `passwdlen`.

It returns `0` if the verification succeeds, and `-1` on error.

## Constants

- `crypto_pwhash_scryptsalsa208sha256_SALTBYTES`
- `crypto_pwhash_scryptsalsa208sha256_STRBYTES`
- `crypto_pwhash_scryptsalsa208sha256_STRPREFIX`
- `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_INTERACTIVE`
- `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_INTERACTIVE`
- `crypto_pwhash_scryptsalsa208sha256_OPSLIMIT_SENSITIVE`
- `crypto_pwhash_scryptsalsa208sha256_MEMLIMIT_SENSITIVE`

## Notes

Cleartext passwords should not stay in memory longer than needed.

It is highly recommended to use `sodium_mlock()` to lock memory regions storing cleartext passwords, and to call `sodium_munlock()` right after `crypto_pwhash_scryptsalsa208sha256_str()` and `crypto_pwhash_scryptsalsa208sha256_str_verify()` return.

`sodium_munlock()` overwrites the region with zeros before unlocking it, so it doesn't have to be done before calling this function.
