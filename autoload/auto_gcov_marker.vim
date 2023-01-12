if exists('g:autoloaded_auto_gcov_marker') || &cp || version < 700
    finish
else
    if !exists("g:auto_gcov_marker_line_covered")
        let g:auto_gcov_marker_line_covered = '✓'
    endif
    if !exists("g:auto_gcov_marker_line_uncovered")
        let g:auto_gcov_marker_line_uncovered = '✘'
    endif
    if !exists("g:auto_gcov_marker_branch_covered")
        let g:auto_gcov_marker_branch_covered = '✓✓'
    endif 
    if !exists("g:auto_gcov_marker_branch_partly_covered")
        let g:auto_gcov_marker_branch_partly_covered = '✓✘'
    endif
    if !exists("g:auto_gcov_marker_branch_uncovered")
        let g:auto_gcov_marker_branch_uncovered = '✘✘'
    endif
    if !exists("g:auto_gcov_marker_gcov_path")
        let g:auto_gcov_marker_gcov_path = '.'
    endif
    if !exists("g:auto_gcov_marker_gcno_path")
        let g:auto_gcov_marker_gcno_path = '.'
    endif

    if !hlexists('GcovLineCovered')
        highlight GCovLineCovered term=bold ctermfg=108 ctermbg=None guifg=#8ec07c guibg=None
    endif
    if !hlexists('GcovLineUncovered')
        highlight GCovLineUncovered term=bold ctermfg=167 ctermbg=None guifg=#fb4934 guibg=None
    endif
    if !hlexists('GcovBranchCovered')
        highlight GCovBranchCovered term=bold ctermfg=108 ctermbg=None guifg=#8ec07c guibg=None
    endif
    if !hlexists('GcovBranchPartlyCovered')
        highlight GCovBranchPartlyCovered ctermfg=214 ctermbg=None guifg=#fabd2f guibg=None
    endif
    if !hlexists('GcovBranchUncovered')
        highlight GCovBranchUncovered term=bold ctermfg=167 ctermbg=None guifg=#fb4934 guibg=None
    endif
endif

let g:sign_place = 1


function auto_gcov_marker#BuildCov(...)
    let filename = expand('%:t:r')
    let gcda_files = globpath(g:auto_gcov_marker_gcno_path, '/**/' . filename . '.gcda', 1, 1)

    if len(gcda_files) == '0'
      let filename = expand('%:t')
      let gcda_files = globpath(g:auto_gcov_marker_gcno_path, '/**/' . filename . '.gcda', 1, 1)
    endif

    if len(gcda_files) == '0'
      echo "gcda file not found"
      return
    endif

    let gcov_files = []
    for gcda_file in gcda_files
      let file_path = fnamemodify(gcda_file, ':p:h')

      " silent exe '!(cd ' . g:auto_gcov_marker_gcov_path . '; gcov -i -b -m ' . gcno . ') > /dev/null'
      " silent exe '!(cd ' . file_path . '; gcov -a -m -o ' . filename . '.gcno x) '
      silent exe '!(cd ' . file_path . '; gcov ' . file_path . '/' . filename . '.gcda --branch-counts --branch-probabilities --demangled-names --hash-filenames --object-directory ' . file_path . ' --stdout > ' . file_path . '/' . filename . '.gcov ) '
      redraw!

      let gcov = file_path . '/' . filename . '.gcov'
      if(!filereadable(gcov))
        let gcov = g:auto_gcov_marker_gcov_path . '/' . expand('%:t') . '.gcno.gcov'
      endif

      if(filereadable(gcov))
        call add(gcov_files, gcov)
      endif

    endfor

    if(len(gcov_files) > 0)
        call auto_gcov_marker#SetCov(gcov_files)
    endif

endfunction

function auto_gcov_marker#ClearCov(...)
    const linecount =  line('$')

    let lnum = 1
    while lnum <= line("$")
      exe ":sign unplace ". g:sign_place . " file=" . expand("%:p")
      let lnum = lnum + 1
    endwhile
endfunction

