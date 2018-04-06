//
//  CocoaNetHack.m
//  NetHackMac
//
//  Created by James McGrogan on 3/19/18.
//  Copyright © 2018 James McGrogan. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "hack.h"
static struct passwd *NDECL(get_unix_pw);

static boolean wiz_error_flag = FALSE;

boolean
authorize_wizard_mode()
{
    struct passwd *pw = get_unix_pw();
    
    if (pw && sysopt.wizards && sysopt.wizards[0]) {
        if (check_user_string(sysopt.wizards))
            return TRUE;
    }
    wiz_error_flag = TRUE; /* not being allowed into wizard mode */
    return FALSE;
}

#include <pwd.h>

boolean
check_user_string(optstr)
char *optstr;
{
    struct passwd *pw = get_unix_pw();
    int pwlen;
    char *eop, *w;
    char *pwname;
    
    if (optstr[0] == '*')
        return TRUE; /* allow any user */
    if (!pw)
        return FALSE;
    if (sysopt.check_plname)
        pwname = plname;
        else
            pwname = pw->pw_name;
            pwlen = strlen(pwname);
            eop = eos(optstr);
            w = optstr;
            while (w + pwlen <= eop) {
                if (!*w)
                    break;
                if (isspace(*w)) {
                    w++;
                    continue;
                }
                if (!strncmp(w, pwname, pwlen)) {
                    if (!w[pwlen] || isspace(w[pwlen]))
                        return TRUE;
                }
                while (*w && !isspace(*w))
                    w++;
            }
    return FALSE;
}

static struct passwd *
get_unix_pw()
{
    char *user;
    unsigned uid;
    static struct passwd *pw = (struct passwd *) 0;
    
    if (pw)
        return pw; /* cache answer */
    
    uid = (unsigned) getuid();
    user = getlogin();
    if (user) {
        pw = getpwnam(user);
        if (pw && ((unsigned) pw->pw_uid != uid))
            pw = 0;
    }
    if (pw == 0) {
        user = nh_getenv("USER");
        if (user) {
            pw = getpwnam(user);
            if (pw && ((unsigned) pw->pw_uid != uid))
                pw = 0;
        }
        if (pw == 0) {
            pw = getpwuid(uid);
        }
    }
    return pw;
}

#include <sys/stat.h>

boolean
file_exists(path)
const char *path;
{
    struct stat sb;
    
    /* Just see if it's there - trying to figure out if we can actually
     * execute it in all cases is too hard - we really just want to
     * catch typos in SYSCF.
     */
    if (stat(path, &sb)) {
        return FALSE;
    }
    return TRUE;
}

void
sethanguphandler(handler)
void FDECL((*handler), (int));
{
#ifdef SA_RESTART
    /* don't want reads to restart.  If SA_RESTART is defined, we know
     * sigaction exists and can be used to ensure reads won't restart.
     * If it's not defined, assume reads do not restart.  If reads restart
     * and a signal occurs, the game won't do anything until the read
     * succeeds (or the stream returns EOF, which might not happen if
     * reading from, say, a window manager). */
    struct sigaction sact;
    
    (void) memset((genericptr_t) &sact, 0, sizeof sact);
    sact.sa_handler = (SIG_RET_TYPE) handler;
    (void) sigaction(SIGHUP, &sact, (struct sigaction *) 0);
#ifdef SIGXCPU
    (void) sigaction(SIGXCPU, &sact, (struct sigaction *) 0);
#endif
#else /* !SA_RESTART */
    (void) signal(SIGHUP, (SIG_RET_TYPE) handler);
#ifdef SIGXCPU
    (void) signal(SIGXCPU, (SIG_RET_TYPE) handler);
#endif
#endif /* ?SA_RESTART */
}

void
port_insert_pastebuf(buf)
char *buf;
{
    /* This should be replaced when there is a Cocoa port. */
    const char *errfmt;
    size_t len;
    FILE *PB = popen("/usr/bin/pbcopy","w");
    if(!PB){
        errfmt = "Unable to start pbcopy (%d)\n";
        goto error;
    }
    
    len = strlen(buf);
    /* Remove the trailing \n, carefully. */
    if(buf[len-1] == '\n') len--;
    
    /* XXX Sorry, I'm too lazy to write a loop for output this short. */
    if(len!=fwrite(buf,1,len,PB)){
        errfmt = "Error sending data to pbcopy (%d)\n";
        goto error;
    }
    
    if(pclose(PB)!=-1){
        return;
    }
    errfmt = "Error finishing pbcopy (%d)\n";
    
error:
    raw_printf(errfmt,strerror(errno));
}

