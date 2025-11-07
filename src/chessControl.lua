

function handleChessControls()

    if (gs_csrActv) then
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
            gs_csr = vector((gs_csr.x + moveCursor.x )% 8 + 1, (gs_csr.y + moveCursor.y )% 8 + 1)
        end

        if btnp(5) then
            local board = gs_curGmPos.board
            local csrI = boardIndex(gs_csr)
            local pc = board[csrI]

            if not gs_pcLift then
                if pc ~= "." and (isWhitePiece(pc) == gs_curGmPos.whiteTurn) then
                    sfx(3);
                    gs_curPcLegMvs = getPieceLegalMoves(gs_curGmPos, gs_csr)
                    gs_pcLift = gs_csr
                end
            else
                if contains(gs_curPcLegMvs, csrI) then
                    gs_csrActv = false
                    gs_lstCsrPos[gs_curGmPos.whiteTurn and "white" or "black"] = gs_csr;
                    gs_pcMvng = {from = gs_pcLift, to = gs_csr}
                    gs_curPcLegMvs = {}
                    if board[csrI] ~= "." and (isWhitePiece(board[csrI]) ~= gs_curGmPos.whiteTurn) then
                        gs_pcCptd = gs_csr
                    end
                    gs_pcLift = nil
                elseif vectorcmp(gs_csr, gs_pcLift) then
                    gs_pcLift = nil
                    gs_curPcLegMvs = {}
                elseif isSameColorPiece(board[csrI], board[boardIndex(gs_pcLift)]) then
                    sfx(3);
                    gs_curPcLegMvs = getPieceLegalMoves(gs_curGmPos, gs_csr)
                    gs_pcLift = gs_csr
                end
            end
        end
    end

    if (btnp(4)) then
        sfx(0)
        gs_scrn = "matchMenu"
        gs_mnCsr = 1
        gs_mnSte = {}
    end


end

function on_moveAnimationFinished()
    sfx(4);

    gs_mvAnimFin = true
    makeMove(gs_curGmPos, 
        boardIndex(gs_pcMvng.from), 
        boardIndex(gs_pcMvng.to))

    if (isMate(gs_curGmPos, gs_curGmPos.whiteTurn)) then
        gs_matchOvr = {
            reason = "mate",
            result = gs_curGmPos.whiteTurn and "black" or "white"
        }
    elseif (isStalemate(gs_curGmPos, gs_curGmPos.whiteTurn)) then
        gs_matchOvr = {
            reason = "stale",
            result = "draw"
        }
    end

    gs_mvsNtn[#gs_mvsNtn + 1] = getMoveNotation(gs_posHtr[#gs_posHtr] or gameState_startPosition, gs_pcMvng.from, gs_pcMvng.to)
    if (isCheck(gs_curGmPos, gs_curGmPos.whiteTurn)) then
        sfx(5);
    end
    gs_posHtr[#gs_posHtr + 1] = deep_copy(gs_curGmPos)
    gs_pcMvng = nil
    gs_pcCptd = nil
end

function processMoveAnimationFinished()
    if gs_mvAnimFin then
        gs_mvAnimFin = false
    
        if gs_matchOvr == nil and (gs_curGmPos.whiteTurn and gs_cpuWt) or (not gs_curGmPos.whiteTurn and gs_cpuBk) then
            lucania_startSecond = stat(85)
            lucania_coroutine = cocreate(function()
                move, score = lucania_search(gs_curGmPos, gs_curGmPos.whiteTurn)
                move_from = boardIndexToSquare(move.from)
                move_to = boardIndexToSquare(move.to)
                gs_pcMvng = {from = move_from, to = move_to}
            end)

        elseif gs_matchOvr then
            gs_csrActv = false

            -- Delay game over splash
            add(async_to_run, cocreate(function()
                for i=0,45 do
                    yield()
                end
                music(0)
                gs_scrn = "matchMenu"
                gs_mnCsr = 1
            end))

        else
            gs_csrActv = true
            gs_csr = gs_lstCsrPos[gs_curGmPos.whiteTurn and "white" or "black"] or vector(4, 4);
        end
    end

end

function handleViewNotationControl()

    if (btnp(2)) then
        sfx(2)
        gs_mnCsr = max(1, gs_mnCsr - 1)
        gs_curGmPos = gs_posHtr[gs_mnCsr]
    elseif (btnp(3)) then
        sfx(2)
        gs_mnCsr = min(gs_mnCsr + 1, #gs_posHtr)
        gs_curGmPos = gs_posHtr[gs_mnCsr]
    elseif (btnp(4)) then
        sfx(1)
        gs_curGmPos = deep_copy(gs_posHtr[#gs_posHtr])
        gs_scrn = "chess"
        gs_csrActv = true

        -- Delay - avoid freez in menu
        add(async_to_run, cocreate(function()
            for i=0,3 do
                yield()
            end
            gs_mvAnimFin = true
        end))
    elseif (btnp(5)) then
        sfx(1)
        while #gs_mvsNtn > gs_mnCsr do
            del(gs_mvsNtn, gs_mvsNtn[#gs_mvsNtn])
        end
        while #gs_posHtr > gs_mnCsr do
            del(gs_posHtr, gs_posHtr[#gs_posHtr])
        end
        gs_curGmPos = deep_copy(gs_posHtr[#gs_posHtr])
        gs_csrActv = not ((gs_curGmPos.whiteTurn and gs_cpuWt) or (not gs_curGmPos.whiteTurn and gs_cpuBk));
        gs_scrn = "chess";
        gs_matchOvr = nil

        -- Delay - avoid freez in menu
        add(async_to_run, cocreate(function()
            for i=0,3 do
                yield()
            end
            gs_mvAnimFin = true
        end))
    end

end