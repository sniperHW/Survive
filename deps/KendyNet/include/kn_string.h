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
#ifndef _KN_STRING_H
#define _KN_TRING_H
#include <stdint.h>

typedef struct kn_string* kn_string_t;

kn_string_t kn_new_string(const char *);

void     kn_release_string(kn_string_t);

const char *kn_to_cstr(kn_string_t);

void     kn_string_copy(kn_string_t,kn_string_t,uint32_t n);

int32_t  kn_string_len(kn_string_t);

void     kn_string_append(kn_string_t,const char*);


#endif