void
regularize(s)
register char *s;
{
    register char *lp;
    
    while ((lp = index(s, '.')) != 0 || (lp = index(s, '/')) != 0
           || (lp = index(s, ' ')) != 0)
        *lp = '_';
#if defined(SYSV) && !defined(AIX_31) && !defined(SVR4) && !defined(LINUX) \
&& !defined(__APPLE__)
    /* avoid problems with 14 character file name limit */
#ifdef COMPRESS
    /* leave room for .e from error and .Z from compress appended to
     * save files */
    {
#ifdef COMPRESS_EXTENSION
        int i = 12 - strlen(COMPRESS_EXTENSION);
#else
        int i = 10; /* should never happen... */
#endif
        if (strlen(s) > i)
            s[i] = '\0';
    }
#else
    if (strlen(s) > 11)
    /* leave room for .nn appended to level files */
        s[11] = '\0';
#endif
#endif
}

int
dosh()
{
    char *str;
    
#ifdef SYSCF
    if (!sysopt.shellers || !sysopt.shellers[0]
        || !check_user_string(sysopt.shellers)) {
        /* FIXME: should no longer assume a particular command keystroke,
         and perhaps ought to say "unavailable" rather than "unknown" */
        Norep("Unknown command '!'.");
        return 0;
    }
#endif
    if (child(0)) {
        if ((str = getenv("SHELL")) != (char *) 0)
            (void) execl(str, str, (char *) 0);
        else
            (void) execl("/bin/sh", "sh", (char *) 0);
        raw_print("sh: cannot execute.");
        exit(EXIT_FAILURE);
    }
    return 0;
}

int
child(wt)
int wt;
{
    register int f;
    
    suspend_nhwindows((char *) 0); /* also calls end_screen() */
#ifdef _M_UNIX
    sco_mapon();
#endif
#ifdef __linux__
    linux_mapon();
#endif
    if ((f = fork()) == 0) { /* child */
        (void) setgid(getgid());
        (void) setuid(getuid());
#ifdef CHDIR
        (void) chdir(getenv("HOME"));
#endif
        return 1;
    }
    if (f == -1) { /* cannot fork */
        pline("Fork failed.  Try again.");
        return 0;
    }
    /* fork succeeded; wait for child to exit */
#ifndef NO_SIGNAL
    (void) signal(SIGINT, SIG_IGN);
    (void) signal(SIGQUIT, SIG_IGN);
#endif
    (void) wait((int *) 0);
#ifdef _M_UNIX
    sco_mapoff();
#endif
#ifdef __linux__
    linux_mapoff();
#endif
#ifndef NO_SIGNAL
    (void) signal(SIGINT, (SIG_RET_TYPE) done1);
    if (wizard)
        (void) signal(SIGQUIT, SIG_DFL);
#endif
        if (wt) {
            raw_print("");
            wait_synch();
        }
    resume_nhwindows();
    return 0;
}

static void FDECL(chdirx, (const char *, BOOLEAN_P));
static boolean NDECL(whoami);
static void FDECL(process_options, (int, char **));
static void NDECL(wd_message);

