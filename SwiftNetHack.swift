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
    @objc func cocoa_create_nhwindow(_ type: Int32) -> winid
    @objc func cocoa_display_nhwindow(_ window: winid, blocking: Bool)
    @objc func cocoa_start_menu(_ window: winid) -> Void
    @objc func cocoa_end_menu(_ window: winid, query: String) -> Void
    @objc func cocoa_update_inventory() -> Void
    @objc func cocoa_display_file(_ str: String, complain: Bool) -> Void
    @objc func cocoa_cliparound(_ x: Int, y: Int) -> Void
    @objc func cocoa_clear_nhwindow(_ window: winid) -> Void
    @objc func cocoa_destroy_nhwindow(_ window: winid) -> Void
    @objc func cocoa_raw_print(_ str: String) -> Void
    @objc func cocoa_raw_print_bold(_ str: String) -> Void
    @objc func cocoa_mark_synch() -> Void
    @objc func cocoa_wait_synch() -> Void
    @objc func cocoa_get_nh_event() -> Void
    @objc func cocoa_nh_poskey(_ s: PosKey) -> Int32
    @objc func cocoa_yn_function(_ ques: String, choices: String?, def: CChar) -> CChar
    @objc func cocoa_delay_output() -> Void
    @objc func cocoa_add_menu(_ window: winid, glyph: Int, identifier: UnsafePointer<anything>, ch: CChar, gch: CChar, attr: Int, str: String, preselected: Bool) -> Void
    @objc func cocoa_select_menu(_ window: winid, how: Int32) -> MenuList
    @objc func cocoa_print_glyph(_ window: winid, x: CSignedChar, y: CSignedChar, glyph: Int, bkglyph: Int) -> Void
    @objc func cocoa_curs(_ window: winid, x: Int, y: Int) -> Void
    @objc func cocoa_putstr(_ window: winid, attr: Int, str: String) -> Void
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
    @objc func cocoa_outrip(_ window: winid, how: Int32, when: Int) -> Void
    @objc func cocoa_resume_nhwindows() -> Void
    func setKey(_ key: Int32)
    func getKey(_ adjust: Int32) -> Int32
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

class Window<T>: CustomStringConvertible {
    let strs = [NHW_MESSAGE: "NHW_MESSAGE",
                NHW_STATUS: "NHW_STATUS",
                NHW_MAP: "NHW_MAP",
                NHW_MENU: "NHW_MENU",
                NHW_TEXT: "NHW_TEXT"]
    var id: winid
    var type: Int32
    public var window: T?
    var menu: MenuList? = nil
    
    public var description: String {
        return "Window: id: \(self.id) type: \(self.getTypeStr() ?? "UNKNOWN")"
    }
    
    init(_ id: winid, type: Int32) {
        self.id = id
        self.type = type
    }

    func setWindow(_ window: T) {
        self.window = window
    }
    
    func getTypeStr() -> String? {
        return self.strs[self.type]
    }
}


struct PlayerTypeIterator<T>: IteratorProtocol, Sequence {
    typealias Element = (Int32, Character, String)
    let player: Player
    let values: UnsafePointer<T>
    let isItTheEnd: (UnsafePointer<T>) -> Bool
    let lookup: (T) -> String?
    let max: Int32
    let choices: MenuChoices = MenuChoices()
    
    var current: UnsafePointer<T>
    var count: Int32 = 0
    var index: Int32 = 0
    
    init(_ player: Player,
         values: UnsafePointer<T>,
         isItTheEnd: @escaping (UnsafePointer<T>) -> Bool,
         lookup: @escaping (T) -> String?,
         max: Int32 = -1) {
        self.player = player
        self.values = values
        self.isItTheEnd = isItTheEnd
        self.lookup = lookup
        self.max = max
        self.current = values
    }
    
    mutating func next() -> Element? {
        var retval: Element? = nil
        var choice: Character
        
        while retval == nil {
            if self.isItTheEnd(self.current) || (max > 0 && count >= max) {
                break
            } else {
                choice = Character(Unicode.Scalar(UInt8(choices.next()!)))
                if let value = self.lookup(self.current.pointee) {
                    retval = (index, choice, value)
                    count += 1
                }
                index += 1
                current = current.advanced(by: 1)
            }
        }
        return retval
    }
    
