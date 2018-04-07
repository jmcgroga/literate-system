//
//  SwiftNetHackBridge.h
//  NetHackMac
//
//  Created by James McGrogan on 3/20/18.
//  Copyright © 2018 James McGrogan. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "hack.h"
#import "NetHackSwift-Swift.h"

extern struct window_procs cocoa_procs;
extern void FDECL(win_cocoa_init, (int));
extern void FDECL(cocoa_init_nhwindows, (int *, char **));
extern void NDECL(cocoa_player_selection);
extern winid FDECL(cocoa_create_nhwindow, (int));
extern void FDECL(cocoa_display_nhwindow, (winid, BOOLEAN_P));
extern void FDECL(cocoa_start_menu, (winid));
extern void FDECL(cocoa_end_menu, (winid, const char *));
extern void NDECL(cocoa_update_inventory);
extern void FDECL(cocoa_display_file, (const char *, BOOLEAN_P));
#ifdef CLIPPING
extern void FDECL(cocoa_cliparound, (int, int));
#endif
extern void FDECL(cocoa_clear_nhwindow, (winid));
extern void FDECL(cocoa_print_glyph, (winid, XCHAR_P, XCHAR_P, int, int));
extern void FDECL(cocoa_curs, (winid, int, int));
extern void FDECL(cocoa_putstr, (winid, int, const char *));
extern void FDECL(cocoa_destroy_nhwindow, (winid));
extern void FDECL(cocoa_raw_print, (const char *));
extern void FDECL(cocoa_raw_print_bold, (const char *));
extern void NDECL(cocoa_mark_synch);
extern void NDECL(cocoa_wait_synch);
extern void NDECL(cocoa_get_nh_event);
extern int FDECL(cocoa_nh_poskey, (int *, int *, int *));
extern char FDECL(cocoa_yn_function, (const char *, const char *, CHAR_P));
extern void NDECL(cocoa_delay_output);
extern void FDECL(cocoa_add_menu, (winid, int, const ANY_P *, CHAR_P, CHAR_P, int, const char *, BOOLEAN_P));
extern int FDECL(cocoa_select_menu, (winid, int, MENU_ITEM_P **));
extern int NDECL(cocoa_nhgetch);
extern void FDECL(cocoa_getlin, (const char *, char *));
extern void NDECL(cocoa_askname);
extern void NDECL(cocoa_nhbell);
extern int NDECL(cocoa_doprev_message);
extern int NDECL(cocoa_get_ext_cmd);

extern void NDECL(cocoa_start_screen);
extern void NDECL(cocoa_end_screen);

extern void FDECL(cocoa_number_pad, (int));

extern void FDECL(cocoa_preference_update, (const char *));
extern void FDECL(cocoa_outrip, (winid, int, time_t));

extern void FDECL(cocoa_exit_nhwindows, (const char *));
extern void FDECL(cocoa_suspend_nhwindows, (const char *));
extern void NDECL(cocoa_resume_nhwindows);
