# Cosign Testing

This repo is just me toying around with cosign.

## Usage

1. Execute `make alpine` on your local host to build the `alpine` testing image and exec into it
1. From inside the container, execute any of the following targets:
    - `make sign` - push and sign an image
    - `make annotate` - same as `make sign`, but with annotations
    - `make verify` - verify a pushed + signed image
    - `make verify_annotate` - same as `make verify`, but with annotations

There's multiple variables that can be tweaked within the `Makefile`, so definitely poke around.

## Containerfile.alpine

This is used to build `kkeekk/cosign`, the image used for testing cosign.

Some jank was required to properly be able to use docker within the container. To start:

- Install `docker-cli` to have all the docker commands within the container
- Volume mount the host `docker.sock` into the container, allowing docker commands to execute

This is great, docker commands work within the container. Except we're running as `root` inside the container, which can be annoying.

For example, mounting a host directory into the container, generating files within the container, and then not being able to see them without `chown`-ing them.

To solve that, the Makefile:

- Determines the GID of the `docker` group on the host
    - `$(shell getent group docker | cut -d: -f3)`
- Determines the UID/GID of the user on the host
    - `$(shell id -u)` and `$(shell id -g)`
- Pass in these IDs into `docker build`

Once in the `Containerfile`:

- Create a new group with the same GID as the host user's group
- Create a new user with the same UID as the host user, and add it to the previously created group
- Create a `docker` group with the same GID as the `docker` group on the host
- Add the newly created user to the previously created `docker` group
- Set the newly created user as the active user when running the image

Now the image can be ran with full access to docker with a simple:

- `docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock <image name>`

Also, if a host directory is mounted in, any created files will have the same UID:GID as the host user. Double win!

## Example output

`cosign sign`
```
cosign sign -y --key cosign.key ttl.sh/27f40d36-6d9c-4fbd-8e83-474a34bf4edc@sha256:28a07c2d3d7824b0e6e9c12930b6cb18609f5e002aa284d759528a3615a633cc

... some terms and stuff ...

tlog entry created with index: 115519903
Pushing signature to: ttl.sh/27f40d36-6d9c-4fbd-8e83-474a34bf4edc
```

`cosign sign` with annotations
```
cosign sign -y --key cosign.key -a name=6372cfae-4aa7-452f-a79d-9b6aa65b0c6a -a tag=1hr -a date=2024-07-26T04:08:16+00:00 ttl.sh/6372cfae-4aa7-452f-a79d-9b6aa65b0c6a@sha256:28a07c2d3d7824b0e6e9c12930b6cb18609f5e002aa284d759528a3615a633cc

... some terms and stuff ...

tlog entry created with index: 115510934
Pushing signature to: ttl.sh/6372cfae-4aa7-452f-a79d-9b6aa65b0c6a
```

`cosign verify`
- Note: The json output was sent through `jq` to format it nicely and then pasted
```
cosign verify --key cosign.pub ttl.sh/6372cfae-4aa7-452f-a79d-9b6aa65b0c6a:1hr

Verification for ttl.sh/6372cfae-4aa7-452f-a79d-9b6aa65b0c6a:1hr --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key

[
  {
    "critical": {
      "identity": {
        "docker-reference": "ttl.sh/6372cfae-4aa7-452f-a79d-9b6aa65b0c6a"
      },
      "image": {
        "docker-manifest-digest": "sha256:28a07c2d3d7824b0e6e9c12930b6cb18609f5e002aa284d759528a3615a633cc"
      },
      "type": "cosign container image signature"
    },
    "optional": {
      "Bundle": {
        "SignedEntryTimestamp": "MEUCIQCz4f0Zw5fmmYp538R5jW1UkakBafYz4FNblD76rUywWwIgMt1KvNrRphPXEh4ztsFe1slvVMGQgArt3LDMkvBgU6w=",
        "Payload": {
          "body": "eyJhcGlWZXJzaW9uIjoiMC4wLjEiLCJraW5kIjoiaGFzaGVkcmVrb3JkIiwic3BlYyI6eyJkYXRhIjp7Imhhc2giOnsiYWxnb3JpdGhtIjoic2hhMjU2IiwidmFsdWUiOiI5NjQxZWEwNWFlOWUzNmJlYmI5NDdmMGU2YmNiNmIzNDYwYjQ1NmQ1NTBmY2ZhMTBjMDA5YjRiNTlmZTVjMjYwIn19LCJzaWduYXR1cmUiOnsiY29udGVudCI6Ik1FVUNJRnN4aXpsU09CSDAweC9DM29UWHdOL0JBVnQ4VElZakEwNkxDV2t4YnV2RkFpRUExNDRDTy9vdkZsci8zby9XYVM4VC93TmFLY2dUWElYRFl3dUkzSTBrZGRJPSIsInB1YmxpY0tleSI6eyJjb250ZW50IjoiTFMwdExTMUNSVWRKVGlCUVZVSk1TVU1nUzBWWkxTMHRMUzBLVFVacmQwVjNXVWhMYjFwSmVtb3dRMEZSV1VsTGIxcEplbW93UkVGUlkwUlJaMEZGUkVsUmJIcDNRMUl2YVdaVFRtMVNjeTluVFcxS01rUlVVVlU1TUFwVEsySnFla0owY0VSWU5rTkhOV2Q0Vm5NMU1VTnVWak5HTmpKeVRGQjFRVzl3VFVkRGFIQmxLME41ZGpBNFdsWlBkMDVFUmtZNVRHdDNQVDBLTFMwdExTMUZUa1FnVUZWQ1RFbERJRXRGV1MwdExTMHRDZz09In19fX0=",
          "integratedTime": 1721966897,
          "logIndex": 115510934,
          "logID": "c0d23d6ad406973f9559f3ba2d1ca01f84147d8ffc5b8445c224f98b9591801d"
        }
      },
      "date": "2024-07-26T04:08:16+00:00",
      "name": "6372cfae-4aa7-452f-a79d-9b6aa65b0c6a",
      "tag": "1hr"
    }
  }
]
```

