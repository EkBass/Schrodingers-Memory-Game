' ================================================================
' Project: Schrödinger's Memory Game
'
' Author: EkBass, 2026
' - https://github.com/EkBass
'
' License: MIT
' - https://mit-license.org/
'
' Dev-target: BazzBasic
' - https://github.com/EkBass/BazzBasic
'
' Platform: Win 64
' ================================================================

LET MENU_Y0# = 275
LET MENU_Y1# = 330
LET MENU_Y2# = 380
LET MENU_Y3# = 430
LET MENU_Y4# = 480
LET MENU_HW#     = 100
LET MENU_HH#     = 31
LET MENU_SCALE#  = 0.5
LET MENU_DRAW_X# = 300
LET MENU_CX#     = 320

' --- High score ---
LET MENU_HS_FONT#      = "C:/Windows/Fonts/arial.ttf"
LET MENU_HS_SIZE#      = 20
LET MENU_HS_PREFIX#    = "HIGH SCORE: "
LET MENU_HS_PREFIX_W#  = 137.79
LET MENU_HS_DIGIT_W#   = 11.12
LET MENU_HS_LEFT#      = 100
LET MENU_HS_RIGHT#     = 700
LET MENU_HS_Y#         = 24
LET MENU_HS_DEFAULT#   = 1 

LET menuBestScore$ = MENU_HS_DEFAULT# 

GOTO [menu:moduleEnd]

