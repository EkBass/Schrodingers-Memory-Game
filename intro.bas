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

' This is technically same intro as I used in my previous game RGB Visions
' Nostalgic little  devil

DEF FN Intro$()
    DIM iData$
    LET iData$("block")  = 40
    LET iData$("cols")   = SCREEN_W# / iData$("block")
    LET iData$("rows")   = SCREEN_H# / iData$("block")
    LET iData$("total")  = iData$("cols") * iData$("rows")

    iData$("img") = LOADIMAGE(PATH_IMAGES# + "intro.png")

    MOVESHAPE iData$("img"), 1, 1

    iData$("music") = LOADSOUND(PATH_AUDIO# + "halloween.mp3")


    iData$("framePerBlock") = 13

    ' Loop counters must be regular variables (not array elements)
    LET r$ = 0
    LET c$ = 0
    LET idx$ = 0

    DIM order$
    FOR r$ = 0 TO iData$("rows") - 1
        FOR c$ = 0 TO iData$("cols") - 1
            order$(idx$, 0) = r$
            order$(idx$, 1) = c$
            idx$ = idx$ + 1
        NEXT
    NEXT

    DIM covered$
    FOR r$ = 0 TO iData$("rows") - 1
        FOR c$ = 0 TO iData$("cols") - 1
            covered$(r$, c$) = 1
        NEXT
    NEXT

    LET revealed$ = 0
    LET frameCount$ = 0
    LET running$ = 1
	LET retVal$ = INKEY

    SOUNDONCE(iData$("music"))
	
    WHILE running$ = TRUE
		retVal$ = INKEY
		
		IF retVal$ = 0 THEN retVal$ = MOUSELEFT
		
        IF retVal$ <> 0 THEN
			running$ = FALSE
		END IF
		
        frameCount$ = frameCount$ + 1
        IF MOD(frameCount$, iData$("framePerBlock")) = 0 THEN
            IF revealed$ < iData$("total") THEN
                r$ = order$(revealed$, 0)
                c$ = order$(revealed$, 1)
                covered$(r$, c$) = 0
                revealed$ = revealed$ + 1
            ELSE
                running$ = 0
            ENDIF
        ENDIF

        SCREENLOCK ON
        DRAWSHAPE iData$("img")
        FOR r$ = 0 TO iData$("rows") - 1
            FOR c$ = 0 TO iData$("cols") - 1
                IF covered$(r$, c$) = 1 THEN
                    LINE (c$ * iData$("block"), r$ * iData$("block"))-(c$ * iData$("block") + iData$("block"), r$ * iData$("block") + iData$("block")), RGB(96, 96, 96), BF
                ENDIF
            NEXT
        NEXT
        SCREENLOCK OFF
        SLEEP 20
    WEND

	
    SOUNDSTOP(iData$("music"))

	REMOVESHAPE iData$("img")
	
    DELARRAY order$
    DELARRAY covered$
    DELARRAY iData$
    RETURN retVal$
END DEF