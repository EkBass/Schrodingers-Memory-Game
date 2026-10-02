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

LET GAME_GRID#         = 5
LET GAME_CELLS#        = 25
LET GAME_CENTER#       = 12         ' row 3, column 3 - Schrodinger's box
LET GAME_PAIRS#        = 12
LET GAME_SPECIES#      = 16         ' 1a/1b ... Na/Nb in assets/img/pairs. "Species" is bit silly, but this was after 4th beer
LET GAME_SCALE#        = 0.75
LET GAME_CARD#         = 96
LET GAME_GAP#          = 10
LET GAME_STEP#         = GAME_CARD# + GAME_GAP#
LET GAME_BOARD_W#      = GAME_GRID# * GAME_CARD# + (GAME_GRID# - 1) * GAME_GAP#
LET GAME_BOARD_X#      = (800 - GAME_BOARD_W#) / 2
LET GAME_BOARD_Y#      = 66

' --- Timing and scoring ---
LET GAME_PREVIEW_MS#   = 10000
LET GAME_REVEAL_MS#    = 1000       ' how long missed pair stays visible
LET GAME_START_TIME#   = 220        ' seconds to play
LET GAME_LOW_TIME#     = 30         ' clock turns red here
LET GAME_BONUS_ALIVE#  = 5
LET GAME_BONUS_DEAD#   = 0
LET GAME_PENALTY#      = 5
LET GAME_LAUGH_ONE_IN# = 10         ' 1 miss in N laughs instead of buzzing

' --- Arrays: DIM'd once here, refilled on every new game ---
DIM gameImg$                        ' image handles: "1a".."16b", "back-a", "back-b"
DIM gameRoster$                     ' shuffled species numbers 1..GAME_SPECIES#
DIM gameDeck$                       ' the 24 cards before they are laid out
DIM gameSpecies$                    ' per cell 0..24: species, -1 = the box
DIM gameAlive$                      ' per cell: TRUE alive / FALSE dead
DIM gameOpen$                       ' per cell: TRUE when matched

' --- Game state ---
LET gameAssetsLoaded$  = FALSE
LET gameRunning$       = FALSE
LET gameState$         = ""         ' preview / pick1 / pick2 / reveal / over
LET gameStateTick$     = 0
LET gameStartTick$     = 0
LET gameTimeLeft$      = 0
LET gameBonus$         = 0
LET gamePairs$         = 0
LET gameAlivePairs$    = 0
LET gameDeadPairs$     = 0
LET gameMisses$        = 0
LET gamePick1$         = -1
LET gamePick2$         = -1
LET gameMatch$         = FALSE
LET gameWon$           = FALSE
LET gameNewRecord$     = FALSE
LET gameBest$          = 0

' --- Input ---
LET gameKey$           = 0
LET gameMouseNow$      = 0
LET gameMouseWas$      = 0
LET gameClicked$       = FALSE
LET gameCell$          = -1
LET gameLocalX$        = 0
LET gameLocalY$        = 0
LET gameCol$           = 0
LET gameRow$           = 0

' --- Helpers. GOSUB shares one scope with the whole program, so every
'     subroutine uses its own names to avoid accidental collisions. ---
LET gameSwap$          = 0
LET gameTmp$           = 0
LET gameDeckPos$       = 0
LET gdX$               = 0
LET gdY$               = 0
LET gdKey$             = ""
LET gdFace$            = FALSE
LET gdSecs$            = 0
LET gdLine1$           = ""
LET gdLine2$           = ""

GOTO [game:moduleEnd]

