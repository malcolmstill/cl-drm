
# cl-drm

LibDRM is an interface to the Linux Direct Rendering Manager (DRM). LibDRM provides a user-space API for mode setting. `cl-drm` is a Common Lisp wrapper for librdrm.

## Status

`cl-drm` is being developed primarily in support of [ulubis](https://github.com/malcolmstill/ulubis) and is therefor feature incomplete. Pull requests adding more of the API are more than welcome.

## Requiremnts

`cl-drm` (obiously) requires libdrm. It is likely that libdrm already exists on your Linux installation if it is recent.

## Installation

```
CL-USER> (ql:quickload :cl-drm)
```
