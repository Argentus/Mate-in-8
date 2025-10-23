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