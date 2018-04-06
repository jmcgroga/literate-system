//
//  SwiftNetHack.swift
//  NetHackMac
//
//  Created by James McGrogan on 3/20/18.
//  Copyright © 2018 James McGrogan. All rights reserved.
//

import Foundation

@objc public class SwiftNetHack : NSObject {
    var windows: [Int32: Window] = [:]
    
    override init() {
        print("I'm initialized!")
    }
    
    @objc func cocoa_init_nhwindows(_ argcp: Int32, argv: [String]) -> Void {
        print("Here's what init_nhwindows had: \(argcp) \(argv)")
    }
    
    func choose_choice<T>(values: UnsafePointer<T>,
                          isItTheEnd: (UnsafePointer<T>) -> Bool,
                          lookup: (T) -> String?,
                          max: Int32 = -1) -> Int32 {
        let choices: MenuChoices = MenuChoices()
        var current: UnsafePointer<T> = values
        var choice: Character
        var count: Int32 = 0
        
        while !isItTheEnd(current) {
            choice = Character(Unicode.Scalar(UInt8(choices.next()!)))
            if let value = lookup(current.pointee) {
                print("\(choice): \(value)")
                count += 1
            }
            current = current.advanced(by: 1)
            if max > 0 && count >= max {
                break
            }
        }
        return GetKeyPress() - 97
    }
    
    @objc func cocoa_player_selection(_ races: UnsafePointer<Race>,
                                      roles: UnsafePointer<Role>,
                                      genders: UnsafePointer<Gender>,
                                      aligns: UnsafePointer<Align>) -> Void {
        print("player_selection")
        var selectedGender: Gender
        var selectedRole: Role
        var selectedAlign: Align
        var selectedRace: Race

        flags.initgend = choose_choice(values: genders, isItTheEnd: { (_ x: UnsafePointer<Gender>) -> Bool in
            return false
        }, lookup: { (_ x: Gender) -> String? in
            return String(cString: x.adj, encoding: String.Encoding.utf8)
        },
           max: ROLE_GENDERS)
        
        selectedGender = genders[Int(flags.initgend)]
        
        flags.initalign = choose_choice(values: aligns, isItTheEnd: { (_ x: UnsafePointer<Align>) -> Bool in
            return false
        }, lookup: { (_ x: Align) -> String? in
            return String(cString: x.adj, encoding: String.Encoding.utf8)
        },
           max: ROLE_ALIGNS)
        
        selectedAlign = aligns[Int(flags.initalign)]

        flags.initrole = choose_choice(values: roles, isItTheEnd: { (_ x: UnsafePointer<Role>) -> Bool in
            return (x.pointee.name.m == nil)
        }, lookup: { (_ x: Role) -> String? in
            if (UInt16(x.allow & selectedAlign.allow) & UInt16(ROLE_ALIGNMASK) == 0) ||
                (UInt16(x.allow & selectedGender.allow) & UInt16(ROLE_GENDMASK) == 0) {
                return nil
            }
            if selectedGender.allow == ROLE_MALE || x.name.f == nil {
                return String(cString: x.name.m, encoding: String.Encoding.utf8)
            } else {
                return String(cString: x.name.f, encoding: String.Encoding.utf8)
            }
        })
        
        selectedRole = roles[Int(flags.initrole)]

        flags.initrace = choose_choice(values: races, isItTheEnd: { (_ x: UnsafePointer<Race>) -> Bool in
            return (x.pointee.noun == nil)
        }, lookup: { (_ x: Race) -> String? in
            return ((UInt16(x.allow & selectedRole.allow) & UInt16(ROLE_RACEMASK) == 0) ||
                (UInt16(x.allow & selectedAlign.allow) & UInt16(ROLE_ALIGNMASK) == 0) ||
                (UInt16(x.allow & selectedGender.allow) & UInt16(ROLE_GENDMASK) == 0)) ? nil : String(cString: x.noun, encoding: String.Encoding.utf8)
        })

        selectedRace = races[Int(flags.initrace)]
    }
    
