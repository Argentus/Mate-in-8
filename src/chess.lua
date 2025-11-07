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
    K = split("1, -1, 10, -10, 11, -11, 9, -9"),
    k = split("1, -1, 10, -10, 11, -11, 9, -9")
}

function get960StartingPosition()
    local pos = getStartingPosition()
    local options = {1,3,5,7}
    local b1 = rnd(options)
    local b2 = rnd(options) + 1

    options = split"1,2,3,4,5,6,7,8"
    del(options, b1)
    del(options, b2)
    local q = rnd(options)
    del(options, q)
    local n1 = rnd(options)
    del(options, n1)
    local n2 = rnd(options) 
    del(options, n2)

    local r1 = options[1]
    local r2 = options[3]
    local k = options[2]

    pos.board[21 + b1] = "B"
    pos.board[21 + b2] = "B"
    pos.board[21 + q] = "Q"
    pos.board[21 + n1] = "N"
    pos.board[21 + n2] = "N"
    pos.board[21 + r1] = "R"
    pos.board[21 + r2] = "R"
    pos.board[21 + k] = "K"
    pos.whiteOrigARookPosition = 21 + r1
    pos.whiteOrigHRookPosition = 21 + r2

    pos.board[91 + b1] = "b"
    pos.board[91 + b2] = "b"
    pos.board[91 + q] = "q"
    pos.board[91 + n1] = "n"
    pos.board[91 + n2] = "n"
    pos.board[91 + r1] = "r"
    pos.board[91 + r2] = "r"
    pos.board[91 + k] = "k"
    pos.blackOrigARookPosition = 91 + r1
    pos.blackOrigHRookPosition = 91 + r2

    pos.hash = getPositionHash(pos)
    pos.visitedPositions[1] = getFen(pos)
    return pos
end

function getStartingPosition()
    local pos = {
        board = split(FRESH_BOARD),
        whiteTurn = true,
        enPassant = nil,
        capdPcs = {
            white = {},
            black = {}
        },
        wtCslH = true,
        wtCslA = true,
        whiteOrigHRookPosition = 29,
        whiteOrigARookPosition = 22,
        bkCslH = true,
        bkCslA = true,
        blackOrigHRookPosition = 99,
        blackOrigARookPosition = 92,
        visitedPositions = {},
        movesSinceLastCapture = 0
    }
    pos.hash = getPositionHash(pos)
    pos.visitedPositions[1] = getFen(pos)
    return pos
end