' ============================================================
[menu:init]
    DIM menuBtn$
    menuBtn$("bg")       = LOADIMAGE(PATH_IMAGES# + "intro.png")
    menuBtn$("new_game") = LOADIMAGE(PATH_IMAGES# + "button_new_game.png")
    menuBtn$("sound_on") = LOADIMAGE(PATH_IMAGES# + "button_sound_on.png")
    menuBtn$("sound_off")= LOADIMAGE(PATH_IMAGES# + "button_sound_off.png")
    menuBtn$("music_on") = LOADIMAGE(PATH_IMAGES# + "button_music_on.png")
    menuBtn$("music_off")= LOADIMAGE(PATH_IMAGES# + "button_music_off.png")
    menuBtn$("manual")   = LOADIMAGE(PATH_IMAGES# + "button_manual.png")
    menuBtn$("exit")     = LOADIMAGE(PATH_IMAGES# + "button_exit.png")

    SCALESHAPE menuBtn$("new_game"),  MENU_SCALE#
    SCALESHAPE menuBtn$("sound_on"),  MENU_SCALE#
    SCALESHAPE menuBtn$("sound_off"), MENU_SCALE#
    SCALESHAPE menuBtn$("music_on"),  MENU_SCALE#
    SCALESHAPE menuBtn$("music_off"), MENU_SCALE#
    SCALESHAPE menuBtn$("manual"),    MENU_SCALE#
    SCALESHAPE menuBtn$("exit"),      MENU_SCALE#

    LET menuMusic$ = LOADSOUND(PATH_AUDIO# + "pumpkin.mp3")
    IF musicState$ = true THEN SOUNDREPEAT(menuMusic$)

    LET menuSel$       = 0
    LET menuDone$      = false
    LET menuAction$    = ""
    LET menuClickCool$ = 0
    LET menuBestScore$ = MENU_HS_DEFAULT#
    LET menuHsText$    = ""
    LET menuHsX$       = 0
    LET menuHsColor$   = RGB(255, 255, 103)

    
    LOADFONT MENU_HS_FONT#, MENU_HS_SIZE#

    DIM menuY$
    menuY$(0) = MENU_Y0#
    menuY$(1) = MENU_Y1#
    menuY$(2) = MENU_Y2#
    menuY$(3) = MENU_Y3#
    menuY$(4) = MENU_Y4#
    LET hlCY$ = MENU_Y0#

    ' Mouse
    LET menuMouseX$     = 0
    LET menuMouseY$     = 0
    LET menuMouseLastX$ = -1
    LET menuMouseLastY$ = -1
    LET menuMouseNow$   = 0
    LET menuMouseWas$   = 0
    LET menuHover$      = -1
    LET menuHoverDist$  = 0
    LET mhDist$         = 0
RETURN

' ============================================================
[menu:run]
    menuBestScore$ = MENU_HS_DEFAULT#
    IF FileExists("highscore.txt") THEN
        LET gHsSave$ = FileRead("highscore.txt")
        IF HASKEY(gHsSave$("best")) THEN
            menuBestScore$ = INT(VAL(gHsSave$("best")))
        ENDIF
    ENDIF

    IF menuBestScore$ < MENU_HS_DEFAULT# THEN menuBestScore$ = MENU_HS_DEFAULT#


    menuHsText$ = MENU_HS_PREFIX# + menuBestScore$
    menuHsX$ = (MENU_HS_LEFT# + MENU_HS_RIGHT#) / 2 -
               (MENU_HS_PREFIX_W# + LEN(STR(menuBestScore$)) * MENU_HS_DIGIT_W#) / 2
    menuHsX$ = INT(menuHsX$)

    LET menuDone$   = false
    LET menuAction$ = ""

    menuMouseWas$ = MOUSELEFT
    menuMouseLastX$ = MOUSEX
    menuMouseLastY$ = MOUSEY

    WHILE menuDone$ = false
        LET menuKey$ = INKEY

        GOSUB [menu:mouse]

        IF menuKey$ = KEY_UP# THEN
            menuSel$ = menuSel$ - 1
            IF menuSel$ < 0 THEN menuSel$ = 4
        ENDIF
        IF menuKey$ = KEY_DOWN# THEN
            menuSel$ = menuSel$ + 1
            IF menuSel$ > 4 THEN menuSel$ = 0
        ENDIF
        IF menuKey$ = KEY_ENTER# THEN GOSUB [menu:activate]
        IF menuKey$ = KEY_ESC#   THEN menuAction$ = "exit" : menuDone$ = true

        SCREENLOCK ON
        GOSUB [menu:draw]
        SCREENLOCK OFF
        SLEEP 16
    WEND
RETURN

[menu:mouse]
    menuMouseX$ = MOUSEX
    menuMouseY$ = MOUSEY

    menuHover$ = -1
    menuHoverDist$ = MENU_HH# + 1
    IF BETWEEN(menuMouseX$, MENU_DRAW_X#, MENU_DRAW_X# + MENU_HW# * 2) THEN
        FOR mh$ = 0 TO 4
            mhDist$ = ABS(menuMouseY$ - menuY$(mh$))
            IF mhDist$ < menuHoverDist$ THEN
                menuHover$ = mh$
                menuHoverDist$ = mhDist$
            ENDIF
        NEXT mh$
    ENDIF

    IF menuMouseX$ <> menuMouseLastX$ OR menuMouseY$ <> menuMouseLastY$ THEN
        IF menuHover$ <> -1 THEN menuSel$ = menuHover$
        menuMouseLastX$ = menuMouseX$
        menuMouseLastY$ = menuMouseY$
    ENDIF

    menuMouseNow$ = MOUSELEFT
    IF menuMouseNow$ = 1 AND menuMouseWas$ = 0 AND menuHover$ <> -1 THEN
        menuSel$ = menuHover$
        GOSUB [menu:activate]
    ENDIF
    menuMouseWas$ = menuMouseNow$
RETURN


[menu:draw]
    MOVESHAPE menuBtn$("bg"), 0, 0
    DRAWSHAPE menuBtn$("bg")

    MOVESHAPE menuBtn$("new_game"), MENU_DRAW_X#, MENU_Y0# - MENU_HH#
    DRAWSHAPE menuBtn$("new_game")

    IF soundState$ = true THEN
        MOVESHAPE menuBtn$("sound_on"),  MENU_DRAW_X#, MENU_Y1# - MENU_HH#
        DRAWSHAPE menuBtn$("sound_on")
    ELSE
        MOVESHAPE menuBtn$("sound_off"), MENU_DRAW_X#, MENU_Y1# - MENU_HH#
        DRAWSHAPE menuBtn$("sound_off")
    ENDIF

    IF musicState$ = true THEN
        MOVESHAPE menuBtn$("music_on"),  MENU_DRAW_X#, MENU_Y2# - MENU_HH#
        DRAWSHAPE menuBtn$("music_on")
    ELSE
        MOVESHAPE menuBtn$("music_off"), MENU_DRAW_X#, MENU_Y2# - MENU_HH#
        DRAWSHAPE menuBtn$("music_off")
    ENDIF

    MOVESHAPE menuBtn$("manual"), MENU_DRAW_X#, MENU_Y3# - MENU_HH#
    DRAWSHAPE menuBtn$("manual")

    MOVESHAPE menuBtn$("exit"), MENU_DRAW_X#, MENU_Y4# - MENU_HH#
    DRAWSHAPE menuBtn$("exit")

    ' Highlight selected button
    hlCY$ = menuY$(menuSel$)
    LINE (MENU_DRAW_X# - 2, hlCY$ - MENU_HH# - 2)-(MENU_DRAW_X# + MENU_HW# * 2 + 2, hlCY$ + MENU_HH# + 2), RGB(255,255,103), B

    DRAWSTRING menuHsText$, menuHsX$, MENU_HS_Y#, menuHsColor$
RETURN

' ============================================================
[menu:activate]
    IF menuSel$ = 0 THEN menuAction$ = "new_game" : menuDone$ = true

    IF menuSel$ = 1 THEN
        IF soundState$ = true THEN
            soundState$ = false
        ELSE
            soundState$ = true
        ENDIF
    ENDIF

    IF menuSel$ = 2 THEN
        IF musicState$ = true THEN
            musicState$ = false
            SOUNDSTOP(menuMusic$)
        ELSE
            musicState$ = true
            SOUNDREPEAT(menuMusic$)
        ENDIF
    ENDIF

    IF menuSel$ = 3 THEN
        LET temp$ = SHELL("cmd /c start manual.pdf")
    ENDIF

    IF menuSel$ = 4 THEN menuAction$ = "exit" : menuDone$ = true
RETURN

' ============================================================
[menu:cleanup]
    SOUNDSTOP(menuMusic$)
	
	' killing the game would clear memory, so this is more for a habbit
    REMOVESHAPE menuBtn$("bg")
    REMOVESHAPE menuBtn$("new_game")
    REMOVESHAPE menuBtn$("sound_on")
    REMOVESHAPE menuBtn$("sound_off")
    REMOVESHAPE menuBtn$("music_on")
    REMOVESHAPE menuBtn$("music_off")
    REMOVESHAPE menuBtn$("manual")
    REMOVESHAPE menuBtn$("exit")
    DELARRAY menuBtn$
    DELARRAY menuY$

    LOADFONT
RETURN

' ============================================================
[menu:moduleEnd]
