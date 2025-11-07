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
        (position.wtCslH and "K" or "") ..
        (position.wtCslA and "Q" or "") ..
        (position.bkCslH and "k" or "") ..
        (position.bkCslA and "q" or "")
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

    if position.wtCslH   then hash = bxor(hash, zobrist["cK"]) end
    if position.wtCslA  then hash = bxor(hash, zobrist["cQ"]) end
    if position.bkCslH   then hash = bxor(hash, zobrist["ck"]) end
    if position.bkCslA  then hash = bxor(hash, zobrist["cq"]) end

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

function getFen(position)
    local fen = ""
    for rank=8,1,-1 do
        local emptyCount = 0
        for file=1,8 do
            local sqIdx = boardIndex(vector(file, rank))
            local piece = position.board[sqIdx]
            if piece == "." then
                emptyCount += 1
            else
                if emptyCount > 0 then
                    fen = fen .. emptyCount
                    emptyCount = 0
                end
                fen = fen .. piece
            end
        end
        if emptyCount > 0 then
            fen = fen .. emptyCount
        end
        if rank > 1 then
            fen = fen .. "/"
        end
    end

    fen = fen .. " " .. (position.whiteTurn and "w" or "b") .. " "

    local castling = ""
    if position.wtCslH then castling ..= position.whiteOrigHRookPosition == 29 and "K" or to_upper(getFile(position.whiteOrigHRookPosition)) end
    if position.wtCslA then castling ..= position.whiteOrigARookPosition == 22 and "Q" or to_upper(getFile(position.whiteOrigARookPosition))  end
    if position.bkCslH then castling ..= position.blackOrigHRookPosition == 99 and "k" or getFile(position.blackOrigHRookPosition) end
    if position.bkCslA then castling ..= position.blackOrigARookPosition == 92 and "q" or getFile(position.blackOrigARookPosition) end
    if castling == "" then castling = "-" end
    fen ..= castling .. " "

    if position.enPassant then
        local epSquare = boardIndexToSquare(position.enPassant)
        fen ..= chr(96 + epSquare.x) .. tostring(epSquare.y)
    else
        fen ..= "-"
    end

    fen ..= " " .. position.movesSinceLastCapture .. " " .. flr(#position.visitedPositions / 2 + 1)

    return fen
end

function getFile(idx)
    return chr(95 + (idx % 10))
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

    -- ambig?
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
    if isMate(gs_curGmPos, gs_curGmPos.whiteTurn) then
        notation = notation .. "#"
    elseif  isCheck(gs_curGmPos, gs_curGmPos.whiteTurn) then
        notation = notation .. "+"
    end


    return notation
end