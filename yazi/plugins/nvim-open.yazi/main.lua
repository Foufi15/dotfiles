--- Ouvre l'élément survolé dans nvim.
--- window : nouvelle fenêtre tmux (fichier ou dossier)
--- popup  : popup tmux (fichier ou dossier)
--- Hors tmux : nvim directement dans le terminal courant.

local hovered = ya.sync(function()
	local h = cx.active.current.hovered
	if not h then
		return nil
	end
	return { path = tostring(h.url), cwd = tostring(cx.active.current.cwd) }
end)

return {
	entry = function(_, job)
		local mode = job.args[1] or "window"
		local item = hovered()
		if not item then
			return
		end

		if not os.getenv("TMUX") then
			ya.emit("shell", { "nvim " .. ya.quote(item.path), block = true })
			return
		end

		local args
		if mode == "popup" then
			args = { "display-popup", "-E", "-w", "90%", "-h", "90%", "-d", item.cwd, "--", "nvim", item.path }
		else
			args = { "new-window", "-c", item.cwd, "--", "nvim", item.path }
		end

		-- status() et non spawn() : l'enfant serait tué dès qu'il est libéré
		local status, err = Command("tmux"):arg(args):stderr(Command.PIPED):status()
		if not status or not status.success then
			ya.notify { title = "nvim-open", content = "tmux a échoué : " .. tostring(err or status.code), level = "error", timeout = 5 }
		end
	end,
}
