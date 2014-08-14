/* top.c - Source file:         show Linux processes */
/*
 * Copyright (c) 2002, by:      James C. Warner
 *    All rights reserved.      8921 Hilloway Road
 *                              Eden Prairie, Minnesota 55347 USA
 *                             <warnerjc@worldnet.att.net>
 *
 * This file may be used subject to the terms and conditions of the
 * GNU Library General Public License Version 2, or any later version
 * at your option, as published by the Free Software Foundation.
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Library General Public License for more details.
 * 
 * For their contributions to this program, the author wishes to thank:
 *    Albert D. Cahalan, <albert@users.sf.net>
 *    Craig Small, <csmall@small.dropbear.id.au>
 *
 * Changes by Albert Cahalan, 2002-2004.
 */
#include <sys/ioctl.h>
#include <sys/resource.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#undef tab

#include <time.h>
#include <unistd.h>
#include <values.h>

#include "proc/devname.h"
#include "proc/wchan.h"
#include "proc/procps.h"
#include "proc/readproc.h"
#include "proc/escape.h"
#include "proc/sig.h"
#include "proc/sysinfo.h"
#include "proc/version.h"
#include "proc/whattime.h"
#include "top.h"

char **filter;
int    filter_size = 0;

static char outbuf[4096];

/*######  Miscellaneous global stuff  ####################################*/

        /* The original and new terminal attributes */
//static struct termios Savedtty,
//                      Rawtty;
//static int Ttychanged = 0;

        /* Name of user config file (dynamically constructed) and our
           'Current' rcfile contents, initialized with defaults but may be
           overridden with the local rcfile (old or new-style) values */
static char  Rc_name [OURPATHSZ];
static RCF_t Rc = DEF_RCFILE;

        /* The run-time acquired page size */
static unsigned Page_size;
static unsigned page_to_kb_shift;

        /* SMP Irix/Solaris mode */
static int  Cpu_tot;
static double pcpu_max_value;  // usually 99.9, for %CPU display
        /* assume no IO-wait stats, overridden if linux 2.5.41 */
static const char *States_fmts = STATES_line2x4;

        /* Specific process id monitoring support */
static pid_t Monpids [MONPIDMAX] = { 0 };
static int   Monpidsidx = 0;

        /* A postponed error message */
static char Msg_delayed [SMLBUFSIZ];
static int  Msg_awaiting = 0;

// This is the select() timeout. Clear it in sig handlers to avoid a race.
// (signal happens just as we are about to select() and thus does not
// break us out of the select(), causing us to delay until timeout)
static volatile struct timeval tv;
#define ZAP_TIMEOUT do{tv.tv_usec=0; tv.tv_sec=0;}while(0);

        /* Configurable Display support ##################################*/

        /* Current screen dimensions.
           note: the number of processes displayed is tracked on a per window
                 basis (see the WIN_t).  Max_lines is the total number of
                 screen rows after deducting summary information overhead. */
        /* Current terminal screen size. */
static int Screen_cols, Screen_rows, Max_lines;

// set to 1 if writing to the last column would be troublesome
// (we don't distinguish the lowermost row from the other rows)
static int avoid_last_column;

        /* This is really the number of lines needed to display the summary
           information (0 - nn), but is used as the relative row where we
           stick the cursor between frames. */
static int Msg_row;

        /* Global/Non-windows mode stuff that is NOT persistent */
static int No_ksyms = -1,       // set to '0' if ksym avail, '1' otherwise
           PSDBopen = 0,        // set to '1' if psdb opened (now postponed)
           Batch = 0,           // batch mode, collect no input, dumb output
           Loops = -1,          // number of iterations, -1 loops forever
           Secure_mode = 0;     // set if some functionality restricted

        /* Some cap's stuff to reduce runtime calls --
           to accomodate 'Batch' mode, they begin life as empty strings */
static char  Cap_clr_eol    [CAPBUFSIZ],
             Cap_clr_eos    [CAPBUFSIZ],
             Cap_clr_scr    [CAPBUFSIZ],
             Cap_rmam       [CAPBUFSIZ],
             Cap_smam       [CAPBUFSIZ],
             Cap_curs_norm  [CAPBUFSIZ],
             Cap_curs_huge  [CAPBUFSIZ],
             Cap_home       [CAPBUFSIZ],
             Cap_norm       [CAPBUFSIZ],
             Cap_reverse    [CAPBUFSIZ],
             Caps_off       [CAPBUFSIZ];
static int   Cap_can_goto = 0;

        /* Some optimization stuff, to reduce output demands...
           The Pseudo_ guys are managed by wins_resize and frame_make.  They
           are exploited in a macro and represent 90% of our optimization.
           The Stdout_buf is transparent to our code and regardless of whose
           buffer is used, stdout is flushed at frame end or if interactive. */
static char *Pseudo_scrn;
static int   Pseudo_row, Pseudo_cols, Pseudo_size;

        /* ////////////////////////////////////////////////////////////// */
        /* Special Section: multiple windows/field groups  ---------------*/

        /* The pointers to our four WIN_t's, and which of those is considered
           the 'current' window (ie. which window is associated with any summ
           info displayed and to which window commands are directed) */
static WIN_t Winstk [GROUPSMAX],
             *Curwin;

        /* Frame oriented stuff that can't remain local to any 1 function
           and/or that would be too cumbersome managed as parms,
           and/or that are simply more efficiently handled as globals
           (first 2 persist beyond a single frame, changed infrequently) */
static int       Frames_libflags;       // PROC_FILLxxx flags (0 = need new)
//atic int       Frames_maxcmdln;       // the largest from the 4 windows
static unsigned  Frame_maxtask;         // last known number of active tasks
                                        // ie. current 'size' of proc table
static unsigned  Frame_running,         // state categories for this frame
                 Frame_sleepin,
                 Frame_stopped,
                 Frame_zombied;
static float     Frame_tscale;          // so we can '*' vs. '/' WHEN 'pcpu'
static int       Frame_srtflg,          // the subject window's sort direction
                 Frame_ctimes,          // the subject window's ctimes flag
                 Frame_cmdlin;          // the subject window's cmdlin flag
        /* ////////////////////////////////////////////////////////////// */


/*######  Sort callbacks  ################################################*/

        /*
         * These happen to be coded in the same order as the enum 'pflag'
         * values.  Note that 2 of these routines serve double duty --
         * 2 columns each.
         */

SCB_NUMx(P_PID, XXXID)
SCB_NUMx(P_PPD, ppid)
SCB_STRx(P_URR, ruser)
SCB_NUMx(P_UID, euid)
SCB_STRx(P_URE, euser)
SCB_STRx(P_GRP, egroup)
SCB_NUMx(P_TTY, tty)
SCB_NUMx(P_PRI, priority)
SCB_NUMx(P_NCE, nice)
SCB_NUMx(P_CPN, processor)
SCB_NUM1(P_CPU, pcpu)
                                        // also serves P_TM2 !
static int sort_P_TME (const proc_t **P, const proc_t **Q)
{
   if (Frame_ctimes) {
      if ( ((*P)->cutime + (*P)->cstime + (*P)->utime + (*P)->stime)
        < ((*Q)->cutime + (*Q)->cstime + (*Q)->utime + (*Q)->stime) )
           return SORT_lt;
      if ( ((*P)->cutime + (*P)->cstime + (*P)->utime + (*P)->stime)
        > ((*Q)->cutime + (*Q)->cstime + (*Q)->utime + (*Q)->stime) )
           return SORT_gt;
   } else {
      if ( ((*P)->utime + (*P)->stime) < ((*Q)->utime + (*Q)->stime))
         return SORT_lt;
      if ( ((*P)->utime + (*P)->stime) > ((*Q)->utime + (*Q)->stime))
         return SORT_gt;
   }
   return SORT_eq;
}

SCB_NUM1(P_VRT, size)
SCB_NUM2(P_SWP, size, resident)
SCB_NUM1(P_RES, resident)               // also serves P_MEM !
SCB_NUM1(P_COD, trs)
SCB_NUM1(P_DAT, drs)
SCB_NUM1(P_SHR, share)
SCB_NUM1(P_FLT, maj_flt)
SCB_NUM1(P_DRT, dt)
SCB_NUMx(P_STA, state)

