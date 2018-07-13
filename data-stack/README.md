# Data stack

Tools to manage machine learning (and more in general) big data sets

## Requirements

- Store data in k8s
- Applications in k8s access data sets
- Users can access data sets from local machines
- Authorization and authentication

## Possible stack

- Minio is the object store (minio, S3 compatible open source)
- Apache drill to query object and create metadata repository
- Fuse S3 file system

## Open points

- minio has an auth based on tokens, how to use ldap?
- Apache drill supports auth on some data stores, but not on S3 (minio excluded)

## Other projects

- Alluxio, virtual file system, auth only in commercial edition
- [Dreemio](https://www.dremio.com/compare/dremio-compared-sql-execution-engine-alternatives), like apache drill with much more features, auth only in commercial edition

