function! CordCompleteList(ArgLead, CmdLine, CmdPos)
    let l:is_new_arg = (a:ArgLead ==# '' && a:CmdLine[a:CmdPos - 1] =~# '\s')

    " All args up to cursor position
    let l:args = split(a:CmdLine[:a:CmdPos - 1], '\s\+')

    " === First-level command completion ===
    if len(l:args) <= 1 || (len(l:args) == 2 && a:ArgLead !=# '')
        let l:commands = luaeval('require("cord.api.command").get_commands()')
        return filter(l:commands, 'v:val =~# "^" . a:ArgLead')
    endif

    let l:main_cmd = l:args[1]

    " === Feature list for enable/disable/toggle ===
    if l:main_cmd =~# '\v^(enable|disable|toggle)$'
        let l:features = luaeval('require("cord.api.command").get_features()')
        return filter(l:features, 'v:val =~# "^" . a:ArgLead')
    endif

    " === Subcommand completion ===
    if len(l:args) == 2 || (len(l:args) == 3 && !l:is_new_arg)
        let l:subcommands = luaeval('require("cord.api.command").get_subcommands(_A)', l:main_cmd)
        return filter(l:subcommands, 'v:val =~# "^" . a:ArgLead')
    endif

    return []
endfunction

" Command runner
command! -nargs=+ -complete=customlist,CordCompleteList Cord lua require("cord.api.command").handle(<q-args>)

lua << EOF
-- Skip initialization if defer flag is set
if vim.g.cord_defer_startup == true then
    return
end

-- Schedule initialization on next loop tick
vim.schedule(function()
    local config = require("cord.api.config").verify()
    if not config then return end

    if config.enabled then
        vim.cmd([[
            augroup Cord
                autocmd!
                autocmd VimLeavePre * lua require("cord.server"):cleanup()
            augroup END
        ]])

        require("cord.server"):initialize()
    end
end)
EOF