static int sort_P_CMD (const proc_t **P, const proc_t **Q)
{
   /* if a process doesn't have a cmdline, we'll consider it a kernel thread
      -- since displayed tasks are given special treatment, we must too */
   if (Frame_cmdlin && ((*P)->cmdline || (*Q)->cmdline)) {
      if (!(*Q)->cmdline) return Frame_srtflg * -1;
      if (!(*P)->cmdline) return Frame_srtflg;
      return Frame_srtflg *
         strncmp((*Q)->cmdline[0], (*P)->cmdline[0], (unsigned)Curwin->maxcmdln);
   }
   // this part also handles the compare if both are kernel threads
   return Frame_srtflg * strcmp((*Q)->cmd, (*P)->cmd);
}

SCB_NUM1(P_WCH, wchan)
SCB_NUM1(P_FLG, flags)

        /* ///////////////////////////////// special sort for prochlp() ! */
static int sort_HST_t (const HST_t *P, const HST_t *Q)
{
   return P->pid - Q->pid;
}


/*######  Tiny useful routine(s)  ########################################*/


// This routine simply formats whatever the caller wants and
// returns a pointer to the resulting 'const char' string...
static const char *fmtmk (const char *fmts, ...) __attribute__((format(printf,1,2)));
static const char *fmtmk (const char *fmts, ...)
{
   static char buf[BIGBUFSIZ];          // with help stuff, our buffer
   va_list va;                          // requirements exceed 1k

   va_start(va, fmts);
   vsnprintf(buf, sizeof(buf), fmts, va);
   va_end(va);
   return (const char *)buf;
}

void putp(const char *str){
	
}


// This guy is just our way of avoiding the overhead of the standard
// strcat function (should the caller choose to participate)
static inline char *scat (char *restrict dst, const char *restrict src)
{
   while (*dst) dst++;
   while ((*(dst++) = *(src++)));
   return --dst;
}


// Trim the rc file lines and any 'open_psdb_message' result which arrives
// with an inappropriate newline (thanks to 'sysmap_mmap')
static char *strim_0 (char *str)
{
   static const char ws[] = "\b\e\f\n\r\t\v\x9b";  // 0x9b is an escape
   char *p;

   if ((p = strpbrk(str, ws))) *p = 0;
   return str;
}


// Show an error, but not right now.
// Due to the postponed opening of ksym, using open_psdb_message,
// if P_WCH had been selected and the program is restarted, the
// message would otherwise be displayed prematurely.
static void msg_save (const char *fmts, ...) __attribute__((format(printf,1,2)));
static void msg_save (const char *fmts, ...)
{
   char tmp[SMLBUFSIZ];
   va_list va;

   va_start(va, fmts);
   vsnprintf(tmp, sizeof(tmp), fmts, va);
   va_end(va);
      /* we'll add some extra attention grabbers to whatever this is */
   snprintf(Msg_delayed, sizeof(Msg_delayed), "\a***  %s  ***", strim_0(tmp));
   Msg_awaiting = 1;
}


/*
 * Show lines with specially formatted elements, but only output
 * what will fit within the current screen width.
 *    Our special formatting consists of:
 *       "some text <_delimiter_> some more text <_delimiter_>...\n"
 *    Where <_delimiter_> is a single byte in the range of:
 *       \01 through \10  (in decimalizee, 1 - 8)
 *    and is used to select an 'attribute' from a capabilities table
 *    which is then applied to the *preceding* substring.
 * Once recognized, the delimiter is replaced with a null character
 * and viola, we've got a substring ready to output!  Strings or
 * substrings without delimiters will receive the Cap_norm attribute.
 *
 * Caution:
 *    This routine treats all non-delimiter bytes as displayable
 *    data subject to our screen width marching orders.  If callers
 *    embed non-display data like tabs or terminfo strings in our
 *    glob, a line will truncate incorrectly at best.  Worse case
 *    would be truncation of an embedded tty escape sequence.
 *
 *    Tabs must always be avoided or our efforts are wasted and
 *    lines will wrap.  To lessen but not eliminate the risk of
 *    terminfo string truncation, such non-display stuff should
 *    be placed at the beginning of a "short" line.
 *    (and as for tabs, gimme 1 more color then no worries, mate) */
static void show_special (int interact, const char *glob)
{ 
	strcat(outbuf,glob);
}

/*
 * Do some scaling stuff.
 * We'll interpret 'num' as one of the following types and
 * try to format it to fit 'width'.
 *    SK_no (0) it's a byte count
 *    SK_Kb (1) it's kilobytes
 *    SK_Mb (2) it's megabytes
 *    SK_Gb (3) it's gigabytes
 *    SK_Tb (4) it's terabytes  */
static const char *scale_num (unsigned long num, const int width, const unsigned type)
{
      /* kilobytes, megabytes, gigabytes, terabytes, duh! */
   static double scale[] = { 1024.0, 1024.0*1024, 1024.0*1024*1024, 1024.0*1024*1024*1024, 0 };
      /* kilo, mega, giga, tera, none */
#ifdef CASEUP_SCALE
   static char nextup[] =  { 'K', 'M', 'G', 'T', 0 };
#else
   static char nextup[] =  { 'k', 'm', 'g', 't', 0 };
#endif
   static char buf[TNYBUFSIZ];
   double *dp;
   char *up;

      /* try an unscaled version first... */
   if (width >= snprintf(buf, sizeof(buf), "%lu", num)) return buf;

      /* now try successively higher types until it fits */
   for (up = nextup + type, dp = scale; *dp; ++dp, ++up) {
         /* the most accurate version */
      if (width >= snprintf(buf, sizeof(buf), "%.1f%c", num / *dp, *up))
         return buf;
         /* the integer version */
      if (width >= snprintf(buf, sizeof(buf), "%ld%c", (unsigned long)(num / *dp), *up))
         return buf;
   }
      /* well shoot, this outta' fit... */
   return "?";
}


#include <pwd.h>

static int selection_type;
static uid_t selection_uid;

// FIXME: this is "temporary" code we hope
static int good_uid(const proc_t *restrict const pp){
   switch(selection_type){
   case 'p':
      return 1;
   case 0:
      return 1;
   case 'U':
      if (pp->ruid == selection_uid) return 1;
      if (pp->suid == selection_uid) return 1;
      if (pp->fuid == selection_uid) return 1;
      // FALLTHROUGH
   case 'u':
      if (pp->euid == selection_uid) return 1;
      // FALLTHROUGH
   default:
      ;  // don't know what it is; find bugs fast
   }
   return 0;
}

/*######  Library Alternatives  ##########################################*/

        /*
         * Handle our own memory stuff without the risk of leaving the
         * user's terminal in an ugly state should things go sour. */

static void *alloc_c (unsigned numb) MALLOC;
static void *alloc_c (unsigned numb)
{
   void * p;

   if (!numb) ++numb;
   if (!(p = calloc(1, numb)))
     return NULL;
   return p;
}

static void *alloc_r (void *q, unsigned numb) MALLOC;
static void *alloc_r (void *q, unsigned numb)
{
   void *p;

   if (!numb) ++numb;
   if (!(p = realloc(q, numb)))
		return NULL;
   return p;
}


        /*
         * This guy's modeled on libproc's 'five_cpu_numbers' function except
         * we preserve all cpu data in our CPU_t array which is organized
         * as follows:
         *    cpus[0] thru cpus[n] == tics for each separate cpu
         *    cpus[Cpu_tot]        == tics from the 1st /proc/stat line */
