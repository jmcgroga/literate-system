//
//  SwiftNetHackBridge.m
//  NetHackMac
//
//  Created by James McGrogan on 3/20/18.
//  Copyright © 2018 James McGrogan. All rights reserved.
//

#import "SwiftNetHackBridge.h"

struct window_procs cocoa_procs = {
    "cocoa",
    (WC_COLOR | WC_HILITE_PET | WC_ASCII_MAP | WC_TILED_MAP
     | WC_PLAYER_SELECTION | WC_PERM_INVENT | WC_MOUSE_SUPPORT),
    0L, // WC2 flag mask
    cocoa_init_nhwindows,
    cocoa_player_selection,
    /*cocoa_askname, cocoa_get_nh_event, cocoa_exit_nhwindows,cocoa_suspend_nhwindows, cocoa_resume_nhwindows,*/
    cocoa_askname, cocoa_get_nh_event, cocoa_exit_nhwindows, cocoa_suspend_nhwindows, cocoa_resume_nhwindows,
    cocoa_create_nhwindow,
    cocoa_clear_nhwindow, cocoa_display_nhwindow, cocoa_destroy_nhwindow, cocoa_curs,
    cocoa_putstr, genl_putmixed, cocoa_display_file, cocoa_start_menu, cocoa_add_menu,
    cocoa_end_menu, cocoa_select_menu,
    genl_message_menu, // no need for X-specific handling
    cocoa_update_inventory, cocoa_mark_synch, cocoa_wait_synch,
#ifdef CLIPPING
    cocoa_cliparound,
#endif
#ifdef POSITIONBAR
    donull,
#endif
    cocoa_print_glyph, cocoa_raw_print, cocoa_raw_print_bold, cocoa_nhgetch,
    cocoa_nh_poskey, cocoa_nhbell, cocoa_doprev_message, cocoa_yn_function,
    cocoa_getlin, cocoa_get_ext_cmd, cocoa_number_pad, cocoa_delay_output,
#ifdef CHANGE_COLOR // only a Mac option currently
    donull, donull,
#endif
    // other defs that really should go away (they're tty specific)
    cocoa_start_screen, cocoa_end_screen,
#ifdef GRAPHIC_TOMBSTONE
    cocoa_outrip,
#else
    genl_outrip,
#endif
    cocoa_preference_update, genl_getmsghistory, genl_putmsghistory,
    genl_status_init, genl_status_finish, genl_status_enablefield,
    genl_status_update,
    genl_can_suspend_no, // XXX may not always be correct
};

void
win_cocoa_init(dir)
int dir;
{
    if (!swiftNetHack) {
        swiftNetHack = [[SwiftNetHack alloc] init];
    }
}

void
cocoa_init_nhwindows(argcp, argv)
int *argcp;
char **argv;
{
    NSMutableArray<NSString *> *strs = [NSMutableArray<NSString*> arrayWithCapacity:*argcp];
    for (int i = 0; i < *argcp; ++i) {
        [strs setObject:[NSString stringWithCString:argv[i] encoding:NSUTF8StringEncoding] atIndexedSubscript:i];
    }
    [swiftNetHack cocoa_init_nhwindows: *argcp argv: strs];
}

void
cocoa_player_selection()
{
    [swiftNetHack cocoa_player_selection: races roles: roles genders: genders aligns: aligns];
}

winid
cocoa_create_nhwindow(type)
int type;
{
    return [swiftNetHack cocoa_create_nhwindow: type];
}

void
cocoa_display_nhwindow(window, blocking)
winid window;
boolean blocking;
{
    [swiftNetHack cocoa_display_nhwindow: window blocking: blocking];
}

void
cocoa_start_menu(window)
winid window;
{
    [swiftNetHack cocoa_start_menu: window];
}

void
cocoa_end_menu(window, query)
winid window;
const char *query;
{
    [swiftNetHack cocoa_end_menu: window query: (query ? [NSString stringWithCString:query encoding:NSUTF8StringEncoding] : nil)];
}

void
cocoa_update_inventory()
{
    [swiftNetHack cocoa_update_inventory];
}

void
cocoa_display_file(str, complain)
const char *str;
boolean complain;
{
    [swiftNetHack cocoa_display_file: (complain ? [NSString stringWithCString:str encoding:NSUTF8StringEncoding] : nil) complain: complain];
}

void
cocoa_cliparound(x, y)
int x UNUSED;
int y UNUSED;
{
    [swiftNetHack cocoa_cliparound: x y: y];
}

void
cocoa_clear_nhwindow(window)
winid window;
{
    [swiftNetHack cocoa_clear_nhwindow: window];
}

void
cocoa_print_glyph(window, x, y, glyph, bkglyph)
winid window;
xchar x, y;
int glyph;
int bkglyph UNUSED;
{
    [swiftNetHack cocoa_print_glyph:window x:x y:y glyph:glyph bkglyph:bkglyph];
}

void
cocoa_curs(window, x, y)
winid window;
int x, y;
{
    [swiftNetHack cocoa_curs: window x: x y: y];
}