    @objc func cocoa_create_nhwindow(_ type: Int32) -> Int32 {
        let winid: Int32 = Int32(windows.count) + 1
        windows[winid] = Window(winid, type: type)
        print("create_nhwindow: \(winid)")
        return Int32(winid);
    }
    
    @objc func cocoa_display_nhwindow(_ window: Int, blocking: Bool) {
        print("display_nhwindow")
    }

    @objc func cocoa_clear_nhwindow(_ window: Int) -> Void {
        print("clear_nhwindow: \(window)")
    }

    @objc func cocoa_start_menu(_ window: Int32) -> Void {
        print("start_menu")
        windows[window]?.menu = MenuList()
    }
    
    @objc func cocoa_end_menu(_ window: Int, query: String) -> Void {
        print("end_menu: \(query)")
    }
    
    @objc func cocoa_update_inventory() -> Void {
        print("cocoa_update_inventory")
    }
    
    @objc func cocoa_display_file(_ str: String, complain: Bool) -> Void {
        print("cocoa_display_file: \(str) \(complain)")
    }
    
    @objc func cocoa_cliparound(_ x: Int, y: Int) -> Void {
        print("cocoa_cliparound: \(x) \(y)")
    }

    @objc func cocoa_print_glyph(_ window: Int, x: CSignedChar, y: CSignedChar, glyph: Int, bkglyph: Int) -> Void {
        print("cocoa_print_glyph: \(window) \(x) \(y) \(glyph) \(bkglyph)")
    }

    @objc func cocoa_curs(_ window: Int, x: Int, y: Int) -> Void {
        print("cocoa_curs: \(window) \(x) \(y)")
    }
    
    @objc func cocoa_putstr(_ window: Int, attr: Int, str: String) -> Void {
        print("cocoa_putstr: \(window) \(attr) \(str)")
    }
    
    @objc func cocoa_destroy_nhwindow(_ window: Int32) -> Void {
        print("destroy_nhwindow")
        windows.removeValue(forKey: window)
    }

    @objc func cocoa_raw_print(_ str: String) -> Void {
        print("raw_print: \(str)")
    }

    @objc func cocoa_raw_print_bold(_ str: String) -> Void {
        print("raw_print_bold: \(str)")
    }

    @objc func cocoa_mark_synch() -> Void {
        print("mark_synch")
    }

    @objc func cocoa_wait_synch() -> Void {
        print("wait_synch")
    }

    @objc func cocoa_get_nh_event() -> Void {
        print("get_nh_event")
    }
    
    @objc func cocoa_nh_poskey(_ s: PosKey) -> Int32 {
        let input: Int32 = GetKeyPress() //TODO: Change this to respond to keypress or mouse click
        print("nh_poskey: \(s) Key: \(input)")
        s.x = 45
        s.y = 5
        s.mod = 1
        return input
    }
    
    @objc func cocoa_yn_function(_ ques: String, choices: String?, def: CChar) -> CChar {
        print("yn_function: \(ques) \(choices)")
        let input: Int32 = GetKeyPress()
        if let choices = choices {
            //return CChar(Array(_choices.utf8)[0])
        }
        return CChar(input)
    }
    
    @objc func cocoa_delay_output() -> Void {
        print("delay_output")
    }
    
    @objc func cocoa_add_menu(_ window: Int32, glyph: Int, identifier: UnsafePointer<anything>, ch: CChar, gch: CChar, attr: Int, str: String, preselected: Bool) -> Void {

        if let menu = windows[window]?.menu {
            var useCh:CChar = ch

            if ch == 0 && attr == 0 {
                if let next = menu.menuChoices.next() {
                    useCh = next
                } else {
                    print("add_menu: out of choices!")
                    return
                }
            }
            
            let x = Character(Unicode.Scalar(UInt8(useCh)))
            let y = Character(Unicode.Scalar(UInt8(gch)))
            
            
            print("add_menu: \(window) \(glyph) \(x) \(y) \(attr) \(str) \(preselected) \(identifier.pointee.a_char)")
            let menuItem = MenuItem()
            menuItem.identifier = identifier.pointee
            menuItem.str = str
            menuItem.attr = attr
            menuItem.preselected = preselected
            menuItem.selector = useCh
            menuItem.gselector = gch
            menuItem.glyph = glyph
            menu.addMenuItem(item: menuItem)
        } else {
            print("cocoa_add_menu: \(window) window not found")
        }
    }