static CPU_t *cpus_refresh (CPU_t *cpus)
{
   static FILE *fp = NULL;
   int i;
   int num;
   // enough for a /proc/stat CPU line (not the intr line)
   char buf[SMLBUFSIZ];

   /* by opening this file once, we'll avoid the hit on minor page faults
      (sorry Linux, but you'll have to close it for us) */
   if (!fp) {
      if (!(fp = fopen("/proc/stat", "r")))
		 return NULL;
      /* note: we allocate one more CPU_t than Cpu_tot so that the last slot
               can hold tics representing the /proc/stat cpu summary (the first
               line read) -- that slot supports our View_CPUSUM toggle */
      cpus = alloc_c((1 + Cpu_tot) * sizeof(CPU_t));
   }
   rewind(fp);
   fflush(fp);

   // first value the last slot with the cpu summary line
   if (!fgets(buf, sizeof(buf), fp)) return NULL;
   cpus[Cpu_tot].x = 0;  // FIXME: can't tell by kernel version number
   cpus[Cpu_tot].y = 0;  // FIXME: can't tell by kernel version number
   cpus[Cpu_tot].z = 0;  // FIXME: can't tell by kernel version number
   num = sscanf(buf, "cpu %Lu %Lu %Lu %Lu %Lu %Lu %Lu %Lu",
      &cpus[Cpu_tot].u,
      &cpus[Cpu_tot].n,
      &cpus[Cpu_tot].s,
      &cpus[Cpu_tot].i,
      &cpus[Cpu_tot].w,
      &cpus[Cpu_tot].x,
      &cpus[Cpu_tot].y,
      &cpus[Cpu_tot].z
   );
   if (num < 4)
		return NULL;

   // and just in case we're 2.2.xx compiled without SMP support...
   if (Cpu_tot == 1) {
      cpus[1].id = 0;
      memcpy(cpus, &cpus[1], sizeof(CPU_t));
   }

   // now value each separate cpu's tics
   for (i = 0; 1 < Cpu_tot && i < Cpu_tot; i++) {
      if (!fgets(buf, sizeof(buf), fp)) return NULL;
      cpus[i].x = 0;  // FIXME: can't tell by kernel version number
      cpus[i].y = 0;  // FIXME: can't tell by kernel version number
      cpus[i].z = 0;  // FIXME: can't tell by kernel version number
      num = sscanf(buf, "cpu%u %Lu %Lu %Lu %Lu %Lu %Lu %Lu %Lu",
         &cpus[i].id,
         &cpus[i].u, &cpus[i].n, &cpus[i].s, &cpus[i].i, &cpus[i].w, &cpus[i].x, &cpus[i].y, &cpus[i].z
      );
      if (num < 4)
		return NULL;
   }
   return cpus;
}


        /*
         * Refresh procs *Helper* function to eliminate yet one more need
         * to loop through our darn proc_t table.  He's responsible for:
         *    1) calculating the elapsed time since the previous frame
         *    2) counting the number of tasks in each state (run, sleep, etc)
         *    3) maintaining the HST_t's and priming the proc_t pcpu field
         *    4) establishing the total number tasks for this frame */
static void prochlp (proc_t *this)
{
   static HST_t    *hist_sav = NULL;
   static HST_t    *hist_new = NULL;
   static unsigned  hist_siz = 0;       // number of structs
   static unsigned  maxt_sav;           // prior frame's max tasks
   TIC_t tics;

   if (unlikely(!this)) {
      static struct timeval oldtimev;
      struct timeval timev;
      struct timezone timez;
      HST_t *hist_tmp;
      float et;

      gettimeofday(&timev, &timez);
      et = (timev.tv_sec - oldtimev.tv_sec)
         + (float)(timev.tv_usec - oldtimev.tv_usec) / 1000000.0;
      oldtimev.tv_sec = timev.tv_sec;
      oldtimev.tv_usec = timev.tv_usec;

      // if in Solaris mode, adjust our scaling for all cpus
      Frame_tscale = 100.0f / ((float)Hertz * (float)et * (Rc.mode_irixps ? 1 : Cpu_tot));
      maxt_sav = Frame_maxtask;
      Frame_maxtask = Frame_running = Frame_sleepin = Frame_stopped = Frame_zombied = 0;

      // reuse memory each time around
      hist_tmp = hist_sav;
      hist_sav = hist_new;
      hist_new = hist_tmp;
      // prep for our binary search by sorting the last frame's HST_t's
      qsort(hist_sav, maxt_sav, sizeof(HST_t), (QFP_t)sort_HST_t);
      return;
   }

   switch (this->state) {
      case 'R':
         Frame_running++;
         break;
      case 'S':
      case 'D':
         Frame_sleepin++;
         break;
      case 'T':
         Frame_stopped++;
         break;
      case 'Z':
         Frame_zombied++;
         break;
   }

   if (unlikely(Frame_maxtask+1 >= hist_siz)) {
      hist_siz = hist_siz * 5 / 4 + 100;  // grow by at least 25%
      hist_sav = alloc_r(hist_sav, sizeof(HST_t) * hist_siz);
      hist_new = alloc_r(hist_new, sizeof(HST_t) * hist_siz);
   }
   /* calculate time in this process; the sum of user time (utime) and
      system time (stime) -- but PLEASE dont waste time and effort on
      calcs and saves that go unused, like the old top! */
   hist_new[Frame_maxtask].pid  = this->tid;
   hist_new[Frame_maxtask].tics = tics = (this->utime + this->stime);

#if 0
{  int i;
   int lo = 0;
   int hi = maxt_sav - 1;

   // find matching entry from previous frame and make ticks elapsed
   while (lo <= hi) {
      i = (lo + hi) / 2;
      if (this->tid < hist_sav[i].pid)
         hi = i - 1;
      else if (likely(this->tid > hist_sav[i].pid))
         lo = i + 1;
      else {
         tics -= hist_sav[i].tics;
         break;
      }
   }
}
#else
{
   HST_t tmp;
   const HST_t *ptr;
   tmp.pid = this->tid;
   ptr = bsearch(&tmp, hist_sav, maxt_sav, sizeof tmp, sort_HST_t);
   if(ptr) tics -= ptr->tics;
}
#endif

   // we're just saving elapsed tics, to be converted into %cpu if
   // this task wins it's displayable screen row lottery... */
   this->pcpu = tics;
// if (Frames_maxcmdln) { }
   // shout this to the world with the final call (or us the next time in)
   Frame_maxtask++;
}


        /*
         * This guy's modeled on libproc's 'readproctab' function except
         * we reuse and extend any prior proc_t's.  He's been customized
         * for our specific needs and to avoid the use of <stdarg.h> */
