// Verminal - Terminal Emulator in V
module main

import iui as ui
import os
import gx

fn cmd_theme(mut win ui.Window, mut tbox ui.TextArea, args []string) {
	if args.len == 1 {
		tbox.lines << 'Usage: theme <dark,light,red,green>'
		return
	}

	if args[1] == 'light' {
		win.set_theme(ui.theme_default())
	}

	if args[1] == 'gray' {
		win.set_theme(ui.theme_dark())
	}

	if args[1] == 'dark' {
		win.set_theme(theme_dark())
	}

	if args[1] == 'red' {
		win.set_theme(ui.theme_black_red())
	}

	if args[1] == 'green' {
		win.set_theme(theme_green())
	}
}

pub fn theme_green() ui.Theme {
	return ui.Theme{
		name: 'Terminal Green'
		text_color: gx.rgb(24, 245, 24)
		background: gx.black
		button_bg_normal: gx.black
		button_bg_hover: gx.black
		button_bg_click: gx.black
		button_border_normal: gx.rgb(130, 130, 130)
		button_border_hover: gx.black
		button_border_click: gx.black
		menubar_background: gx.rgb(30, 30, 30)
		menubar_border: gx.rgb(30, 30, 30)
		dropdown_background: gx.black
		dropdown_border: gx.black
		textbox_background: gx.black
		textbox_border: gx.black
		checkbox_selected: gx.gray
		checkbox_bg: gx.black
		progressbar_fill: gx.gray
		scroll_track_color: gx.black
		scroll_bar_color: gx.gray
	}
}

fn cmd_cd(mut win ui.Window, mut tbox ui.TextArea, args []string) {
	mut path := win.extra_map['path']
	if args.len == 1 {
		tbox.text = tbox.text + path
		return
	}

	if args[1] == '..' {
		path = path.substr(0, path.replace('\\', '/').last_index('/') or { 0 }) // '
	} else {
		if os.is_abs_path(args[1]) {
			path = os.real_path(args[1])
		} else {
			path = os.real_path(path + '/' + args[1])
		}
	}
	if os.exists(path) {
		win.extra_map['path'] = path
	} else {
		tbox.text = tbox.text + 'Cannot find the path specified: ' + path
	}
}

fn tree_cmd(dir string, mut tbox ui.TextArea, tabs int) {
	path := os.real_path(dir)
	files := os.ls(path) or { [] }
	for file in files {
		joined := os.join_path(path, file)
		if os.is_dir(joined) {
			tbox.lines << '│\t'.repeat(tabs) + '├───' + file
			tree_cmd(joined, mut tbox, tabs + 1)
		}
	}
	if tabs == 0 {
		add_new_input_line(mut tbox)
	}
}

fn cmd_dir(mut tbox ui.TextArea, path string, args []string) {
	mut ls := os.ls(os.real_path(path)) or { [''] }
	mut txt := ' Directory of ' + path + '\n\n'
	for file in ls {
		txt = txt + '\t' + file + '\n'
	}
	// os.file_last_mod_unix(os.real_path(path + '/' + file)).str()
	tbox.text = tbox.text + txt
}

fn cmd_v(mut tbox ui.TextArea, args []string) {
	mut pro := os.execute('cmd /min /c ' + args.join(' '))
	tbox.text = tbox.text + pro.output.trim_space()
}

fn cmd_exec(mut win ui.Window, mut tbox ui.TextArea, args []string) {
	// Make sure we are in the correct directory
	os.chdir(win.extra_map['path']) or { tbox.lines << err.str() }

	if os.user_os() == 'windows' {
		cmd_exec_win(mut win, mut tbox, args)
	} else {
		cmd_exec_unix(mut win, mut tbox, args)
	}
}

// Linux
fn cmd_exec_unix(mut win ui.Window, mut tbox ui.TextArea, args []string) {
	mut cmd := os.Command{
		path: args.join(' ')
	}

	cmd.start() or { tbox.lines << err.str() }
	for !cmd.eof {
		out := cmd.read_line()
		if out.len > 0 {
			for line in out.split_into_lines() {
				tbox.lines << line.trim_space()
			}
		}
	}
	add_new_input_line(mut tbox)

	cmd.close() or { tbox.lines << err.str() }
}

// Windows;
// os.Command not fully implemented on Windows, so cmd.exe is used
//
fn cmd_exec_win(mut win ui.Window, mut tbox ui.TextArea, args []string) {
	mut pro := os.new_process('cmd')

	mut argsa := ['/min', '/c', args.join(' ')]
	pro.set_args(argsa)

	pro.set_redirect_stdio()
	pro.run()

	for pro.is_alive() {
		out := pro.stdout_read()
		if out.len > 0 {
			for line in out.split_into_lines() {
				tbox.lines << line.trim_space()
			}
		}
		err := pro.stderr_read()
		if err.len > 0 {
			for line in err.split('\n') {
				tbox.lines << line.trim_space()
			}
		}
	}
	add_new_input_line(mut tbox)

	pro.close()
}
