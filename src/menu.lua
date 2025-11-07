
MAIN_MENU_CHOICES = {
    {
        label = "Variant",
        options = {"Chess", "Chess960"}
    },
    {
        label = "versus",
        options = {"Computer", "Player"}
    },
    {
        label = "Color",
        options = {"White", "Black"}
    }
}

function handleMainMenuControl()
    if (btnp(0) or btnp(4)) then
        sfx(0)
        gs_mnSte[MAIN_MENU_CHOICES[gs_mnCsr].label] = gs_mnSte[MAIN_MENU_CHOICES[gs_mnCsr].label] % 2 + 1
    elseif (btnp(1)) then
        sfx(0)
        gs_mnSte[MAIN_MENU_CHOICES[gs_mnCsr].label] = (gs_mnSte[MAIN_MENU_CHOICES[gs_mnCsr].label] + 2) % 2 + 1
    elseif (btnp(2)) then
        sfx(2)
        gs_mnCsr = (gs_mnCsr - 2) % 3 + 1
    elseif (btnp(3)) then
        sfx(2)
        gs_mnCsr = (gs_mnCsr) % 3 + 1
    end

    if (btnp(5)) then
        sfx(1);
        gs_is960 = gs_mnSte["Variant"] == 2
        gs_curGmPos = gs_is960 and get960StartingPosition() or getStartingPosition()
        gameState_startPosition = deep_copy(gs_curGmPos)
        gs_csr = vector(4, 2)
        gs_mvsNtn = {}
        gs_posHtr = {}
        gs_lstMv = nil
        gs_lstCsrPos = {
            white = nil,
            black = nil
        }
        gs_matchOvr = nil
        gameState_playingWhite = gs_mnSte.Color == 1
        gs_cpuBk = gs_mnSte.versus == 1 and gameState_playingWhite
        gs_cpuWt = gs_mnSte.versus == 1 and not gameState_playingWhite
        gs_csrActv = not ((gs_curGmPos.whiteTurn and gs_cpuWt) or (not gs_curGmPos.whiteTurn and gs_cpuBk));
        gs_scrn = "chess";

        -- Delay to avoid freez in menu
        add(async_to_run, cocreate(function()
            for i=0,3 do
                yield()
            end
            gs_mvAnimFin = true
        end))
    end
end