static proc_t **procs_refresh (proc_t **table, int flags)
{
#define PTRsz  sizeof(proc_t *)
#define ENTsz  sizeof(proc_t)
   static unsigned savmax = 0;          // first time, Bypass: (i)
   proc_t *ptsk = (proc_t *)-1;         // first time, Force: (ii)
   unsigned curmax = 0;                 // every time  (jeeze)
   PROCTAB* PT;
   static int show_threads_was_enabled = 0; // optimization

   prochlp(NULL);                       // prep for a new frame
   if (Monpidsidx)
      PT = openproc(flags, Monpids);
   else
      PT = openproc(flags);

   // i) Allocated Chunks:  *Existing* table;  refresh + reuse
   if (!(CHKw(Curwin, Show_THREADS))) {
      while (curmax < savmax) {
         if (table[curmax]->cmdline) {
            unsigned idx;
            // Skip if Show_THREADS was never enabled
            if (show_threads_was_enabled) {
               for (idx = curmax + 1; idx < savmax; idx++) {
                  if (table[idx]->cmdline == table[curmax]->cmdline)
                     table[idx]->cmdline = NULL;
               }
            }
            free(*table[curmax]->cmdline);
            table[curmax]->cmdline = NULL;
         }
         if (unlikely(!(ptsk = readproc(PT, table[curmax])))) break;
         prochlp(ptsk);                    // tally & complete this proc_t
         ++curmax;
      }
   }
   else {                          // show each thread in a process separately
      while (curmax < savmax) {
         proc_t *ttsk;
         if (unlikely(!(ptsk = readproc(PT, NULL)))) break;
         show_threads_was_enabled = 1;
         while (curmax < savmax) {
            unsigned idx;
            if (table[curmax]->cmdline) {
               // threads share the same cmdline storage.  'table' is
               // qsort()ed, so must look through the rest of the table.
               for (idx = curmax + 1; idx < savmax; idx++) {
                  if (table[idx]->cmdline == table[curmax]->cmdline)
                     table[idx]->cmdline = NULL;
               }
               free(*table[curmax]->cmdline);  // only free once
               table[curmax]->cmdline = NULL;
            }
            if (!(ttsk = readtask(PT, ptsk, table[curmax]))) break;
            prochlp(ttsk);
            ++curmax;
         }
         free(ptsk);  // readproc() proc_t not used
      }
   }

   // ii) Unallocated Chunks:  *New* or *Existing* table;  extend + fill
   if (!(CHKw(Curwin, Show_THREADS))) {
      while (ptsk) {
         // realloc as we go, keeping 'table' ahead of 'currmax++'
         table = alloc_r(table, (curmax + 1) * PTRsz);
         // here, readproc will allocate the underlying proc_t stg
         if (likely(ptsk = readproc(PT, NULL))) {
            prochlp(ptsk);                 // tally & complete this proc_t
            table[curmax++] = ptsk;
         }
      }
   }
   else {                          // show each thread in a process separately
      while (ptsk) {
         proc_t *ttsk;
         if (likely(ptsk = readproc(PT, NULL))) {
            show_threads_was_enabled = 1;
            while (1) {
               table = alloc_r(table, (curmax + 1) * PTRsz);
               if (!(ttsk = readtask(PT, ptsk, NULL))) break;
               prochlp(ttsk);
               table[curmax++] = ttsk;
            }
            free(ptsk);   // readproc() proc_t not used
         }
      }
   }
   closeproc(PT);

   // iii) Chunkless:  make 'eot' entry, after ensuring proc_t exists
   if (curmax >= savmax) {
      table = alloc_r(table, (curmax + 1) * PTRsz);
      // here, we must allocate the underlying proc_t stg ourselves
      table[curmax] = alloc_c(ENTsz);
      savmax = curmax + 1;
   }
   // this frame's end, but not necessarily end of allocated space
   table[curmax]->tid = -1;
   return table;

#undef PTRsz
#undef ENTsz
}

/*######  Field Table/RCfile compatability support  ######################*/

// from either 'stat' or 'status' (preferred), via bits not otherwise used
#define L_EITHER   PROC_SPARE_1
// These are the Fieldstab.lflg values used here and in reframewins.
// (own identifiers as documentation and protection against changes)
#define L_stat     PROC_FILLSTAT
#define L_statm    PROC_FILLMEM
#define L_status   PROC_FILLSTATUS
#define L_CMDLINE  L_EITHER | PROC_FILLARG
#define L_EUSER    PROC_FILLUSR
#define L_RUSER    L_status | PROC_FILLUSR
#define L_GROUP    L_status | PROC_FILLGRP
#define L_NONE     0
// for reframewins and summary_show 1st pass
#define L_DEFAULT  PROC_FILLSTAT

// a temporary macro, soon to be undef'd...
#define SF(f) (QFP_t)sort_P_ ## f

        /* These are our gosh darn 'Fields' !
           They MUST be kept in sync with pflags !!
           note: for integer data, the length modifiers found in .fmts may
                 NOT reflect the true field type found in proc_t -- this plus
                 a cast when/if displayed provides minimal width protection. */
static FLD_t Fieldstab[] = {
/* .lflg anomolies:
      P_UID, L_NONE  - natural outgrowth of 'stat()' in readproc        (euid)
      P_CPU, L_stat  - never filled by libproc, but requires times      (pcpu)
      P_CMD, L_stat  - may yet require L_CMDLINE in reframewins  (cmd/cmdline)
      L_EITHER       - must L_status, else 64-bit math, __udivdi3 on 32-bit !
      keys   head           fmts     width   scale  sort   desc                     lflg
     ------  -----------    -------  ------  -----  -----  ----------------------   -------- */
   { "AaAa", "   PID",      " %5u",     -1,    -1, SF(PID), "Process Id",           L_NONE   },
   { "BbBb", "  PPID",      " %5u",     -1,    -1, SF(PPD), "Parent Process Pid",   L_EITHER },
   { "CcQq", " RUSER   ",   " %-8.8s",  -1,    -1, SF(URR), "Real user name",       L_RUSER  },
   { "DdCc", "  UID",       " %4u",     -1,    -1, SF(UID), "User Id",              L_NONE   },
   { "EeDd", " USER    ",   " %-8.8s",  -1,    -1, SF(URE), "User Name",            L_EUSER  },
   { "FfNn", " GROUP   ",   " %-8.8s",  -1,    -1, SF(GRP), "Group Name",           L_GROUP  },
   { "GgGg", " TTY     ",   " %-8.8s",   8,    -1, SF(TTY), "Controlling Tty",      L_stat   },
   { "HhHh", "  PR",        " %3d",     -1,    -1, SF(PRI), "Priority",             L_stat   },
   { "IiIi", "  NI",        " %3d",     -1,    -1, SF(NCE), "Nice value",           L_stat   },
   { "JjYy", " #C",         " %2u",     -1,    -1, SF(CPN), "Last used cpu (SMP)",  L_stat   },
   { "KkEe", " %CPU",       " %#4.1f",  -1,    -1, SF(CPU), "CPU usage",            L_stat   },
   { "LlWw", "   TIME",     " %6.6s",    6,    -1, SF(TME), "CPU Time",             L_stat   },
   { "MmRr", "    TIME+ ",  " %9.9s",    9,    -1, SF(TME), "CPU Time, hundredths", L_stat   },
   { "NnFf", " %MEM",       " %#4.1f",  -1,    -1, SF(RES), "Memory usage (RES)",   L_statm  },
   { "OoMm", "  VIRT",      " %5.5s",    5, SK_Kb, SF(VRT), "Virtual Image (kb)",   L_statm  },
   { "PpOo", " SWAP",       " %4.4s",    4, SK_Kb, SF(SWP), "Swapped size (kb)",    L_statm  },
   { "QqTt", "  RES",       " %4.4s",    4, SK_Kb, SF(RES), "Resident size (kb)",   L_statm  },
   { "RrKk", " CODE",       " %4.4s",    4, SK_Kb, SF(COD), "Code size (kb)",       L_statm  },
   { "SsLl", " DATA",       " %4.4s",    4, SK_Kb, SF(DAT), "Data+Stack size (kb)", L_statm  },
   { "TtPp", "  SHR",       " %4.4s",    4, SK_Kb, SF(SHR), "Shared Mem size (kb)", L_statm  },
   { "UuJj", " nFLT",       " %4.4s",    4, SK_no, SF(FLT), "Page Fault count",     L_stat   },
   { "VvSs", " nDRT",       " %4.4s",    4, SK_no, SF(DRT), "Dirty Pages count",    L_statm  },
   { "WwVv", " S",          " %c",      -1,    -1, SF(STA), "Process Status",       L_EITHER },
   // next entry's special: '.head' will be formatted using table entry's own
   //                       '.fmts' plus runtime supplied conversion args!
   { "XxXx", " COMMAND",    " %-*.*s",  -1,    -1, SF(CMD), "Command name/line",    L_EITHER },
   { "YyUu", " WCHAN    ",  " %-9.9s",  -1,    -1, SF(WCH), "Sleeping in Function", L_stat   },
   // next entry's special: the 0's will be replaced with '.'!
   { "ZzZz", " Flags   ",   " %08lx",   -1,    -1, SF(FLG), "Task Flags <sched.h>", L_stat   },
#if 0
   { "..Qq", "   A",        " %4.4s",    4, SK_no, SF(PID), "Accessed Page count",  L_stat   },
   { "..Nn", "  TRS",       " %4.4s",    4, SK_Kb, SF(PID), "Code in memory (kb)",  L_stat   },
   { "..Rr", "  WP",        " %4.4s",    4, SK_no, SF(PID), "Unwritable Pages",     L_stat   },
   { "Jj[{", " #C",         " %2u",     -1,    -1, SF(CPN), "Last used cpu (SMP)",  L_stat   },
   { "..\\|"," Bad",        " %2u",     -1,    -1, SF(CPN), "-- must ignore | --",  0        },
   { "..]}", " Bad",        " %2u",     -1,    -1, SF(CPN), "-- not used --",       0        },
   { "..^~", " Bad",        " %2u",     -1,    -1, SF(CPN), "-- not used --",       0        },
#endif
};
#undef SF


        /* All right, those-that-follow -- Listen Up!
         * For the above table keys and the following present/future rc file
         * compatibility support, you have Mr. Albert D. Cahalan to thank.
         * He must have been in a 'Christmas spirit'.  Were it left to me,
         * this top would never have gotten that close to the former top's
         * crufty rcfile.  Not only is it illogical, it's odoriferous !
         */

        // used as 'to' and/or 'from' args in the ft_xxx utilities...
