
GLUSTER_SO		= /usr/local/lib/glustermount.so

$(GLUSTER_SO): glustermount.c
	${CC} -Wall -march=native -fPIC -shared -o $@ $< -ldl
	echo /usr/local/lib/glustermount.so >> /etc/ld.so.preload

