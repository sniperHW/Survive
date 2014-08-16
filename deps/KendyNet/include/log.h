/*
    Copyright (C) <2012>  <huangweilook@21cn.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/
#ifndef _LOG_H
#define _LOG_H

#include "singleton.h"
#include <stdint.h>
/*
* 一个简单的日志系统
*/

enum{
	LOG_INFO = 0,
	LOG_ERROR,
};

#define MAX_FILE_SIZE 1024*1024*256  //日志文件最大大小256MB

struct logfile;
typedef struct logfile* logfile_t;

logfile_t create_logfile(const char *filename);

void write_log(logfile_t,const char *context);

#define SYSLOG_NAME "syslog"

//写入系统日志,默认文件名由SYSLOG_NAME定义
void write_sys_log(const char *content);

int32_t write_prefix(char *buf,uint8_t loglev);

#define  MAX_LOG_SIZE 65535

//日志格式[INFO|ERROR]yyyy-mm-dd-hh:mm:ss.ms:content
#define LOG(LOGFILE,LOGLEV,...)\
            do{\
                char xx___buf[MAX_LOG_SIZE];\
                int32_t size = write_prefix(xx___buf,LOGLEV);\
                snprintf(&xx___buf[size],MAX_LOG_SIZE-size,__VA_ARGS__);\
                write_log(LOGFILE,xx___buf);\
            }while(0)

#define SYS_LOG(LOGLEV,...)\
            do{\
                char xx___buf[MAX_LOG_SIZE];\
                int32_t size = write_prefix(xx___buf,LOGLEV);\
                snprintf(&xx___buf[size],MAX_LOG_SIZE-size,__VA_ARGS__);\
                write_sys_log(xx___buf);\
            }while(0)


#define DEF_LOG(LOGNAME,LOGFILENAME)\
        typedef struct{  logfile_t _logfile;}LOGNAME;\
        static inline LOGNAME *LOGNAME##create_function(){\
        	LOGNAME *tmp = calloc(1,sizeof(*tmp));\
        	tmp->_logfile = create_logfile(LOGFILENAME);\
        	return tmp;\
        }\
        DECLARE_SINGLETON(LOGNAME)

#define IMP_LOG(LOGNAME) IMPLEMENT_SINGLETON(LOGNAME,LOGNAME##create_function,NULL)

#define GET_LOGFILE(LOGNAME) GET_INSTANCE(LOGNAME)->_logfile           


#endif
