GAME_VERSION = "1.0"

-- Global Game State
gameState_currentScreen = "menu"
async_to_run = {}

-- - Menu state 
gameState_menuControl_cursor = 1
gameState_menuControl_menuState = {
    Variant = 1,
    versus = 1,
    Color = 1
}

-- - Chess state
gameState_boardControl_cursorActive = false
gameState_boardControl_pieceLifted = nil
gameState_boardControl_pieceMoving = nil
gameState_boardControl_pieceCaptured = nil
gameState_boardControl_currentPieceLegalMoves = {}
gameState_playingWhite = true
gameState_computerControlsWhite = false
gameState_computerControlsBlack = false
gameState_boardControl_movesNotation = {}
gameState_boardControl_positionsHistory = {}
gameState_boardControl_lastMove = nil
gameState_boardControl_lastCursorPos = {
    white = nil,
    black = nil
}
gameState_moveAnimationFinished = true
lucania_coroutine = nil
lucania_runSeconds = 0

function _init()
    initZobrist()
    
    palt(11, true)
    palt(0, false)
end

function _update()

    for r in all(async_to_run) do
        if (costatus(r) != "dead") then
            coresume(r)
        else
            del(async_to_run, r)
        end
    end

    if lucania_coroutine and costatus(lucania_coroutine) != "dead" then
        lucania_runSeconds =  stat(85) - lucania_startSecond + 1
        if lucania_runSeconds < 0 then
            lucania_runSeconds = lucania_runSeconds + 60
        end
        coresume(lucania_coroutine)
    else
        lucania_coroutine = nil
        lucania_runSeconds = 0
    end

    if (gameState_currentScreen == "chess") then
        handleChessControls();
        processMoveAnimationFinished();
    elseif (gameState_currentScreen == "menu") then
        handleMainMenuControl();
    elseif (gameState_currentScreen == "matchMenu") then
        handleMatchMenuControl();
    elseif (gameState_currentScreen == "viewNotation") then
        handleViewNotationControl();
    end
end

function _draw()
    if (gameState_currentScreen == "menu") then
        drawMainMenuScreen();
    elseif (gameState_currentScreen == "chess") then
        drawChessboardScreen();
    elseif (gameState_currentScreen == "matchMenu") then
        drawMatchMenuScreen();
    elseif (gameState_currentScreen == "viewNotation") then
        drawViewNotationScreen();
    end
end