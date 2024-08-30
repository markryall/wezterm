function editable(filename)
	-- "foo.bar" -> ".bar"
	local extension = filename:match("^.+(%..+)$")
	if extension then
		-- ".bar" -> "bar"
		extension = extension:sub(2)
		-- wezterm.log_info(string.format("extension is [%s]", extension))
		local binary_extensions = {
			jpg = true,
			jpeg = true,
			-- and so on
		}
		if binary_extensions[extension] then
			-- can't edit binary files
			return false
		end
	end

	-- if there is no, or an unknown, extension, then assume
	-- that our trusty editor will do something reasonable

	return true
end

function extract_filename(uri)
	local start, match_end = uri:find("$EDITOR:")
	if start == 1 then
		-- skip past the colon
		return uri:sub(match_end + 1)
	end
	-- `file://hostname/path/to/file`
	start, match_end = uri:find("file:")
	if start == 1 then
		-- skip "file://", -> `hostname/path/to/file`
		local host_and_path = uri:sub(match_end + 3)
		local start, match_end = host_and_path:find("/")
		if start then
			-- -> `/path/to/file`
			return host_and_path:sub(match_end)
		end
	end

	return nil
end

local wezterm = require("wezterm")
local config = wezterm.config_builder()

wezterm.on("open-uri", function(window, pane, uri)
	local name = extract_filename(uri)
	if name and editable(name) then
		-- Note: if you change your VISUAL or EDITOR environment,
		-- you will need to restart wezterm for this to take effect,
		-- as there isn't a way for wezterm to "see into" your shell
		-- environment and capture it.
		-- local args = { "/opt/homebrew/bin/nvim", "--server", "tmp/nvim.pipe", "--remote-send", "<Esc>:e " .. name .. "<CR>" }
    local args = { "/opt/homebrew/bin/emacsclient", "-n", name },

		local colon_first = name:find(":")
		if colon_first then
			local number = name:sub(colon_first + 1)
			name = name:sub(1, colon_first - 1)

			local colon_second = number:find(":")
			if colon_second then
				number = number:sub(1, colon_second)
			end

      -- args = { "/opt/homebrew/bin/nvim", "--server", "tmp/nvim.pipe", "--remote-send", "<Esc>:e " .. name .. "<CR>" .. number .. "gg" }
      args = { "/opt/homebrew/bin/emacsclient", "-n", "+" .. number, name },
		end

		-- To open a new window:
		local action = wezterm.action({
        SpawnCommandInNewWindow = {
          args = args,
			},
		})

		-- To open in a pane instead
		-- local action = wezterm.action({ SplitHorizontal = {
		-- 	args = { editor, name },
		-- } })

		-- and spawn it!
		window:perform_action(action, pane)

		-- prevent the default action from opening in a browser
		return false
	end
end)

-- For example, changing the color scheme:
config.color_scheme = "AdventureTime"

config.font = wezterm.font("Spot Mono")
config.font_size = 18.0
config.hyperlink_rules = {
	{
		regex = "\\b\\w+://(?:[\\w.-]+)\\.[a-z]{2,15}\\S*\\b",
		format = "$0",
	},
	{
		regex = "\\S*",
		format = "$EDITOR:$0",
	},
}

return config
