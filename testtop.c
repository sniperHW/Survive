#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include "mytop.h"


int main(){
	addfilter("Xorg");
	while(1){
		system("clear");
		printf("%s",top());
		sleep(1);
	}
	return 0;
}
