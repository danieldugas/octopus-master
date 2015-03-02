" OCTOPUS

if exists("g:loaded_octopus_autoload")
    "finish TODO: UNCOMMENT THIS
endif
let g:loaded_octopus_autoload = 1

function! Octopus#version()
    return '0.1.0'
endfunction

" SECTION: Plugin Initialisation functions
"============================================================
function! Octopus#loadClassFiles() "{{{1
    runtime lib/octopus/Tentacle.vim
    runtime lib/octopus/Sucker.vim
endfunction
"}}}1

" SECTION: User Called Functions
"============================================================
" TODO: Decide to implement executeKey(key) function from keymaps {{{1
" executeKey(key)
" if key == 'a'
"     call thisfunction
" endif
" if key == 'b'
" ...
"
" call Octopus#interceptKey() " TODO: REMOVE THIS CALL FROM OTHER FUNCTIONS

function! Octopus#interceptKey() "{{{1
" This function is essential, it calls for the map <Plug>Octopus
" which forces Vim to wait for the next key and decide which 
" mapping to activate. if no key is pressed, this function 
" activates again.
" if an unmapped key (<Plug>Octopus[key] doesn't exist
" the key is stored in the intercept variable
" TODO: Why does <leader>key break octopus?
    let s:intercept =""
    let s:modifier =""
    if getchar(1)
        unlet s:intercept
        unlet s:modifier
        let s:intercept = getchar()
        let s:modifier = getcharmod()
        call Octopus#echoState(
        \"Octopus is unaware of that command: "
        \ . s:intercept . " | " . nr2char(s:intercept) )
    else
        call Octopus#echoState(g:octopusActiveTentacles)
    endif
    if g:OctopusShowVirtualCursors
        call Octopus#cycleCursors()
    endif
    call feedkeys("\<Plug>Octopus")
    " TODO: handle error messages?
endfunction
"}}}1
function! Octopus#keyEsc() "{{{1
    if g:octopusCurrentMode != 'oi'
        call Octopus#sleepOctopus()
    endif
endfunction
"}}}1
function! Octopus#keyMove(direction) "{{{1
    let s:forceCursorOnCount  = 1
    for i in g:octopusActiveTentacles
        let temporaryTentacle = g:Tentacles[i]
        if temporaryTentacle.isActive
            call temporaryTentacle.moveSucker('all',a:direction)
            call temporaryTentacle.highlightSucker('all', 'Active')
        endif
    endfor
    
    " TODO: maybe move this inside the other loop (tentacle 0)
    if g:octopusActiveTentacles == []
        call g:vSucker.move(a:direction)
        call g:vSucker.highlight('Active')
    endif

    let [l, c] = MovePos( getpos(".")[1:2], a:direction, 'noeol' )
    call cursor(l, c)
    
    call Octopus#interceptKey()
endfunction
"}}}1
function! Octopus#wakeOctopus(mode,...) "{{{1
" Arguments: (mode, [tentacletoToggle])
    " find mode THIS NEEDS TO BE BEFORE EVERYTHING ELSE
    if a:mode == 'v' && char2nr(visualmode()) == 22
        let g:octopusCurrentMode = 'ob'
    endif
    if a:mode == 'v' && visualmode() == 'V'
        let g:octopusCurrentMode = 'ol'
    endif
    if a:mode == 'v' && visualmode() == 'v'
        let g:octopusCurrentMode = 'ov'
    endif
    if a:mode == 'n'
        let g:octopusCurrentMode = 'on'
    endif
    
    " init recurring variables
    "unlet g:octopusActiveTentacles
    "unlet temporaryTentacle
    "unlet g:octopusCurrentMode
    let s:cursortoggle = 0
    let s:forceCursorOnCount = 0
    let g:octopusActiveTentacles = []

    " Save and highlight visual selection
    call Octopus#saveVisualSelection()
    call g:vSucker.highlight('Active')
    call cursor(g:vSucker.getCursorRange()[0], g:vSucker.getCursorRange()[1])
    

    " cursor
    let s:old_guicursor = &guicursor
    let s:old_timeoutlen = &timeoutlen
    let s:old_ttimeoutlen = &ttimeoutlen
    set guicursor+=a:ModeMsg
    set timeoutlen=300
    set ttimeoutlen=-1

    " set Read only (prevent hiccups)
    let s:old_readonly = &ro
    set ro

    " display mode
    call Octopus#echoState('')
    
    " check for extra arguments
    if a:0 > 1
        echoerr "Too many arguments passed to function wakeOctopus()"
    else
        if a:0
            call Octopus#toggleTentacle(a:1)
        else
            " wait for commands
            call Octopus#interceptKey()
        endif
    endif
