pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- src/chessControl.lua


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
-- src/chessEngine.lua
lucania_tTable = {}
lucania_TTABLE_SIZE = 65536
lucania_BASE_DEPTH = 4
lucania_QUIESC_DEPTH = 0
lucania_killerMoves = {}
node_count = 0

lucania_nodesBeforeYield = 0
lucania_startSecond = 0

lucania_piece_value = {
    P = 100,
    N = 320,
    B = 330,
    R = 500,
    Q = 900,
    K = 20000
}

lucania_sunfish_pst = {
    P = split("100,100,100,100,100,100,100,100,178,183,186,173,202,182,185,190,107,129,121,144,140,131,144,107,83,116,98,115,114,100,115,87,74,103,110,109,106,101,100,77,78,109,105,89,90,98,103,81,69,108,93,63,64,86,103,69,100,100,100,100,100,100,100,100"),
    p = split("100,100,100,100,100,100,100,100,69,108,93,63,64,86,103,69,78,109,105,89,90,98,103,81,74,103,110,109,106,101,100,77,83,116,98,115,114,100,115,87,107,129,121,144,140,131,144,107,178,183,186,173,202,182,185,190,100,100,100,100,100,100,100,100"),
    N = split("214,227,205,205,270,225,222,210,277,274,380,244,284,342,276,266,290,347,281,354,353,307,342,278,304,304,325,317,313,321,305,297,279,285,311,301,302,315,282,280,262,290,293,302,298,295,291,266,257,265,282,280,282,280,257,260,206,257,254,256,261,245,258,211"),
    n = split("206,257,254,256,261,245,258,211,257,265,282,280,282,280,257,260,262,290,293,302,298,295,291,266,279,285,311,301,302,315,282,280,304,304,325,317,313,321,305,297,290,347,281,354,353,307,342,278,277,274,380,244,284,342,276,266,214,227,205,205,270,225,222,210"),
    B = split("261,242,238,244,297,213,283,270,309,340,355,278,281,351,322,298,311,359,288,361,372,310,348,306,345,337,340,354,346,345,335,330,333,330,337,343,337,336,320,327,334,345,344,335,328,345,340,335,339,340,331,326,327,326,340,336,313,322,305,308,306,305,310,310"),
    b = split("313,322,305,308,306,305,310,310,339,340,331,326,327,326,340,336,334,345,344,335,328,345,340,335,333,330,337,343,337,336,320,327,345,337,340,354,346,345,335,330,311,359,288,361,372,310,348,306,309,340,355,278,281,351,322,298,261,242,238,244,297,213,283,270"),
    R = split("514,508,512,483,516,512,535,529,534,508,535,546,534,541,513,539,498,514,507,512,524,506,504,494,479,484,495,492,497,475,470,473,451,444,463,458,466,450,433,449,437,451,437,454,454,444,453,433,426,441,448,453,450,436,435,426,449,455,461,484,477,461,448,447"),
    r = split("449,455,461,484,477,461,448,447,426,441,448,453,450,436,435,426,437,451,437,454,454,444,453,433,451,444,463,458,466,450,433,449,479,484,495,492,497,475,470,473,498,514,507,512,524,506,504,494,534,508,535,546,534,541,513,539,514,508,512,483,516,512,535,529"),
    Q = split("935,930,921,825,998,953,1017,955,943,961,989,919,949,1005,986,953,927,972,961,989,1001,992,972,931,930,913,951,946,954,949,916,923,915,914,927,924,928,919,909,907,899,923,916,918,913,918,913,902,893,911,929,910,914,914,908,891,890,899,898,916,898,893,895,887"),
    q = split("890,899,898,916,898,893,895,887,893,911,929,910,914,914,908,891,899,923,916,918,913,918,913,902,915,914,927,924,928,919,909,907,930,913,951,946,954,949,916,923,927,972,961,989,1001,992,972,931,943,961,989,919,949,1005,986,953,935,930,921,825,998,953,1017,955"),
    K = split("10003,10053,10046,9900,9900,10059,10082,9937,9967,10009,10054,10055,10055,10054,10009,10002,9937,10011,9942,10043,9932,10027,10036,9968,9944,10049,10010,9995,9980,10012,9999,9950,9944,9956,9947,9971,9948,9952,9991,9949,9952,9957,9956,9920,9935,9967,9970,9967,9995,10002,9985,9949,9942,9981,10012,10003,10016,10029,9996,9985,10005,9998,10039,10017"),
    k = split("10016,10029,9996,9985,10005,9998,10039,10017,9995,10002,9985,9949,9942,9981,10012,10003,9952,9957,9956,9920,9935,9967,9970,9967,9944,9956,9947,9971,9948,9952,9991,9949,9944,10049,10010,9995,9980,10012,9999,9950,9937,10011,9942,10043,9932,10027,10036,9968,9967,10009,10054,10055,10055,10054,10009,10002,10003,10053,10046,9900,9900,10059,10082,9937")
}

function lucania_new_ttEntry(hash, depth, value, flag_exact, flag_lowerbound, flag_upperbound, bestMove)
    return {
        hash = hash,
        depth = depth,
        value = value,
        flag_exact = flag_exact,
        flag_lowerbound = flag_lowerbound,
        flag_upperbound = flag_upperbound,
        bestMove = bestMove
    }
end

function lucania_search(position, white)

    position = deep_copy(position)
    lucania_nodesBeforeYield = 0
    node_count = 0
    local pcCount = 0
    for i = 21, 100 do
        if position.board[i] ~= "." then
            pcCount += 1
        end
    end    
    
    local depth = lucania_BASE_DEPTH

    local bestValue, bestMove = negamax(position, depth, -32000, 32000)
    return bestMove, bestValue
end

function negamax(position, depth, alpha, beta)
    node_count = node_count + 1
    lucania_nodesBeforeYield = lucania_nodesBeforeYield + 1
    if lucania_nodesBeforeYield > 210 then
        lucania_nodesBeforeYield = 0
        yield()
    end

    local alphaOrig = alpha
    local color = position.whiteTurn and 1 or -1
    local positionHash = getPositionHash(position)
    local legalMoves = nil
    local bestMove = nil
    local value = -32000

    local ttEntry = lucania_tTable[positionHash % lucania_TTABLE_SIZE]
    if ttEntry and ttEntry.hash == positionHash and ttEntry.depth >= depth then
        if ttEntry.flag_exact then
            return ttEntry.value, ttEntry.bestMove
        elseif ttEntry.flag_lowerbound and ttEntry.value > alpha then
            alpha = ttEntry.value
        elseif ttEntry.flag_upperbound and ttEntry.value < beta then
            beta = ttEntry.value
        end
        if alpha >= beta then
            return ttEntry.value, ttEntry.bestMove
        end
    end
    
    if depth <= 0 then
        return lucania_quiescence(position, alpha, beta, color, 0), nil
    end

    local legalMoves = getAllLegalMoves(position, position.whiteTurn)
    if #legalMoves == 0 then
        if isCheck(position, position.whiteTurn) then
            return -9999 - depth, nil -- Ckmt
        else
            return 0, nil -- Stalemt
        end
    end
    
    legalMoves = lucania_orderMoves(legalMoves, {}, depth)

    for index, move in ipairs(legalMoves) do
        local moveDepth = depth
        if index > 5 and not (move.takes or move.check) and depth >= 3 then
            moveDepth = depth - 1
        end

        local undo = makeMove(position, move.from, move.to)
        local score, _ = negamax(position, moveDepth - 1, -beta, -alpha)
        score = -score
        undoMove(position, undo)

        if score > value then
            value = score
            bestMove = move
        end
        alpha = max(alpha, value)

        if alpha >= beta then
            if not move.takes then
                lucania_killerMoves[depth] = lucania_killerMoves[depth] or {}
                if #lucania_killerMoves[depth] < 3 or (
                        (lucania_killerMoves[depth][1] and lucania_killerMoves[depth][1].from == move.from and lucania_killerMoves[depth][1].to == move.to) and
                        (lucania_killerMoves[depth][2] and lucania_killerMoves[depth][2].from == move.from and lucania_killerMoves[depth][2].to == move.to)
                    )
                then
                    add(lucania_killerMoves[depth], move)
                end
                if #lucania_killerMoves[depth] > 2 then
                    del(lucania_killerMoves[depth], lucania_killerMoves[depth][1])  -- keep 2
                end
            end
            goto break_search
        end
    end
    ::break_search::

    local flag_exact, flag_lowerbound, flag_upperbound = false, false, false
    if value <= alphaOrig then
        flag_upperbound = true
    elseif value >= beta then
        flag_lowerbound = true
    else
        flag_exact = true
    end

    lucania_tTable[positionHash % lucania_TTABLE_SIZE] = lucania_new_ttEntry(positionHash, depth, value, flag_exact, flag_lowerbound, flag_upperbound, bestMove)
    return value, bestMove