int
my_main(argc, argv)
int argc;
char *argv[];
{
    register int fd;
#ifdef CHDIR
    register char *dir;
#endif
    boolean exact_username;
    boolean resuming = FALSE; /* assume new game */
    boolean plsel_once = FALSE;
    
    sys_early_init();
    
#if defined(__APPLE__)
    {
        /* special hack to change working directory to a resource fork when
         running from finder --sam */
#define MAC_PATH_VALUE ".app/Contents/MacOS/"
        char mac_cwd[1024], *mac_exe = argv[0], *mac_tmp;
        int arg0_len = strlen(mac_exe), mac_tmp_len, mac_lhs_len = 0;
        getcwd(mac_cwd, 1024);
        if (mac_exe[0] == '/' && !strcmp(mac_cwd, "/")) {
            if ((mac_exe = strrchr(mac_exe, '/')))
                mac_exe++;
            else
                mac_exe = argv[0];
            mac_tmp_len = (strlen(mac_exe) * 2) + strlen(MAC_PATH_VALUE);
            if (mac_tmp_len <= arg0_len) {
                mac_tmp = malloc(mac_tmp_len + 1);
                sprintf(mac_tmp, "%s%s%s", mac_exe, MAC_PATH_VALUE, mac_exe);
                if (!strcmp(argv[0] + (arg0_len - mac_tmp_len), mac_tmp)) {
                    mac_lhs_len =
                    (arg0_len - mac_tmp_len) + strlen(mac_exe) + 5;
                    if (mac_lhs_len > mac_tmp_len - 1)
                        mac_tmp = realloc(mac_tmp, mac_lhs_len);
                    strncpy(mac_tmp, argv[0], mac_lhs_len);
                    mac_tmp[mac_lhs_len] = '\0';
                    chdir(mac_tmp);
                }
                free(mac_tmp);
            }
        }
    }
#endif
    
    hname = argv[0];
    hackpid = getpid();
    (void) umask(0777 & ~FCMASK);
    
    choose_windows(DEFAULT_WINDOW_SYS);
    
#ifdef CHDIR /* otherwise no chdir() */
    /*
     * See if we must change directory to the playground.
     * (Perhaps hack runs suid and playground is inaccessible
     *  for the player.)
     * The environment variable HACKDIR is overridden by a
     *  -d command line option (must be the first option given).
     */
    dir = nh_getenv("NETHACKDIR");
    if (!dir)
        dir = nh_getenv("HACKDIR");
        
        if (argc > 1) {
            if (argcheck(argc, argv, ARG_VERSION))
                exit(EXIT_SUCCESS);
            
            if (!strncmp(argv[1], "-d", 2) && argv[1][2] != 'e') {
                /* avoid matching "-dec" for DECgraphics; since the man page
                 * says -d directory, hope nobody's using -desomething_else
                 */
                argc--;
                argv++;
                dir = argv[0] + 2;
                if (*dir == '=' || *dir == ':')
                    dir++;
                if (!*dir && argc > 1) {
                    argc--;
                    argv++;
                    dir = argv[0];
                }
                if (!*dir)
                    error("Flag -d must be followed by a directory name.");
            }
        }
#endif /* CHDIR */
    
    if (argc > 1) {
        /*
         * Now we know the directory containing 'record' and
         * may do a prscore().  Exclude `-style' - it's a Qt option.
         */
        if (!strncmp(argv[1], "-s", 2) && strncmp(argv[1], "-style", 6)) {
#ifdef CHDIR
            chdirx(dir, 0);
#endif
#ifdef SYSCF
            initoptions();
#endif
#ifdef PANICTRACE
            ARGV0 = hname; /* save for possible stack trace */
#ifndef NO_SIGNAL
            panictrace_setsignals(TRUE);
#endif
#endif
            prscore(argc, argv);
            /* FIXME: shouldn't this be using nh_terminate() to free
             up any memory allocated by initoptions() */
            exit(EXIT_SUCCESS);
        }
    } /* argc > 1 */
    
    /*
     * Change directories before we initialize the window system so
     * we can find the tile file.
     */
#ifdef CHDIR
    chdirx(dir, 1);
#endif
    
#ifdef _M_UNIX
    check_sco_console();
#endif
#ifdef __linux__
    check_linux_console();
#endif
    initoptions();
#ifdef PANICTRACE
    ARGV0 = hname; /* save for possible stack trace */
#ifndef NO_SIGNAL
    panictrace_setsignals(TRUE);
#endif
#endif
    exact_username = whoami();
    
    /*
     * It seems you really want to play.
     */
    u.uhp = 1; /* prevent RIP on early quits */
    program_state.preserve_locks = 1;
#ifndef NO_SIGNAL
    sethanguphandler((SIG_RET_TYPE) hangup);
#endif
    
    process_options(argc, argv); /* command line options */
#ifdef WINCHAIN
    commit_windowchain();
#endif
    init_nhwindows(&argc, argv); /* now we can set up window system */
#ifdef _M_UNIX
    init_sco_cons();
#endif
#ifdef __linux__
    init_linux_cons();
#endif
    
#ifdef DEF_PAGER
    if (!(catmore = nh_getenv("HACKPAGER"))
        && !(catmore = nh_getenv("PAGER")))
        catmore = DEF_PAGER;
#endif
#ifdef MAIL
        getmailstatus();
#endif
        
    /* wizard mode access is deferred until here */
        set_playmode(); /* sets plname to "wizard" for wizard mode */
        if (exact_username) {
            /*
             * FIXME: this no longer works, ever since 3.3.0
             * when plnamesuffix() was changed to find
             * Name-Role-Race-Gender-Alignment.  It removes
             * all dashes rather than just the last one,
             * regardless of whether whatever follows each
             * dash matches role, race, gender, or alignment.
             */
            /* guard against user names with hyphens in them */
            int len = (int) strlen(plname);
            /* append the current role, if any, so that last dash is ours */
            if (++len < (int) sizeof plname)
                (void) strncat(strcat(plname, "-"), pl_character,
                               sizeof plname - len - 1);
        }
    /* strip role,race,&c suffix; calls askname() if plname[] is empty
     or holds a generic user name like "player" or "games" */
    plnamesuffix();
    
    if (wizard) {
        /* use character name rather than lock letter for file names */
        locknum = 0;
    } else {
        /* suppress interrupts while processing lock file */
        (void) signal(SIGQUIT, SIG_IGN);
        (void) signal(SIGINT, SIG_IGN);
    }

    dlb_init(); /* must be before newgame() */
    
    /*
     * Initialize the vision system.  This must be before mklev() on a
     * new game or before a level restore on a saved game.
     */
    vision_init();
    
    display_gamewindows();
    
    /*
     * First, try to find and restore a save file for specified character.
     * We'll return here if new game player_selection() renames the hero.
     */
attempt_restore:
    
    /*
     * getlock() complains and quits if there is already a game
     * in progress for current character name (when locknum == 0)
     * or if there are too many active games (when locknum > 0).
     * When proceeding, it creates an empty <lockname>.0 file to
     * designate the current game.
     * getlock() constructs <lockname> based on the character
     * name (for !locknum) or on first available of alock, block,
     * clock, &c not currently in use in the playground directory
     * (for locknum > 0).
     */
    if (*plname) {
        getlock();
        program_state.preserve_locks = 0; /* after getlock() */
    }
    
    if (*plname && (fd = restore_saved_game()) >= 0) {
        const char *fq_save = fqname(SAVEF, SAVEPREFIX, 1);
        
        (void) chmod(fq_save, 0); /* disallow parallel restores */
#ifndef NO_SIGNAL
        (void) signal(SIGINT, (SIG_RET_TYPE) done1);
#endif
#ifdef NEWS
        if (iflags.news) {
            display_file(NEWS, FALSE);
            iflags.news = FALSE; /* in case dorecover() fails */
        }
#endif
        pline("Restoring save file...");
        mark_synch(); /* flush output */
        if (dorecover(fd)) {
            resuming = TRUE; /* not starting new game */
            wd_message();
            if (discover || wizard) {
                /* this seems like a candidate for paranoid_confirmation... */
                if (yn("Do you want to keep the save file?") == 'n') {
                    (void) delete_savefile();
                } else {
                    (void) chmod(fq_save, FCMASK); /* back to readable */
                    nh_compress(fq_save);
                }
            }
        }
    }
    
    if (!resuming) {
        boolean neednewlock = (!*plname);
        /* new game:  start by choosing role, race, etc;
         player might change the hero's name while doing that,
         in which case we try to restore under the new name
         and skip selection this time if that didn't succeed */
        if (!iflags.renameinprogress || iflags.defer_plname || neednewlock) {
            if (!plsel_once)
                player_selection();
            plsel_once = TRUE;
            if (neednewlock && *plname)
                goto attempt_restore;
            if (iflags.renameinprogress) {
                /* player has renamed the hero while selecting role;
                 if locking alphabetically, the existing lock file
                 can still be used; otherwise, discard current one
                 and create another for the new character name */
                if (!locknum) {
                    delete_levelfile(0); /* remove empty lock file */
                    getlock();
                }
                goto attempt_restore;
            }
        }
        newgame();
        wd_message();
    }
    
    /* moveloop() never returns but isn't flagged NORETURN */
    moveloop(resuming);
    
    exit(EXIT_SUCCESS);
    /*NOTREACHED*/
    return 0;
}

