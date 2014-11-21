# The Sodium crypto library (libsodium)

Sodium is a modern, easy-to-use software library for encryption, decryption, signatures, password hashing and more.

It is a portable, cross-compilable, installable, packageable fork of [NaCl](http://nacl.cr.yp.to/), with a compatible API, and an
extended API to improve usability even further.

Its goal is to provide all of the core operations needed to build higher-level cryptographic tools.

Sodium supports a variety of compilers and operating systems,
including Windows (with MinGW or Visual Studio, x86 and x64), iOS and Android.

The design choices emphasize security, and "magic constants" have clear rationales.

The same cannot be said of NIST curves, where the specific origins of
certain constants are not described by the standards.

And despite the emphasis on higher security, primitives are faster
across-the-board than most implementations of the NIST standards.

[Version 1.0.1](https://github.com/jedisct1/libsodium/releases) was released on November 21, 2014.

## Downloading libsodium

- [Github repository](https://github.com/jedisct1/libsodium)
- [Tarballs and pre-compiled binaries](http://download.libsodium.org/libsodium/releases/)
- [Documentation](http://doc.libsodium.org)

## Mailing list

A mailing-list is available to discuss libsodium.

In order to join, just send a random mail to `sodium-subscribe` {at}
`pureftpd`{dot}`org`.

## Offline documentation

This documentation can be downloaded as ePUB (for iPad, iPhone, Mac),
MOBI (for Kindle) and PDF here: http://jedisct1.gitbooks.io/libsodium/

## License

[ISC license](http://en.wikipedia.org/wiki/ISC_license).

See the `LICENSE` file for details.
