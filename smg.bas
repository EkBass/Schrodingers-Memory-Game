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

' INCLUDES
INCLUDE "intro.bas"
INCLUDE "menu.bas"
INCLUDE "game.bas"

' GOSUBS
GOSUB [inits:globals]
GOSUB [inits:screen]
GOSUB [sub:setScreen]



' Loading screen" as intro
LET menuChoice$ = FN Intro$()

' Menu -> game -> menu ... until Exit
GOSUB [menu:init]
GOSUB [menu:run]
GOSUB [menu:cleanup]

WHILE gameExit$ = FALSE
    IF menuAction$ = "new_game" THEN
        GOSUB [game:start]
        GOSUB [menu:init]
        GOSUB [menu:run]
        GOSUB [menu:cleanup]
    ELSE
        gameExit$ = TRUE
    ENDIF
WEND

SOUNDSTOPALL
END


' ********************
' *                  *
' * Subs starts here *
' *                  *
' ********************
[inits:globals]
	' paths
	LET PATH_AUDIO# 	= "assets//audio//"
	LET PATH_IMAGES# 	= "assets//img//"
	LET PATH_PAIRS# 	= "assets/img/pairs//"
	LET soundState$ 	= TRUE
	LET musicState$		= TRUE
	LET gameExit$		= FALSE

	DIM gHsSave$

	LET gDigitColor$  = 0
	LET gDigitTimeMs$ = 0
	LET gDigitY$      = 0
	LET gDigitN$      = 0
	LET gDigitX$      = 0
	LET gColX$        = 0
	LET gDTotalMs$    = 0
	LET gDSecs$       = 0
	LET gDMins$       = 0
	LET gDCenti$      = 0
	LET gDStartX$     = 0
	LET gSt$          = 0
	LET gSh$          = 0
	LET gSw$          = 0
	LET gDx2$         = 0
	LET gDy2$         = 0
	LET gSeg0$        = 0
	LET gSeg1$        = 0
	LET gSeg2$        = 0
	LET gSeg3$        = 0
	LET gSeg4$        = 0
	LET gSeg5$        = 0
	LET gSeg6$        = 0
RETURN
	
	
[inits:screen]
    LET SCREEN_W# 	= 800
    LET SCREEN_H# 	= 600
	LET TITLE# 		= "Schrodinger's Memory Game"
RETURN


[sub:setScreen]
    SCREEN 0, SCREEN_W#, SCREEN_H#, TITLE#
    FULLSCREEN FALSE
RETURN


