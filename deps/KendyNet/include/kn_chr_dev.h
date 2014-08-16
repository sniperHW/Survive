#ifndef _KN_CHR_DEV_H
#define _KN_CHR_DEV_H
//字符设备

#include "kendynet.h"

handle_t kn_new_chrdev(int fd);
//如果close非0,则同时调用close(fd)
int      kn_release_chrdev(handle_t,int close);

int      kn_chrdev_fd(handle_t);

int      kn_chrdev_associate(handle_t,
						     engine_t,
						     void (*cb_ontranfnish)(handle_t,st_io*,int,int),
						     void (*destry_stio)(st_io*));
						   
						   
int      kn_chrdev_write(handle_t,st_io*);
int      kn_chrdev_read(handle_t,st_io*);						   

#endif
