# Rook

## Issues

- timeout mount volume https://github.com/rook/rook/issues/1501

- manual create replica pool <http://docs.ceph.com/docs/mimic/rados/operations/pools/#create-a-pool>
- `ceph osd pool create replicapool 128`
- `ceph osd lspools`
- `rbd create replicapool/test --size 10`
- `rbd info replicapool/test`