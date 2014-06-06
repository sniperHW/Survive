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

#ifndef _WORDFILTER_H
#define _WORDFILTER_H

#include "kn_string.h"

typedef struct wordfilter *wordfilter_t;

wordfilter_t wordfilter_new(const char **forbidwords);

string_t     wordfiltrate(wordfilter_t,const char *str,char replace);

//如果输入串中不含屏蔽字返回1,否则返回0
uint8_t      isvaildword(wordfilter_t,const char *str);


#endif