#define FT_NEW_fmt 0
#define FT_OLD_fmt 2

// '$HOME/Rc_name' contains multiple lines - 2 global + 3 per window.
//   line 1: an eyecatcher, with a shameless advertisement
//   line 2: an id, Mode_altcsr, Mode_irixps, Delay_time and Curwin.
// For each of the 4 windows:
//   line a: contains winname, fieldscur
//   line b: contains winflags, sortindx, maxtasks
//   line c: contains summclr, msgsclr, headclr, taskclr
//   line d: if present, would crash procps-3.1.1
static int rc_read_new (const char *const buf, RCF_t *rc) {
   int i;
   int cnt;
   const char *cp;

   cp = strstr(buf, "\n\n" RCF_EYECATCHER);
   if (!cp) return -1;
   cp = strchr(cp + 2, '\n');
   if (!cp++) return -2;

   cnt = sscanf(cp, "Id:a, Mode_altscr=%d, Mode_irixps=%d, Delay_time=%f, Curwin=%d\n",
      &rc->mode_altscr, &rc->mode_irixps, &rc->delay_time, &rc->win_index
   );
   if (cnt != 4) return -3;
   cp = strchr(cp, '\n');
   if (!cp++) return -4;

   for (i = 0; i < GROUPSMAX; i++) {
      RCW_t *ptr = &rc->win[i];
      cnt = sscanf(cp, "%3s\tfieldscur=%31s\n", ptr->winname, ptr->fieldscur);
      if (cnt != 2) return 5+100*i;  // OK to have less than 4 windows
      if (WINNAMSIZ <= strlen(ptr->winname)) return -6;
      if (strlen(DEF_FIELDS) != strlen(ptr->fieldscur)) return -7;
      cp = strchr(cp, '\n');
      if (!cp++) return -(8+100*i);

      cnt = sscanf(cp, "\twinflags=%d, sortindx=%u, maxtasks=%d \n",
         &ptr->winflags, &ptr->sortindx, &ptr->maxtasks
      );
      if (cnt != 3) return -(9+100*i);
      cp = strchr(cp, '\n');
      if (!cp++) return -(10+100*i);

      cnt = sscanf(cp, "\tsummclr=%d, msgsclr=%d, headclr=%d, taskclr=%d \n",
         &ptr->summclr, &ptr->msgsclr, &ptr->headclr, &ptr->taskclr
      );
      if (cnt != 4) return -(11+100*i);
      cp = strchr(cp, '\n');
      if (!cp++) return -(12+100*i);
      while (*cp == '\t') {  // skip unknown per-window settings
        cp = strchr(cp, '\n');
        if (!cp++) return -(13+100*i);
      }
   }
   return 13;
}



static int rc_read_old (const char *const buf, RCF_t *rc) {
   const char std[] = "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZzJj......";
   const char old[] = "AaBb..CcDd..GgHhIiYyEeWw..FfMmOoTtKkLlPpJjSsVvXxUuZz[{QqNnRr";
   unsigned u;
   const char *cp;
   unsigned c_show = 0;
   int badchar = 0;     // allow a limited number of duplicates and junk

   char scoreboard[256];
   memset(scoreboard, '\0', sizeof scoreboard);

   cp = buf+2;  // skip the "\n\n" we stuck at the beginning
   u = 0;
   for (;;) {
      const char *tmp;
      int c = *cp++;
      if (u+1 >= sizeof rc->win[0].fieldscur) return -1;
      if (c == '\0') return -2;
      if (c == '\n') break;
      if (c & ~0x7f) return -3;
      if (~c & 0x20) c_show |= 1 << (c & 0x1f); // 0x20 means lowercase means hidden
      if (scoreboard[c|0xe0u]) badchar++;       // duplicates not allowed
      scoreboard[c|0xe0u]++;
      tmp = strchr(old,c);
      if (!tmp) continue;
      c = *((tmp-old)+std);
      if (c == '.') continue;
      if (scoreboard[c&0x1fu]) badchar++;       // duplicates not allowed
      scoreboard[c&0x1fu]++;
      rc->win[0].fieldscur[u++] = c;
   }
   rc->win[0].fieldscur[u++] = '\0';
   if (u < 21) return -6;  // catch junk, not good files (had 23 chars in one)
   if (u > 33) return -7;  // catch junk, not good files (had 29 chars in one)
// fprintf(stderr, "badchar: %d\n", badchar); sleep(2);
   if (badchar > 8) return -8;          // too much junk
   if (!c_show) return -9;              // nothing was shown

   // rest of file is optional, but better look right if it exists
   if (!*cp) return 12;
   if (*cp < '2' || *cp > '9') return -13; // stupid, and why isn't '1' valid?
   rc->delay_time = *cp - '0';

   memset(scoreboard, '\0', sizeof(scoreboard));
   for (;;) {
      int c = *++cp & 0xffu;    // protect scoreboard[] from negative char
      if (!c) return -14;       // not OK to hit EOL w/o '\n'
      if (c == '\n') break;
      switch (c) {
         case ' ':
         case '.':
         case '0' ... '9':
            return -15;                 // not supposed to have digits here

//       case 's':                      // mostly for global rcfile
//          rc->mode_secure = 1;
//          break;
         case 'S':
            rc->win[0].winflags |= Show_CTIMES;
            break;
         case 'c':
            rc->win[0].winflags |= Show_CMDLIN;
            break;
         case 'i':
            rc->win[0].winflags &= ~Show_IDLEPS;
            break;
         case 'H':
            rc->win[0].winflags |= Show_THREADS;
            break;
         case 'm':
            rc->win[0].winflags &= ~View_MEMORY;
            break;
         case 'l':
            rc->win[0].winflags &= ~View_LOADAV;
            break;
         case 't':
            rc->win[0].winflags &= ~View_STATES;
            break;
         case 'I':
            rc->mode_irixps = 0;
            break;

         case 'M':
            c = 0; // for scoreboard
            rc->win[0].sortindx = P_MEM;
            break;
         case 'P':
            c = 0; // for scoreboard
            rc->win[0].sortindx = P_CPU;
            break;
         case 'A':                      // supposed to be start_time
            c = 0; // for scoreboard
            rc->win[0].sortindx = P_PID;
            break;
         case 'T':
            c = 0; // for scoreboard
            rc->win[0].sortindx = P_TM2;
            break;
         case 'N':
            c = 0; // for scoreboard
            rc->win[0].sortindx = P_PID;
            break;

         default:
            // just ignore it, except for the scoreboard of course
            break;
      }
      if (scoreboard[c]) return -16;    // duplicates not allowed
      scoreboard[c] = 1;
   }
   return 17;
}

/*######  Startup routines  ##############################################*/

