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
#ifndef _SINGLETON_H
#define _SINGLETON_H

#include <pthread.h>

#define DECLARE_SINGLETON(TYPE)\
        extern pthread_once_t TYPE##_key_once;\
        extern TYPE*          TYPE##_instance;\
        extern void (*TYPE##_fn_destroy)(void*);\
        void TYPE##_on_process_end();\
        void TYPE##_once_routine()


#define IMPLEMENT_SINGLETON(TYPE,CREATE_FUNCTION,DESTYOY_FUNCTION)\
        pthread_once_t TYPE##_key_once = PTHREAD_ONCE_INIT;\
        TYPE*          TYPE##_instance = NULL;\
        void (*TYPE##_fn_destroy)(void*) = DESTYOY_FUNCTION;\
        void TYPE##_on_process_end(){\
        	TYPE##_fn_destroy((void*)TYPE##_instance);\
        }\
        void TYPE##_once_routine(){\
            TYPE##_instance = CREATE_FUNCTION();\
            if(TYPE##_fn_destroy) atexit(TYPE##_on_process_end);\
        }

#define GET_INSTANCE(TYPE)\
        ({do pthread_once(&TYPE##_key_once,TYPE##_once_routine);\
            while(0);\
            TYPE##_instance;})

#endif