-- No legal check, returns undo changes
function makeMove(pos, from, to)

    local board = pos.board
    local pc = board[from]
    local capturedPiece = board[to]

    local undoMove = {
        boardChanges = {},
        capture = nil,
        movesSinceLastCapture = pos.movesSinceLastCapture,
        enPassant = pos.enPassant,
        wtCslH = pos.wtCslH,
        wtCslA = pos.wtCslA,
        bkCslH = pos.bkCslH,
        bkCslA = pos.bkCslA,
    }
    undoMove.boardChanges[from] = pc
    undoMove.boardChanges[to] = capturedPiece

    -- EP
    if (pc == "p" or pc == "P") and pos.enPassant and pos.enPassant == to then
        local epPawn = to + (pos.whiteTurn and -10 or 10)
        capturedPiece = board[epPawn]
        board[epPawn] = "."
        undoMove.boardChanges[epPawn] = capturedPiece
    end

    board[from] = "."
    board[to] = pc

    pos.board = board

    if (capturedPiece ~= ".") and (isWhitePiece(capturedPiece) ~= isWhitePiece(pc))
    then
        pos.capdPcs[pos.whiteTurn and "white" or "black"][#pos.capdPcs[pos.whiteTurn and "white" or "black"] + 1] = capturedPiece
        pos.movesSinceLastCapture = 0
        undoMove.capture = capturedPiece
    else
        pos.movesSinceLastCapture = pos.movesSinceLastCapture + 1
    end

    -- Mark EP sq
    if (pc == "p" or pc == "P") and (abs(from - to) == 20)
    then
        pos.enPassant = to + (pos.whiteTurn and -10 or 10)
    else
        pos.enPassant = nil
    end

    -- Castl
    if pc == "K" then
        if to == 28 and pos.wtCslH then
            board[pos.whiteOrigHRookPosition] = (to == pos.whiteOrigHRookPosition) and "K" or "."
            board[27] = "R"
            undoMove.boardChanges[pos.whiteOrigHRookPosition] = "R"
            undoMove.boardChanges[27] = (from == 27) and "K" or "."
        elseif to == 24 and pos.wtCslA then
            board[pos.whiteOrigARookPosition] = (to == pos.whiteOrigARookPosition) and "K" or "."
            board[25] = "R"
            undoMove.boardChanges[pos.whiteOrigARookPosition] = "R"
            undoMove.boardChanges[25] = (from == 25) and "K" or "."
        end
    elseif pc == "k" then
        if to == 98 and pos.bkCslH then
            board[pos.blackOrigHRookPosition] = (to == pos.blackOrigHRookPosition) and "k" or "."
            board[97] = "r"
            undoMove.boardChanges[pos.blackOrigHRookPosition] = "r"
            undoMove.boardChanges[97] = (from == 97) and "k" or "."
        elseif to == 94 and pos.bkCslA then
            board[pos.blackOrigARookPosition] = (to == pos.blackOrigARookPosition) and "k" or "."
            board[95] = "r"
            undoMove.boardChanges[pos.blackOrigARookPosition] = "r"
            undoMove.boardChanges[95] = (from == 95) and "k" or "."
        end
    end

    -- Castling rights
    if pc == "K" then
        pos.wtCslH = false
        pos.wtCslA = false
    elseif pc == "k" then
        pos.bkCslH = false
        pos.bkCslA = false
    end

    if from == pos.whiteOrigHRookPosition or to == pos.whiteOrigHRookPosition then
        pos.wtCslH = false
    elseif from == pos.whiteOrigARookPosition or to == pos.whiteOrigARookPosition then
        pos.wtCslA = false
    elseif from == pos.blackOrigHRookPosition or to == pos.blackOrigHRookPosition then
        pos.bkCslH = false
    elseif from == pos.blackOrigARookPosition or to == pos.blackOrigARookPosition then
        pos.bkCslA = false
    end

    -- Promotion
    if (pc == "P" and to >= 92) then
        board[to] = "Q"
    elseif (pc == "p" and to <= 29) then
        board[to] = "q"
    end

    pos.whiteTurn = not pos.whiteTurn
    pos.visitedPositions[#pos.visitedPositions + 1] = getFen(pos)

    return undoMove
end

function undoMove(pos, undoMove)
    for index, pc in pairs(undoMove.boardChanges) do
        pos.board[index] = pc
    end
    if (undoMove.capture) then
        pos.capdPcs[pos.whiteTurn and "black" or "white"][#pos.capdPcs[pos.whiteTurn and "black" or "white"]] = nil
    end
    pos.whiteTurn = not pos.whiteTurn
    pos.visitedPositions[#pos.visitedPositions] = nil
    pos.movesSinceLastCapture = undoMove.movesSinceLastCapture
    pos.enPassant = undoMove.enPassant
    pos.wtCslH = undoMove.wtCslH
    pos.wtCslA = undoMove.wtCslA
    pos.bkCslH = undoMove.bkCslH
    pos.bkCslA = undoMove.bkCslA
end

function getPieceLegalMoves(pos, sq, ignoreCheck)
    ignoreCheck = ignoreCheck or false

    local board = pos.board
    local sqI = boardIndex(sq)

    local pc = pos.board[boardIndex(sq)]
    movements = PIECE_MOVES[pc]
    local lgMvs = {}
    local lgMvCaps = {}
    local lgMvCx = {}

    for _, m in pairs(movements) do
        local crawl = (to_lower(pc) == 'r' or to_lower(pc) == 'b' or to_lower(pc) == 'q') and 7 or 1
        local capOrProm = false

        for i = 1, crawl do
            local tgtIdx = sqI + m * i
            local tgtPc = board[tgtIdx]
            if tgtPc == "x" or (tgtPc ~= "." and isBlackPiece(pc) == isBlackPiece(tgtPc)) then
                
                goto cntNxMvt
            end

            -- P
            if to_lower(pc) == "p" then
                if abs(m) == 20 then
                    -- 2-step
                    if (sq.y ~= 2 and sq.y ~= 7) or tgtPc ~= "." or board[sqI + m/2] ~= "." then
                        goto cntNxMvt
                    end
                elseif abs(m) == 10 then
                    -- 1-step
                    if tgtPc ~= "." then
                        goto cntNxMvt
                    end
                    capOrProm = (sq.y == (isWhitePiece(pc) and 8 or 1)) and "Q"
                else 
                    -- Takes
                    if (tgtPc == "." and not (pos.enPassant and (pos.enPassant == tgtIdx))) or (tgtPc ~= "." and (isBlackPiece(pc) == isBlackPiece(tgtPc))) then
                        -- No take
                        goto cntNxMvt
                    else
                        capOrProm = (tgtPc ~= ".") and tgtPc or "P"
                    end
                end
            end

            if tgtPc ~= "." then
                if (isBlackPiece(pc) == isBlackPiece(tgtPc)) then
                    -- No take own
                    goto cntNxMvt
                else
                    capOrProm = to_upper(tgtPc)
                end
            end

            if (not ignoreCheck) then
                local undo = makeMove(pos, sqI, tgtIdx)
                if (not isCheck(pos, isWhitePiece(pc))) then
                    lgMvs[#lgMvs + 1] = tgtIdx
                    if (capOrProm) then
                        lgMvCaps[tgtIdx] = capOrProm
                    end
                    if (isCheck(pos, isBlackPiece(pc))) then
                        lgMvCx[tgtIdx] = true
                    end
                end
                undoMove(pos, undo)
            else
                lgMvs[#lgMvs + 1] = tgtIdx
                if (capOrProm) then
                    lgMvCaps[tgtIdx] = capOrProm
                end
            end

            if tgtPc ~= "." then
                goto cntNxMvt
            end

        end

        ::cntNxMvt::
    end

    -- Castling - support 960
    if to_lower(pc) == "k" then
        if isWhitePiece(pc) then
            -- White
            if pos.wtCslH and not isSqAtk(pos, 28, isWhitePiece(pc)) then
                -- king's route to final sq clear and no harm
                local canDo = true
                if sqI < 28 then
                    for i = sqI + 1, 28 do
                        if (board[i] ~= "." and board[i] ~= "R") or isSqAtk(pos, i, isWhitePiece(pc)) then
                            canDo = false
                            break
                        end
                    end
                end
                
                if sqI ~= 27 and board[27] ~= "." then
                    canDo = false
                end


                if canDo then
                    lgMvs[#lgMvs + 1] = 28
                end
            end
            if pos.wtCslA and not isSqAtk(pos, 24, isWhitePiece(pc)) then
                local canDo = true
                if sqI > 24 then
                    for i = sqI - 1, 24, -1 do
                        if (board[i] ~= "." and board[i] ~= "R") or isSqAtk(pos, i, isWhitePiece(pc)) then
                            canDo = false
                            break
                        end
                    end
                elseif sqI < 24 then
                    if board[24] ~= "." or isSqAtk(pos, 24, isWhitePiece(pc)) then
                        canDo = false
                    end
                end

                if sqI ~= 25 and board[25] ~= "." then
                    canDo = false
                end

                if canDo then
                    lgMvs[#lgMvs + 1] = 24
                end
            end
        else
            if pos.bkCslH and not isSqAtk(pos, 98, isWhitePiece(pc)) then
                local canDo = true
                if sqI < 98 then
                    for i = sqI + 1, 98 do
                        if (board[i] ~= "." and board[i] ~= "r") or isSqAtk(pos, sqI, isWhitePiece(pc)) then
                            canDo = false
                            break
                        end
                    end
                end
                
                if sqI ~= 97 and board[97] ~= "." then
                    canDo = false
                end

                if canDo then
                    lgMvs[#lgMvs + 1] = 98
                end
            end
            if pos.bkCslA and not isSqAtk(pos, 94, isWhitePiece(pc)) then
                local canDo = true
                if sqI > 94 then
                    for i = sqI - 1, 94, -1 do
                        if (board[i] ~= "." and board[i] ~= "r") or isSqAtk(pos, sqI, isWhitePiece(pc)) then
                            canDo = false
                            break
                        end
                    end
                elseif sqI < 94 then
                    if board[94] ~= "." or isSqAtk(pos, 94, isWhitePiece(pc)) then
                        canDo = false
                    end
                end

                if sqI ~= 95 and board[95] ~= "." then
                    canDo = false
                end

                if canDo then
                    lgMvs[#lgMvs + 1] = 94
                end
            end
        end
    end

    return lgMvs, lgMvCaps, lgMvCx
end

function getAllLegalMoves(pos, white, ignoreCheck)
    local lgMvs = {}
    for i = 21, 100 do
        local sq = boardIndexToSquare(i)
        local pc = pos.board[i]
        if (white and isWhitePiece(pc)) or (not white and isBlackPiece(pc)) then 
            local moves, captures, checks = getPieceLegalMoves(pos, sq, ignoreCheck)
            for _, move in pairs(moves) do
                lgMvs[#lgMvs + 1] = {from = i, to = move, takes = captures[move], check = checks[move], pc = pc}
            end
        end
    end
    return lgMvs
end

function isSqAtk(pos, sqI, white)
    local board = pos.board

    -- by P
    local enemyPawnAttackDirection = white and 10 or -10
    local enemyPawn = white and "p" or "P"

    if board[sqI + enemyPawnAttackDirection - 1] == enemyPawn or
       board[sqI + enemyPawnAttackDirection + 1] == enemyPawn then
        return true
    end

    -- by N
    for _,move in ipairs(PIECE_MOVES.N) do
        local knightIndex = sqI + move
        if board[knightIndex] == (white and "n" or "N") then
            return true
        end
    end

    -- by B,Q,K
    for _,move in ipairs(PIECE_MOVES.B) do
        for i = 1, 7 do
            local tgtIdx = sqI + move * i
            if i == 1 and (board[tgtIdx] == (white and "k" or "K")) then
                return true
            end
            if board[tgtIdx] == (white and "b" or "B") or board[tgtIdx] == (white and "q" or "Q") then
                return true
            elseif board[tgtIdx] ~= "." then
                break -- shielded
            end
        end
    end

    -- by R,Q,K
    for _,move in ipairs(PIECE_MOVES.R) do
        for i = 1, 7 do
            local tgtIdx = sqI + move * i
            if i == 1 and (board[tgtIdx] == (white and "k" or "K")) then
                return true
            end
            if board[tgtIdx] == (white and "r" or "R") or board[tgtIdx] == (white and "q" or "Q") then
                return true
            elseif board[tgtIdx] ~= "." then
                break -- shielded
            end
        end
    end

    return false
end

function isCheck(pos, white)
    local kingIndex = nil
    for i = 21, 100 do
        local pc = pos.board[i]
        if (white and pc == "K") or (not white and pc == "k") then
            kingIndex = i
        end
    end

    if not kingIndex then
        return false
    end

    return isSqAtk(pos, kingIndex, white)
end

function isMate(pos, white)
    local lgMvs = getAllLegalMoves(pos, white, false)
    return (#lgMvs == 0) and isCheck(pos, white)
end

function isStalemate(pos, white)
    local lgMvs = getAllLegalMoves(pos, white, false)
    return (#lgMvs == 0) and not isCheck(pos, white)
end