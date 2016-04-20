# NDSLabs Cluster Filesystem Support via GlusterFS
Author/Maintainer:  raila@illinois.edu

This image contains tooling for GlusterFS on NDSLabs clusters:
  ** glusterfs server
  ** glusterfs client
  ** OpenStack CLI for openstack integration

# Prerequisites
  ** A cluster of system with storage mounted - GlusterFS filesystem nodes
  ** A cluster of client systems that will mount GlusterFS volumes that the storage cluster serves

# Bootstrapping server nodes 
  ** Start the image: docker run --restart=always --net=host --privileged -v /:/hostroot -v /var/bricks:/var/bricks -it ndslabs/gluster bash 
  ** Add the mapped volumes into lvm - for each volume:
  *** pvcreate <device-path>
  ** Create the volume group with all of the PV's:  vgcreate glfs <device-path> <device-path> 

# Create and mount the desired bricks - See GlusterFS documentation for variations on striping/replication
  ** Allocate the LV's on the server nodes - the example shown uses symmetric allocation across 2 nodes and 4 bricks
  *** lvcreate -L 250G vgfs brick0; lvcreate -L 250G glfs -n brick1
  *** mkfs.xfs -i size=512 /dev/glfs/brick0; mkfs.xfs -i size=512 /dev/glfs/brick1
  *** echo "/dev/glfs/brick0 /var/bricks/0 xfs defaults 1 2" >> /etc/fstab 
  *** echo "/dev/glfs/brick1 /var/bricks/1 xfs defaults 1 2" >> /etc/fstab 
  *** mount -a
  *** mkdir /var/bricks/0/brick; mkdir /var/bricks/1/brick

# Initialize the cluster and create the volumes:
  ** gluster peer probe <ip's of all other gluster server nodes> 
  *** ex:  gluster peer probe 172.16.1.163
  ** gluster volume create dvol1 transport tcp 172.16.1.162:/var/bricks/0/brick 172.16.1.163:/var/bricks/0/brick
  ** gluster volume create rvol1 replica 2 transport tcp 172.16.1.162:/var/bricks/1/brick 172.16.1.163:/var/bricks/1/brick
  *** In this example,  dvol1 is a striped volume and rvol1 is a replicated volume
  ** gluster volume start dvol1; gluster start rvol1
  ** Volumes are ready to mount, check with glusterfs volume list 

# Enabling per-directory quotas
  ** gluster vol quota dvol1 enable
  ** gluster volume quota dvol1 limit-usage /qtest 5GB
  ** gluster volume quota dvol1 list
    > root@gs1:/run/gluster/dvol1/qtest# gluster volume quota dvol1 list
    > Path                   Hard-limit Soft-limit   Used  Available
    > --------------------------------------------------------------------------------
    > /qtest                                     5.0GB       80%       5.0GB  0Bytes
  ** On client under /qtest:  
  > root@gscli:/var/nds/dvol1/qtest# dd if=/dev/urandom of=random.img count=1024 bs=10M
  > dd: error writing 'random.img': Disk quota exceeded
  > dd: closing output file 'random.img': Disk quota exceeded

# Mounting inside a container with the glusterfs client:
  ** docker run --privileged -it ndslabs/gluster bash
  ** mkdir -p /var/nds/dvol1
  ** mkdir -p /dev/nds/dvol2
  ** mount -t glusterfs 172.16.1.163:/dvol1 /var/nds/dvol1
  ** mount -t glusterfs 172.16.1.163:/dvol1 /var/nds/dvol1

# Mounting to the host 
  ** docker run -v /:/hostroot --net=host --privileged -it ndslabs/gluster bash
  ** mkdir -p /var/nds/dvol1
  ** mkdir -p /dev/nds/dvol2
  ** mount -t glusterfs 172.16.1.163:/dvol1 /var/nds/dvol1
  ** mount -t glusterfs 172.16.1.163:/dvol1 /var/nds/dvol1

# Gluster client for Kubernetes cluster filesystem support
  ** start node kubelets with --allow-privileged=true
  ** All nodes need KUBE_ALLOW_PRIV="--allow-privileged=true" in /etc/kubernetes/config
  ** Run as a Daemon Set, see <http://kubernetes.io/docs/admin/daemons>
  ** Community pod templates:  <https://github.com/wattsteve>
