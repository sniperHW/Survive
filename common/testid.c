#include <stdio.h>
#include <stdlib.h>
#include "idmgr.h"

int main(){
	idmgr_t _id = new_idmgr(1,10);

	if(0 == release_id(_id,10)){
		printf("release_id success\n");
	}
	int i = 0;
	for(; i < 8;++i){
		uint32_t identity;
		if(0 == get_id(_id,&identity)){
			printf("getid %u\n",identity);
		}else{
			printf("cannot getid\n");
		}
	}

	i = 10;
	for(; i > 0; --i){
		if(0 == release_id(_id,i)){
			printf("release_id success:%d\n",i);
		}		
	}

	i = 0;
	for(; i < 11;++i){
		uint32_t identity;
		if(0 == get_id(_id,&identity)){
			printf("getid %u\n",identity);
		}else{
			printf("cannot getid\n");
		}
	}	


	return 0;
}