    func makeIterator() -> PlayerTypeIterator<T> {
        return self
    }
}

class Player {
    let races: UnsafePointer<Race>
    let roles: UnsafePointer<Role>
    let genders: UnsafePointer<Gender>
    let alignments: UnsafePointer<Align>
    
    public var gender: Gender?
    public var role: Role?
    public var alignment: Align?
    public var race: Race?

    init(_ races: UnsafePointer<Race>,
         roles: UnsafePointer<Role>,
         genders: UnsafePointer<Gender>,
         alignments: UnsafePointer<Align>) {
        self.races = races
        self.roles = roles
        self.genders = genders
        self.alignments = alignments
    }
    
    func setGenderByIndex(_ index: Int) {
        self.gender = self.genders[index]
        flags.initgend = Int32(index)
    }

    func setAlignmentByIndex(_ index: Int) {
        self.alignment = self.alignments[index]
        flags.initalign = Int32(index)
    }
    
    func setRoleByIndex(_ index: Int) {
        self.role = self.roles[index]
        flags.initrole = Int32(index)
    }

    func setRaceByIndex(_ index: Int) {
        self.race = self.races[index]
        flags.initrace = Int32(index)
    }

    func getGenders() -> PlayerTypeIterator<Gender> {
        return PlayerTypeIterator<Gender>(self,
                                          values: genders,
                                          isItTheEnd: { (_ x: UnsafePointer<Gender>) -> Bool in
                                            return false
                                            },
                                            lookup: { (_ x: Gender) -> String? in
                                                return String(cString: x.adj, encoding: String.Encoding.utf8)
                                            },
                                            max: ROLE_GENDERS)
    }
    
    func getAlignments() -> PlayerTypeIterator<Align> {
        return PlayerTypeIterator<Align>(self,
                                         values: self.alignments,
                                         isItTheEnd: { (_ x: UnsafePointer<Align>) -> Bool in
                                            return false
                                        },
                                         lookup: { (_ x: Align) -> String? in
                                            return String(cString: x.adj, encoding: String.Encoding.utf8)
                                        },
                                        max: ROLE_ALIGNS)
    }
    
    func getRoles() -> PlayerTypeIterator<Role> {
        return PlayerTypeIterator<Role>(self,
                                        values: roles,
                                        isItTheEnd: { (_ x: UnsafePointer<Role>) -> Bool in
                                            return (x.pointee.name.m == nil)
                                        },
                                        lookup: { (_ x: Role) -> String? in
                                            if (UInt16(x.allow & (self.alignment?.allow)!) & UInt16(ROLE_ALIGNMASK) == 0) ||
                                                (UInt16(x.allow & (self.gender?.allow)!) & UInt16(ROLE_GENDMASK) == 0) {
                                                return nil
                                            }
                                            if (self.gender != nil) && (self.gender!.allow == ROLE_MALE || x.name.f == nil) {
                                                return String(cString: x.name.m, encoding: String.Encoding.utf8)
                                            } else {
                                                return String(cString: x.name.f, encoding: String.Encoding.utf8)
                                            }
                                        })
    }
    
    func getRaces() -> PlayerTypeIterator<Race> {
        return PlayerTypeIterator<Race>(self,
                                        values: races,
                                        isItTheEnd: { (_ x: UnsafePointer<Race>) -> Bool in
                                            return (x.pointee.noun == nil)
                                        },
                                        lookup: { (_ x: Race) -> String? in
                                            return ((UInt16(x.allow & (self.role?.allow)!) & UInt16(ROLE_RACEMASK) == 0) ||
                                                (UInt16(x.allow & (self.alignment?.allow)!) & UInt16(ROLE_ALIGNMASK) == 0) ||
                                                (UInt16(x.allow & (self.gender?.allow)!) & UInt16(ROLE_GENDMASK) == 0)) ? nil : String(cString: x.noun, encoding: String.Encoding.utf8)
        })
    }
}

func setNetHack(_ snh: SwiftNetHack) {
    swiftNetHack = snh
}
