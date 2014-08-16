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
#ifndef _PACKET_H
#define _PACKET_H

#include "buffer.h"
#include "kn_list.h"
#include <stdint.h>
#include <assert.h>

enum{
	WPACKET   = 1,
	RPACKET   = 2,
	RAWPACKET = 3,
};

typedef struct packet
{
    kn_list_node  listnode;
    buffer_t      buf;    
    uint32_t      begin_pos;
    uint32_t      data_size;
    uint8_t       type;
}packet,*packet_t;

void _destroy_packet(packet_t);

#define destroy_packet(p) _destroy_packet((packet_t)p)

#define packet_next(p)   ((packet_t)p)->listnode.next
#define packet_buf(p)    ((packet_t)p)->buf
#define packet_type(p)   ((packet_t)p)->type
#define packet_begpos(p) ((packet_t)p)->begin_pos
#define packet_datasize(p) ((packet_t)p)->data_size
#endif