end

function lucania_quiescence(position, alpha, beta, color, depth)
    node_count = node_count + 1
    lucania_nodesBeforeYield = lucania_nodesBeforeYield + 1
    if lucania_nodesBeforeYield > 210 then
        lucania_nodesBeforeYield = 0
        yield()
    end
    local stand_pat = color * lucania_evaluatePosition(position)
    if depth >= lucania_QUIESC_DEPTH then
        return stand_pat
    end

    if stand_pat >= beta then
        return beta
    end
    if stand_pat > alpha then
        alpha = stand_pat
    end

    local legalMoves = getAllLegalMoves(position, position.whiteTurn)
    local noisyMoves = {}
    for _, move in ipairs(legalMoves) do
        if move.takes or move.check then
            add(noisyMoves, move)
        end
    end

    noisyMoves = lucania_orderMoves(noisyMoves, {}, 0)

    for _, move in ipairs(noisyMoves) do
        local undo = makeMove(position, move.from, move.to)
        local score = -lucania_quiescence(position, -beta, -alpha, -color, depth + 1)
        undoMove(position, undo)

        if score >= beta then
            return beta
        end
        if score > alpha then
            alpha = score
        end
    end

    return alpha
end

function lucania_evaluatePosition(position)
    local value = 0
    for x = 1, 8 do
        for y = 1, 8 do
            local piece = position.board[boardIndex(vector(x, y))]
            if piece ~= "." then
                local pieceValue = lucania_sunfish_pst[piece][(y - 1) * 8 + x]
                value = value + pieceValue * (isWhitePiece(piece) and 1 or -1)
            end
        end
    end
    return value
end

function lucania_orderMoves(moves, killerMoves, depth)
    for _, move in ipairs(moves) do
        local score = 0

        if move.takes then
            local victimVal = lucania_piece_value[to_upper(move.takes)] or 0
            local attackerVal = lucania_piece_value[to_upper(move.piece)] or 1
            score = 10000 + victimVal - attackerVal / 100
        end

        if lucania_killerMoves[depth] and (
            (lucania_killerMoves[depth][1] and lucania_killerMoves[depth][1].from == move.from and lucania_killerMoves[depth][1].to == move.to) or
            (lucania_killerMoves[depth][2] and lucania_killerMoves[depth][2].from == move.from and lucania_killerMoves[depth][2].to == move.to))
            then  
            score = score + 9000
        end

        move.score = score
    end

    for i=2,#moves do
        local j=i
        while j>1 and (moves[j].score or 0) > (moves[j-1].score or 0) do
            moves[j], moves[j-1] = moves[j-1], moves[j]
            j-=1
        end
    end

    return moves
end
-- src/chess.lua
-- idx: [21 + 10 * rank + file]
FRESH_BOARD = "x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,R,N,B,Q,K,B,N,R,x,x,P,P,P,P,P,P,P,P,x,x,.,.,.,.,.,.,.,.,x,x,.,.,.,.,.,.,.,.,x,x,.,.,.,.,.,.,.,.,x,x,.,.,.,.,.,.,.,.,x,x,p,p,p,p,p,p,p,p,x,x,r,n,b,q,k,b,n,r,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x"

PIECE_MOVES = {
    P = split("10, 20, 11, 9"),
    p = split("-10, -20, -11, -9"),
    R = split("1, -1, 10, -10"),
    r = split("1, -1, 10, -10"),
    N = split("21, 19, -21, -19, 12, -12, 8, -8"),
    n = split("21, 19, -21, -19, 12, -12, 8, -8"),
    B = split("11, -11, 9, -9"),
    b = split("11, -11, 9, -9"),
    Q = split("1, -1, 10, -10, 11, -11, 9, -9"),
    q = split("1, -1, 10, -10, 11, -11, 9, -9"),
    K = split("1, -1, 10, -10, 11, -11, 9, -9, 2, -2"),
    k = split("1, -1, 10, -10, 11, -11, 9, -9, 2, -2")
}

function getStartingPosition()
    local position = {
        board = split(FRESH_BOARD),
        whiteTurn = true,
        enPassant = nil,
        capturedPieces = {
            white = {},
            black = {}
        },
        whiteCastleKingside = true,
        whiteCastleQueenside = true,
        blackCastleKingside = true,
        blackCastleQueenside = true,
        visitedPositions = {},
        movesSinceLastCapture = 0
    }
    position.hash = getPositionHash(position)
    return position
end