`cosign verify` with annotations
- Note: The json output was sent through `jq` to format it nicely and then pasted
```
cosign verify --key cosign.pub -a name=f71f46b8-e392-46c6-ae36-23c92ff39a2d ttl.sh/f71f46b8-e392-46c6-ae36-23c92ff39a2d:1hr

Verification for ttl.sh/f71f46b8-e392-46c6-ae36-23c92ff39a2d:1hr --
The following checks were performed on each of these signatures:
  - The specified annotations were verified.
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The signatures were verified against the specified public key

[
  {
    "critical": {
      "identity": {
        "docker-reference": "ttl.sh/f71f46b8-e392-46c6-ae36-23c92ff39a2d"
      },
      "image": {
        "docker-manifest-digest": "sha256:28a07c2d3d7824b0e6e9c12930b6cb18609f5e002aa284d759528a3615a633cc"
      },
      "type": "cosign container image signature"
    },
    "optional": {
      "Bundle": {
        "SignedEntryTimestamp": "MEYCIQCNm496fVAgIFUAOvQaI7myOGvXIGTvPEdzwblnAloUCgIhAOILSRQkGcy7eQcQZPdOCYvUdp7295bCeCv9c9rSVDRm",
        "Payload": {
          "body": "eyJhcGlWZXJzaW9uIjoiMC4wLjEiLCJraW5kIjoiaGFzaGVkcmVrb3JkIiwic3BlYyI6eyJkYXRhIjp7Imhhc2giOnsiYWxnb3JpdGhtIjoic2hhMjU2IiwidmFsdWUiOiJlMTY4MDZhODRkNGNhZDU3M2VjMGI4ODQzZjAyZWMyMjY1NTYzZTk3M2M4ODVlZWU0Nzg4OWM4ZWQwNTIyMWExIn19LCJzaWduYXR1cmUiOnsiY29udGVudCI6Ik1FVUNJSGU3enBtVFVYZys5dGwvNlhqSkVIb094L1l1QjNudGFuY25PUzQ5MWFib0FpRUFrYWo3eEVXbXJxdmJTK2lORUhlMHRESVdrYWpDRVhJNlk1MDBOVEt0UlJ3PSIsInB1YmxpY0tleSI6eyJjb250ZW50IjoiTFMwdExTMUNSVWRKVGlCUVZVSk1TVU1nUzBWWkxTMHRMUzBLVFVacmQwVjNXVWhMYjFwSmVtb3dRMEZSV1VsTGIxcEplbW93UkVGUlkwUlJaMEZGU2pkc1pWTjFaVGhDZGpCdFZqZHZjSE5VVUhnelIxbE5RMWRIVHdwVlRHVnpOMjAzZWxsc1VVWlhkMjVYS3psblJWQXdZMjR3VkhrdlRsWnVTamg2VWtsc1RtYzJjVlJ4WjBOck9HNDJaeTh5VUZkdFJWbEJQVDBLTFMwdExTMUZUa1FnVUZWQ1RFbERJRXRGV1MwdExTMHRDZz09In19fX0=",
          "integratedTime": 1721968644,
          "logIndex": 115520316,
          "logID": "c0d23d6ad406973f9559f3ba2d1ca01f84147d8ffc5b8445c224f98b9591801d"
        }
      },
      "date": "2024-07-26T04:37:23+00:00",
      "name": "f71f46b8-e392-46c6-ae36-23c92ff39a2d",
      "tag": "1hr"
    }
  }
]
```