endfunction
"}}}1
function! Octopus#sleepOctopus() "{{{1
    " make sure everything is as should be
    silent! unlet temporaryTentacle
    "TODO: cleanup other variables?

    for i in range(0,9)
        call Octopus#sleepTentacle(i)
    endfor
    
    call Octopus#forgetVisualSelection()
    
    "restore cursor
    let &guicursor = s:old_guicursor
    let &timeoutlen = s:old_timeoutlen
    let &ttimeoutlen = s:old_ttimeoutlen

    "restor read-only
    let &ro = s:old_readonly

    "TODO: replace this with a useful message
    redraw
    echo ''
endfunction
"}}}1
function! Octopus#toggleTentacle(tentacleID) "{{{1
    if 1 <= a:tentacleID && a:tentacleID <= 8
        let temporaryTentacle = g:Tentacles[a:tentacleID]
        if temporaryTentacle.isActive
            call Octopus#sleepTentacle(a:tentacleID)
        else
            call Octopus#wakeTentacle(a:tentacleID)
        endif
    endif
    if a:tentacleID == 'all'
        if len(g:octopusActiveTentacles) == 8
            for i in range(1,8)
                call Octopus#sleepTentacle(i)
            endfor
        else
            for i in range(1,8)
                call Octopus#wakeTentacle(i)
            endfor
        endif
    endif
    
    if g:octopusActiveTentacles == []
        call Octopus#sleepOctopus()
            "TODO: if not automatically sleep octopus
            "focus on gVsucker again if it wasn't assigned
            "if g:OctopusAutoAssignVisualSelection
    else
        call Octopus#interceptKey()
    endif
endfunction
"}}}1
function! Octopus#clearActiveTentacles() "{{{1
    for i in range(1,8)
        let temporaryTentacle = g:Tentacles[i]
        if temporaryTentacle.isActive
            call temporaryTentacle.rmvSucker('all')
        endif
    endfor

    call Octopus#sleepOctopus()
endfunction
"}}}1
function! Octopus#switchActiveTentacles() "{{{1
    " TODO: fill this
    for i in range(len(g:octopusActiveTentacles)-2, 0, -1) " 7 tentacles -> i in [6 5 4 3 2 1]
        call Octopus#switchTwoTentacles(g:octopusActiveTentacles[i],g:octopusActiveTentacles[i+1])
        call g:Tentacles[g:octopusActiveTentacles[i]].highlightSucker('all', 'Active')
        call g:Tentacles[g:octopusActiveTentacles[i+1]].highlightSucker('all', 'Active')
    endfor
    call g:Tentacles[g:octopusActiveTentacles[-1]].moveCursorToLastSucker()
    call Octopus#interceptKey()
endfunction

"}}}1
function! Octopus#switchTwoTentacles(a, b) "{{{1
    " find the amount of suckers to do this for:
    " TODO: how do I deal with unequal amount of suckers?
    let TentacleA = g:Tentacles[a:a]
    let TentacleB = g:Tentacles[a:b]
    let min = min([TentacleA.suckers, TentacleB.suckers])
    for i in range(1, min)
        let A = TentacleA.getSucker(i)
        let B = TentacleB.getSucker(i)

        " Precalculations to update the range
        let [_, Al1, Al2, Ac1, Ac2] = A.getRange()
        let [_, Bl1, Bl2, Bc1, Bc2] = B.getRange()
        let extralines = 0 "init
        if B.type == 'l' || B.type == 'v'
            let extralines = len(B.content) - 1
        endif
        if A.type == 'l' || A.type == 'v'
            let extralines = extralines - ( len(A.content)-1 )
        endif
        let extracolumns = ( Bc2 - Bc1 ) - ( Ac2 - Ac1 )
        
        " TODO: Fix this when a sucker is missing (create empty suckers?)
        call A.replaceContent(B)
        let posmodif = [Al1, Ac1, extralines, extracolumns]
        call Octopus#updateAllRanges(posmodif)

        " TODO: DEBUG REMOVE
        call A.highlight('Active')
        call B.highlight('Active')

        " TODO: line-visual do not play well with other types!
        " TODO: sucker types must get exchanged at some point.

        " extracolumns is no longer accurate if the selection has moved!
        if len(B.content) > 1 && B.type == 'v'
            let extracolumns = 2*extracolumns
        endif

        call B.replaceContent(A)
        let [_, Bl1, Bl2, Bc1, Bc2] = B.getRange() " B has changed 
        let posmodif = [Bl1, Bc1, -extralines, -extracolumns]
        call Octopus#updateAllRanges(posmodif)
        
        " TODO: DEBUG REMOVE
        call A.highlight('Active')
        call B.highlight('Active')

        " TODO: Remember to update the sucker content if need be!
        call A.updateContent()
        call B.updateContent()
        "TODO: put temp suckers A, B in the tentacles
    endfor

    " TODO: Do I switch the tentacles?
    let temp = deepcopy(TentacleA)
    let TentacleA = TentacleB
    let TentacleB = temp
    unlet temp
