FROM ubuntu:xenial

RUN apt-get update && \
    apt-get install -y apt-utils python-software-properties software-properties-common && \
    add-apt-repository ppa:gluster/glusterfs-3.9 &&\
    apt-get -y update && apt-get -y dist-upgrade &&\
    apt-get -y install host curl net-tools lsof &&\
    apt-get -y install glusterfs-server glusterfs-client attr &&\
    apt-get -y install xfsprogs &&\
    apt-get -y install build-essential &&\
    apt-get -y install lvm2 &&\
    apt-get -y install inotify-tools &&\
    apt-get -y clean all && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* &&\
    mv /var/lib/glusterd /var/lib/glusterd.stock &&\
    mv /etc/glusterfs /etc/glusterfs.stock &&\
    mv /var/log/glusterfs /var/log/glusterfs.stock

ADD FILES.gluster /

EXPOSE 24007 24008 49152 49153 49154 49155 49156 49157 49158 49159 49160