// No mater what *they* say, we handle the really really BIG and
// IMPORTANT stuff upon which all those lessor functions depend!
static void before (char *me)
{
   int i;

      /* setup our program name -- big! */
   //Myname = strrchr(me, '/');
   //if (Myname) ++Myname; else Myname = me;

      /* establish cpu particulars -- even bigger! */
   Cpu_tot = smp_num_cpus;
   if (linux_version_code > LINUX_VERSION(2, 5, 41))
      States_fmts = STATES_line2x5;
   if (linux_version_code >= LINUX_VERSION(2, 6, 0))  // grrr... only some 2.6.0-testX :-(
      States_fmts = STATES_line2x6;
   if (linux_version_code >= LINUX_VERSION(2, 6, 11))
      States_fmts = STATES_line2x7;

      /* get virtual page size -- nearing huge! */
   Page_size = getpagesize();
   i = Page_size;
   while(i>1024){
     i >>= 1;
     page_to_kb_shift++;
   }

   pcpu_max_value = 99.9;

   Fieldstab[P_CPN].head = " P";
   Fieldstab[P_CPN].fmts = " %1u";
   if(smp_num_cpus>9){
      Fieldstab[P_CPN].head = "  P";
      Fieldstab[P_CPN].fmts = " %2u";
   }
   if(smp_num_cpus>99){
      Fieldstab[P_CPN].head = "   P";
      Fieldstab[P_CPN].fmts = " %3u";
   }
   if(smp_num_cpus>999){
      Fieldstab[P_CPN].head = "    P";
      Fieldstab[P_CPN].fmts = " %4u";
   }

   {
      static char pid_fmt[6];
      unsigned pid_digits = get_pid_digits();
      if(pid_digits<4) pid_digits=4;
      snprintf(pid_fmt, sizeof pid_fmt, " %%%uu", pid_digits);
      Fieldstab[P_PID].fmts = pid_fmt;
      Fieldstab[P_PID].head = "        PID" + 10 - pid_digits;
      Fieldstab[P_PPD].fmts = pid_fmt;
      Fieldstab[P_PPD].head = "       PPID" + 10 - pid_digits;
   }
}


// Config file read *helper* function.
// Anything missing won't show as a choice in the field editor,
// so make sure there is exactly one of each letter.
//
// Due to Rik blindly accepting damem's broken patches, procps-2.0.1x
// has 3 ("three"!!!) instances of "#C", "LC", or "CPU". Fix that too.
static void confighlp (char *fields) {
   unsigned upper[PFLAGSSIZ];
   unsigned lower[PFLAGSSIZ];
   char c;
   char *cp;

   memset(upper, '\0', sizeof upper);
   memset(lower, '\0', sizeof lower);

   cp = fields;
   for (;;) {
      c = *cp++;
      if (!c) break;
      if(isupper(c)) upper[c&0x1f]++;
      else           lower[c&0x1f]++;
   }

   c = 'a';
   while (c <= 'z') {
      if (upper[c&0x1f] && lower[c&0x1f]) {
         lower[c&0x1f] = 0;             // got both, so wipe out unseen column
         for (;;) {
            cp = strchr(fields, c);
            if (cp) memmove(cp, cp+1, strlen(cp));
            else break;
         }
      }
      while (lower[c&0x1f] > 1) {               // got too many a..z
         lower[c&0x1f]--;
         cp = strchr(fields, c);
         memmove(cp, cp+1, strlen(cp));
      }
      while (upper[c&0x1f] > 1) {               // got too many A..Z
         upper[c&0x1f]--;
         cp = strchr(fields, toupper(c));
         memmove(cp, cp+1, strlen(cp));
      }
      if (!upper[c&0x1f] && !lower[c&0x1f]) {   // both missing
         lower[c&0x1f]++;
         memmove(fields+1, fields, strlen(fields)+1);
         fields[0] = c;
      }
      c++;
   }
}


// First attempt to read the /etc/rcfile which contains two lines
// consisting of the secure mode switch and an update interval.
// It's presence limits what ordinary users are allowed to do.
// (it's actually an old-style config file)
//
// Then build the local rcfile name and try to read a crufty old-top
// rcfile (whew, odoriferous), which may contain an embedded new-style
// rcfile.   Whether embedded or standalone, new-style rcfile values
// will always override that crufty stuff!
// note: If running in secure mode via the /etc/rcfile,
//       Delay_time will be ignored except for root.
static void configs_read (void)
{
   const RCF_t def_rcf = DEF_RCFILE;
   char fbuf[MEDBUFSIZ];
   int i, fd;
   RCF_t rcf;
   float delay = Rc.delay_time;

   // read part of an old-style config in /etc/toprc
   fd = open(SYS_RCFILESPEC, O_RDONLY);
   if (fd > 0) {
      ssize_t num;
      num = read(fd, fbuf, sizeof(fbuf) - 1);
      if (num > 0) {
         const char *sec = strchr(fbuf, 's');
         const char *eol = strchr(fbuf, '\n');
         if (eol) {
            const char *two = eol + 1;  // line two
            if (sec < eol) Secure_mode = !!sec;
            eol = strchr(two, '\n');
            if (eol && eol > two && isdigit(*two)) Rc.delay_time = atof(two);
         }
      }
      close(fd);
   }

   rcf = def_rcf;
   fd = open(Rc_name, O_RDONLY);
   if (fd > 0) {
      ssize_t num;
      num = read(fd, fbuf+2, sizeof(fbuf) -3);
      if (num > 0) {
         fbuf[0] = '\n';
         fbuf[1] = '\n';
         fbuf[num+2] = '\0';
//fprintf(stderr,"rc_read_old returns %d\n",rc_read_old(fbuf, &rcf));
//sleep(2);
         if (rc_read_new(fbuf, &rcf) < 0) {
            rcf = def_rcf;                       // on failure, maybe mangled
            if (rc_read_old(fbuf, &rcf) < 0) rcf = def_rcf;
         }
         delay = rcf.delay_time;
      }
      close(fd);
   }

   // update Rc defaults, establish a Curwin and fix up the window stack
   Rc.mode_altscr = rcf.mode_altscr;
   Rc.mode_irixps = rcf.mode_irixps;
   if (rcf.win_index >= GROUPSMAX) rcf.win_index = 0;
   Curwin = &Winstk[rcf.win_index];
   for (i = 0; i < GROUPSMAX; i++) {
      memcpy(&Winstk[i].rc, &rcf.win[i], sizeof rcf.win[i]);
      confighlp(Winstk[i].rc.fieldscur);
   }

   if(Rc.mode_irixps && smp_num_cpus>1){
      // good for 100 CPUs per process
      pcpu_max_value = 9999.0;
      Fieldstab[P_CPU].fmts = " %4.0f";
   }

   // lastly, establish the true runtime secure mode and delay time
   if (!getuid()) Secure_mode = 0;
   if (!Secure_mode) Rc.delay_time = delay;
}


/*######  Field Selection/Ordering routines  #############################*/


/*######  Windows/Field Groups support  #################################*/

