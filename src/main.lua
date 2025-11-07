GAME_VERSION = "1.0"

-- Global Game State
gs_scrn = "menu"
async_to_run = {}

-- - Menu state 
gs_mnCsr = 1    -- menu cursr pos
gs_mnSte = {
    Variant = 1,
    versus = 1,
    Color = 1
}

-- - Chess state
gs_csrActv = false
gs_is960 = false
gs_pcLift = nil
gs_pcMvng = nil
gs_pcCptd = nil
gs_curPcLegMvs = {}
gs_plnWt = true
gs_cpuWt = false
gs_cpuBk = false
gs_mvsNtn = {}
gs_posHtr = {}
gs_lstMv = nil
gs_lstCsrPos = {
    white = nil,
    black = nil
}
gs_mvAnimFin = true
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
        ok, err = coresume(lucania_coroutine)
        if not ok then
        end
    else
        lucania_coroutine = nil
        lucania_runSeconds = 0
    end

    if (gs_scrn == "chess") then
        handleChessControls();
        processMoveAnimationFinished();
    elseif (gs_scrn == "menu") then
        handleMainMenuControl();
    elseif (gs_scrn == "matchMenu") then
        handleMatchMenuControl();
    elseif (gs_scrn == "viewNotation") then
        handleViewNotationControl();
    end
end

function _draw()
    if (gs_scrn == "menu") then
        drawMainMenuScreen();
    elseif (gs_scrn == "chess") then
        drawChessboardScreen();
    elseif (gs_scrn == "matchMenu") then
        drawMatchMenuScreen();
    elseif (gs_scrn == "viewNotation") then
        drawViewNotationScreen();
    end
end