let g:is_win = has('win32') || has('win64')
let g:is_linux = has('unix') && !has('macunix')
let g:is_mac = has('macunix')

let g:config_file_list = ['options.vim',
	\ 'mappings.vim',
	\ 'plugins.vim',
	\ 'custom.vim',
	\ 'plugins_conf.vim',
	\ ]

let g:nvim_config_root = expand('<sfile>:p:h')

for s:filename in g:config_file_list
	execute printf('source %s/%s', g:nvim_config_root, s:filename)
endfor