// For each of the four windows:
//    1) Set the number of fields/columns to display
//    2) Create the field columns heading
//    3) Set maximum cmdline length, if command lines are in use
// In the process, the required PROC_FILLxxx flags will be rebuilt!
static void reframewins (void)
{
   WIN_t *w;
   char *s;
   const char *h;
   int i, needpsdb = 0;

// Frames_libflags = 0;  // should be called only when it's zero
// Frames_maxcmdln = 0;  // to become largest from up to 4 windows, if visible
   w = Curwin;
   do {
      if (!Rc.mode_altscr || CHKw(w, VISIBLE_tsk)) {
         // build window's procflags array and establish a tentative maxpflgs
         for (i = 0, w->maxpflgs = 0; w->rc.fieldscur[i]; i++) {
            if (isupper(w->rc.fieldscur[i]))
               w->procflags[w->maxpflgs++] = w->rc.fieldscur[i] - 'A';
         }

         /* build a preliminary columns header not to exceed screen width
            while accounting for a possible leading window number */
         *(s = w->columnhdr) = '\0';
         if (Rc.mode_altscr) s = scat(s, " ");
         for (i = 0; i < w->maxpflgs; i++) {
            h = Fieldstab[w->procflags[i]].head;
            // oops, won't fit -- we're outta here...
            if (Screen_cols+1 < (int)((s - w->columnhdr) + strlen(h))) break;
            s = scat(s, h);
         }

         // establish the final maxpflgs and prepare to grow the command column
         // heading via maxcmdln - it may be a fib if P_CMD wasn't encountered,
         // but that's ok because it won't be displayed anyway
         w->maxpflgs = i;
         w->maxcmdln = Screen_cols - (strlen(w->columnhdr) - strlen(Fieldstab[P_CMD].head));

         // finally, we can build the true run-time columns header, format the
         // command column heading, if P_CMD is really being displayed, and
         // rebuild the all-important PROC_FILLxxx flags that will be used
         // until/if we're we're called again
         *(s = w->columnhdr) = '\0';
//         if (Rc.mode_altscr) s = scat(s, fmtmk("%d", w->winnum));
         for (i = 0; i < w->maxpflgs; i++) {
            int advance = (i==0) && !Rc.mode_altscr;
            h = Fieldstab[w->procflags[i]].head;
            if (P_WCH == w->procflags[i]) needpsdb = 1;
            if (P_CMD == w->procflags[i]) {
               s = scat(s, fmtmk(Fieldstab[P_CMD].fmts+advance, w->maxcmdln, w->maxcmdln, "COMMAND"/*h*/  ));
               if (CHKw(w, Show_CMDLIN)) {
                  Frames_libflags |= L_CMDLINE;
//                if (w->maxcmdln > Frames_maxcmdln) Frames_maxcmdln = w->maxcmdln;
               }
            } else
               s = scat(s, h+advance);
            Frames_libflags |= Fieldstab[w->procflags[i]].lflg;
         }
         if (Rc.mode_altscr) w->columnhdr[0] = w->winnum + '0';
      }
      if (Rc.mode_altscr) w = w->next;
   } while (w != Curwin);

   // do we need the kernel symbol table (and is it already open?)
   if (needpsdb) {
      if (No_ksyms == -1) {
         No_ksyms = 0;
         if (open_psdb_message(NULL, msg_save))
            No_ksyms = 1;
         else
            PSDBopen = 1;
      }
   }

   if (selection_type=='U') Frames_libflags |= L_status;

   if (Frames_libflags & L_EITHER) {
      Frames_libflags &= ~L_EITHER;
      if (!(Frames_libflags & L_stat)) Frames_libflags |= L_status;
   }
   if (!Frames_libflags) Frames_libflags = L_DEFAULT;
   if (selection_type=='p') Frames_libflags |= PROC_PID;
}


// Set up the raw/incomplete field group windows --
// they'll be finished off after startup completes.
// [ and very likely that will override most/all of our efforts ]
// [               --- life-is-NOT-fair ---                     ]
static void windows_stage1 (void)
{
   WIN_t *w;
   int i;

   for (i = 0; i < GROUPSMAX; i++) {
      w = &Winstk[i];
      w->winnum = i + 1;
      w->rc = Rc.win[i];
      w->captab[0] = Cap_norm;
      w->captab[1] = Cap_norm;
      w->captab[2] = w->cap_bold;
      w->captab[3] = w->capclr_sum;
      w->captab[4] = w->capclr_msg;
      w->captab[5] = w->capclr_pmt;
      w->captab[6] = w->capclr_hdr;
      w->captab[7] = w->capclr_rowhigh;
      w->captab[8] = w->capclr_rownorm;
      w->next = w + 1;
      w->prev = w - 1;
      ++w;
   }
      /* fixup the circular chains... */
   Winstk[3].next = &Winstk[0];
   Winstk[0].prev = &Winstk[3];
   Curwin = Winstk;
}


/*######  Main Screen routines  ##########################################*/

// State display *Helper* function to calc and display the state
// percentages for a single cpu.  In this way, we can support
// the following environments without the usual code bloat.
//    1) single cpu machines
//    2) modest smp boxes with room for each cpu's percentages
//    3) massive smp guys leaving little or no room for process
//       display and thus requiring the cpu summary toggle
static void summaryhlp (CPU_t *cpu, const char *pfx)
{
   // we'll trim to zero if we get negative time ticks,
   // which has happened with some SMP kernels (pre-2.4?)
#define TRIMz(x)  ((tz = (SIC_t)(x)) < 0 ? 0 : tz)
   SIC_t u_frme, s_frme, n_frme, i_frme, w_frme, x_frme, y_frme, z_frme, tot_frme, tz;
   float scale;

   u_frme = cpu->u - cpu->u_sav;
   s_frme = cpu->s - cpu->s_sav;
   n_frme = cpu->n - cpu->n_sav;
   i_frme = TRIMz(cpu->i - cpu->i_sav);
   w_frme = cpu->w - cpu->w_sav;
   x_frme = cpu->x - cpu->x_sav;
   y_frme = cpu->y - cpu->y_sav;
   z_frme = cpu->z - cpu->z_sav;
   tot_frme = u_frme + s_frme + n_frme + i_frme + w_frme + x_frme + y_frme + z_frme;
   if (tot_frme < 1) tot_frme = 1;
   scale = 100.0 / (float)tot_frme;

   // display some kinda' cpu state percentages
   // (who or what is explained by the passed prefix)
   show_special(
      0,
      fmtmk(
         States_fmts,
         pfx,
         (float)u_frme * scale,
         (float)s_frme * scale,
         (float)n_frme * scale,
         (float)i_frme * scale,
         (float)w_frme * scale,
         (float)x_frme * scale,
         (float)y_frme * scale,
         (float)z_frme * scale
      )
   );
   Msg_row += 1;

   // remember for next time around
   cpu->u_sav = cpu->u;
   cpu->s_sav = cpu->s;
   cpu->n_sav = cpu->n;
   cpu->i_sav = cpu->i;
   cpu->w_sav = cpu->w;
   cpu->x_sav = cpu->x;
   cpu->y_sav = cpu->y;
   cpu->z_sav = cpu->z;

#undef TRIMz
}


// Begin a new frame by:
//    1) Refreshing the all important proc table
//    2) Displaying uptime and load average (maybe)
//    3) Displaying task/cpu states (maybe)
//    4) Displaying memory & swap usage (maybe)
// and then, returning a pointer to the pointers to the proc_t's!
static proc_t **summary_show (void)
{
   static proc_t **p_table = NULL;
   static CPU_t  *smpcpu = NULL;

   // whoa first time, gotta' prime the pump...
   if (!p_table) {
      p_table = procs_refresh(NULL, Frames_libflags);
      putp(Cap_clr_scr);
      putp(Cap_rmam);
#ifndef PROF
      // sleep for half a second
      tv.tv_sec = 0;
      tv.tv_usec = 500000;
      select(0, NULL, NULL, NULL, &tv);  // ought to loop until done
#endif
   } else {
      putp(Batch ? "\n\n" : Cap_home);
   }
   p_table = procs_refresh(p_table, Frames_libflags);
	
   //int i = 0;
   //for(;p_table[i] && p_table[i]->tid >= 0;++i);	



   // Display Uptime and Loadavg
   if (CHKw(Curwin, View_LOADAV)) {
      if (!Rc.mode_altscr) {
         show_special(0, fmtmk(LOADAV_line, "top", sprint_uptime()));
      } else {
         show_special(
            0,
            fmtmk(
               CHKw(Curwin, VISIBLE_tsk) ? LOADAV_line_alt : LOADAV_line,
               Curwin->grpname,
               sprint_uptime()
            )
         );
      }
      Msg_row += 1;
   }

   // Display Task and Cpu(s) States
   if (CHKw(Curwin, View_STATES)) {
      show_special(
         0,
         fmtmk(
            STATES_line1,
            Frame_maxtask, Frame_running, Frame_sleepin, Frame_stopped, Frame_zombied
         )
      );
      Msg_row += 1;

      smpcpu = cpus_refresh(smpcpu);

	  {
         int i;
         char tmp[SMLBUFSIZ];
         // display each cpu's states separately
         for (i = 0; i < Cpu_tot; i++) {
            snprintf(tmp, sizeof(tmp), "Cpu%-3d:", smpcpu[i].id);
            summaryhlp(&smpcpu[i], tmp);
         }
      }
   }

   // Display Memory and Swap stats
   meminfo();
   if (CHKw(Curwin, View_MEMORY)) {
      show_special(0, fmtmk(MEMORY_line1
         , kb_main_total/1024, kb_main_used/1024, kb_main_free/1024, kb_main_buffers/1024));
      show_special(0, fmtmk(MEMORY_line2
         , kb_swap_total/1024, kb_swap_used/1024, kb_swap_free/1024, kb_main_cached/1024));
      Msg_row += 2;
   }

   SETw(Curwin, NEWFRAM_cwo);
   return p_table;
}


