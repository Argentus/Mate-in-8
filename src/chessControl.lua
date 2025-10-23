

function handleChessControls()
    if lucania_coroutine  then
        coresume(lucania_coroutine)
    end

    if (gameState_boardControl_cursorActive) then
        local moveCursor
        if btnp(0) then
            moveCursor = gameState_playingWhite and vector(-2, -1) or vector(0, -1)
        elseif btnp(1) then
            moveCursor = gameState_playingWhite and vector(0, -1) or vector(-2, -1)
        elseif btnp(2) then
            moveCursor = gameState_playingWhite and vector(-1, 0) or vector(-1, -2)
        elseif btnp(3) then
            moveCursor = gameState_playingWhite and vector(-1, -2) or vector(-1, 0)
        end

        if moveCursor then
            sfx(2);
            gameState_boardControl_cursor = vector((gameState_boardControl_cursor.x + moveCursor.x )% 8 + 1, (gameState_boardControl_cursor.y + moveCursor.y )% 8 + 1)
        end

        if btnp(5) then
            local board = gameState_currentGamePosition.board
            local cursorIndex = boardIndex(gameState_boardControl_cursor)
            local piece = board[cursorIndex]

            if not gameState_boardControl_pieceLifted then
                if piece ~= "." and (isWhitePiece(piece) == gameState_currentGamePosition.whiteTurn) then
                    sfx(3);
                    gameState_boardControl_currentPieceLegalMoves = getPieceLegalMoves(gameState_currentGamePosition, gameState_boardControl_cursor)
                    gameState_boardControl_pieceLifted = gameState_boardControl_cursor
                end
            else
                if vectorcmp(gameState_boardControl_cursor, gameState_boardControl_pieceLifted) then
                    gameState_boardControl_pieceLifted = nil
                    gameState_boardControl_currentPieceLegalMoves = {}
                elseif isSameColorPiece(board[cursorIndex], board[boardIndex(gameState_boardControl_pieceLifted)]) then
                    sfx(3);
                    gameState_boardControl_currentPieceLegalMoves = getPieceLegalMoves(gameState_currentGamePosition, gameState_boardControl_cursor)
                    gameState_boardControl_pieceLifted = gameState_boardControl_cursor
                elseif contains(gameState_boardControl_currentPieceLegalMoves, cursorIndex) then
                    gameState_boardControl_cursorActive = false
                    gameState_boardControl_lastCursorPos[gameState_currentGamePosition.whiteTurn and "white" or "black"] = gameState_boardControl_cursor;
                    gameState_boardControl_pieceMoving = {from = gameState_boardControl_pieceLifted, to = gameState_boardControl_cursor}
                    gameState_boardControl_currentPieceLegalMoves = {}
                    if board[cursorIndex] ~= "." then
                        gameState_boardControl_pieceCaptured = gameState_boardControl_cursor
                    end
                    gameState_boardControl_pieceLifted = nil
                end
            end
        end
    end

    if (btnp(4)) then
        sfx(0)
        gameState_currentScreen = "matchMenu"
        gameState_menuControl_cursor = 1
        gameState_menuControl_menuState = {}
    end


end

