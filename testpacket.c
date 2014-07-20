#include "rpacket.h"
#include "wpacket.h"



int main(){
	wpacket_t wpk = NEW_WPK(64);
	wpk_write_string(wpk,"12345");
	wpk_write_string(wpk,"12345");
	wpk_write_string(wpk,"12345");
	wpk_write_string(wpk,"12345");
	wpk_write_string(wpk,"12345");
	wpk_write_string(wpk,"123");
	wpk_write_uint32(wpk,100);

	rpacket_t rpk = rpk_create_by_other((struct packet*)wpk);
	printf("%u\n",reverse_read_uint32(rpk));

	return 0;

}