#define PAGES_TO_KB(n)  (unsigned long)( (n) << page_to_kb_shift )

// the following macro is our means to 'inline' emitting a column -- next to
// procs_refresh, that's the most frequent and costly part of top's job !
#define MKCOL(va...) do {                                                    \
   if(likely(!(   CHKw(q, Show_HICOLS)  &&  q->rc.sortindx==i   ))) {        \
      snprintf(cbuf, sizeof(cbuf), f, ## va);                                \
   } else {                                                                  \
      snprintf(_z, sizeof(_z), f, ## va);                                    \
      snprintf(cbuf, sizeof(cbuf), "%s%s%s",                                 \
         q->capclr_rowhigh,                                                  \
         _z,                                                                 \
         !(CHKw(q, Show_HIROWS) && 'R' == p->state) ? q->capclr_rownorm : "" \
      );                                                                     \
      pad += q->len_rowhigh;                                                 \
      if (!(CHKw(q, Show_HIROWS) && 'R' == p->state)) pad += q->len_rownorm; \
   }                                                                         \
} while (0)

// Display information for a single task row.
static void task_show (const WIN_t *q, const proc_t *p)
{ 
   if(!filter_size)return;	
   char mybuf[1024] = {0};
   const char *fmt = "pid:%u,usr:%s,cpu:%#4.2f,mem:%#.2fMB,cmd:%s\n";
   float u = (float)p->pcpu * Frame_tscale;
   if (u > pcpu_max_value) u = pcpu_max_value;
   char cmd[256];
   int  maxcmd = 256;
   escape_command(cmd, p, sizeof cmd, &maxcmd,4);
   int match = 0;
   int i = 0;
   for(;i<filter_size;++i){
      if(strstr(cmd,filter[i])){
		match = 1;
		break;
	  }
   }
   if(match){
		sprintf(mybuf,fmt,(unsigned)p->XXXID,p->euser,u,((float)PAGES_TO_KB(p->resident)/1024),cmd);   	
		strcat(outbuf,mybuf);
   }		
}


// Squeeze as many tasks as we can into a single window,
// after sorting the passed proc table.
static void window_show (proc_t **ppt, WIN_t *q, int *lscr)
{
#ifdef SORT_SUPRESS
   // the 1 flag that DOES and 2 flags that MAY impact our proc table qsort
#define srtMASK  ~( Qsrt_NORMAL | Show_CMDLIN | Show_CTIMES )
   static FLG_t sav_indx = 0;
   static int   sav_flgs = -1;
#endif
   int i, lwin;

   strcat(outbuf,"process_info\n");
   // Display Column Headings -- and distract 'em while we sort (maybe)
   //PUFF("\n%s%s%s%s", q->capclr_hdr, q->columnhdr, Caps_off, Cap_clr_eol);

#ifdef SORT_SUPRESS
   if (CHKw(Curwin, NEWFRAM_cwo)
   || sav_indx != q->rc.sortindx
   || sav_flgs != (q->rc.winflags & srtMASK)) {
      sav_indx = q->rc.sortindx;
      sav_flgs = (q->rc.winflags & srtMASK);
#endif
      if (CHKw(q, Qsrt_NORMAL)) Frame_srtflg = 1; // this one's always needed!
      else                      Frame_srtflg = -1;
      Frame_ctimes = CHKw(q, Show_CTIMES);        // this and next, only maybe
      Frame_cmdlin = CHKw(q, Show_CMDLIN);
      qsort(ppt, Frame_maxtask, sizeof(proc_t *), Fieldstab[q->rc.sortindx].sort);
#ifdef SORT_SUPRESS
   }
#endif
   // account for column headings
   (*lscr)++;
   lwin = 1;
   i = 0;

   while ( ppt[i]->tid != -1) {
      if ((CHKw(q, Show_IDLEPS) || ('S' != ppt[i]->state && 'Z' != ppt[i]->state && 'T' != ppt[i]->state))
      && good_uid(ppt[i]) ) {
         // Display a process Row
         task_show(q, ppt[i]);
      }
      ++i;
   }
   // for this frame that window's toast, cleanup for next time
   q->winlines = 0;
   OFFw(Curwin, FLGSOFF_cwo);

#ifdef SORT_SUPRESS
#undef srtMASK
#endif
}


/*######  Entry point plus two  ##########################################*/

// This guy's just a *Helper* function who apportions the
// remaining amount of screen real estate under multiple windows
static void framehlp (int wix, int max)
{
   int i, rsvd, size, wins;

   // calc remaining number of visible windows + total 'user' lines
   for (i = wix, rsvd = 0, wins = 0; i < GROUPSMAX; i++) {
      if (CHKw(&Winstk[i], VISIBLE_tsk)) {
         rsvd += Winstk[i].rc.maxtasks;
         ++wins;
         if (max <= rsvd) break;
      }
   }
   if (!wins) wins = 1;
   // set aside 'rsvd' & deduct 1 line/window for the columns heading
   size = (max - wins) - rsvd;
   if (0 <= size) size = max;
   size = (max - wins) / wins;

   // for remaining windows, set WIN_t winlines to either the user's
   // maxtask (1st choice) or our 'foxized' size calculation
   // (foxized  adj. -  'fair and balanced')
   for (i = wix ; i < GROUPSMAX; i++) {
      if (CHKw(&Winstk[i], VISIBLE_tsk)) {
         Winstk[i].winlines =
            Winstk[i].rc.maxtasks ? Winstk[i].rc.maxtasks : size;
      }
   }
}


// Initiate the Frame Display Update cycle at someone's whim!
// This routine doesn't do much, mostly he just calls others.
//
// (Whoa, wait a minute, we DO caretake those row guys, plus)
// (we CALCULATE that IMPORTANT Max_lines thingy so that the)
// (*subordinate* functions invoked know WHEN the user's had)
// (ENOUGH already.  And at Frame End, it SHOULD be apparent)
// (WE am d'MAN -- clearing UNUSED screen LINES and ensuring)
// (the CURSOR is STUCK in just the RIGHT place, know what I)
// (mean?  Huh, "doesn't DO MUCH"!  Never, EVER think or say)
// (THAT about THIS function again, Ok?  Good that's better.)
static void frame_make (void)
{
   proc_t **ppt;
   int i, scrlins;

   // note: all libproc flags are managed by
   //       reframewins(), who also builds each window's column headers
   if (!Frames_libflags) {
      reframewins();
      memset(Pseudo_scrn, '\0', Pseudo_size);
   }
   Pseudo_row = Msg_row = scrlins = 0;
   ppt = summary_show();

   Max_lines = (Screen_rows - Msg_row) - 1;

   Curwin->winlines = Curwin->rc.maxtasks;
   window_show(ppt, Curwin, &scrlins);


}


static int isinit = 0;

void addfilter(const char *procname){   
   char **tmp = calloc(filter_size+1,sizeof(*tmp));   
   int i = 0;
   for(; i < filter_size; ++i){
		tmp[i] = filter[i];
   }
   if(filter) free(filter);
   filter = tmp;
   filter[filter_size] = calloc(1,strlen(procname)+1);
   strcpy(filter[filter_size],procname);
   filter_size += 1;	
}

const char* top(){
	if(!isinit){
		before(NULL);                                        //                 +-------------+
		windows_stage1();                    //                 top (sic) slice
		configs_read();                      //                 > spread etc, <
		isinit = 1;
	}
	outbuf[0] = 0; 
    frame_make();
	return outbuf;
}



