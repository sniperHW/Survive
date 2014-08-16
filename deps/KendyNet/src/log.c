#include "log.h"
#include "kn_list.h"
#include "kn_thread.h"
#include <string.h>
#include "kendynet.h"
#include "kn_atomic.h"
#include "kn_thread_mailbox.h"

static pthread_once_t g_log_key_once = PTHREAD_ONCE_INIT;
static kn_thread_mailbox_t g_logthd_mailbox;//log线程的邮箱 

static kn_thread_t    g_log_thd = NULL;
static engine_t       g_log_engine = NULL;

static kn_list        g_log_file_list;
static kn_mutex_t     g_mtx_log_file_list;


const char *log_lev_str[] = {
	"INFO",
	"ERROR"
};

struct logfile{
	kn_list_node node;
	char     filename[256];
	FILE    *file;
	uint32_t total_size;
};

struct log_item{
	logfile_t _logfile;
	char content[0];
};

DEF_LOG(sys_log,SYSLOG_NAME);
IMP_LOG(sys_log);


int32_t write_prefix(char *buf,uint8_t loglev)
{
	struct timespec tv;
    clock_gettime (CLOCK_REALTIME, &tv);
	struct tm _tm;
	localtime_r(&tv.tv_sec, &_tm);
	return sprintf(buf,"[%s]%04d-%02d-%02d-%02d:%02d:%02d.%03d[%x]:",log_lev_str[loglev],
				   _tm.tm_year+1900,_tm.tm_mon+1,_tm.tm_mday,_tm.tm_hour,_tm.tm_min,_tm.tm_sec,
				   (int32_t)tv.tv_nsec/1000000,(uint32_t)pthread_self());
}

static void on_mail(kn_thread_mailbox_t *from,void *mail){
	struct log_item *item = mail;
	if(item->_logfile->file == NULL || item->_logfile->total_size > MAX_FILE_SIZE)
	{
		if(item->_logfile->total_size){
			fclose(item->_logfile->file);
			item->_logfile->total_size = 0;
		}
		//还没创建文件
		char filename[128];
		struct timespec tv;
		clock_gettime(CLOCK_REALTIME, &tv);
		struct tm _tm;
		localtime_r(&tv.tv_sec, &_tm);
		snprintf(filename,128,"%s-%04d-%02d-%02d %02d.%02d.%02d.%03d.log",item->_logfile->filename,
			   _tm.tm_year+1900,_tm.tm_mon+1,_tm.tm_mday,_tm.tm_hour,_tm.tm_min,_tm.tm_sec,(int32_t)tv.tv_nsec/1000000);
		item->_logfile->file = fopen(filename,"w+");
		if(!item->_logfile->file){
			printf("%d\n",errno);
			return;
		}
	}
	fprintf(item->_logfile->file,"%s\n",item->content);
	//fflush(item->_logfile->file);
	item->_logfile->total_size += strlen(item->content);	
}

static void* log_routine(void *arg){
	kn_setup_mailbox(g_log_engine,MODE_FAST,on_mail);
	g_logthd_mailbox = kn_self_mailbox();
	FENCE;
	kn_engine_run(g_log_engine);
	//向所有打开的日志文件写入"log close success"
	struct logfile *l = NULL;
	char buf[128];
	kn_mutex_lock(g_mtx_log_file_list);
	while((l = (struct logfile*)kn_list_pop(&g_log_file_list)) != NULL)
	{
		if(l->file){
			int32_t size = write_prefix(buf,LOG_INFO);
			snprintf(&buf[size],128-size,"log close success");
			fprintf(l->file,"%s\n",buf);
		}
	}	
	kn_mutex_unlock(g_mtx_log_file_list); 	
	return NULL;
}

static void on_process_end()
{
	kn_stop_engine(g_log_engine);
	if(g_log_thd)
		kn_thread_join(g_log_thd);
	kn_release_engine(g_log_engine);
}

void _write_log(logfile_t logfile,const char *content)
{
	uint32_t content_len = strlen(content)+1;
	struct log_item *item = calloc(1,sizeof(*item) + content_len);
	item->_logfile = logfile;
	strncpy(item->content,content,content_len);	
	while(!g_logthd_mailbox.ptr)
		FENCE;	
	int8_t ret = kn_send_mail(g_logthd_mailbox,item,free);
	if(ret != 0) free(item);
}
			           
static void log_once_routine(){
	make_empty_ident((ident*)&g_logthd_mailbox);
	kn_list_init(&g_log_file_list);
	g_mtx_log_file_list = kn_mutex_create();
	g_log_engine = kn_new_engine();
	g_log_thd = kn_create_thread(THREAD_JOINABLE);
	kn_thread_start_run(g_log_thd,log_routine,NULL);
	atexit(on_process_end);
}

logfile_t create_logfile(const char *filename)
{
	pthread_once(&g_log_key_once,log_once_routine);
	logfile_t _logfile = calloc(1,sizeof(*_logfile));
	strncpy(_logfile->filename,filename,256);
	kn_mutex_lock(g_mtx_log_file_list);
	kn_list_pushback(&g_log_file_list,(kn_list_node*)_logfile);
	kn_mutex_unlock(g_mtx_log_file_list);	
	return _logfile;
}


void write_log(logfile_t logfile,const char *content){
	_write_log(logfile,content);
}

void write_sys_log(const char *content){
	_write_log(GET_LOGFILE(sys_log),content);
}
