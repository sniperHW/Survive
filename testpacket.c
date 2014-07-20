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
	wpacket_t wpk2 = wpk_create_by_rpacket(rpk);
	wpk_write_uint32(wpk2,100);
	wpk_destroy(wpk);
	rpk_destroy(rpk);
	wpk_destroy(wpk2);
	printf("%d\n",buffer_count);
	

	return 0;

}
