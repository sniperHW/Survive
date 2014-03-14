#ifndef _GAMEDB_H
#define _GAMEDB_H

#include "core/db/asyndb.h"
#include "../avatar.h"

int32_t init_gamedb_module();

int32_t gamedb_request(player_t,db_request_t request);

#endif
