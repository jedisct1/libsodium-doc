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

## Usage

```c
int crypto_kx_seed_keypair(unsigned char pk[crypto_kx_PUBLICKEYBYTES],
                           unsigned char sk[crypto_kx_SECRETKEYBYTES],
                           const unsigned char seed[crypto_kx_SEEDBYTES]);
```