-- No legal check, returns undo changes
function makeMove(position, from, to)

    local board = position.board
    local piece = board[from]
    local capturedPiece = board[to]

    local undoMove = {
        boardChanges = {},
        capture = nil,
        movesSinceLastCapture = position.movesSinceLastCapture,
        enPassant = position.enPassant,
        whiteCastleKingside = position.whiteCastleKingside,
        whiteCastleQueenside = position.whiteCastleQueenside,
        blackCastleKingside = position.blackCastleKingside,
        blackCastleQueenside = position.blackCastleQueenside,
    }
    undoMove.boardChanges[from] = piece
    undoMove.boardChanges[to] = capturedPiece

    -- EP
    if (piece == "p" or piece == "P") and position.enPassant and position.enPassant == to then
        local enPassantPawn = to + (position.whiteTurn and -10 or 10)
        capturedPiece = board[enPassantPawn]
        board[enPassantPawn] = "."
        undoMove.boardChanges[enPassantPawn] = capturedPiece
    end

    board[from] = "."
    board[to] = piece

    position.board = board

    if capturedPiece ~= "." then
        position.capturedPieces[position.whiteTurn and "white" or "black"][#position.capturedPieces[position.whiteTurn and "white" or "black"] + 1] = capturedPiece
        position.movesSinceLastCapture = 0
        undoMove.capture = capturedPiece
    else
        position.movesSinceLastCapture = position.movesSinceLastCapture + 1
    end

    -- Mark EP sq
    if (piece == "p" or piece == "P") and (abs(from - to) == 20)
    then
        position.enPassant = to + (position.whiteTurn and -10 or 10)
    else
        position.enPassant = nil
    end

    -- Castling
    if piece == "K" then
        if to == 28 and position.whiteCastleKingside then
            -- W K-side
            board[29] = "."
            board[27] = "R"
            undoMove.boardChanges[29] = "R"
            undoMove.boardChanges[27] = "."
        elseif to == 24 and position.whiteCastleQueenside then
            -- W Q-side
            board[22] = "."
            board[25] = "R"
            undoMove.boardChanges[22] = "R"
            undoMove.boardChanges[25] = "."
        end
    elseif piece == "k" then
        if to == 98 and position.blackCastleKingside then
            -- B K-side
            board[99] = "."
            board[97] = "r"
            undoMove.boardChanges[99] = "r"
            undoMove.boardChanges[97] = "."
        elseif to == 94 and position.blackCastleQueenside then
            -- B Q-side
            board[92] = "."
            board[95] = "r"
            undoMove.boardChanges[92] = "r"
            undoMove.boardChanges[95] = "."
        end
    end

    -- Castling rights
    if piece == "K" then
        position.whiteCastleKingside = false
        position.whiteCastleQueenside = false
    elseif piece == "k" then
        position.blackCastleKingside = false
        position.blackCastleQueenside = false
    end

    if from == 29 or to == 29 then
        position.whiteCastleKingside = false
    elseif from == 22 or to == 22 then
        position.whiteCastleQueenside = false
    elseif from == 99 or to == 99 then
        position.blackCastleKingside = false
    elseif from == 92 or to == 92 then
        position.blackCastleQueenside = false
    end

    -- Promotion
    if (piece == "P" and to >= 92) then
        board[to] = "Q"
    elseif (piece == "p" and to <= 29) then
        board[to] = "q"
    end

    position.whiteTurn = not position.whiteTurn
    position.visitedPositions[#position.visitedPositions + 1] = getPositionId(position)

    return undoMove
end

function undoMove(position, undoMove)
    for index, piece in pairs(undoMove.boardChanges) do
        position.board[index] = piece
    end
    if (undoMove.capture) then
        position.capturedPieces[position.whiteTurn and "black" or "white"][#position.capturedPieces[position.whiteTurn and "black" or "white"]] = nil
    end
    position.whiteTurn = not position.whiteTurn
    position.visitedPositions[#position.visitedPositions] = nil
    position.movesSinceLastCapture = undoMove.movesSinceLastCapture
    position.enPassant = undoMove.enPassant
    position.whiteCastleKingside = undoMove.whiteCastleKingside
    position.whiteCastleQueenside = undoMove.whiteCastleQueenside
    position.blackCastleKingside = undoMove.blackCastleKingside
    position.blackCastleQueenside = undoMove.blackCastleQueenside
end

function getPieceLegalMoves(position, square, ignoreCheck)
    ignoreCheck = ignoreCheck or false

    local board = position.board
    local squareIndex = boardIndex(square)

    local piece = position.board[boardIndex(square)]
    movements = PIECE_MOVES[piece]
    local legalMoves = {}
    local legalMovesCaptures = {}
    local legalMovesChecks = {}

    for _, movement in pairs(movements) do
        local crawl = (to_lower(piece) == 'r' or to_lower(piece) == 'b' or to_lower(piece) == 'q') and 7 or 1
        local capturesOrPromotes = false

        for i = 1, crawl do
            local targetIndex = squareIndex + movement * i
            local targetPiece = board[targetIndex]
            if targetPiece == "x" or (targetPiece ~= "." and isBlackPiece(piece) == isBlackPiece(targetPiece)) then
                
                goto continueNextMovement
            end

            -- P
            if to_lower(piece) == "p" then
                if abs(movement) == 20 then
                    -- 2-step
                    if (square.y ~= 2 and square.y ~= 7) or targetPiece ~= "." or board[squareIndex + movement/2] ~= "." then
                        goto continueNextMovement
                    end
                elseif abs(movement) == 10 then
                    -- 1-step
                    if targetPiece ~= "." then
                        goto continueNextMovement
                    end
                    capturesOrPromotes = (square.y == (isWhitePiece(piece) and 8 or 1)) and "Q"
                else 
                    -- Takes
                    if (targetPiece == "." and not (position.enPassant and (position.enPassant == targetIndex))) or (targetPiece ~= "." and (isBlackPiece(piece) == isBlackPiece(targetPiece))) then
                        -- No take
                        goto continueNextMovement
                    else
                        capturesOrPromotes = (targetPiece ~= ".") and targetPiece or "P"
                    end
                end

            -- K
            elseif to_lower(piece) == "k" then
                if movement == 2 then
                    -- Kside cstl
                    if  (isWhitePiece(piece) and not position.whiteCastleKingside) or 
                        (isBlackPiece(piece) and not position.blackCastleKingside) or
                        board[squareIndex + 1] ~= "." or 
                        board[squareIndex + 2] ~= "." or
                        -- Check
                        (
                            (not ignoreCheck) and (
                                isSquareAttacked2(position, squareIndex, isWhitePiece(piece)) or
                                isSquareAttacked2(position, squareIndex + 1, isWhitePiece(piece))
                            )
                        )
                    then
                        goto continueNextMovement
                    end
                elseif movement == -2 then
                    -- Qside cstl
                    if  (isWhitePiece(piece) and not position.whiteCastleQueenside) or 
                        (isBlackPiece(piece) and not position.blackCastleQueenside) or
                        board[squareIndex - 1] ~= "." or 
                        board[squareIndex - 2] ~= "." or
                        board[squareIndex - 3] ~= "." or
                        -- Check
                        (
                            (not ignoreCheck) and (
                                isSquareAttacked2(position, squareIndex, isWhitePiece(piece)) or
                                isSquareAttacked2(position, squareIndex - 1, isWhitePiece(piece)) or 
                                isSquareAttacked2(position, squareIndex - 2, isWhitePiece(piece))
                            )
                        )
                    then
                        goto continueNextMovement
                    end
                end
            end

            if targetPiece ~= "." then
                if (isBlackPiece(piece) == isBlackPiece(targetPiece)) then
                    -- No take own
                    goto continueNextMovement
                else
                    capturesOrPromotes = to_upper(targetPiece)
                end
            end

            if (not ignoreCheck) then
                local undo = makeMove(position, squareIndex, targetIndex)
                if (not isCheck(position, isWhitePiece(piece))) then
                    legalMoves[#legalMoves + 1] = targetIndex
                    if (capturesOrPromotes) then
                        legalMovesCaptures[targetIndex] = capturesOrPromotes
                    end
                    if (isCheck(position, isBlackPiece(piece))) then
                        legalMovesChecks[targetIndex] = true
                    end
                end
                undoMove(position, undo)
            else
                legalMoves[#legalMoves + 1] = targetIndex
                if (capturesOrPromotes) then
                    legalMovesCaptures[targetIndex] = capturesOrPromotes
                end
            end

            if targetPiece ~= "." then
                goto continueNextMovement
            end

        end

        ::continueNextMovement::
    end

    return legalMoves, legalMovesCaptures, legalMovesChecks
end

function getAllLegalMoves(position, white, ignoreCheck)
    local legalMoves = {}
    for i = 21, 100 do
        local square = boardIndexToSquare(i)
        local piece = position.board[i]
        if (white and isWhitePiece(piece)) or (not white and isBlackPiece(piece)) then 
            local moves, captures, checks = getPieceLegalMoves(position, square, ignoreCheck)
            for _, move in pairs(moves) do
                legalMoves[#legalMoves + 1] = {from = i, to = move, takes = captures[move], check = checks[move], piece = piece}
            end
        end
    end
    return legalMoves
end

function isSquareAttacked2(position, squareIndex, white)
    local board = position.board

    -- by P
    local enemyPawnAttackDirection = white and 10 or -10    -- Actually the opposite, we are looking at the pawn, not pawn POV
    local enemyPawn = white and "p" or "P"

    if board[squareIndex + enemyPawnAttackDirection - 1] == enemyPawn or
       board[squareIndex + enemyPawnAttackDirection + 1] == enemyPawn then
        return true
    end

    -- by N
    for _,move in ipairs(PIECE_MOVES.N) do
        local knightIndex = squareIndex + move
        if board[knightIndex] == (white and "n" or "N") then
            return true
        end
    end

    -- by B,Q,K
    for _,move in ipairs(PIECE_MOVES.B) do
        for i = 1, 7 do
            local targetIndex = squareIndex + move * i
            if i == 1 and (board[targetIndex] == (white and "k" or "K")) then
                return true
            end
            if board[targetIndex] == (white and "b" or "B") or board[targetIndex] == (white and "q" or "Q") then
                return true
            elseif board[targetIndex] ~= "." then
                break -- shielded
            end
        end
    end

    -- by R,Q,K
    for _,move in ipairs(PIECE_MOVES.R) do
        for i = 1, 7 do
            local targetIndex = squareIndex + move * i
            if i == 1 and (board[targetIndex] == (white and "k" or "K")) then
                return true
            end
            if board[targetIndex] == (white and "r" or "R") or board[targetIndex] == (white and "q" or "Q") then
                return true
            elseif board[targetIndex] ~= "." then
                break -- shielded
            end
        end
    end

    return false
end

function isCheck(position, white)
    local kingIndex = nil
    for i = 21, 100 do
        local piece = position.board[i]
        if (white and piece == "K") or (not white and piece == "k") then
            kingIndex = i
        end
    end

    if not kingIndex then
        return false
    end

    return isSquareAttacked2(position, kingIndex, white)
end

function isMate(position, white)
    local legalMoves = getAllLegalMoves(position, white, false)
    return (#legalMoves == 0) and isCheck(position, white)
end

function isStalemate(position, white)
    local legalMoves = getAllLegalMoves(position, white, false)
    return (#legalMoves == 0) and not isCheck(position, white)
end
-- src/graphics.lua
--
-- Anim Utils

function ease_out(a, b, t)
    return lerp(a, b, t * (2 - t))
end

function ease_in(a, b, t)
    return lerp(a, b, t * t)
end

function ease_peak(a, b, t)
    return lerp(a, b, 4 * t * (1 - t))
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function drawChessboardScreen()
    processAnimations()
    drawChessboardBackground()
    drawChessboard()
    drawChessboardUI()
    -- Bottom bar
    print("(Y) for menu", 8, 120, 7);
end

function pieceSprite(h, x, y)
    return {h = h, x = x, y = y}
end
PIECES_SPRITES = {
    P = pieceSprite(7, 0, 9),
    R = pieceSprite(8, 8, 8),
    N = pieceSprite(9, 16, 7),
    B = pieceSprite(11, 24, 5),
    K = pieceSprite(15, 32, 1),
    Q = pieceSprite(13, 40, 3),
    p = pieceSprite(7, 0, 25),
    r = pieceSprite(8, 8, 24),
    n = pieceSprite(9, 16, 23),
    b = pieceSprite(11, 24, 21),
    k = pieceSprite(15, 32, 17),
    q = pieceSprite(13, 40, 19)
}

-- Anim parameters
LIFT_ANIM_DURATION = 6
RELEASE_ANIM_DURATION = 6
LIFT_ANIM_HEIGHT = -3
MOVE_ANIM_DURATION = 12
MOVE_ANIM_HEIGHT = -12

-- Active anims
animations_liftPiece = {}
animations_releasePiece = {}
animations_movePiece = nil
animations_capturePiece = {}

function animateCapturePiece(index)
    local piece = gameState_currentGamePosition.board[index]
    local pieceSprite = PIECES_SPRITES[piece]

    -- Prepare sandbox
    local sandbox = ""
    for i = 1,pieceSprite.h do
        sandbox = sandbox .. "11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,11,"
    end
    sandbox = split(sandbox)
    -- Copy sprite to sndbx
    for iy = 0, pieceSprite.h - 1 do
        for ix = 0, 7 do
            sandbox[iy * 16 + ix + 4] = sget(pieceSprite.x + ix, pieceSprite.y + iy)
        end
    end
    local anim = {
        age = 0,
        h = pieceSprite.h,
        sandbox = sandbox,
    }

    animations_capturePiece[index] = anim
end

function animateSandboxMovement(sandbox, h, age)
    local w = 16

    for y = h - 1, 0, -1 do
        for x = 0, w - 1 do
            local i = x + y * w
            local color = sandbox[i]

            if color ~= 11 then
                -- Rnd decay
                if rnd(ceil((600 - age) / 10)) < 1 then
                    sandbox[i] = 11
                else
                    local below = i + w
                    if sandbox[below] == 11 then
                        sandbox[below] = color
                        sandbox[i] = 11
                    else
                        -- slide
                        local dir = (rnd(1) < 0.5 and -1 or 1)
                        local dx = x + dir

                        if dx >= 0 and dx < w then
                            local diagonal = dx + (y + 1) * w
                            if sandbox[diagonal] == 11 then
                                sandbox[diagonal] = color
                                sandbox[i] = 11
                            end
                        end
                    end
                end
            end
        end
    end
    return sandbox
end


function animateLiftPiece(index)
    local anim = {
        progress = 0,
        dy = 0
    }
    animations_liftPiece[index] = anim
end

function animateReleasePiece(index) 
    local anim = {
        progress = 0,
        dy = LIFT_ANIM_HEIGHT
    }
    animations_releasePiece[index] = anim
    animations_liftPiece[index] = nil
end

function animateReleaseAllPieces()
    for index, anim in pairs(animations_liftPiece) do
            animateReleasePiece(index)
    end
end

function animateMovePiece(from, to)
    local anim = {
        progress = 0,
        from_x = (gameState_playingWhite and from.x or (9 - from.x)) * 10 - 2, 
        from_y = (gameState_playingWhite and (9 - from.y) or from.y) * 10 + 16 + LIFT_ANIM_HEIGHT,
        to_x = (gameState_playingWhite and to.x or (9 - to.x)) * 10 - 2,
        to_y = (gameState_playingWhite and (9 - to.y) or to.y) * 10 + 16
    }
    animations_liftPiece[boardIndex(from)] = nil
    animations_movePiece = anim
end

function processAnimations()

    -- Anim trig logic
    local pieceLifted = gameState_boardControl_cursorActive and boardIndex(gameState_boardControl_pieceLifted or gameState_boardControl_cursor)
    local board = gameState_currentGamePosition.board
    local whiteTurn = gameState_currentGamePosition.whiteTurn

    if not pieceLifted or not gameState_boardControl_cursorActive or (board[pieceLifted] >= "a" and whiteTurn) or
        (board[pieceLifted] < "a" and not whiteTurn) then
            -- No lift opponent pieces
            pieceLifted = nil
    end

    if (pieceLifted) then
        if not animations_liftPiece[pieceLifted] then
            animateReleaseAllPieces()
            animateLiftPiece(pieceLifted)
        end
    elseif next(animations_liftPiece) then
        animateReleaseAllPieces()
    end

    if gameState_boardControl_pieceMoving and not animations_movePiece then
        animateMovePiece(gameState_boardControl_pieceMoving.from, gameState_boardControl_pieceMoving.to)
    end
    if gameState_boardControl_pieceCaptured and 
        ((not animations_capturePiece[boardIndex(gameState_boardControl_pieceCaptured)]) or 
         (animations_capturePiece[boardIndex(gameState_boardControl_pieceCaptured)].age > MOVE_ANIM_DURATION)) then
        animateCapturePiece(boardIndex(gameState_boardControl_pieceCaptured))
    end

    -- Anim progress update

    for index, anim in pairs(animations_liftPiece) do
        if (anim.progress < LIFT_ANIM_DURATION) then
            anim.progress = anim.progress + 1
            anim.dy = ceil(ease_out(0, LIFT_ANIM_HEIGHT, anim.progress / LIFT_ANIM_DURATION))
            animations_liftPiece[index] = anim
        end 
    end
    for index, anim in pairs(animations_releasePiece) do
        if (anim.progress < RELEASE_ANIM_DURATION) then
            anim.progress = anim.progress + 1
            anim.dy = ceil(ease_out(LIFT_ANIM_HEIGHT, 0, anim.progress / RELEASE_ANIM_DURATION))
            animations_releasePiece[index] = anim
        else
            animations_releasePiece[index] = nil
        end
    end

    if (animations_movePiece) then
        local anim = animations_movePiece
        if (anim.progress < MOVE_ANIM_DURATION) then
            anim.progress = anim.progress + 1
            local progressRatio = anim.progress / MOVE_ANIM_DURATION
            anim.x = ease_out(anim.from_x, anim.to_x, progressRatio)
            anim.y = ceil(ease_in(anim.from_y, anim.to_y, progressRatio) + ease_peak(0, MOVE_ANIM_HEIGHT, progressRatio))
            animations_movePiece = anim
        else
            animations_movePiece = nil
            on_moveAnimationFinished()      -- Let game control know animation is finished and we can update board
        end
    end

    for index, anim in pairs(animations_capturePiece) do
        anim.age = anim.age + 1
        if anim.age > 360 then
            animations_capturePiece[index] = nil
        else
            anim.sandbox = animateSandboxMovement(anim.sandbox, anim.h, anim.age)
            animations_capturePiece[index] = anim
        end
    end
end

function drawChessboardBackground()
    for y = 16, 100, 12 do
        for x = 0, 120, 8 do
            sspr(72, 0, 8, 12, x, y)
        end
    end
    for x = 0, 128, 24 do
        sspr(80, 0, 24, 16, x, 0, 24, 16)
        sspr(80, 0, 24, 16, x, 112, 24, 16, false, true)
    end
end

function drawChessboard()

    local board = gameState_currentGamePosition.board

    -- board frame
    line(6,16,88,16, 0)
    line(5,15,88,15, 2)
    line(4,14,89,14, 0)

    line(6,97,87,97, 0)
    line(5,98,88,98, 2)
    line(4,99,89,99, 0)

    line(6,16,6,97, 0)
    line(5,15,5,98, 2)
    line(4,14,4,99, 0)

    line(87,16,87,97, 0)
    line(88,15,88,98, 2)
    line(89,14,89,99, 0)

    local blackSquare = gameState_playingWhite and false or true
    for ix = 1, 8 do
        for iy = 1, 8 do
            local file = gameState_playingWhite and ix or (9 - ix)
            local rank = gameState_playingWhite and (9 - iy) or iy
            sspr(56, blackSquare and 0 or 16, 10, 10, ix * 10 -3, iy * 10 + 7)
            if gameState_boardControl_cursorActive and gameState_boardControl_cursor.x == file and gameState_boardControl_cursor.y == rank then
                line(ix * 10 -3, iy * 10 + 7, ix * 10 + 6, iy * 10 + 7, gameState_currentGamePosition.whiteTurn and 9 or 8)
                line(ix * 10 -3, iy * 10 + 7, ix * 10 - 3, iy * 10 + 16, gameState_currentGamePosition.whiteTurn and 9 or 8)
                line(ix * 10 -3, iy * 10 + 16, ix * 10 + 6, iy * 10 + 16, gameState_currentGamePosition.whiteTurn and 9 or 8)
                line(ix * 10 + 6, iy * 10 + 7, ix * 10 + 6, iy * 10 + 16, gameState_currentGamePosition.whiteTurn and 9 or 8)
            end

            blackSquare = not blackSquare
        end
        blackSquare = not blackSquare
    end
    for ix = 1, 8 do
        for iy = 1, 8 do
            local file = gameState_playingWhite and ix or (9 - ix)
            local rank = gameState_playingWhite and (9 - iy) or iy
            local bIndex = boardIndex(vector(file, rank))
            local piece = board[bIndex]

            if piece ~= "." then
                sspr(56, blackSquare and 12 or 28, 10, 4, ix * 10 - 3, iy * 10 + 13) -- shadow
            end

            if animations_capturePiece[bIndex] then
                local anim = animations_capturePiece[bIndex]
                for siy = 0, anim.h - 1 do
                    for six = 0, 15 do
                        local color = anim.sandbox[siy * 16 + six]
                        if color ~= 11 then
                            pset(ix * 10 - 6 + six, iy * 10 + 16 - anim.h + siy, color)
                        end
                    end
                end
            end

            if piece ~= "." then
                if animations_movePiece and gameState_boardControl_pieceMoving and gameState_boardControl_pieceMoving.from.x == file and gameState_boardControl_pieceMoving.from.y == rank then
                    drawPiece(piece, animations_movePiece.x, animations_movePiece.y, "move")
                else
                    local dy = animations_liftPiece[bIndex] and animations_liftPiece[bIndex].dy or (animations_releasePiece[bIndex] and animations_releasePiece[bIndex].dy or 0)
                    if not (gameState_boardControl_pieceCaptured and gameState_boardControl_pieceCaptured.x == file and gameState_boardControl_pieceCaptured.y == rank) then
                        drawPiece(piece, ix * 10 - 2, iy * 10 + 16 + dy)
                    end
                end
            end

            if contains(gameState_boardControl_currentPieceLegalMoves, bIndex) then
                line(ix * 10, iy * 10 + 10 , ix * 10 + 3, iy * 10 + 13, gameState_currentGamePosition.whiteTurn and 9 or 8)
                line(ix * 10, iy * 10 + 13 , ix * 10 + 3, iy * 10 + 10, gameState_currentGamePosition.whiteTurn and 9 or 8)
            end
            blackSquare = not blackSquare
        end
        blackSquare = not blackSquare
    end
end

function drawPiece(piece, x, y, state)
    local pieceSprite = PIECES_SPRITES[piece]
    sspr(pieceSprite.x, pieceSprite.y, 8, pieceSprite.h, x, y - pieceSprite.h)
end

function drawChessboardUI(viewNotation)
    viewNotation = viewNotation or nil
    -- Captd pieces
    for i, piece in pairs(gameState_currentGamePosition.capturedPieces[gameState_playingWhite and "black" or "white"]) do
        local pieceSprite = PIECES_SPRITES[piece]
        sspr(pieceSprite.x, pieceSprite.y, 8, pieceSprite.h, 1 + i * 5, 14 - pieceSprite.h)
    end
    for i, piece in pairs(gameState_currentGamePosition.capturedPieces[gameState_playingWhite and "white" or "black"]) do
        local pieceSprite = PIECES_SPRITES[piece]
        sspr(pieceSprite.x, pieceSprite.y, 8, pieceSprite.h, 1 + i * 5, 106 - pieceSprite.h)
    end

    -- Notation
    local firstDisplayedMoveIndex = 1
    if (viewNotation) then
        firstDisplayedMoveIndex = max(0, min(gameState_menuControl_cursor - 6, #gameState_boardControl_movesNotation - 12))
    else
        firstDisplayedMoveIndex = max(#gameState_boardControl_movesNotation - 12, 0)
    end
    
    if firstDisplayedMoveIndex > 0 then
        for i = 119, 91, -4 do
            sspr(72, 18, 8, 6, i, 12)
        end
    end
    rectfill(94, 14, 128, 99, 15)
    line(93, 14, 93, 99, 0)
    line(93, 13, 128, 13, 5)
    for i = 120, 92, -4 do
        spr(41, i, 99)
    end

    if #gameState_boardControl_movesNotation == 0 then
        print_custom("1.", 95, 16, 8)


    else
        for i = 1, min(#gameState_boardControl_movesNotation, 12) do
            local moveIndex = firstDisplayedMoveIndex + i
            if moveIndex % 2 == 1 then
                print_custom( "" .. (flr(moveIndex / 2) + 1) .. ".", 95, 10 + i * 6, 8)
                if viewNotation and moveIndex == gameState_menuControl_cursor then
                    print_custom( "" .. (flr(moveIndex / 2) + 1) .. ".", 96, 10 + i * 6, 7)
                end
            else
                print_custom("...", 95, 10 + i * 6, 0)
                if viewNotation and moveIndex == gameState_menuControl_cursor then
                    print_custom("...", 96, 10 + i * 6, 7)
                end
            end

            if viewNotation and moveIndex == gameState_menuControl_cursor then
                print_custom(gameState_boardControl_movesNotation[moveIndex], 106, 10 + i * 6, 9)
            end
            print_custom(gameState_boardControl_movesNotation[moveIndex], 107, 10 + i * 6, 0)
        end
    end

    -- Thinking indictr
    if (lucania_runSeconds != 0) then
        dots = ""
        for i=0, lucania_runSeconds, 2 do
            dots = dots .. "."
        end
        print("Thinking" .. dots, 18, 51, 2)
        print("Thinking" .. dots, 20, 49, 2)
        print("Thinking" .. dots, 19, 50, 0)
    end

end

function print_custom(str, x, y, color, scale)
    scale = scale or 1
    color = color or 0
    pal(0, color)

    local char_to_index = split("62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,52,53,54,55,56,57,58,59,60,61,77,78,79,80,81,82,83,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,84,85,86,87,88,89,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,90,91,92,93")
    local ox = x
    for i=1,#str do
        local c = ord(str, i)
        if c == 10 then
            x = ox
            y += 4 * scale
        elseif c == 32 then
            x += 4 * scale
        elseif c > 32 and c <= 126 then
            local ci = char_to_index[c - 32]
            local cx = (ci % 16) * 3
            local cy = flr(ci / 16) * 4 + 32
            sspr(cx, cy, 3, 4, x, y, scale * 3, scale * 4)
            x += 4 * scale
        end
    end

    pal(0, 0)
end
   
function drawViewNotationScreen()
    processAnimations()
    drawChessboardBackground()
    drawChessboard()
    drawChessboardUI(true)
    print("(Y) resume, (X) roll back", 8, 120, 7);
end
-- src/main.lua
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
-- src/menu.lua

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
-- src/utils.lua
function vector(x, y)
    return {x = x, y = y}
end

function vectorcmp(a, b)
    return a and b and a.x == b.x and a.y == b.y
end

function boardIndex(square)
    return square and (11 + 10 * square.y + square.x) or nil
end

function boardIndexToSquare(index)
    local x = index % 10 - 1
    local y = flr(index / 10) - 1
    return vector(x, y)
end

function isBlackPiece(piece)
    return piece > "a" and piece < "x"
end

function isWhitePiece(piece)
    return piece > "A" and piece < "Z"
end

function isSameColorPiece(piece1, piece2)
    return piece1 ~= "." and piece2 ~= "." and isBlackPiece(piece1) == isBlackPiece(piece2)
end

function getPositionId(position)

    local s = ""
    for i=21, 100 do
        local p = position.board[i]
        if p ~= "x" then
            s = s..p
        end
    end
    s = s ..
        (position.whiteTurn and "w" or "b") ..
        (position.whiteCastleKingside and "K" or "") ..
        (position.whiteCastleQueenside and "Q" or "") ..
        (position.blackCastleKingside and "k" or "") ..
        (position.blackCastleQueenside and "q" or "")
    return s
end

zobrist = {}
chessPieces = split("P,N,B,R,Q,K,p,n,b,r,q,k")

function initZobrist()
    -- rnd numbers for piece-sqrs
    for pi=1,#chessPieces do
        zobrist[chessPieces[pi]] = {}
        for sq=22,99 do
            zobrist[chessPieces[pi]][sq] = flr(rnd(0x7fffffff))
        end
    end
    -- turn
    zobrist["side"] = flr(rnd(0x7fffffff))
    -- cstl rights
    zobrist["cK"] = flr(rnd(0x7fffffff)) -- w K side
    zobrist["cQ"] = flr(rnd(0x7fffffff)) -- w Q side
    zobrist["ck"] = flr(rnd(0x7fffffff)) -- b K side
    zobrist["cq"] = flr(rnd(0x7fffffff)) -- b Q side
end

function getPositionHash(position)
    local hash = 0

    local sq64 = 1
    for i=22, 99 do
        local piece = position.board[i]
        if piece ~= "x" and piece ~= "." then
                hash = bxor(hash, zobrist[piece][i])
        end
    end

    if not position.whiteTurn then
        hash = bxor(hash, zobrist["side"])
    end

    if position.whiteCastleKingside   then hash = bxor(hash, zobrist["cK"]) end
    if position.whiteCastleQueenside  then hash = bxor(hash, zobrist["cQ"]) end
    if position.blackCastleKingside   then hash = bxor(hash, zobrist["ck"]) end
    if position.blackCastleQueenside  then hash = bxor(hash, zobrist["cq"]) end

    return hash
end

function to_lower(str)
    local out = ""
    for i = 1, #str do
        local c = ord(str, i)
        if c >= 65 and c <= 90 then
            c += 32
        end
        out ..= chr(c)
    end
    return out
end

function to_upper(str)
    local out = ""
    for i = 1, #str do
        local c = ord(str, i)
        if c >= 97 and c <= 122 then
            c -= 32
        end
        out ..= chr(c)
    end
    return out
end

function contains(arr, val)
    for i=1,#arr do
        if arr[i] == val then
            return true
        end
    end
    return false
end

function deep_copy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = deep_copy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function getMoveNotation(position, from, to)
    local piece = position.board[boardIndex(from)]
    local targetPiece = position.board[boardIndex(to)]
    local notation = ""

    if to_lower(piece) == "k" and (abs(from.x - to.x) == 2) then
        -- Castl
        if to.x > from.x then
            notation = "O-O"
        else
            notation = "O-O-O"
        end
        return notation
    elseif to_lower(piece) == "p" then
        notation = ""
    else
        notation = to_upper(piece)
    end

    local takingEp = to_lower(piece) == "p" and position.enPassant == boardIndex(to)
    if targetPiece ~= "." or takingEp then
        notation = notation .. "x"
    end

    notation = notation .. chr(96 + to.x) .. (to.y)

    if position.enPassant and position.enPassant == boardIndex(to) then
        notation = notation .. " e.p."
    end

    -- ambiguous?
    local clarification = ""
    for i, p in pairs(position.board) do
        if p == piece and i ~= boardIndex(from) then
            local square = boardIndexToSquare(i)
            local moves = getPieceLegalMoves(position, square)
            if contains(moves, boardIndex(to)) then
                clarification = chr(96 + from.x)
                if square.x == from.x then
                    clarification = clarification .. from.y
                    goto ambiguous_break
                end
            end
        end
    end
    ::ambiguous_break::
    if clarification != "" then
        if piece != "p" and piece != "P" then
            -- clarif. after piece
            notation = piece .. clarification .. sub(notation, 2)
        else
            notation = clarification .. notation
        end
    end

    -- is P promo
    if (piece == "P" and to.y == 8) or (piece == "p" and to.y == 1) then
        notation = notation .. "=Q"
    end

    -- Check/Mate
    if isMate(gameState_currentGamePosition, gameState_currentGamePosition.whiteTurn) then
        notation = notation .. "#"
    elseif  isCheck(gameState_currentGamePosition, gameState_currentGamePosition.whiteTurn) then
        notation = notation .. "+"
    end


    return notation
end
__gfx__
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb1155555555bbbbbb44444444555555555555555555555555bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb99bbbbbbbbbbbbbbbbbbb1555555551bbbbbb45444544455545554555455545554555bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000bbbbbbbbbbbbbbbbbb5555555555bbbbbb44444444445444544454445444544454bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0760bbb909090bbbbbbbbb5555555551bbbbbb44444444544545254544544544444544bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0760bb00979600bbbbbbbb5555555555bbbbbb44444444554452225445554454445445bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbb9bbbbb077660b077766d0bbbbbbbb5555555551bbbbbb44454445555445254454545445454455bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbb079bbbb0766d0bb0766d0bbbbbbbbb5555555551bbbbbb44444444955544544555555544544555bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbb0bbbbbbb0790bbb0766d0bbb0dd0bbbbbbbbbb5555555551bbbbbb44444444555445454454545445454455bbbbbbbbbbb0000000000000
bbbbbbbb070dd0d0b0700bbbb0779d0bbb0dd0bbbb0660bbbbbbbbbb5555555551bbbbbb44444444554454445445554454445445bbbbbbbbbbb0000000000000
bb0000bb067d6dd0b076600bb0769d0bb079790bb07d7d0bbbbbbbbb1111111111bbbbbb54445444544545554544544545554544bbbbbbbbbbb0000000000000
b0776d0bb076dd0b076766d0bb06d0bbbb0dd0bbbb0dd0bbbbbbbbbbbbbbbbbbbbbbbbbb44444444445444444454445444444454bbbbbbbbbbb0000000000000
b0766d0bb07d6d0b0766d00bbbb00bbbbb0660bbbb0760bbbbbbbbbbbbbbbbbbbbbbbbbb44444444454555555545454555555545bbbbbbbbbbb0000000000000
bb0660bbb076dd0b066d0bbbbb0660bbb0766d0bb0766d0bbbbbbbbbbbb2222bbbbbbbbb44444444544444444444544444444444bbbbbbbbbbb0000000000000
b0766d0b076d6dd0b0d6d00bb076dd0bb0766d0bb0766d0bbbbbbbbbb22222222bbbbbbb44444444444444444444444444444444bbbbbbbbbbb0000000000000
076dddd00676d6d0076dddd0076dddd0076dddd0076dddd0bbbbbbbb2222222222bbbbbb44444444555455545554555455545554bbbbbbbbbbb0000000000000
000000000000000000000000000000000000000000000000bbbbbbbbb22222222bbbbbbb44444444444444444444444444444444bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb7666666666bbbbbbb05f5f5f000000000000000000000000bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb99bbbbbbbbbbbbbbbbbbb7666666666bbbbbbb0555555000000000000000000000000bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000bbbbbbbbbbbbbbbbbb6666666666bbbbbbb0000000000000000000000000000000bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0d10bbb909090bbbbbbbbb6666666667bbbbbb000fffff000000000000000000000000bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0d10bb009d9100bbbbbbbb6666666666bbbbbb050fffff000000000000000000000000bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbb9bbbbb0dd110b0ddd1100bbbbbbbb6666666667bbbbbb050fff5f000000000000000000000000bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbb0d9bbbb0d1100bb0d1100bbbbbbbbb6666666666bbbbbb050ff5f5000000000000000000000000bbbbbbbbbbb0000000000000
bbbbbbbbbbbbbbbbbb0bbbbbbb0d90bbb0d1100bbb0000bbbbbbbbbb6666666667bbbbbb00055555000000000000000000000000bbbbbbbbbbb0000000000000
bbbbbbbb0d0d0d00b0d00bbbb0dd900bbb0000bbbb0110bbbbbbbbbb6666666667bbbbbbbbbbbbbb000000000000000000000000bbbbbbbbbbb0000000000000
bb0000bb01d01000b0d1100bb0d1900bb0d9d90bb0d0d00bbbbbbbbb6677777777bbbbbbb9bbbb9b000000000000000000000000bbbbbbbbbbb0000000000000
b0dd100bb011000b0d1d1100bb0100bbbb0000bbbb0000bbbbbbbbbbbbbbbbbbbbbbbbbbbb9bb9bb000000000000000000000000bbbbbbbbbbb0000000000000
b0d1100bb010100b0d11000bbbb00bbbbb0110bbbb0d10bbbbbbbbbbbbbbbbbbbbbbbbbbbbb99bbb000000000000000000000000bbbbbbbbbbb0000000000000
bb0110bbb011000b01100bbbbb0110bbb0d1100bb0d1100bbbbbbbbbbbbddddbbbbbbbbbbbb99bbb000000000000000000000000bbbbbbbbbbb0000000000000
b0d1100b0d101000b001000bb0d1000bb0d1100bb0d1100bbbbbbbbbbddddddddbbbbbbbbb9bb9bb000000000000000000000000bbbbbbbbbbb0000000000000
0d10000001d101000d1000000d1000000d1000000d100000bbbbbbbbddddddddddbbbbbbb9bbbb9b000000000000000000000000bbbbbbbbbbb0000000000000
000000000000000000000000000000000000000000000000bbbbbbbbbddddddddbbbbbbbbbbbbbbb000000000000000000000000bbbbbbbbbbb0000000000000
00b00bb0000b000000b000b00000000b00bb000b00b0b00bbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000bbbbbbbbbbb0000000000000
0b00000bb0b000b0bb0bb0b0b0bbb000b0bb0000b00b00b0bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000bbbbbbbbbbb0000000000000
0000b00bb0b00bb00b0b0000b0b0b00b00bb0b00b00b000bbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
0b0000b0000b0000bb0000b0000b000b00000b00b0b0b0bbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
b0b00bb0b0000b00b00b00b00b000000b0bbbbbbb0b0bb00bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
0b00b000bb0b0b00b0000b0b0b0b00b0000bb00b000b00bbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
00000bbb0b0b0b00b00000b0b0b0bb0b00b00bb0b000b00bbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
b000b000bb0b000b0b00b0b0b0b000b00000000000b000bbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
00b0bbb0bbb00bbb0bbbbbbbbbbbbbbbbbbbbbbb0bbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
0b00bbbbbbbb0b0b0b0bb0bbb0b00000b0b0b000000b00b0bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
b0000bb0b0b000bb0b00000b0b000000000bb0bb0b0b00b0bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
00b0b0b00b0b0b0b000000b000b0bbbb00bb00bb00000b0bbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbb00bb0b00b00b0b0000b00000b0b00bb0b0b0bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
0000b00b000b0b000bb0bb0000000b0bbbb0000000b0b0b0bbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
000b0bb00b0b0b0b0b0bbbb0bb0bb0000b0b0b0bb0bbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
b000b000bb00b0000000000bbb000b000b0bb0bb0bb0bbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
bb0b0b0b0b00b0bb0bb0b0b0bbbbbbbbbbbbbb0bbbb0bb0bbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
000b00bb0b0bb0b0bbbb0b0bb0bbbbbbbbbbb0bb0bbbb0bbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
000b0b00b00bbbb0bbbb00b0000b0b000bbb0bbbbbb0bb0bbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
0bb00b0b0000bbbb0bb0bbbbb0b0bbbbbb0b0bbb0b0bbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
0000bb000b0000b0bbb00b0bbbb0bbb00b0b00bbb0bbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
bbbb0bb000b00bbb0bbb00b0bbbb0b0bbb0bbb0000bbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
0000bbbbb0bb0bbbb0bb0bbbbbbbbbb0bb0bb0b0bbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
bbbbbbb0bb0b00bbb0b00bbb000bbbb00b0b00bbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbb700bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb700bbbbbbbbbbbbbbbbbbbbbbbbb70000bbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbb700bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb700bbbbbbbbbbbbbbbbbbbbbbbbb70000bbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbb7000bb700000bbbbbbbbbbbbbbbbbb700bbbbbbbbbbbbbbbbbbbbbbb700000bbbbbbbbbbbbbbbbbbbbbb700070000bbbbbb22bbbbbbbb
bbbbbbbbbbbbbbbbbbb7000bb700000bbbbbbbbbbbbbbbbbb700bbbbbbbbbbbbbbbbbbbbbbb700000bbbbbbbbbbbbbbbbbbbbbb700070000bbb2222222bbbbbb
bbbbbbbbbbbbbbbbb700bb7000bbb700000bbbbbbbbbbbbbb700bbbbbbbbbbbbbbbbbbbbbbbb700bbbbbbbbbbbbbbbbbbbbbb7000bbbb7000bb22222222bbbbb
bbbbbbbbbbbbbbbb7000bb7000bbb7000bbbbbbb700bbbbb7000bbbbbbb70000bbbbbbbbbbbbbbbbbbb700bb700b2bbbb22bb70000022700022222222222bbbb
bbbbbbbbbbbbbbbb7000bb7000bbb7000bbbbbbb700bbbbb7000bbbbb2b70000bbb2b222bb2b222bbbb700bb700b22b222222700000227000222222222222bbb
bbbbbbbbbbbbbbbb7000bb7000bbb7000b7002270002bbb270002bb2222700000222222222227002b27000700002222222222227000007000222222222222bbb
bbbbbbbbbbbbbbbb7000227000bb27000b70022700022b22700022222227000002222222b22270022270007000022222222222270000070002222222222222bb
bbbbbbbbbbb2700000002270002b270002b27000000222700000000222702700022222222227000270000000000222222222222271100022222222222222222b
bbbbbbbbb2222b22700022700022270002bb222700022222700022227000270002222222270000000270007000022222222222227111011122222222222222bb
bbbbbb222222222270002270002227000222222700022222700022227000270002222222270000000270007011122222222222227111000122222222222222bb
bbbbbb22222222227000227000222700022227000002222270002222700000222222222222270102227000711112222222222227122711112222222222222bbb
bbbbb2222222700000002270002227000222700000022222700022227000002222222222222711122270107111122222222227111227111112222222222222bb
bbbbb2222222711001012271112227001222712701122222711122227101222222222222222711122270007111122222222227111222271112222222222222bb
bbbb2222222222227111227111222701127101270112222271117111110022222222222222271112227111711112222222222711122227111222222222b22bbb
bbbb2222222222227111227111222701127011271112222271117111111122222222222222271112227111711112222222222711122227111222222bbbbbbbbb
bbb2222222222222711122711222271112711127111271227111711271112271111222222227111222711171111711b22b222711122711111222222bbbbbbbbb
bb2222222227111271112222712227122222711171111222711111222271111122222222271111111111117111112bbbbb22222711171111bbbbbbbbbbbbbbbb
bbbb2222222711127111222271222712222271117111122b71111122227111112222222227111111111111711111bbbbbbb2222711171111bbbbbbbbbbbbbbbb
bbb222222227122271111122271111b22b2222222222bbbbb711112222bb22bb22b222222b271112bbb7112b711bbbbbbbbbbbbb71111bbbbbbbbbbbbbbbbbbb
bbbb22222227122b71111122271111bbbbb22222222b2bbbb71111222b2bbbbbbbbbbbbbbbb7111bbbb711bb711bbbbbbbbbbbbb71111bbbbbbbbbbbbbbbbbbb
bb22222222227111112222222b2bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb711bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb222222222bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbb22222222b2bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbb2222b2bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
__sfx__
000300002e73031720247002470024700097002470024700247000870008700087000870008700167001570015700147001470013700137001370013700127001570015700157002b70000700007000070000700
00060000247202b730307403370028700287002870028700287002870028700277002770027700277002670026700267002670026700267002570025700257002570025700257002570024700247002470023700
000200002d55516700107001370015700187001a7000f70013700167001b700237002570007700077000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
00010000077200773007740077500775008750097500b7500d75012750177301772017700177001770017700177003b7003b7002670023700257002570025700257003a700267002670026700267002670026700
000200001275007710046400563007610096100c6001060014600156000f6001d6000b60023600056000260001600006000000000000000000000000000000000000000000000000000000000000000000000000
00010000275502b5600f5603056032560215603255020540305301a5402d5302c530135202851027510105100f550205501c550085501755014550295002b5002c5002750027500375002750023500215001f500
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
696400001525717257182571c2571525717257182571c2571525717257182571c2571525717257182571c2571525717257182571c2571525717257182571c2571525717257182571c2571525717257182571c257
001000000955009550095500955009550095500955009550095500955009550095500955009550095500955009550095500955009550095500955009550095500955009550095500955009550095500955009550
__music__
00 08094344

