# py3status to awesomewm
A module for converting [i3status](https://i3wm.org/docs/i3status.html)/[py3status](https://github.com/ultrabug/py3status) json output to awesomewm widgets, with colorization & clickibility.

This is a module that takes an [awful.widget.layoutbox](https://awesomewm.org/doc/api/classes/awful.widget.layoutbox.html) and populates it with [awful.widget.textbox](https://awesomewm.org/doc/api/classes/wibox.widget.textbox.html)s for each module, and updates them when `py3status` spits out an update. It also attaches button handlers that pass commands to `py3-cmd`.

### Usage
Create a container to keep your statusline in:
`local statusline = wibox.layout.fixed.horizontal()`

Require the module, and call `setup()`, passing it the container:
`require("py32awe").setup(statusline)`

And add the container to your existing bar:
```lua
awful.screen.connect_for_each_screen(function(s)
-- ...
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        -- ...
        { -- Right widgets
            statusline,
            layout = wibox.layout.fixed.horizontal,
        },
    }
    -- ...
```

`setup()` also optionally takes a table, instead of the container.

The table has several keys:

- `container` (required): the mentioned container.

- `bar_command` (optional, string, default: 'py3status'): the command to run when starting the bar.

- `bar_stop_command` (optional, string, default: 'pkill py3status'): the command to run to stop the bar when awesome exits.

- `spacer_string` (optional, string, default: ' | '): a string placed between modules

- `default_color` (optional, string, default: 'white'): the color to make modules that don't specify their own-it's [pango markup](https://docs.gtk.org/Pango/), but tl;dr: css colors

- `module_override_handler` (optional, function, arguments (`module`, `widget`), default nil): a function that's called for each module during each update. `module` is a table with the data from py3status, `widget` is the awesome widget. Example that fixes the width of a clock:
  ```lua
  module_override_handler = function (module, widget)
    if module.name == 'clock' then
      widget.forced_width = 105
    end
  end
  ```


### Notes:
I wrote this for py3status, but it should work for i3status. Not tested, and you'll have to set the output format to json in the config file.

If py3status uses 100% of a cpu, set `bar_command` to `script -qfec "py3status"`.

~~On `bar_command_limit`: at the time of writing, py3status has a bug ([my report](https://github.com/ultrabug/py3status/issues/2186)) where it uses 100% of a cpu core when called by a program that isn't `i3` or a graphical terminal. As a bodge, py32awe will call [cpulimit](https://github.com/ultrabug/py3status/issues/2186) and use that to limit it, if `bar_command_limit` is truthy. I recommend setting `bar_command_limit` to about 3 to fix this, py3status runs fine limited. `bar_command_limit` to about 3 to fix this, py3status runs fine limited.~~
~The issue is being addressed in [pr 2104](https://github.com/ultrabug/py3status/pull/2104) and if that's merged it's probably fixed.~
The issue is merged and it's not fixed :( the `script` workaround causes no issues, though.

I copied this from my personal dotfiles, for history see the last commit before that [here](https://github.com/spiderforrest/fotdiles/commit/6f0334e8fe62e14fae1d3e2673dbe5089ba067fd).