' ============================================================
' Main loop of one game
' ============================================================
[game:start]
    GOSUB [game:loadAssets]
    GOSUB [game:resetVars]
    GOSUB [game:deal]

    IF musicState$ THEN SOUNDREPEAT(SND_MUSIC#)

    gameState$     = "preview"
    gameStateTick$ = TICKS
    gameMouseWas$  = MOUSELEFT
    gameRunning$   = TRUE

    WHILE gameRunning$
        gameKey$ = INKEY
        IF gameKey$ = KEY_ESC# THEN gameRunning$ = FALSE

        GOSUB [game:readMouse]
        GOSUB [game:update]

        SCREENLOCK ON
        GOSUB [game:draw]
        SCREENLOCK OFF
        SLEEP 16
    WEND

    SOUNDSTOP(SND_MUSIC#)
RETURN

' ============================================================
' 
' ============================================================
[game:loadAssets]
    IF gameAssetsLoaded$ = FALSE THEN
        FOR gl$ = 1 TO GAME_SPECIES#
            gameImg$(gl$ + "a") = LOADIMAGE(PATH_PAIRS# + gl$ + "a.png")
            gameImg$(gl$ + "b") = LOADIMAGE(PATH_PAIRS# + gl$ + "b.png")
            SCALESHAPE gameImg$(gl$ + "a"), GAME_SCALE#
            SCALESHAPE gameImg$(gl$ + "b"), GAME_SCALE#
        NEXT gl$
        ' Card backs: back-a = alive, back-b = dead. The difference is
        ' subtle on purpose - an observant player can read the state.
        gameImg$("back-a") = LOADIMAGE(PATH_PAIRS# + "back-a.png")
        gameImg$("back-b") = LOADIMAGE(PATH_PAIRS# + "back-b.png")
        SCALESHAPE gameImg$("back-a"), GAME_SCALE#
        SCALESHAPE gameImg$("back-b"), GAME_SCALE#

        ' Sound handles never change -> constants
        LET SND_MUSIC#     = LOADSOUND(PATH_AUDIO# + "lofi.mp3")
        LET SND_CORRECT#   = LOADSOUND(PATH_AUDIO# + "correct.mp3")
        LET SND_INCORRECT# = LOADSOUND(PATH_AUDIO# + "incorrect.mp3")
        LET SND_LAUGH#     = LOADSOUND(PATH_AUDIO# + "laugh.mp3")

        ' Colors are created once, not every frame
        LET GAME_COL_BG#      = RGB(20, 12, 30)
        LET GAME_COL_TEXT#    = RGB(230, 220, 200)
        LET GAME_COL_TIME#    = RGB(255, 170, 40)
        LET GAME_COL_PICK#    = RGB(255, 170, 40)
        LET GAME_COL_GOOD#    = RGB(90, 200, 90)
        LET GAME_COL_BAD#     = RGB(220, 60, 60)
        LET GAME_COL_BOX#     = RGB(45, 25, 60)
        LET GAME_COL_BOXLINE# = RGB(140, 90, 170)

        gameAssetsLoaded$ = TRUE
    END IF
RETURN

' ============================================================
[game:resetVars]
    gameTimeLeft$   = GAME_START_TIME#
    gameBonus$      = 0
    gamePairs$      = 0
    gameAlivePairs$ = 0
    gameDeadPairs$  = 0
    gameMisses$     = 0
    gamePick1$      = -1
    gamePick2$      = -1
    gameWon$        = FALSE
    gameNewRecord$  = FALSE
RETURN

' ============================================================
' Picks 12 random cards, doubles them, shuffles (Fisher-Yates)
' and lays the cards on the board, skipping the center box.
' ============================================================
[game:deal]
    FOR gs$ = 0 TO GAME_SPECIES# - 1
        gameRoster$(gs$) = gs$ + 1
    NEXT gs$
    FOR gs$ = GAME_SPECIES# - 1 TO 1 STEP -1
        gameSwap$ = RND(gs$ + 1)
        gameTmp$ = gameRoster$(gs$)
        gameRoster$(gs$) = gameRoster$(gameSwap$)
        gameRoster$(gameSwap$) = gameTmp$
    NEXT gs$

    FOR gs$ = 0 TO GAME_PAIRS# - 1
        gameDeck$(gs$ * 2) = gameRoster$(gs$)
        gameDeck$(gs$ * 2 + 1) = gameRoster$(gs$)
    NEXT gs$
    FOR gs$ = GAME_PAIRS# * 2 - 1 TO 1 STEP -1
        gameSwap$ = RND(gs$ + 1)
        gameTmp$ = gameDeck$(gs$)
        gameDeck$(gs$) = gameDeck$(gameSwap$)
        gameDeck$(gameSwap$) = gameTmp$
    NEXT gs$

    gameDeckPos$ = 0
    FOR gs$ = 0 TO GAME_CELLS# - 1
        gameAlive$(gs$) = TRUE
        gameOpen$(gs$) = FALSE
        IF gs$ = GAME_CENTER# THEN
            gameSpecies$(gs$) = -1
        ELSE
            gameSpecies$(gs$) = gameDeck$(gameDeckPos$)
            gameDeckPos$ += 1
        END IF
    NEXT gs$
RETURN

' ============================================================
' Input
' ============================================================

' A click is the moment the button goes down
[game:readMouse]
    gameMouseNow$ = MOUSELEFT
    gameClicked$ = FALSE
    IF gameMouseNow$ = 1 AND gameMouseWas$ = 0 THEN gameClicked$ = TRUE
    gameMouseWas$ = gameMouseNow$
RETURN

' Sets gameCell$ to the card under the mouse (0..24), or -1.
[game:cellAtMouse]
    gameCell$ = -1
    gameLocalX$ = MOUSEX - GAME_BOARD_X#
    gameLocalY$ = MOUSEY - GAME_BOARD_Y#
    IF gameLocalX$ >= 0 AND gameLocalY$ >= 0 THEN
        gameCol$ = INT(gameLocalX$ / GAME_STEP#)
        gameRow$ = INT(gameLocalY$ / GAME_STEP#)
        IF gameCol$ < GAME_GRID# AND gameRow$ < GAME_GRID# THEN
            IF gameLocalX$ - gameCol$ * GAME_STEP# < GAME_CARD# AND gameLocalY$ - gameRow$ * GAME_STEP# < GAME_CARD# THEN
                gameCell$ = gameRow$ * GAME_GRID# + gameCol$
            END IF
        END IF
    END IF
RETURN

' ============================================================
' Game logic - step per frame
' ============================================================
[game:update]
    IF gameState$ = "preview" THEN
        IF TICKS - gameStateTick$ >= GAME_PREVIEW_MS# THEN
            gameState$ = "pick1"
            gameStartTick$ = TICKS          ' the clock starts now
        END IF

    ELSEIF gameState$ = "over" THEN
        IF gameClicked$ OR gameKey$ = KEY_ENTER# THEN gameRunning$ = FALSE

    ELSE
        ' pick1 / pick2 / reveal - the clock is running
        GOSUB [game:updateTime]
        IF gameTimeLeft$ <= 0 THEN
            gameTimeLeft$ = 0
            gameWon$ = FALSE
            gameState$ = "over"
        ELSEIF gameState$ = "reveal" THEN
            IF TICKS - gameStateTick$ >= GAME_REVEAL_MS# THEN
                ' The observation changed them: flip both cards
                gameAlive$(gamePick1$) = 1 - gameAlive$(gamePick1$)
                gameAlive$(gamePick2$) = 1 - gameAlive$(gamePick2$)
                gamePick1$ = -1
                gamePick2$ = -1
                gameState$ = "pick1"
            END IF
        ELSEIF gameClicked$ THEN
            GOSUB [game:cellAtMouse]
            GOSUB [game:tryPick]
        END IF
    END IF
RETURN

' Time left = start time + bonuses - elapsed seconds
[game:updateTime]
    gameTimeLeft$ = GAME_START_TIME# + gameBonus$ - INT((TICKS - gameStartTick$) / 1000)
RETURN

' Accepts the clicked card if it is a legal pick
[game:tryPick]
    IF gameCell$ <> -1 AND gameCell$ <> GAME_CENTER# THEN
        IF gameOpen$(gameCell$) = FALSE AND gameCell$ <> gamePick1$ THEN
            IF gameState$ = "pick1" THEN
                gamePick1$ = gameCell$
                gameState$ = "pick2"
            ELSE
                gamePick2$ = gameCell$
                GOSUB [game:resolve]
            END IF
        END IF
    END IF
RETURN

' Second card is open: solve the outcome.
[game:resolve]
    gameMatch$ = FALSE
    IF gameSpecies$(gamePick1$) = gameSpecies$(gamePick2$) THEN
        IF gameAlive$(gamePick1$) = gameAlive$(gamePick2$) THEN gameMatch$ = TRUE
    END IF

    IF gameMatch$ THEN
        gameOpen$(gamePick1$) = TRUE
        gameOpen$(gamePick2$) = TRUE
        gamePairs$ += 1
        IF gameAlive$(gamePick1$) THEN
            gameBonus$ += GAME_BONUS_ALIVE#
            gameAlivePairs$ += 1
        ELSE
            gameBonus$ += GAME_BONUS_DEAD#
            gameDeadPairs$ += 1
        END IF
        IF soundState$ THEN SOUNDONCE(SND_CORRECT#)

        gamePick1$ = -1
        gamePick2$ = -1
        IF gamePairs$ = GAME_PAIRS# THEN
            GOSUB [game:updateTime]
            gameWon$ = TRUE
            GOSUB [game:saveScore]
            gameState$ = "over"
        ELSE
            gameState$ = "pick1"
        END IF
    ELSE
        gameBonus$ -= GAME_PENALTY#
        gameMisses$ += 1
        IF soundState$ THEN
            IF RND(GAME_LAUGH_ONE_IN#) = 0 THEN
                SOUNDONCE(SND_LAUGH#)
            ELSE
                SOUNDONCE(SND_INCORRECT#)
            END IF
        END IF
        gameState$ = "reveal"
        gameStateTick$ = TICKS
    END IF
RETURN

' Score = time left,
[game:saveScore]
    gameBest$ = 0
    IF HASKEY(gHsSave$("best")) THEN gameBest$ = VAL(gHsSave$("best"))
    gameNewRecord$ = FALSE
    IF gameTimeLeft$ > gameBest$ THEN
        gameNewRecord$ = TRUE
        gHsSave$("best") = gameTimeLeft$
        FILEWRITE "highscore.txt", gHsSave$
    END IF
RETURN

' ============================================================
' Drawing
' ============================================================
[game:draw]
    LINE (0, 0)-(SCREEN_W#, SCREEN_H#), GAME_COL_BG#, BF
    GOSUB [game:drawHud]

    FOR gd$ = 0 TO GAME_CELLS# - 1
        gdX$ = GAME_BOARD_X# + MOD(gd$, GAME_GRID#) * GAME_STEP#
        gdY$ = GAME_BOARD_Y# + INT(gd$ / GAME_GRID#) * GAME_STEP#

        IF gd$ = GAME_CENTER# THEN
            ' Schrodinger's box - drawn with LINE, never opens
            LINE (gdX$, gdY$)-(gdX$ + GAME_CARD#, gdY$ + GAME_CARD#), GAME_COL_BOX#, BF
            LINE (gdX$, gdY$)-(gdX$ + GAME_CARD#, gdY$ + GAME_CARD#), GAME_COL_BOXLINE#, B
            DRAWSTRING "?", gdX$ + 44, gdY$ + 38, GAME_COL_BOXLINE#
        ELSE
            gdFace$ = FALSE
            IF gameState$ = "preview" OR gameState$ = "over" THEN gdFace$ = TRUE
            IF gameOpen$(gd$) OR gd$ = gamePick1$ OR gd$ = gamePick2$ THEN gdFace$ = TRUE

            IF gdFace$ THEN
                IF gameAlive$(gd$) THEN
                    gdKey$ = gameSpecies$(gd$) + "a"
                ELSE
                    gdKey$ = gameSpecies$(gd$) + "b"
                END IF
            ELSE
                ' Face down: the back still hints at the state
                IF gameAlive$(gd$) THEN
                    gdKey$ = "back-a"
                ELSE
                    gdKey$ = "back-b"
                END IF
            END IF

            MOVESHAPE gameImg$(gdKey$), gdX$, gdY$
            DRAWSHAPE gameImg$(gdKey$)

            IF gd$ = gamePick1$ OR gd$ = gamePick2$ THEN
                LINE (gdX$ - 3, gdY$ - 3)-(gdX$ + GAME_CARD# + 2, gdY$ + GAME_CARD# + 2), GAME_COL_PICK#, B
            END IF
        END IF
    NEXT gd$
RETURN

[game:drawHud]
    IF gameState$ = "preview" THEN
        gdSecs$ = CEIL((GAME_PREVIEW_MS# - (TICKS - gameStateTick$)) / 1000)
        gdLine1$ = FSTRING("Memorize the board! Everything is ALIVE... for {{-gdSecs$-}} more seconds.")
        DRAWSTRING gdLine1$, 20, 12, GAME_COL_TEXT#
        DRAWSTRING "A pair must match in creature AND state. A miss flips both cards.", 20, 36, GAME_COL_TEXT#

    ELSEIF gameState$ = "over" THEN
        IF gameWon$ THEN
            IF gameNewRecord$ THEN
                gdLine1$ = FSTRING("Every box is open! Score {{-gameTimeLeft$-}} - NEW RECORD!")
            ELSE
                gdLine1$ = FSTRING("Every box is open! Score {{-gameTimeLeft$-}}   (best {{-gameBest$-}})")
            END IF
            DRAWSTRING gdLine1$, 20, 12, GAME_COL_GOOD#
        ELSE
            DRAWSTRING "Time ran out. The box opens itself...", 20, 12, GAME_COL_BAD#
        END IF
        gdLine2$ = FSTRING("Living pairs {{-gameAlivePairs$-}}   Dead pairs {{-gameDeadPairs$-}}   Misses {{-gameMisses$-}}      Click or press Enter")
        DRAWSTRING gdLine2$, 20, 36, GAME_COL_TEXT#

    ELSE
        gdLine1$ = FSTRING("TIME  {{-gameTimeLeft$-}}")
        IF gameTimeLeft$ <= GAME_LOW_TIME# THEN
            DRAWSTRING gdLine1$, 20, 24, GAME_COL_BAD#
        ELSE
            DRAWSTRING gdLine1$, 20, 24, GAME_COL_TIME#
        END IF
        gdLine2$ = FSTRING("PAIRS  {{-gamePairs$-}} / {{-GAME_PAIRS#-}}")
        DRAWSTRING gdLine2$, 660, 24, GAME_COL_TEXT#
    END IF
RETURN

' ============================================================
[game:moduleEnd]