endfunction
"}}}1

" SECTION: Octopus State
"============================================================
function! Octopus#echoState(keys) "{{{1
    redraw "redraw before echo avoids 'press enter' messages
    if g:octopusCurrentMode=='on' 
        echo "-- OCTOPUS NORMAL --"a:keys 
    endif
    if g:octopusCurrentMode=='ov' 
        echo "-- OCTOPUS VISUAL --"a:keys 
    endif
    if g:octopusCurrentMode=='ob'
        echo "-- OCTOPUS BLOCK-VISUAL --"a:keys
    endif
    if g:octopusCurrentMode=='ol'
        echo "-- OCTOPUS LINE-VISUAL --"a:keys
    endif
endfunction
"}}}1

" SECTION: Tentacle State
"============================================================
function! Octopus#wakeTentacle(tentacleID) "{{{1
    " TODO: current mode becomes first tentacle mode?
    let temporaryTentacle = g:Tentacles[a:tentacleID]
    if !temporaryTentacle.isActive
        if exists('g:vSucker')
            if g:OctopusAutoAssignVisualSelection
                if g:octopusCurrentMode[1] != 'n' 
                    let g:newSucker = g:vSucker "newSucker is checked later to prevent overlap (moveCursorToLastSucker)
                    call temporaryTentacle.addSucker( deepcopy(g:vSucker) )
                endif
                call Octopus#forgetVisualSelection()
            else
                call g:vSucker.highlight('Passive')
            endif
        endif
        
        if temporaryTentacle.suckers == 0 "prevent active empty tentacles {{{2
            let [l1, c1] = getpos(".")[1:2]
            let [l2, c2] = getpos(".")[1:2]
            
            " TODO: copy last active tentacle one line down instead
            " better yet, test if cursor is in an active tentacle, if yes,
            " move it down
            " Prevent overlap {{{3
            if exists('g:newSucker')
                let old = g:newSucker.range
                let coerced = copy(old)
                let coerced[3] = CoerceColumn(old[1], old[3])
                let coerced[4] = CoerceColumn(old[2], old[4])
                if [l1, l2, c1, c2] == coerced[1:4]
                    let [l1, l2, c1, c2] = old[1:4]
                    let l1 = l1 + 1
                    let l2 = l2 + 1
                endif
                unlet g:newSucker
            endif    "}}}
            
            let g:newSucker = g:OctopusSucker.New()

            call g:newSucker.setRange([0, l1, l2, c1, c2])
            call g:newSucker.updateContent()
            "TODO: find a cleaner way of allowing visual selection
            call g:newSucker.setType(g:octopusCurrentMode[1])
            call temporaryTentacle.addSucker( deepcopy(g:newSucker))
        endif "}}}

        call temporaryTentacle.moveCursorToLastSucker()
        call temporaryTentacle.highlightSucker('all', 'Active')
        let temporaryTentacle.isActive = 1
        call add(g:octopusActiveTentacles, a:tentacleID)
    endif
endfunction
"}}}1
function! Octopus#sleepTentacle(tentacleID) "{{{1
    let temporaryTentacle = g:Tentacles[a:tentacleID]
    if temporaryTentacle.isActive
        call temporaryTentacle.highlightSucker('all', 'Passive')
        call temporaryTentacle.highlightCursors(0)
        let temporaryTentacle.isActive = 0
        call filter(g:octopusActiveTentacles, 'v:val != a:tentacleID')
    endif
endfunction
"}}}1