function on_moveAnimationFinished()
    sfx(4);

    gameState_moveAnimationFinished = true
    makeMove(gameState_currentGamePosition, 
        boardIndex(gameState_boardControl_pieceMoving.from), 
        boardIndex(gameState_boardControl_pieceMoving.to))

    if (isMate(gameState_currentGamePosition, gameState_currentGamePosition.whiteTurn)) then
        gameState_matchOver = {
            reason = "mate",
            result = gameState_currentGamePosition.whiteTurn and "black" or "white"
        }
    elseif (isStalemate(gameState_currentGamePosition, gameState_currentGamePosition.whiteTurn)) then
        gameState_matchOver = {
            reason = "stale",
            result = "draw"
        }
    end

    gameState_boardControl_movesNotation[#gameState_boardControl_movesNotation + 1] = getMoveNotation(gameState_boardControl_positionsHistory[#gameState_boardControl_positionsHistory] or gameState_startPosition, gameState_boardControl_pieceMoving.from, gameState_boardControl_pieceMoving.to)
    if (isCheck(gameState_currentGamePosition, gameState_currentGamePosition.whiteTurn)) then
        sfx(5);
    end
    gameState_boardControl_positionsHistory[#gameState_boardControl_positionsHistory + 1] = deep_copy(gameState_currentGamePosition)
    gameState_boardControl_pieceMoving = nil
    gameState_boardControl_pieceCaptured = nil
end

function processMoveAnimationFinished()
    if gameState_moveAnimationFinished then
        gameState_moveAnimationFinished = false
    
        if gameState_matchOver == nil and (gameState_currentGamePosition.whiteTurn and gameState_computerControlsWhite) or (not gameState_currentGamePosition.whiteTurn and gameState_computerControlsBlack) then
            lucania_startSecond = stat(85)
            lucania_coroutine = cocreate(function()
                move, score = lucania_search(gameState_currentGamePosition, gameState_currentGamePosition.whiteTurn)
                move_from = boardIndexToSquare(move.from)
                move_to = boardIndexToSquare(move.to)
                gameState_boardControl_pieceMoving = {from = move_from, to = move_to}
            end)

        elseif gameState_matchOver then
            gameState_boardControl_cursorActive = false

            -- Delay game over splash
            add(async_to_run, cocreate(function()
                for i=0,45 do
                    yield()
                end
                music(0)
                gameState_currentScreen = "matchMenu"
                gameState_menuControl_cursor = 1
            end))

        else
            gameState_boardControl_cursorActive = true
            gameState_boardControl_cursor = gameState_boardControl_lastCursorPos[gameState_currentGamePosition.whiteTurn and "white" or "black"] or vector(4, 4);
        end
    end

end

function handleViewNotationControl()

    if (btnp(2)) then
        sfx(2)
        gameState_menuControl_cursor = max(1, gameState_menuControl_cursor - 1)
        gameState_currentGamePosition = gameState_boardControl_positionsHistory[gameState_menuControl_cursor]
    elseif (btnp(3)) then
        sfx(2)
        gameState_menuControl_cursor = min(gameState_menuControl_cursor + 1, #gameState_boardControl_positionsHistory)
        gameState_currentGamePosition = gameState_boardControl_positionsHistory[gameState_menuControl_cursor]
    elseif (btnp(4)) then
        sfx(1)
        gameState_currentGamePosition = deep_copy(gameState_boardControl_positionsHistory[#gameState_boardControl_positionsHistory])
        gameState_currentScreen = "chess"
        gameState_boardControl_cursorActive = true

        -- Delay - avoid freez in menu
        add(async_to_run, cocreate(function()
            for i=0,3 do
                yield()
            end
            gameState_moveAnimationFinished = true
        end))
    elseif (btnp(5)) then
        sfx(1)
        while #gameState_boardControl_movesNotation > gameState_menuControl_cursor do
            del(gameState_boardControl_movesNotation, gameState_boardControl_movesNotation[#gameState_boardControl_movesNotation])
        end
        while #gameState_boardControl_positionsHistory > gameState_menuControl_cursor do
            del(gameState_boardControl_positionsHistory, gameState_boardControl_positionsHistory[#gameState_boardControl_positionsHistory])
        end
        gameState_currentGamePosition = deep_copy(gameState_boardControl_positionsHistory[#gameState_boardControl_positionsHistory])
        gameState_boardControl_cursorActive = not ((gameState_currentGamePosition.whiteTurn and gameState_computerControlsWhite) or (not gameState_currentGamePosition.whiteTurn and gameState_computerControlsBlack));
        gameState_currentScreen = "chess";
        gameState_matchOver = nil

        -- Delay - avoid freez in menu
        add(async_to_run, cocreate(function()
            for i=0,3 do
                yield()
            end
            gameState_moveAnimationFinished = true
        end))
    end

end