    @objc func cocoa_select_menu(_ window: Int32, how: Int32) -> MenuList {
        let input: CChar = CChar(GetKeyPress())
        print("select_menu: \(window) \(how) Key: \(String(input))")
        let menuList = MenuList()

        if let menu = windows[window]?.menu,
            let item = menu.menuSelector[input] {
            switch how {
            case PICK_ONE:
                menuList.addMenuItem(item: item)
                break
            default:
                print("Can't handle how \(how)")
            }
        } else {
            print("No menu or item for window \(window) key: \(input)!")
        }
        
        return menuList
    }
    
    @objc func cocoa_nhgetch() -> Int32 {
        return GetKeyPress()
    }
    
    @objc func get__line(_ question: String) -> String {
        print("Question: \(question)")
        if let input = readLine(strippingNewline: true) {
            return input
        }
        return ""
    }
    
    @objc func cocoa_askname() -> String {
        print("cocoa_askname")
        print("What is your name?")
        if let input = readLine(strippingNewline: true) {
            return input
        }
        return ""
    }
    
    @objc func cocoa_nhbell() -> Void {
        print("Ding!")
    }
    
    @objc func cocoa_doprev_message() -> Int32 {
        print("cocoa_doprev_message")
        return 0;
    }
    
    @objc func cocoa_get_ext_cmd(_ extcmdlist: UnsafePointer<ext_func_tab>) -> Int32 {
        print("cocoa_get_ext_cmd")
        var list = extcmdlist
        var index = 0
        
        while let ef_txt = list.pointee.ef_txt {
            if let str = NSString(cString: ef_txt, encoding:String.Encoding.utf8.rawValue) {
                print("\(index): \(str)")
            }
            list = list.advanced(by: 1)
            index += 1
        }
        
        if let line = readLine(strippingNewline: true),
            let selection = Int32(line) {
            return selection
        }
        return -1
    }
    
    @objc func cocoa_start_screen() -> Void {
        print("cocoa_start_screen")
    }
    
    @objc func cocoa_end_screen() -> Void {
        print("cocoa_end_screen")
    }
    
    @objc func cocoa_number_pad(_ state: Int32) -> Void {
        print("cocoa_number_pad")
    }
    
    @objc func cocoa_preference_update(_ pref: String) -> Void {
        print("cocoa_preference_update \(pref)")
    }
    
    @objc func cocoa_outrip(_ window: Int32, how: Int32, when: Int) -> Void {
        print("cocoa_outrip: \(window) \(how) \(when)")
    }

    @objc func cocoa_exit_nhwindows(_ dummy: String) -> Void {
        print("cocoa_exit_nhwindows \(dummy)")
    }

    @objc func cocoa_suspend_nhwindows(_ str: String) -> Void {
        print("cocoa_suspend_nhwindows \(str)")
    }

    @objc func cocoa_resume_nhwindows() -> Void {
        print("cocoa_resume_nhwindows")
    }
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

func GetKeyPress () -> Int32
{
    var key: Int = 0
    let c: cc_t = 0
    let cct = (c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c, c) // Set of 20 Special Characters
    var oldt: termios = termios(c_iflag: 0, c_oflag: 0, c_cflag: 0, c_lflag: 0, c_cc: cct, c_ispeed: 0, c_ospeed: 0)
    
    tcgetattr(STDIN_FILENO, &oldt) // 1473
    var newt = oldt
    newt.c_lflag = 1217  // Reset ICANON and Echo off
    tcsetattr( STDIN_FILENO, TCSANOW, &newt)
    key = Int(getchar())  // works like "getch()"
    getchar() // TODO: REMOVE THIS!! eat the new line
    tcsetattr( STDIN_FILENO, TCSANOW, &oldt)
    return Int32(key)
}

