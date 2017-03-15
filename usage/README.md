# Usage

```c
#include <sodium.h>

int main(void)
{
    if (sodium_init() == -1) {
        return 1;
    }
    ...
}
```

`sodium.h` is the only header that has to be included.

The library is called `sodium` \(use `-lsodium` to link it\), and proper compilation/linker flags can be obtained using `pkg-config` on systems where it is available:

```bash
CFLAGS=$(pkg-config --cflags libsodium)
LDFLAGS=$(pkg-config --libs libsodium)
```

For static linking, Visual Studio users should define `SODIUM_STATIC=1` and `SODIUM_EXPORT=`. This is not required on other platforms.

`sodium_init()` initializes the library and should be called before any other function provided by Sodium.  
The function can be called more than once, and can be called simultaneously from multiple threads since version 1.0.11.

After this function returns, all of the other functions provided by Sodium will be thread-safe.

`sodium_init()` doesn't perform any memory allocations. However, on Unix systems, it may open `/dev/urandom` and keep the descriptor open, so that the device remains accessible after a `chroot()` call.  
Multiple calls to `sodium_init()` do not cause additional descriptors to be opened.

`sodium_init()` returns `0` on success, `-1` on failure, and `1` if the library had already been initialized.

