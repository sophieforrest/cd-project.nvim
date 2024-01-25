local cd_hooks = require("cd-project.hooks")
local project = require("cd-project.project")
local utils = require("cd-project.utils")

---@return string|nil
local function find_project_dir()
	local found = vim.fs.find(
		CdProjectConfig.project_dir_pattern,
		{ upward = true, stop = vim.loop.os_homedir(), path = vim.fs.dirname(vim.fn.expand("%:p")) }
	)

	if #found == 0 then
		return vim.loop.os_homedir()
	end

	local project_dir = vim.fs.dirname(found[1])

	if not project_dir or project_dir == "." or project_dir == "" or project_dir == " " then
		project_dir = string.match(vim.fn.execute("pwd"), "^%s*(.-)%s*$")
	end

	if not project_dir or project_dir == "." or project_dir == "" or project_dir == " " then
		return nil
	end

	return project_dir
end

---@return string[]
local function get_project_paths()
	local projects = project.get_projects(CdProjectConfig.projects_config_filepath)
	local paths = {}
	for _, value in ipairs(projects) do
		table.insert(paths, value.path)
	end
	return paths
end

---@param dir string
local function cd_project(dir)
	vim.g.cd_project_last_project = vim.g.cd_project_current_project
	vim.g.cd_project_current_project = dir
	vim.fn.execute("cd " .. dir)

	local hooks = cd_hooks.get_hooks(CdProjectConfig.hooks, dir, "AFTER_CD")
	for _, hook in ipairs(hooks) do
		hook(dir)
	end
end

local function add_current_project()
	local current_config = CdProjectConfig
	local project_dir = find_project_dir()

	if not project_dir then
		return utils.log_err("Can't find project path of current file")
	end

	local projects = project.get_projects(CdProjectConfig.projects_config_filepath)

	if vim.tbl_contains(get_project_paths(), project_dir) then
		return vim.notify("Project already exists: " .. project_dir)
	end

	local new_project = {
		path = project_dir,
		name = "name place holder", -- TODO: allow user to edit the name of the project
	}
	table.insert(projects, new_project)
	project.write_projects(projects, current_config.projects_config_filepath)
	vim.notify("Project added: \n" .. project_dir)
end

local function back()
	local last_project = vim.g.cd_project_last_project
	if not last_project then
		vim.notify("Can't find last project. Haven't switch project yet.")
	end
	cd_project(last_project)
end

return {
	cd_project = cd_project,
	add_current_project = add_current_project,
	get_project_paths = get_project_paths,
	back = back,
	find_project_dir = find_project_dir,
}