static void
chdirx(dir, wr)
const char *dir;
boolean wr;
{
    if (dir /* User specified directory? */
#ifdef HACKDIR
        && strcmp(dir, HACKDIR) /* and not the default? */
#endif
        ) {
#ifdef SECURE
        (void) setgid(getgid());
        (void) setuid(getuid()); /* Ron Wessels */
#endif
    } else {
        /* non-default data files is a sign that scores may not be
         * compatible, or perhaps that a binary not fitting this
         * system's layout is being used.
         */
#ifdef VAR_PLAYGROUND
        int len = strlen(VAR_PLAYGROUND);
        
        fqn_prefix[SCOREPREFIX] = (char *) alloc(len + 2);
        Strcpy(fqn_prefix[SCOREPREFIX], VAR_PLAYGROUND);
        if (fqn_prefix[SCOREPREFIX][len - 1] != '/') {
            fqn_prefix[SCOREPREFIX][len] = '/';
            fqn_prefix[SCOREPREFIX][len + 1] = '\0';
        }
#endif
    }
    
#ifdef HACKDIR
    if (dir == (const char *) 0)
        dir = HACKDIR;
#endif
        
        if (dir && chdir(dir) < 0) {
            perror(dir);
            error("Cannot chdir to %s.", dir);
        }

    /* warn the player if we can't write the record file
     * perhaps we should also test whether . is writable
     * unfortunately the access system-call is worthless.
     */
    if (wr) {
#ifdef VAR_PLAYGROUND
        fqn_prefix[LEVELPREFIX] = fqn_prefix[SCOREPREFIX];
        fqn_prefix[SAVEPREFIX] = fqn_prefix[SCOREPREFIX];
        fqn_prefix[BONESPREFIX] = fqn_prefix[SCOREPREFIX];
        fqn_prefix[LOCKPREFIX] = fqn_prefix[SCOREPREFIX];
        fqn_prefix[TROUBLEPREFIX] = fqn_prefix[SCOREPREFIX];
#endif
        check_recordfile(dir);
    }
}

