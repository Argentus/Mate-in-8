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