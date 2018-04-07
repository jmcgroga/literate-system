//
//  SwiftNetHack.swift
//  NetHackMac
//
//  Created by James McGrogan on 3/20/18.
//  Copyright © 2018 James McGrogan. All rights reserved.
//

import Foundation

@objc protocol SwiftNetHack {
    @objc func win_cocoa_init(_ dir: Int32) -> Void
    @objc func cocoa_init_nhwindows(_ argcp: Int32, argv: [String]) -> Void
    @objc func cocoa_player_selection(_ races: UnsafePointer<Race>,
                                      roles: UnsafePointer<Role>,
                                      genders: UnsafePointer<Gender>,
                                      aligns: UnsafePointer<Align>) -> Void
    @objc func cocoa_create_nhwindow(_ type: Int32) -> Int32
    @objc func cocoa_display_nhwindow(_ window: Int, blocking: Bool)
    @objc func cocoa_start_menu(_ window: Int32) -> Void
    @objc func cocoa_end_menu(_ window: Int, query: String) -> Void
    @objc func cocoa_update_inventory() -> Void
    @objc func cocoa_display_file(_ str: String, complain: Bool) -> Void
    @objc func cocoa_cliparound(_ x: Int, y: Int) -> Void
    @objc func cocoa_clear_nhwindow(_ window: Int) -> Void
    @objc func cocoa_destroy_nhwindow(_ window: Int32) -> Void
    @objc func cocoa_raw_print(_ str: String) -> Void
    @objc func cocoa_raw_print_bold(_ str: String) -> Void
    @objc func cocoa_mark_synch() -> Void
    @objc func cocoa_wait_synch() -> Void
    @objc func cocoa_get_nh_event() -> Void
    @objc func cocoa_nh_poskey(_ s: PosKey) -> Int32
    @objc func cocoa_yn_function(_ ques: String, choices: String?, def: CChar) -> CChar
    @objc func cocoa_delay_output() -> Void
    @objc func cocoa_add_menu(_ window: Int32, glyph: Int, identifier: UnsafePointer<anything>, ch: CChar, gch: CChar, attr: Int, str: String, preselected: Bool) -> Void
    @objc func cocoa_select_menu(_ window: Int32, how: Int32) -> MenuList
    @objc func cocoa_print_glyph(_ window: Int, x: CSignedChar, y: CSignedChar, glyph: Int, bkglyph: Int) -> Void
    @objc func cocoa_curs(_ window: Int, x: Int, y: Int) -> Void
    @objc func cocoa_putstr(_ window: Int, attr: Int, str: String) -> Void
    @objc func cocoa_nhgetch() -> Int32
    @objc func cocoa_getlin(_ question: String) -> String
    @objc func cocoa_askname() -> String
    @objc func cocoa_start_screen() -> Void
    @objc func cocoa_end_screen() -> Void
    @objc func cocoa_number_pad(_ state: Int32) -> Void
    @objc func cocoa_preference_update(_ pref: String) -> Void
    @objc func cocoa_exit_nhwindows(_ dummy: String) -> Void
    @objc func cocoa_suspend_nhwindows(_ str: String) -> Void
    @objc func cocoa_nhbell() -> Void
    @objc func cocoa_doprev_message() -> Int32
    @objc func cocoa_get_ext_cmd(_ extcmdlist: UnsafePointer<ext_func_tab>) -> Int32
    @objc func cocoa_outrip(_ window: Int32, how: Int32, when: Int) -> Void
    @objc func cocoa_resume_nhwindows() -> Void
}

@objc class PosKey : NSObject {
    @objc var x: Int32 = 0
    @objc var y: Int32 = 0
    @objc var mod: Int32 = 0
    
    @objc init(_ x: Int32, y: Int32, mod: Int32) {
        self.x = x
        self.y = y
        self.mod = mod
    }
}

@objc class MenuList: NSObject {
    var menuList: [MenuItem] = []
    var menuSelector: [CChar: MenuItem] = [:]
    var menuGSelector: [CChar: MenuItem] = [:]
    let menuChoices: MenuChoices = MenuChoices()
    @objc var count: Int32 = 0
    
    @objc override init() {
    }
    
    func addMenuItem(item: MenuItem) {
        menuList.append(item)
        if let ch = item.selector {
            menuSelector[ch] = item
        }
        if let gch = item.gselector {
            menuGSelector[gch] = item
        }
        self.count = Int32(menuList.count)
    }
    
    @objc func getMenuList() -> UnsafeMutablePointer<menu_item> {
        let list: UnsafeMutablePointer<menu_item> =  UnsafeMutablePointer<menu_item>.allocate(capacity: menuList.count)
        for (i, item) in menuList.enumerated() {
            if let identifier = item.identifier {
                list[i].item = identifier
                list[i].count = i + 1
            }
        }
        return list
    }
}

class MenuItem {
    var identifier: anything? /* Opaque type to identify this selection */
    var pick_count: Int = -1      /* specific selection count; -1 if none */
    var str: String?          /* The text of the item. */
    var attr: Int?            /* Attribute for the line. */
    var selected: Bool = false     /* Been selected? */
    var preselected: Bool = false  /*   in advance?  */
    var selector: CChar?      /* Char used to select this entry. */
    var gselector: CChar?     /* Group selector. */
    var glyph: Int?           /* Glyph */
}

class MenuChoices {
    var _next: CChar? = CChar("a".utf8.first!)
    
    func next() -> CChar? {
        let retval = _next
        
        if let tst = _next {
            switch tst {
            case CChar("z".utf8.first!):
                _next = CChar("A")
                break
            case CChar("Z".utf8.first!):
                _next = CChar("0")
                break
            case CChar("9".utf8.first!):
                _next = nil
                break
            default:
                _next = _next?.advanced(by: 1)
            }
        }
        return retval
    }
}

class Window {
    var window: Int32
    var type: Int32
    var menu: MenuList? = nil
    
    init(_ window: Int32, type: Int32) {
        self.window = window
        self.type = type
    }
}

func setNetHack(_ snh: SwiftNetHack) {
    swiftNetHack = snh
}