void
cocoa_putstr(window, attr, str)
winid window;
int attr;
const char *str;
{
    [swiftNetHack cocoa_putstr:window attr:attr str:[NSString stringWithCString:str encoding:NSUTF8StringEncoding]];
}

void
cocoa_destroy_nhwindow(window)
winid window;
{
    [swiftNetHack cocoa_destroy_nhwindow: window];
}

void
cocoa_raw_print(str)
const char *str;
{
    [swiftNetHack cocoa_raw_print: [NSString stringWithCString:str encoding:NSUTF8StringEncoding]];
}

void
cocoa_raw_print_bold(str)
const char *str;
{
    [swiftNetHack cocoa_raw_print_bold: [NSString stringWithCString:str encoding:NSUTF8StringEncoding]];
}

void
cocoa_mark_synch()
{
    [swiftNetHack cocoa_mark_synch];
}

void
cocoa_wait_synch()
{
    [swiftNetHack cocoa_wait_synch];
}

void
cocoa_get_nh_event()
{
    [swiftNetHack cocoa_get_nh_event];
}

int
cocoa_nh_poskey(x, y, mod)
int *x, *y, *mod;
{
    PosKey *p = [[PosKey alloc] init:*x y:*y mod:*mod];
    int retval = [swiftNetHack cocoa_nh_poskey:p];
    *x = p.x;
    *y = p.y;
    *mod = p.mod;
    return retval;
}

char
cocoa_yn_function(ques, choices, def)
const char *ques;
const char *choices; /* string of possible response chars; any char if Null */
char def;            /* default response if user hits <space> or <return> */
{
    NSString *_choices = (choices ? [NSString stringWithCString:choices encoding:NSUTF8StringEncoding] : nil);
    return [swiftNetHack cocoa_yn_function:[NSString stringWithCString:ques encoding:NSUTF8StringEncoding] choices:_choices def:def];
}

void
cocoa_delay_output()
{
    [swiftNetHack cocoa_delay_output];
}

void
cocoa_add_menu(window, glyph, identifier, ch, gch, attr, str, preselected)
winid window;
int glyph; /* unused (for now) */
const anything *identifier;
char ch;
char gch; /* group accelerator (0 = no group) */
int attr;
const char *str;
boolean preselected;
{
    [swiftNetHack cocoa_add_menu:window glyph:glyph identifier:identifier ch:ch gch:gch attr:attr str:[NSString stringWithCString:str encoding:NSUTF8StringEncoding] preselected:preselected];
}

int
cocoa_select_menu(window, how, menu_list)
winid window;
int how;
menu_item **menu_list;
{
    MenuList *menuList = [swiftNetHack cocoa_select_menu:window how:how];
    *menu_list = [menuList getMenuList];
    return menuList.count;
}

int
cocoa_nhgetch()
{
    return [swiftNetHack cocoa_nhgetch];
}

void
cocoa_getlin(question, input)
const char *question;
char *input;
{
    NSString *answer = [swiftNetHack get__line:[NSString stringWithCString:question encoding:NSUTF8StringEncoding]];
    strncpy(input, [answer cStringUsingEncoding:NSUTF8StringEncoding], BUFSZ);
}

void
cocoa_askname()
{
    NSString *answer = [swiftNetHack cocoa_askname];
    strncpy(plname, [answer cStringUsingEncoding:NSUTF8StringEncoding], PL_NSIZ);
}

void
cocoa_nhbell()
{
    [swiftNetHack cocoa_nhbell];
}

int
cocoa_doprev_message()
{
    return [swiftNetHack cocoa_doprev_message];
}

int
cocoa_get_ext_cmd()
{
    return [swiftNetHack cocoa_get_ext_cmd: extcmdlist];
}

void
cocoa_start_screen()
{
    [swiftNetHack cocoa_start_screen];
}

void
cocoa_end_screen()
{
    [swiftNetHack cocoa_end_screen];
}

void
cocoa_number_pad(state) /* called from options.c */
int state;
{
    [swiftNetHack cocoa_number_pad:state];
}

void
cocoa_preference_update(pref)
const char *pref;
{
    [swiftNetHack cocoa_preference_update:[NSString stringWithCString:pref encoding:NSUTF8StringEncoding]];
}

void
cocoa_outrip(window, how, when)
winid window;
int how;
time_t when;
{
    [swiftNetHack cocoa_outrip:window how:how when:when];
}

void
cocoa_exit_nhwindows(dummy)
const char *dummy;
{
    [swiftNetHack cocoa_exit_nhwindows: [NSString stringWithCString:dummy encoding:NSUTF8StringEncoding]];
}

void
cocoa_suspend_nhwindows(str)
const char *str;
{
    [swiftNetHack cocoa_suspend_nhwindows: [NSString stringWithCString:str encoding:NSUTF8StringEncoding]];
}

void
cocoa_resume_nhwindows()
{
    [swiftNetHack cocoa_resume_nhwindows];
}
