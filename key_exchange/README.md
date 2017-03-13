# Key exchange

## Example \(client-side\)

```c
unsigned char client_pk[crypto_kx_PUBLICKEYBYTES], client_sk[crypto_kx_SECRETKEYBYTES];
unsigned char client_rx[crypto_kx_SESSIONKEYBYTES], client_tx[crypto_kx_SESSIONKEYBYTES];

/* Generate the client's key pair */
crypto_kx_keypair(client_pk, client_sk);

/* Prerequisite after this point: the server's public key must be known by the client */

/* Compute two shared keys using the server's public key and the client's secret key.
   client_rx will be used by the client to receive data from the server,
   client_tx will by used by the client to send data to the server. */
if (crypto_kx_client_session_keys(client_rx, client_tx,
                                  client_pk, client_sk, server_pk) != 0) {
    /* Suspicious server public key, bail out */
}
```

## Example \(server-side\)

```c
unsigned char server_pk[crypto_kx_PUBLICKEYBYTES], server_sk[crypto_kx_SECRETKEYBYTES];
unsigned char server_rx[crypto_kx_SESSIONKEYBYTES], server_tx[crypto_kx_SESSIONKEYBYTES];

/* Generate the server's key pair */
crypto_kx_keypair(server_pk, server_sk);

/* Prerequisite after this point: the client's public key must be known by the server */

/* Compute two shared keys using the client's public key and the server's secret key.
   server_rx will be used by the server to receive data from the client,
   server_tx will by used by the server to send data to the client. */
if (crypto_kx_server_session_keys(server_rx, server_tx,
                                  server_pk, server_sk, client_pk) != 0) {
    /* Suspicious client public key, bail out */
}
```

## Purpose

Using the key exchange API, two parties can securely compute a set of shared keys using their peer's public key and their own secret key.

This API was introduced in libsodium 1.0.12.

## Usage

```c
int crypto_kx_keypair(unsigned char pk[crypto_kx_PUBLICKEYBYTES],
                      unsigned char sk[crypto_kx_SECRETKEYBYTES]);
```

The `crypto_kx_keypair()` function creates a new key pair. It puts the public key into `pk` and the secret key into `sk`.

```c
int crypto_kx_seed_keypair(unsigned char pk[crypto_kx_PUBLICKEYBYTES],
                           unsigned char sk[crypto_kx_SECRETKEYBYTES],
                           const unsigned char seed[crypto_kx_SEEDBYTES]);
```

The `crypto_kx_seed_keypair()` function computes a deterministic key pair from the seed `seed` \(`crypto_kx_SEEDBYTES` bytes\).

```c
int crypto_kx_client_session_keys(unsigned char rx[crypto_kx_SESSIONKEYBYTES],
                                  unsigned char tx[crypto_kx_SESSIONKEYBYTES],
                                  const unsigned char client_pk[crypto_kx_PUBLICKEYBYTES],
                                  const unsigned char client_sk[crypto_kx_SECRETKEYBYTES],
                                  const unsigned char server_pk[crypto_kx_PUBLICKEYBYTES]);
```

The `crypto_kx_client_session_keys()` function computes a pair of shared keys \(`rx` and `tx`\) using the client's public key `client_pk`, the client's secret key `client_sk` and the server's public key `server_pk`.

It returns `0` on success, or `-1` if the server's public key is not acceptable.

The shared secret key `rx` should be used by the client to receive data from the server, whereas `tx` should be used for data flowing in the opposite direction.

`rx` and `tx` are both `crypto_kx_SESSIONKEYBYTES` bytes long. If only one session key is required, either `rx` or `tx` can be set to `NULL`.

```c
int crypto_kx_server_session_keys(unsigned char rx[crypto_kx_SESSIONKEYBYTES],
                                  unsigned char tx[crypto_kx_SESSIONKEYBYTES],
                                  const unsigned char server_pk[crypto_kx_PUBLICKEYBYTES],
                                  const unsigned char server_sk[crypto_kx_SECRETKEYBYTES],
                                  const unsigned char client_pk[crypto_kx_PUBLICKEYBYTES]);
```

The `crypto_kx_server_session_keys()` function computes a pair of shared keys \(`rx` and `tx`\) using the server's public key `server_pk`, the server's secret key `server_sk` and the client's public key `client_pk`.

It returns `0` on success, or `-1` if the client's public key is not acceptable.

The shared secret key `rx` should be used by the server to receive data from the client, whereas `tx` should be used for data flowing in the opposite direction.

`rx` and `tx` are both `crypto_kx_SESSIONKEYBYTES` bytes long. If only one session key is required, either `rx` or `tx` can be set to `NULL`.

## Constants

* `crypto_kx_PUBLICKEYBYTES`
* `crypto_kx_SECRETKEYBYTES`
* `crypto_kx_SEEDBYTES`
* `crypto_kx_SESSIONKEYBYTES`
* `crypto_kx_PRIMITIVE`

## Algorithm details

* Diffie-Hellman function: X25519
* Entropy extractor and key derivation function: BLAKE2B

## Notes

For earlier versions of the library that didn't implement this API, or to build different constructions, the X25519 function is accessible directly using the `crypto_scalarmult_*()` API.

Having different keys for each direction allows counters to be safely used as nonces without having to wait for an acknowledgement after every message.

