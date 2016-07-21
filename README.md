# NDSLabs GlusterFS Cluster Filesystem Support 
Tooling and support for GlusterFS servers and clients.
##Supports:
* container as client - mount in container
* container as server - serve from container
* host as client - mount in host via container
* host as server - serve from host via container 

## Commands
* **usage** - Consult this prior to use for instructions for you image - default command
```
docker run --rm -it ndslabs/gluster usage
```
* **server** - Serves a Consult usage or see below
* **client** - Consult usage or see below
*  
* Author/Maintainer:  raila@illinois.edu
```--cap-add SYS_ADMIN --device /dev/fuse```


## Prerequisites
* A cluster of system with mountable storage - GlusterFS filesystem nodes
* A cluster of client systems that will mount GlusterFS volumes that the storage cluster serves
* A basic understanding of GlusterFS 

# Conventions
* LVM volume group per "pool" using one physical volume per volume group at provisioning
* Multiple LV's can be cut from the VG for bricks in the pool - i.e. multiple independent cluster volumes from the same pool
* LV's formatted as xfs -i size=512 - to support attributes in a single inode
* LVM VG names match the cluster volume "name" identifying their "pool" on each server, 
* Brick local LV mounts on the servers are under /var/glfs/<pool>/brick<#> - Supports known cluster kernel OS's
* Each brick has a top-level brick directory containing the data, from Gluster conventions
  * WARNING: writing directly to a brick will corrupt the volume
* Example node with 2 storage mount points and 2 pools:
```
Disk devices: /dev/vdb1 /dev/vdb1
Volume Groups:  HA scratch
PV assignments: vdb1->HA, vdb2->scratch
LVs and mounts:  /dev/mapper/HA-brick0:/var/glfs/HA/brick0  /dev/mapper/scratch-brick0:/var/glfs/scratch/brick0
```

# Host storage setup - within the chroot in container
* initialize PVs, create VG and LV per-pool, format the bricks, and mount
```
pvcreate /dev/vdb1
pvcreate /dev/vdb2
vgcreate HA /dev/vdb1
vgcreate scratch /dev/vdb2
lvcreate -l 100%VG HA -n brick0
lvcreate -l 100%VG scratch -n brick0
mkfs.xfs -i size=512 /dev/mapper/HA-brick0
mkfs.xfs -i size=512 /dev/mapper/scratch-brick0
echo "/dev/mapper/HA-brick0 /var/glfs/HA/brick0 xfs defaults 1 2" >> /etc/fstab 
echo "/dev/mapper/scratch-brick0 /var/glfs/scratch/brick0 xfs defaults 1 2" >> /etc/fstab 
mkdir /var/glfs/HA/brick0/brick
mkdir /var/glfs/scatch/brick0/brick
```

# GFS setup

## Start the gluster server container and exec into it 
```
docker run --restart=always --name=glusterfs --net=host --privileged -v /:/hostroot -v /var/glfs:/var/glfs -d ndslabs/gluster
docker exec -it glusterfs bash
# chroot /hostroot
```

## Initialize the cluster FS servers
```
gluster peer probe 172.16.1.161
gluster peer probe 172.16.1.162 
gluster peer probe 172.16.1.163 
  ...
```

## Create the Gluster volumes per pool
* In this example,  dvol1 is a striped volume and rvol1 is a replicated volume
```
gluster volume create scratch transport tcp 172.16.1.162:/var/glfs/scratch/brick0 172.16.1.163:/var/glfs/scratch/brick0
gluster volume create rvol1 replica 2 transport tcp 172.16.1.162:/var/glfs/HA/brick0 172.16.1.163:/var/glfs/HA/brick0
gluster volume start HA
gluster volume start scratch
cluster volume list
```

# Client mounts
```
mount -t glusterfs 172.16.1.163:/scratch /scratch
```

# Enabling per-directory quotas
```
gluster vol quota HA enable
gluster volume quota HA limit-usage /qtest 5GB
gluster volume quota HA list
    root@gs1:/run/gluster/dvol1/qtest# gluster volume quota dvol1 list
    Path                   Hard-limit Soft-limit   Used  Available
    --------------------------------------------------------------------------------
    /qtest                                     5.0GB       80%       5.0GB  0Bytes
```
* Test from client
```
root@gscli:/var/nds/dvol1/qtest# dd if=/dev/urandom of=random.img count=1024 bs=10M
dd: error writing 'random.img': Disk quota exceeded
dd: closing output file 'random.img': Disk quota exceeded
```

# Mounting inside a container with the glusterfs client:
```
docker run --privileged -it ndslabs/gluster bash
mkdir -p /var/nds/dvol1
mkdir -p /dev/nds/dvol2
mount -t glusterfs 172.16.1.163:/scratch /scratch
```

# Mounting in-host via container
```
docker run -v /:/hostroot --net=host --privileged -it ndslabs/gluster bash
mkdir -p /hostroot/scratch
mount -t glusterfs 172.16.1.163:/scratch /hostroot/scratch
```

# Gluster client for Kubernetes cluster filesystem support
* start node kubelets with --allow-privileged=true
* All nodes need KUBE_ALLOW_PRIV="--allow-privileged=true" in /etc/kubernetes/config
* Run as a Daemon Set, see <http://kubernetes.io/docs/admin/daemons>
* Quick-start templates:  <https://github.com/wattsteve>

## Temporary pending documentation update:
SC run:  docker run --net=host --pid=host --privileged  -v /dev:/dev  -v /var:/var -v /run:/run -v /:/media/host -it  ndslabs/gluster bash