" SECTION: Apply to Buffers and Tentacles
"============================================================
function! Octopus#cycleCursors(...) "{{{1
    let s:cursortoggle = ( s:cursortoggle == 0 ) + s:forceCursorOnCount "alternates between 0 and 1
    let s:forceCursorOnCount = max([0, s:forceCursorOnCount - 1])
    if g:octopusActiveTentacles == []
        call g:vSucker.highlightCursor(s:cursortoggle)
    else
        for i in g:octopusActiveTentacles
            let temporaryTentacle = g:Tentacles[i]
            call temporaryTentacle.highlightCursors(s:cursortoggle)
        endfor
    endif

endfunction
"}}}1
function! Octopus#saveVisualSelection() "{{{1
    let g:vSucker = g:OctopusSucker.New()
    if g:octopusCurrentMode[1] == 'b' || g:octopusCurrentMode[1] == 'v'
        let [l1, c1] = getpos("'<")[1:2]
        let [l2, c2] = getpos("'>")[1:2]
        " TODO: This doesn't work, vim thinks the cursor is at the start of
        " the visual selection until it is exited.
        "if getpos(".")[1] <= l1 && getpos(".")[2] <= c1
         "   let g:vSucker.cursorPos = 'start'
        "endif
    endif
    if g:octopusCurrentMode[1] == 'l'
        let [l1, c1] = getpos("'<")[1:2]
        let [l2, c2] = getpos("'>")[1:2]
        " last column coercion moved to setRange() function
    endif
    if g:octopusCurrentMode[1] == 'n'
        let [l1, c1] = getpos(".")[1:2]
        let [l2, c2] = getpos(".")[1:2]
    endif
    
    call g:vSucker.setRange([0, l1, l2, c1, c2])
    call g:vSucker.setType(g:octopusCurrentMode[1])
    call g:vSucker.updateContent()
endfunction
"}}}1
function! Octopus#updateAllRanges(posmodif) "{{{1
    " When lines and columns are added/removed
    " at point [l c] update all ranges after
    " that point to reflect the modification
    let [l, c, extralines, extracolumns] = a:posmodif
    for i in range(1,8)
        for ii in range(1, g:Tentacles[i].suckers)
            let S = g:Tentacles[i].getSucker(ii)

            let [Sbuf, Sl1, Sl2, Sc1, Sc2] = S.getRange() " sucker values
            let [_,    Nl1, Nl2, Nc1, Nc2] = S.getRange() " new values
            
            " TODO: Edge case, S is in , move S to 's new
            " position? would require l and c too
            if S.type == 'b'
                "TODO : DO this better
                if min([Sl1, Sl2]) <= l && l <= max([Sl1, Sl2])
                    if min([Sc1, Sc2]) <= c && c <= max([Sc1, Sc2])
                        if Sc2 >= Sc1
                            let Nc2 = Sc2 + extracolumns
                        else
                            let Nc1 = Sc1 + extracolumns
                        endif
                    endif
                    if c < min([Sc1, Sc2])
                        let Nc1 = Sc1 + extracolumns
                        let Nc2 = Sc2 + extracolumns
                    endif

                    if Sl2 >= Sl1
                        let Nl2 = Sl2 + extralines
                    else
                        let Nl1 = Sl1 + extralines
                    endif
                endif


                if l < min([Sl1, Sl2])
                    let Nl1 = Sl1 + extralines
                    let Nl2 = Sl2 + extralines
                endif

            else
                " if sucker is not block-visual
                if Sl1 == l && Sc1 > c
                    let Nc1 = Sc1 + extracolumns
                    let Nl1 = Sl1 + extralines
                endif
                if Sl1 > l
                    let Nl1 = Sl1 + extralines
                    if Nl1 == l && Nl1 > c
                        let Nc1 = Sc1 + extracolumns
                    endif
                endif

                if Sl2 == l && Sc2 > c
                    let Nc2 = Sc2 + extracolumns
                    let Nl2 = Sl2 + extralines
                endif
                if Sl2 > l
                    let Nl2 = Sl2 + extralines
                    if Nl2 == l && Nl2 > c
                        let Nc2 = Sc2 + extracolumns
                    endif
                endif
            endif
            call S.setRange([Sbuf, Nl1, Nl2, Nc1, Nc2])

        endfor
    endfor

endfunction
"}}}1
function! Octopus#forgetVisualSelection() "{{{1
    " TODO: Debug missing IDs
    if exists('g:vSucker')
        let [l, c] = g:vSucker.getCursorRange()
        call cursor(l, c)
        call g:vSucker.unHighlight()
        call g:vSucker.highlightCursor(0)
        unlet g:vSucker
    endif
endfunction
"}}}1


" vim: set sw=4 tabstop=4 expandtab et fdm=marker
