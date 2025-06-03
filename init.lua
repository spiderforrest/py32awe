
-- py3status bar jank

local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")

--[[{{{ notes
    the actual widget should be several? or one widget.textbox
          several might be easier for click events. also spacing
      the text those want is in pango markup format
          which basically just xml & html objects
          <span foreground="green"></span> for instance does what u think it do
              https://docs.gtk.org/Pango/struct.Color.html
      parsing should be done by calling py3status with spawn.with_line_callback
          then errytime py3status updates it'll run the cb fn
      parsing itself should be done with string.gmatch
          the format is basically comma seperated array that holds json for each element
          should be able to get it into a lua metatable/array that contains everything for each element
              then i should be able to translate to pango
      click events can be handled with the lovely py3-cmd-just add a handler to pass clicks on & attach to each element

      OF NOTE!
          i should generate the handlers and such by keeping track of the elements
          just use the cb to update the text & check if more need to be initialized
          (and color)
          to avoid recrating handlers every half second
          just because this is a hobby project and i paid for the cpu cycles i'm gonna not use them

      the lua patterns:
          it looks like "{.-}" will match each object
          i think i just need to pull each of them out!
          and then parse them into a table
          is this gonna be uhh
              for obj_str in string.gfind(input, '{.-}') do
                  parse and store obj_str
                      for pair_str in string.gfind(obj_str, '".-": ".-"')
                          the pattern should be.... '".-":' to get the key and ': ".-"' for value
}}}]]

local M = {}

-- create the table to fill with widgets
local bar_widgets = {}

local function add_mouse_py3_passthrough (button, target) --{{{
      return awful.button({ }, button, function ()
        awful.spawn.with_shell( "py3-cmd click --button " .. tostring(button) .. " " .. tostring(target))
      end)
end --}}}

-- create the widgets the modules repersent
local function generate_widgets(modules, box) --{{{
  -- clear out the previous set of textboxes
  for _, widget in ipairs(bar_widgets) do
    box:remove_widgets(widget)
  end

  -- populate a table with generated textbox widgets
  for i, module in ipairs(modules) do
    -- just create a buncha empty textboxes, we'll just mutate them later
    bar_widgets[i] = wibox.widget.textbox()
    -- attach buttons
    bar_widgets[i]:buttons(gears.table.join(
      add_mouse_py3_passthrough(1, module.name),
      add_mouse_py3_passthrough(2, module.name),
      add_mouse_py3_passthrough(3, module.name),
      add_mouse_py3_passthrough(4, module.name),
      add_mouse_py3_passthrough(5, module.name)
      ))
  end
  -- add the widgets to the box
  for _, widget in ipairs(bar_widgets) do
    box:add(widget)
  end
end --}}}

local function utf8_decode(str)
  return str:gsub("\\u(%x%x%x%x)", function(hex)
    return utf8.char(tonumber(hex, 16))
     end)
end

local function parse_json(json_str, box) --{{{
  json_str = utf8_decode(json_str)
  -- create the array that will be filled with the data from the json output and the iterator
  local modules = {}
  local module_itr = 1 -- lua arrays actually start at anything you want btw

  -- track the number of modules, so if it grows, we can regenerate the widgets
  local i3_module_counter = #bar_widgets or 0
  -- iterate through all the {} pairs-each is a i3/py3 module
  for module_str in string.gmatch(json_str, "{.-}") do
    -- create the module's table and grab the name to use as key
    local module_tbl = {}
    -- pull out each key/value pair and hyuck them in the module's table
    for key, val in string.gmatch(module_str, '"(.-)": "(.-)"') do
       module_tbl[key] = val
    end
    -- append the module's table to the decoded array
    modules[module_itr] = module_tbl
    module_itr = module_itr + 1
  end

  -- check if there's more modules this run than the last and regenerate(or create them initally) if so
  if i3_module_counter < module_itr then
    generate_widgets(modules, box)
  end

  -- cool! now we have converted a json string to a lua table without copy pasting from stack overflow. proud of me.
  return modules
end --}}}

-- set the text inside each widget to match the i3 output
local function update_widgets(widgets, modules) --{{{
    -- set text for each widget
  for i, widget in ipairs(widgets) do
    local pango_string
    if modules[i].color then -- they don't always have the color key
      pango_string = '<span color="' .. modules[i].color .. '">' .. gears.string.xml_escape(modules[i].full_text) .. "</span>"
    else
      pango_string = '<span color="' .. M.default_color .. '">' .. gears.string.xml_escape(modules[i].full_text) .. '</span>'
    end

    -- call a user function to modify the widget, if they want
    M.module_override_handler(modules[i], widget)

    if i ~= 1 then -- don't put a seperator on the end
      pango_string = M.spacer .. pango_string
    end

    widget:set_markup_silently(pango_string)
  end
end --}}}

-- call the statusline command and set up the callback function
M.setup = function (setup_tbl)
  -- default args
  M.bar_command_limit = false
  M.bar_command = "py3status"
  M.spacer = ' | '
  M.default_color = 'white'
  M.module_override_handler = function(_,_) end
  -- load setup args
  for key,v in pairs(setup_tbl) do
     M[key] = v
  end

    awful.spawn.with_line_callback(M.bar_command, { stdout = function (stdout) --{{{
    -- call the parser
    local modules = parse_json(stdout, M.container)
    update_widgets(bar_widgets, modules)
  end })

end


--}}}


return M

  -- vim: foldmethod=marker
