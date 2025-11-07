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
    local piece = gs_curGmPos.board[index]
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
    local pieceLifted = gs_csrActv and boardIndex(gs_pcLift or gs_csr)
    local board = gs_curGmPos.board
    local whiteTurn = gs_curGmPos.whiteTurn

    if not pieceLifted or not gs_csrActv or (board[pieceLifted] >= "a" and whiteTurn) or
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

    if gs_pcMvng and not animations_movePiece then
        animateMovePiece(gs_pcMvng.from, gs_pcMvng.to)
    end
    if gs_pcCptd and 
        ((not animations_capturePiece[boardIndex(gs_pcCptd)]) or 
         (animations_capturePiece[boardIndex(gs_pcCptd)].age > MOVE_ANIM_DURATION)) then
        animateCapturePiece(boardIndex(gs_pcCptd))
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

    local board = gs_curGmPos.board

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
            if gs_csrActv and gs_csr.x == file and gs_csr.y == rank then
                line(ix * 10 -3, iy * 10 + 7, ix * 10 + 6, iy * 10 + 7, gs_curGmPos.whiteTurn and 9 or 8)
                line(ix * 10 -3, iy * 10 + 7, ix * 10 - 3, iy * 10 + 16, gs_curGmPos.whiteTurn and 9 or 8)
                line(ix * 10 -3, iy * 10 + 16, ix * 10 + 6, iy * 10 + 16, gs_curGmPos.whiteTurn and 9 or 8)
                line(ix * 10 + 6, iy * 10 + 7, ix * 10 + 6, iy * 10 + 16, gs_curGmPos.whiteTurn and 9 or 8)
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
                if animations_movePiece and gs_pcMvng and gs_pcMvng.from.x == file and gs_pcMvng.from.y == rank then
                    drawPiece(piece, animations_movePiece.x, animations_movePiece.y, "move")
                else
                    local dy = animations_liftPiece[bIndex] and animations_liftPiece[bIndex].dy or (animations_releasePiece[bIndex] and animations_releasePiece[bIndex].dy or 0)
                    if not (gs_pcCptd and gs_pcCptd.x == file and gs_pcCptd.y == rank) then
                        drawPiece(piece, ix * 10 - 2, iy * 10 + 16 + dy)
                    end
                end
            end

            if contains(gs_curPcLegMvs, bIndex) then
                line(ix * 10, iy * 10 + 10 , ix * 10 + 3, iy * 10 + 13, gs_curGmPos.whiteTurn and 9 or 8)
                line(ix * 10, iy * 10 + 13 , ix * 10 + 3, iy * 10 + 10, gs_curGmPos.whiteTurn and 9 or 8)
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
    for i, piece in pairs(gs_curGmPos.capdPcs[gameState_playingWhite and "black" or "white"]) do
        local pieceSprite = PIECES_SPRITES[piece]
        sspr(pieceSprite.x, pieceSprite.y, 8, pieceSprite.h, 1 + i * 5, 14 - pieceSprite.h)
    end
    for i, piece in pairs(gs_curGmPos.capdPcs[gameState_playingWhite and "white" or "black"]) do
        local pieceSprite = PIECES_SPRITES[piece]
        sspr(pieceSprite.x, pieceSprite.y, 8, pieceSprite.h, 1 + i * 5, 106 - pieceSprite.h)
    end

    -- Notation
    local firstDisplayedMoveIndex = 1
    if (viewNotation) then
        firstDisplayedMoveIndex = max(0, min(gs_mnCsr - 6, #gs_mvsNtn - 12))
    else
        firstDisplayedMoveIndex = max(#gs_mvsNtn - 12, 0)
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

    if #gs_mvsNtn == 0 then
        print_custom("1.", 95, 16, 8)


    else
        for i = 1, min(#gs_mvsNtn, 12) do
            local moveIndex = firstDisplayedMoveIndex + i
            if moveIndex % 2 == 1 then
                print_custom( "" .. (flr(moveIndex / 2) + 1) .. ".", 95, 10 + i * 6, 8)
                if viewNotation and moveIndex == gs_mnCsr then
                    print_custom( "" .. (flr(moveIndex / 2) + 1) .. ".", 96, 10 + i * 6, 7)
                end
            else
                print_custom("...", 95, 10 + i * 6, 0)
                if viewNotation and moveIndex == gs_mnCsr then
                    print_custom("...", 96, 10 + i * 6, 7)
                end
            end

            if viewNotation and moveIndex == gs_mnCsr then
                print_custom(gs_mvsNtn[moveIndex], 106, 10 + i * 6, 9)
            end
            print_custom(gs_mvsNtn[moveIndex], 107, 10 + i * 6, 0)
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