function drawMainMenuScreen()
    drawChessboardBackground();
    sspr(0, 64, 128, 32, 0, 16);

    print_custom("v." .. GAME_VERSION, 32, 44, 9);
    print_custom("by Argentus", 29, 51, 6);

    print("Start game:", 20, 66, 2)
    print("Start game:", 21, 65, 1)
    print("Start game:", 22, 64, 7)

    for i, setting in pairs(MAIN_MENU_CHOICES) do
        local y = 66 + i * 8
        nSpaces = flr((20 - #setting.options[gs_mnSte[setting.label]]) / 2 - #setting.label)
        spaces = ""
        for i = 0, nSpaces do
            spaces = spaces .. " "
        end

        local text = (gs_mnCsr == i and "> " or "  ") .. setting.label .. spaces .. " << " .. setting.options[gs_mnSte[setting.label]] .. " >> "
        print(text, 20, y+1, gs_mnCsr == i and 8 or 5)
        print(text, 20, y, 7)
    end

    print("Press (X) to Start!", 23, 106, 2)
    print("Press (X) to Start!", 24, 105, 7)
end

function drawMatchMenuScreen()
    processAnimations()
    drawChessboardBackground()
    drawChessboard()
    drawChessboardUI()

    rectfill(14, 18, 80, 88, 1)
    rectfill(15, 17, 80, 87, 2)
    rectfill(16, 16, 80, 86, 5)
    rectfill(17, 17, 79, 85, 0)
    rectfill(18, 18, 78, 84, 15)

    if gs_matchOvr then
        local reason = gs_matchOvr.reason
        local result = gs_matchOvr.result
        if reason == "mate" then
            print("Checkmate", 27, 25, 9)
            print("Checkmate", 27, 24, 1)
        elseif reason == "stale" then
            print("Stalemate", 27, 25, 9)
            print("Stalemate", 27, 24, 1)
        end

        if result == "white" then 
            print("White wins", 25, 32, 0)
            print("White wins", 27, 30, 0)
            print("White wins", 26, 31, 7)
        elseif result == "black" then
            print("Black wins", 26, 32, 7)
            print("Black wins", 28, 30, 7)
            print("Black wins", 27, 31, 0)
        else
            print("It's a draw", 26, 30, 9)
            print("It's a draw", 24, 32, 9)
            print("It's a draw", 25, 31, 2)
        end
    else
        print("Game Paused", 23, 25, 9)
        print("Game Paused", 23, 24, 1)
    end

    local CHOICES = {
        "Resume", "View moves", "Copy PGN", "Copy FEN", "Exit Match" 
    }

    for i,option in pairs(CHOICES) do
        print((gs_mnCsr == i and "> " or "  ") .. option, 22, 36 + i * 8, gs_mnCsr == i and 7 or 9)
        print((gs_mnCsr == i and "> " or "  ") .. option, 23, 35 + i * 8, 2)
    end

    print("(Y) back to game", 8, 120, 7);
end

function handleMatchMenuControl()
    if (btnp(4)) then
        sfx(0)
        gs_scrn = "chess"
    end

    if (btnp(5)) then
        sfx(1)
        if (gs_mnCsr == 1) then
            gs_scrn = "chess"
        elseif (gs_mnCsr == 2) then
            gs_csrActv = false
            gs_scrn = "viewNotation"
            gs_mnCsr = #gs_mvsNtn
        elseif (gs_mnCsr == 3) then
            -- Copy PGN
            local pgn = ""
            pgn ..= "[Date \"" .. stat(90) .. "." .. stat(91) .. "." .. stat(92) .. "\"]\n"
            pgn ..= "[White \"" .. (gs_cpuWt and "Lucania Chess Computer" or (gameState_playingWhite and "Player 1" or "Player 2")) .. "\"]\n"
            pgn ..= "[Black \"" .. (gs_cpuBk and "Lucania Chess Computer" or (gameState_playingWhite and "Player 2" or "Player 1")) .. "\"]\n"
            
            local result = nil
            if (gs_matchOvr) then
                result = gs_matchOvr.result
                if result == "white" then
                    result = "1-0"
                elseif result == "black" then
                    result = "0-1"
                else
                    result = "1/2-1/2"
                end
                pgn = pgn .. "[Result \"" .. result .. "\"]\n"
            else 
                pgn = pgn .. "[Result \"*\"]\n"
            end

            if (gs_is960) then
                pgn = pgn .. "[Variant \"Chess960\"]\n"
            end
            if (gs_curGmPos.visitedPositions[1] ~= "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") then
                pgn = pgn .. "[FEN \"" .. gs_curGmPos.visitedPositions[1] .. "\"]\n[SetUp \"1\"]\n" 
            end

            pgn = pgn .. "\n"
            for i = 1, #gs_mvsNtn, 2 do
                local number = flr((i+1)/2)
                pgn = pgn .. number .."." .. gs_mvsNtn[i] .. " " .. ((#gs_mvsNtn >= i+1) and (gs_mvsNtn[i+1] .. " ") or "")
            end
            if result then
                pgn = pgn .. " " .. result
            end
            printh(pgn, "@clip")

        elseif (gs_mnCsr == 4) then
            -- Copy FEN
            local fen = getFen(gs_curGmPos)
            printh(fen, "@clip")

        elseif (gs_mnCsr == 5) then
            gs_scrn = "menu"
            gs_mnCsr = 1
            gs_mnSte = {
                Variant = 1,
                versus = 1,
                Color = 1
            }
        end
    end

    if (btnp(2)) then
        sfx(2)
        gs_mnCsr = (gs_mnCsr - 2) % 5 + 1
    elseif (btnp(3)) then
        sfx(2)
        gs_mnCsr = (gs_mnCsr) % 5 + 1
    end
end