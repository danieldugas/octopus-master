"CLASS: Tentacle
"Octopus possesses 8 deployable tentacles, each with multiple suckers
"Each tentacle has many suckers, which stick to a range in the file.
"exampleTentacle = {isActive: 0, suckers: 2, 1: firstSucker, 2: secondSucker }
"============================================================
let s:Tentacle = {}
let g:OctopusTentacle = s:Tentacle

" FUNCTION: s:Tentacle.New() {{{1
function! s:Tentacle.New(ID)
    let newTentacle = copy(self)
    let newTentacle.suckers = 0
    let newTentacle.isActive = 0
    let newTentacle.ID = a:ID
    return newTentacle
endfunction

" FUNCTION: s:Tentacle.addSucker(sucker) {{{1
function! s:Tentacle.addSucker(sucker)
    let self.suckers+=1
    let a:sucker.parent = self.ID
    execute "let self." . self.suckers . " = a:sucker"
endfunction

" FUNCTION: s:Tentacle.getSucker(suckerNumber) {{{1
function! s:Tentacle.getSucker(suckerNumber)
    exec "let sucker = self." . a:suckerNumber
    return sucker
endfunction

" FUNCTION: s:Tentacle.rmvSucker(suckerNumber) {{{1
function! s:Tentacle.rmvSucker(suckerNumber)
    " a string starting with a letter is evaluated as 0!
    if a:suckerNumber <= self.suckers && a:suckerNumber != 0
        execute "call self." . a:suckerNumber . ".unHighlight()"
        execute "call self." . a:suckerNumber . ".highlightCursor(0)"
        execute "unlet self." . a:suckerNumber

        " shift all remaining suckers to fill the gap
        for i in range(a:suckerNumber, self.suckers-1)
            execute "let self." . i . " = self." . (i+1)
        endfor
        execute "unlet self." . self.suckers

        let self.suckers-=1
    endif
    if a:suckerNumber == 'last'
        execute "call self." . self.suckers . ".unHighlight()"
        execute "call self." . self.suckers . ".highlightCursor(0)"
        execute "unlet self." . self.suckers
        let self.suckers-=1
    endif
    if a:suckerNumber == 'all'
        for i in range(1,self.suckers)
            execute "call self." . i . ".unHighlight()"
            execute "call self." . i . ".highlightCursor(0)"
            execute "unlet self." . i
        endfor
        let self.suckers=0
    endif
endfunction

" FUNCTION: s:Tentacle.moveSucker(suckerNumber, direction) {{{1
function! s:Tentacle.moveSucker(suckerNumber, direction)
    " a string starting with a letter is evaluated as 0!
    if a:suckerNumber <= self.suckers && a:suckerNumber != 0
        execute "call self." . a:suckerNumber . ".move(a:direction)"
    endif
    if a:suckerNumber == 'last'
        execute "call self." . self.suckers . ".move(a:direction)"
    endif
    if a:suckerNumber == 'all'
        for i in range(1,self.suckers)
            execute "call self." . i . ".move(a:direction)"
        endfor
    endif
endfunction

" FUNCTION: s:Tentacle.highlightSucker(suckerNumber, style) {{{1
function! s:Tentacle.highlightSucker(suckerNumber, style)
    " a string starting with a letter is evaluated as 0!
    if a:suckerNumber <= self.suckers && a:suckerNumber != 0
        execute "call self." . a:suckerNumber . ".highlight(a:style)"
    endif
    if a:suckerNumber == 'last'
        execute "call self." . self.suckers . ".highlight(a:style)"
    endif
    if a:suckerNumber == 'all'
        for i in range(1,self.suckers)
            execute "call self." . i . ".highlight(a:style)"
        endfor
    endif
endfunction

" FUNCTION: s:Tentacle.unHighlightSucker(suckerNumber) {{{1
function! s:Tentacle.unHighlightSucker(suckerNumber)
    if a:suckerNumber <= self.suckers && a:suckerNumber != 0
        execute "call self." . a:suckerNumber . ".unHighlight()"
    endif
    if a:suckerNumber == 'last'
        execute "call self." . self.suckers . ".unHighlight()"
    endif
    if a:suckerNumber == 'all'
        for i in range(1,self.suckers)
            execute "call self." . i . ".unHighlight()"
        endfor
    endif
endfunction

" FUNCTION: s:Tentacle.moveCursorToLastSucker() {{{1
function! s:Tentacle.moveCursorToLastSucker()

    execute "let [l, c] = self." . self.suckers . ".getCursorRange()"
    call cursor(l, c)
        
endfunction

" FUNCTION: s:Tentacle.highlightCursors(toggle) {{{1
function! s:Tentacle.highlightCursors(toggle)
    for i in range(1,self.suckers)
        execute "call self." . i . ".highlightCursor(a:toggle)"
    endfor
endfunction

" }}}

" vim: set sw=4 tabstop=4 expandtab et fdm=marker