static int
eraseoldlocks()
{
    register int i;
    
    program_state.preserve_locks = 0; /* not required but shows intent */
    /* cannot use maxledgerno() here, because we need to find a lock name
     * before starting everything (including the dungeon initialization
     * that sets astral_level, needed for maxledgerno()) up
     */
    for (i = 1; i <= MAXDUNGEON * MAXLEVEL + 1; i++) {
        /* try to remove all */
        set_levelfile_name(lock, i);
        (void) unlink(fqname(lock, LEVELPREFIX, 0));
    }
    set_levelfile_name(lock, 0);
    if (unlink(fqname(lock, LEVELPREFIX, 0)))
        return 0; /* cannot remove it */
    return 1;     /* success! */
}

static struct stat buf;

static int
veryold(fd)
int fd;
{
    time_t date;
    
    if (fstat(fd, &buf))
        return 0; /* cannot get status */
#ifndef INSURANCE
    if (buf.st_size != sizeof (int))
        return 0; /* not an xlock file */
#endif
#if defined(BSD) && !defined(POSIX_TYPES)
    (void) time((long *) (&date));
#else
    (void) time(&date);
#endif
    if (date - buf.st_mtime < 3L * 24L * 60L * 60L) { /* recent */
        int lockedpid; /* should be the same size as hackpid */
        
        if (read(fd, (genericptr_t) &lockedpid, sizeof lockedpid)
            != sizeof lockedpid)
        /* strange ... */
            return 0;
        
        /* From: Rick Adams <seismo!rick> */
        /* This will work on 4.1cbsd, 4.2bsd and system 3? & 5. */
        /* It will do nothing on V7 or 4.1bsd. */
#ifndef NETWORK
        /* It will do a VERY BAD THING if the playground is shared
         by more than one machine! -pem */
        if (!(kill(lockedpid, 0) == -1 && errno == ESRCH))
#endif
            return 0;
    }
    (void) close(fd);
    return 1;
}

