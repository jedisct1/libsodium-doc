# The Sodium crypto library (libsodium)

Sodium is a modern, easy-to-use software library for encryption, decryption, signatures, password hashing, and more.

It is a portable, cross-compilable, installable, and packageable fork of [NaCl](http://nacl.cr.yp.to/), with a compatible but extended API to improve usability even further.

Its goal is to provide all of the core operations needed to build higher-level cryptographic tools.

Sodium is cross-platform and cross-language. It runs on many compilers and operating systems, including Windows (with MinGW or Visual Studio, x86, x86_64 and arm64), iOS, and Android. JavaScript and WebAssembly versions are also available and fully supported. Furthermore, bindings for all common programming languages are available and well-supported.

The design choices emphasize security and ease of use. But despite the emphasis on high security, primitives are faster across-the-board than most implementations.

## Downloading libsodium

[libsodium 1.0.20-stable](https://download.libsodium.org/libsodium/releases/) is the latest version.

- [Tarballs and pre-compiled binaries](https://download.libsodium.org/libsodium/releases/)
- [GitHub repository](https://github.com/jedisct1/libsodium)
- [Documentation](https://doc.libsodium.org)

## Mailing list

A mailing list is available to discuss libsodium.

To join, just send a random email to `sodium-subscribe` {at} `pureftpd`{dot}`org`.

## License

[ISC license](https://en.wikipedia.org/wiki/ISC_license).

See the `LICENSE` file for details.

## Thanks\!

Sodium is developed by volunteers. We would like to especially thank the following companies and organizations for their contribution:

- [Paragonie Initiative Enterprise](https://paragonie.com/), who donated a Raspberry Pi to ensure that the library works perfectly on this hardware. Thanks\!
- [Private Internet Access](https://www.privateinternetaccess.com), who sponsored a [complete security audit](https://www.privateinternetaccess.com/blog/libsodium-audit-results/). This is amazing, thanks\!
- [Maximilian Blochberger](https://github.com/blochberger) and Joshua Small, who both generously donated $100. This will help cover the infrastructure costs a lot. Thanks again, Max and Joshua\!
- [BestKru](https://bestkru.com)

People who designed the primitives and wrote implementations the library is based on can be found in the [AUTHORS](https://raw.githubusercontent.com/jedisct1/libsodium/master/AUTHORS) file. This project wouldn't exist without them.

Also, a huge "thank you" to people and companies who contributed bindings for their favorite programming languages. A list can be found in the [THANKS](https://raw.githubusercontent.com/jedisct1/libsodium/master/THANKS) file.

Another huge "thank you" to package maintainers who have been doing an amazing job at building packages for many distributions and operating systems.

Finally, thanks to **you** for reading this documentation and for the awesome projects you are going to build with this library\!
