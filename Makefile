HUB_IMAGES		:=	gluster
IMAGES			:=	$(HUB_IMAGES)

GLUSTER_SO		= FILES.gluster/usr/local/lib/glustermount.so
IMAGE.gluster: 	$(GLUSTER_SO)

include Makefile.nds

$(GLUSTER_SO): glustermount.c
	${CC} -Wall -fPIC -shared -o $@ $< -ldl -D_FILE_OFFSET_BITS=64