void
getlock()
{
    register int i = 0, fd, c;
    const char *fq_lock;
    
#ifdef TTY_GRAPHICS
    /* idea from rpick%ucqais@uccba.uc.edu
     * prevent automated rerolling of characters
     * test input (fd0) so that tee'ing output to get a screen dump still
     * works
     * also incidentally prevents development of any hack-o-matic programs
     */
    /* added check for window-system type -dlc */
    if (!strcmp(windowprocs.name, "tty"))
        if (!isatty(0))
            error("You must play from a terminal.");
#endif
    
    /* we ignore QUIT and INT at this point */
    if (!lock_file(HLOCK, LOCKPREFIX, 10)) {
        wait_synch();
        error("%s", "");
    }
    
    /* default value of lock[] is "1lock" where '1' gets changed to
     'a','b',&c below; override the default and use <uid><charname>
     if we aren't restricting the number of simultaneous games */
    if (!locknum)
        Sprintf(lock, "%u%s", (unsigned) getuid(), plname);
    
    regularize(lock);
    set_levelfile_name(lock, 0);
    
    if (locknum) {
        if (locknum > 25)
            locknum = 25;
        
        do {
            lock[0] = 'a' + i++;
            fq_lock = fqname(lock, LEVELPREFIX, 0);
            
            if ((fd = open(fq_lock, 0)) == -1) {
                if (errno == ENOENT)
                    goto gotlock; /* no such file */
                perror(fq_lock);
                unlock_file(HLOCK);
                error("Cannot open %s", fq_lock);
            }
            
            /* veryold() closes fd if true */
            if (veryold(fd) && eraseoldlocks())
                goto gotlock;
            (void) close(fd);
        } while (i < locknum);
        
        unlock_file(HLOCK);
        error("Too many hacks running now.");
    } else {
        fq_lock = fqname(lock, LEVELPREFIX, 0);
        if ((fd = open(fq_lock, 0)) == -1) {
            if (errno == ENOENT)
                goto gotlock; /* no such file */
            perror(fq_lock);
            unlock_file(HLOCK);
            error("Cannot open %s", fq_lock);
        }
        
        /* veryold() closes fd if true */
        if (veryold(fd) && eraseoldlocks())
            goto gotlock;
        (void) close(fd);
        
        {
            const char destroy_old_game_prompt[] =
            "There is already a game in progress under your name.  Destroy old game?";
            
            if (iflags.window_inited) {
                /* this is a candidate for paranoid_confirmation */
                c = yn(destroy_old_game_prompt);
            } else {
                (void) printf("\n%s [yn] ", destroy_old_game_prompt);
                (void) fflush(stdout);
                if ((c = getchar()) != EOF) {
                    int tmp;
                    
                    (void) putchar(c);
                    (void) fflush(stdout);
                    while ((tmp = getchar()) != '\n' && tmp != EOF)
                        ; /* eat rest of line and newline */
                }
            }
        }
        if (c == 'y' || c == 'Y') {
            if (eraseoldlocks()) {
                goto gotlock;
            } else {
                unlock_file(HLOCK);
                error("Couldn't destroy old game.");
            }
        } else {
            unlock_file(HLOCK);
            error("%s", "");
        }
    }
    
gotlock:
    fd = creat(fq_lock, FCMASK);
    unlock_file(HLOCK);
    if (fd == -1) {
        error("cannot creat lock file (%s).", fq_lock);
    } else {
        if (write(fd, (genericptr_t) &hackpid, sizeof hackpid)
            != sizeof hackpid) {
            error("cannot write lock (%s)", fq_lock);
        }
        if (close(fd) == -1) {
            error("cannot close lock (%s)", fq_lock);
        }
    }
}

static boolean
whoami()
{
    /*
     * Who am i? Algorithm: 1. Use name as specified in NETHACKOPTIONS
     *            2. Use $USER or $LOGNAME    (if 1. fails)
     *            3. Use getlogin()        (if 2. fails)
     * The resulting name is overridden by command line options.
     * If everything fails, or if the resulting name is some generic
     * account like "games", "play", "player", "hack" then eventually
     * we'll ask him.
     * Note that we trust the user here; it is possible to play under
     * somebody else's name.
     */
    if (!*plname) {
        register const char *s;
        
        s = nh_getenv("USER");
        if (!s || !*s)
            s = nh_getenv("LOGNAME");
        if (!s || !*s)
            s = getlogin();
        
        if (s && *s) {
            (void) strncpy(plname, s, sizeof plname - 1);
            if (index(plname, '-'))
                return TRUE;
        }
    }
    return FALSE;
}

