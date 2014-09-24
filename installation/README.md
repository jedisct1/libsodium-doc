# Installation

Sodium is a shared library with a machine-independent set of
headers, so that it can easily be used by 3rd party projects.

The library is built using autotools, making it easy to package.

Installation is trivial, and both compilation and testing can take
advantage of multiple CPU cores.

Download a
[tarball of libsodium](https://download.libsodium.org/libsodium/releases/),
then follow the ritual:

```bash
$ ./configure
$ make && make check
# make install
```

Pre-compiled Win32 packages are available for download at the same
location.

Integrity of source tarballs can currently be checked using PGP or
verified DNS queries (`dig +dnssec +short txt <file>.download.libsodium.org`
returns the SHA-256 of any file available for download).

## Pre-built libraries

[Pre-built x86 and x64 libraries for Visual Studio 2010, 2012 and 2013](https://download.libsodium.org/libsodium/releases/) are available, as well as pre-built libraries for MingW32 and MingW64.

## Cross-compiling

Cross-compilation is fully supported. This is an example of
cross-compiling to ARM using the GNU tools for ARM embedded processors:

```bash
$ export PATH=/path/to/gcc-arm-none-eabi/bin:$PATH
$ export LDFLAGS='--specs=nosys.specs'
$ export CFLAGS='-Os'
$ ./configure --host=arm-none-eabi --prefix=/install/path
$ make install
```

```make check``` can also build the test apps, but these have to be
run on the native platform.

Note: `--specs=nosys.specs` is only required for the ARM compilation
toolchain.

## Integrity checking

The following PGP public key can be used to verify the signature of the distributed files.

```
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.0.7 (OpenBSD)

mQGiBDyLn3ERBACaS8c1UxJxm/gV6iJkzA82O1TMbBXAJdr0uIkBCtsYnM5GRb1p
+FSfuulLpB6lOOJAd00TQT06WBeVYYQdepLlL7oBL+13SPBdY2Kw2jZUY9MQZppf
St4Z0Dy0JFCjn94vLWRd+KZI2sqXsM2/NMYcWSnkO5Ohta5BQFcCpJAHqwCgygUV
2TWFyNSqvrccIBWQ2I17ZKED/3tQEO1YOenyDV1w44bS6kN0Eh+63cFeIO4t6QJM
rEJSna7Q0R8VdDaaRpHKzPzLAXNrts66RGUnGdW0AuN7PEeVF2a/v8RaMofbntxT
Emz3oqG3kIScwk2bXOTI5vtyuyE9LemUkBu+8+GAeOzVNQyqc/R+fu0Fyc8/rQmv
MrMZA/9YKMb4N7qZacawCASYG+y2fO1ZEUUmC+xsEU4GhY9pQePRpht2WDBO8fQj
XGNt1Y6bL00XHDCn5KiYc19vC+yg36Wg/lFzouLaT5gKdnZ1RvBJYEeViUMXFMKi
MqwPVAMUgvrJbO2oPPI+z9/H36F9kOk/TcsGt0ZXM/p0zMscoLQoRnJhbmsgREVO
SVMgKEplZGkvU2VjdG9yIE9uZSkgPGpANHUubmV0PohGBBMRAgAGBQI9iNjmAAoJ
EJJrxRcc3qQ5c2UAoJf0tsX2qVB1B3BR8qXhOmi6cjY3AKDBf2y+y/0xsdKz3SP/
jUmPoTEWyrQgSmVkaS9TZWN0b3IgT25lIDxqQHB1cmVmdHBkLm9yZz6IXwQTEQIA
HwIbAwQLBwMCAxUCAwMWAgECHgECF4ACGQEFAj2RbHcACgkQkmvFFxzepDkEhgCf
QEV5k4Bdw4yzG03GFdcipuxeg4kAnAmkamDV3aGdXlAloxYl5hjCq6FhtDdGcmFu
ayBERU5JUyAoSmVkaS9TZWN0b3IgT25lKSA8MGRheWRpZ2VzdEBwdXJlZnRwZC5v
cmc+iFwEExECABwFAj2RbjECGwMECwcDAgMVAgMDFgIBAh4BAheAAAoJEJJrxRcc
3qQ5lbwAniNQ30oCObN3xcOqUGY3PK1AxMiAAKCbvMDXYgzgAna7jW8YM+I/RvJR
ubkBDQQ8i597EAQAnL2f9pOjM72r9znZ8Zp9UPYuoMVlEcAqEWu02dexYlOczLmU
nYmAH1EE2znYklEPBvxvOrY6NDLSqxHj9E8aK1OqxJVnG0b/mdUWk6rgu8/5cgB+
XQOBxgmIc+Y4jxpzVzdst1ezYuBCENykCIw/7pKXMZs9obwF52dGKvFLtpMAAwYD
/11hDNQLaDdiTP3yDKVx2vp0Hozsp1I+gLfHX7ucCRSRPbQCt25Q8/9cE26UBBJT
cqiXdSHHxslkm2Bn3DAoUJ8up28tZdfgNA8mnZ+EnBmRLF6TaQIZIi/NVe1VrDAX
rkDK2+xwm9wHoLCmiRcMWGoeyjUdPPQGvCR6ry0FMhqniEYEGBECAAYFAjyLn3sA
CgkQkmvFFxzepDmzSgCeLxnh2llbSZrWxzUn9PP9j258FAAAoLr7R//w/MSwN24+
WkiLGnusVPtk
=5Jlq
-----END PGP PUBLIC KEY BLOCK-----
```

