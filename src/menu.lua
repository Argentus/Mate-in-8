
MAIN_MENU_CHOICES = {
    {
        label = "Variant",
        options = {"Chess", "Chess"} -- Add 960 later
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
        gameState_menuControl_menuState[MAIN_MENU_CHOICES[gameState_menuControl_cursor].label] = gameState_menuControl_menuState[MAIN_MENU_CHOICES[gameState_menuControl_cursor].label] % 2 + 1
    elseif (btnp(1)) then
        sfx(0)
        gameState_menuControl_menuState[MAIN_MENU_CHOICES[gameState_menuControl_cursor].label] = (gameState_menuControl_menuState[MAIN_MENU_CHOICES[gameState_menuControl_cursor].label] + 2) % 2 + 1
    elseif (btnp(2)) then
        sfx(2)
        gameState_menuControl_cursor = (gameState_menuControl_cursor - 2) % 3 + 1
    elseif (btnp(3)) then
        sfx(2)
        gameState_menuControl_cursor = (gameState_menuControl_cursor) % 3 + 1
    end

    if (btnp(5)) then
        sfx(1);
        gameState_currentGamePosition = getStartingPosition()
        gameState_startPosition = deep_copy(gameState_currentGamePosition)
        gameState_boardControl_cursor = vector(4, 2)
        gameState_boardControl_movesNotation = {}
        gameState_boardControl_positionsHistory = {}
        gameState_boardControl_lastMove = nil
        gameState_boardControl_lastCursorPos = {
            white = nil,
            black = nil
        }
        gameState_playingWhite = gameState_menuControl_menuState.Color == 1
        gameState_computerControlsBlack = gameState_menuControl_menuState.versus == 1 and gameState_playingWhite
        gameState_computerControlsWhite = gameState_menuControl_menuState.versus == 1 and not gameState_playingWhite
        gameState_boardControl_cursorActive = not ((gameState_currentGamePosition.whiteTurn and gameState_computerControlsWhite) or (not gameState_currentGamePosition.whiteTurn and gameState_computerControlsBlack));
        gameState_currentScreen = "chess";

        -- Delay to avoid freez in menu
        add(async_to_run, cocreate(function()
            for i=0,3 do
                yield()
            end
            gameState_moveAnimationFinished = true
        end))
    end
end

function drawMainMenuScreen()
    drawChessboardBackground();
    sspr(0, 64, 128, 32, 0, 16);

    print_custom("v." .. GAME_VERSION, 32, 44, 9);

    print("Start game:", 20, 66, 2)
    print("Start game:", 21, 65, 1)
    print("Start game:", 22, 64, 7)

    for i, setting in pairs(MAIN_MENU_CHOICES) do
        local y = 66 + i * 8
        nSpaces = flr((20 - #setting.options[gameState_menuControl_menuState[setting.label]]) / 2 - #setting.label)
        spaces = ""
        for i = 0, nSpaces do
            spaces = spaces .. " "
        end

        local text = (gameState_menuControl_cursor == i and "> " or "  ") .. setting.label .. spaces .. " << " .. setting.options[gameState_menuControl_menuState[setting.label]] .. " >> "
        print(text, 20, y+1, gameState_menuControl_cursor == i and 8 or 5)
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

    rectfill(14, 18, 80, 81, 1)
    rectfill(15, 17, 80, 80, 2)
    rectfill(16, 16, 80, 79, 5)
    rectfill(17, 17, 79, 78, 0)
    rectfill(18, 18, 78, 77, 15)

    if gameState_matchOver then
        local reason = gameState_matchOver.reason
        local result = gameState_matchOver.result
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
        "Resume", "View moves", "Copy PGN", "Exit Match" 
    }

    for i,option in pairs(CHOICES) do
        print((gameState_menuControl_cursor == i and "> " or "  ") .. option, 22, 36 + i * 8, gameState_menuControl_cursor == i and 7 or 9)
        print((gameState_menuControl_cursor == i and "> " or "  ") .. option, 23, 35 + i * 8, 2)
    end

    print("(Y) back to game", 8, 120, 7);
end

function handleMatchMenuControl()
    if (btnp(4)) then
        sfx(0)
        gameState_currentScreen = "chess"
    end

    if (btnp(5)) then
        sfx(1)
        if (gameState_menuControl_cursor == 1) then
            gameState_currentScreen = "chess"
        elseif (gameState_menuControl_cursor == 2) then
            gameState_boardControl_cursorActive = false
            gameState_currentScreen = "viewNotation"
            gameState_menuControl_cursor = #gameState_boardControl_movesNotation
        elseif (gameState_menuControl_cursor == 3) then
            -- Copy PGN
            local pgn = ""
            for i = 1, #gameState_boardControl_movesNotation, 2 do
                local number = flr((i+1)/2)
                pgn = pgn .. number .."." .. gameState_boardControl_movesNotation[i] .. " " .. ((#gameState_boardControl_movesNotation >= i+1) and (gameState_boardControl_movesNotation[i+1] .. " ") or "")
            end
            printh(pgn, "@clip")

        elseif (gameState_menuControl_cursor == 4) then
            gameState_currentScreen = "menu"
            gameState_menuControl_cursor = 1
            gameState_menuControl_menuState = {
                Variant = 1,
                versus = 1,
                Color = 1
            }
        end
    end

    if (btnp(2)) then
        sfx(2)
        gameState_menuControl_cursor = (gameState_menuControl_cursor - 2) % 4 + 1
    elseif (btnp(3)) then
        sfx(2)
        gameState_menuControl_cursor = (gameState_menuControl_cursor) % 4 + 1
    end
end