static void
process_options(argc, argv)
int argc;
char *argv[];
{
    int i, l;
    
    /*
     * Process options.
     */
    while (argc > 1 && argv[1][0] == '-') {
        argv++;
        argc--;
        l = (int) strlen(*argv);
        /* must supply at least 4 chars to match "-XXXgraphics" */
        if (l < 4)
            l = 4;
        
        switch (argv[0][1]) {
            case 'D':
            case 'd':
                if ((argv[0][1] == 'D' && !argv[0][2])
                    || !strcmpi(*argv, "-debug")) {
                    wizard = TRUE, discover = FALSE;
                } else if (!strncmpi(*argv, "-DECgraphics", l)) {
                    load_symset("DECGraphics", PRIMARY);
                    switch_symbols(TRUE);
                } else {
                    raw_printf("Unknown option: %s", *argv);
                }
                break;
            case 'X':
                
                discover = TRUE, wizard = FALSE;
                break;
#ifdef NEWS
            case 'n':
                iflags.news = FALSE;
                break;
#endif
            case 'u':
                if (argv[0][2]) {
                    (void) strncpy(plname, argv[0] + 2, sizeof plname - 1);
                } else if (argc > 1) {
                    argc--;
                    argv++;
                    (void) strncpy(plname, argv[0], sizeof plname - 1);
                } else {
                    raw_print("Player name expected after -u");
                }
                break;
            case 'I':
            case 'i':
                if (!strncmpi(*argv, "-IBMgraphics", l)) {
                    load_symset("IBMGraphics", PRIMARY);
                    load_symset("RogueIBM", ROGUESET);
                    switch_symbols(TRUE);
                } else {
                    raw_printf("Unknown option: %s", *argv);
                }
                break;
            case 'p': /* profession (role) */
                if (argv[0][2]) {
                    if ((i = str2role(&argv[0][2])) >= 0)
                        flags.initrole = i;
                } else if (argc > 1) {
                    argc--;
                    argv++;
                    if ((i = str2role(argv[0])) >= 0)
                        flags.initrole = i;
                }
                break;
            case 'r': /* race */
                if (argv[0][2]) {
                    if ((i = str2race(&argv[0][2])) >= 0)
                        flags.initrace = i;
                } else if (argc > 1) {
                    argc--;
                    argv++;
                    if ((i = str2race(argv[0])) >= 0)
                        flags.initrace = i;
                }
                break;
            case 'w': /* windowtype */
                config_error_init(FALSE, "command line", FALSE);
                choose_windows(&argv[0][2]);
                config_error_done();
                break;
            case '@':
                flags.randomall = 1;
                break;
            default:
                if ((i = str2role(&argv[0][1])) >= 0) {
                    flags.initrole = i;
                    break;
                }
                /* else raw_printf("Unknown option: %s", *argv); */
        }
    }
    
#ifdef SYSCF
    if (argc > 1)
        raw_printf("MAXPLAYERS are set in sysconf file.\n");
#else
    /* XXX This is deprecated in favor of SYSCF with MAXPLAYERS */
        if (argc > 1)
            locknum = atoi(argv[1]);
#endif
#ifdef MAX_NR_OF_PLAYERS
        /* limit to compile-time limit */
            if (!locknum || locknum > MAX_NR_OF_PLAYERS)
                locknum = MAX_NR_OF_PLAYERS;
#endif
#ifdef SYSCF
            /* let syscf override compile-time limit */
                if (!locknum || (sysopt.maxplayers && locknum > sysopt.maxplayers))
                    locknum = sysopt.maxplayers;
#endif
}

static void
wd_message()
{
    if (wiz_error_flag) {
        if (sysopt.wizards && sysopt.wizards[0]) {
            char *tmp = build_english_list(sysopt.wizards);
            pline("Only user%s %s may access debug (wizard) mode.",
                  index(sysopt.wizards, ' ') ? "s" : "", tmp);
            free(tmp);
        } else
            pline("Entering explore/discovery mode instead.");
        wizard = 0;
        discover = 1; /* (paranoia) */
    } else if (discover)
        You("are in non-scoring explore/discovery mode.");
}