function auto_gcov_marker#SetCov(...)
    if(a:0 == 1)
      let gcov_files = a:1
    else
      return
    endif

    " Clear previous markers.
    call auto_gcov_marker#ClearCov()

    " Prepare signs
    exe ":sign define gcov_line_covered texthl=GcovLineCovered text=" . g:auto_gcov_marker_line_covered
    exe ":sign define gcov_line_uncovered texthl=GcovLineUncovered text=" . g:auto_gcov_marker_line_uncovered
    exe ":sign define gcov_branch_covered texthl=GcovBranchCovered text=" . g:auto_gcov_marker_branch_covered
    exe ":sign define gcov_branch_partly_covered texthl=GcovBranchPartlyCovered text=" . g:auto_gcov_marker_branch_partly_covered
    exe ":sign define gcov_branch_uncovered texthl=GcovBranchUncovered text=" . g:auto_gcov_marker_branch_uncovered

    " Read files and fillin marks dictionary
    let marks = {}
    for gcov_file in gcov_files
      try
          let current_file = readfile(gcov_file)
      catch
        echo "Failed to read gcov file [". gcov_file . "]"
        return
      endtry

      for line in current_file
        if line =~ 'function' || line =~ 'call' || line =~ 'branch'
          continue
        endif 

        let execcount = trim(split(line, ':')[0])
        let linenum = trim(split(line, '[:,]')[1])

        if linenum == '0'
          continue
        endif


        if execcount == '%%%%%' || stridx(linenum, '-block') > 0
          let block = trim(split(trim(split(line, '[:,]')[1]))[1])
          if block > '0'
            " do block processing
          endif
        elseif execcount == '#####' 
          if !has_key(marks, linenum) || marks[linenum] != 'linecovered'
            let marks[linenum] = 'lineuncovered'
          endif
        elseif execcount == '0' 
          if !has_key(marks, linenum) || marks[linenum] != 'linecovered'
            let marks[linenum] = 'lineuncovered'
          endif
        elseif execcount == 'branch'
          let branchcoverage = split(line, '[:,]')[2]
          if branchcoverage == 'notexec'
            if !has_key(marks, linenum) || marks[linenum] == 'lineuncovered' || marks[linenum] == 'branchuncovered'
              let marks[linenum] = 'branchuncovered'
            endif
            if marks[linenum] == 'linecovered' || marks[linenum] == 'branchpartlycovered' || marks[linenum] == 'branchcovered'
              let marks[linenum] = 'branchpartlycovered'
            endif
          elseif branchcoverage == 'taken'
            if !has_key(marks, linenum) || marks[linenum] == 'linecovered' || marks[linenum] == 'branchcovered'
              let marks[linenum] = 'branchcovered'
            endif
            if marks[linenum] == 'lineuncovered' || marks[linenum] == 'branchpartlycovered' || marks[linenum] == 'branchuncovered'
              let marks[linenum] = 'branchpartlycovered'
            endif
          elseif branchcoverage == 'nottaken'
              if !has_key(marks, linenum) || marks[linenum] == 'lineuncovered' || marks[linenum] == 'branchuncovered'
                let marks[linenum] = 'branchuncovered'
              endif
              if marks[linenum] == 'linecovered' || marks[linenum] == 'branchpartlycovered' || marks[linenum] == 'branchcovered'
                let marks[linenum] = 'branchpartlycovered'
              endif
          endif
        elseif execcount == '-'
          let line_code = split(line, '[:,]')
          if len(line_code) > 2 && trim(line_code[2]) == '}'
            let marks[linenum] = 'linecovered'
          endif
        elseif execcount > '0' 
            let marks[linenum] = 'linecovered'
        else
          echom "Encountered else case, not sure what to do"
        endif

      endfor
    endfor 

    set encoding=utf-8 nobomb
    let file_path = expand("%:p")

    " Iterate over marks dictionary and place signs
    for [line, marktype] in items(marks)
        if marktype == 'linecovered'
            exe ":sign place " . g:sign_place . " line=" . line . " name=gcov_line_covered file=" . file_path
        elseif marktype == 'lineuncovered'
            exe ":sign place " . g:sign_place . " line=" . line . " name=gcov_line_uncovered file=" . file_path
        elseif marktype == 'branchcovered'
            exe ":sign place " . g:sign_place . " line=" . line . " name=gcov_branch_covered file=" . file_path
        elseif marktype == 'branchpartlycovered'
            exe ":sign place " . g:sign_place . " line=" . line . " name=gcov_branch_partly_covered file=" . file_path
        elseif marktype == 'branchuncovered'
            exe ":sign place " . g:sign_place . " line=" . line . " name=gcov_branch_uncovered file=" . file_path
        endif
    endfor

    " Set the coverage file for the current buffer
    " let b:coveragefile = fnamemodify(filename, ':p')
endfunction

let g:autoloaded_auto_gcov_marker = 1
