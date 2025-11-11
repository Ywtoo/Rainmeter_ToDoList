-- ========================================
-- DataManager.lua
-- Gerencia operações CRUD de tasks (arquivo txt)
-- ========================================

DataManager = {}

-- Constantes
DataManager.MARK = 'x'
DataManager.DIVIDER = '|'
DataManager.COL_NAME = 1
DataManager.COL_CHECKBOX = 2
DataManager.COL_IMPORTANT = 3
DataManager.COL_DAILY = 4
DataManager.COL_DATE = 5

-- Inicializa caminhos dos arquivos
function DataManager.Initialize(taskFile, trashFile, trashLimit)
	DataManager.taskFile = taskFile
	DataManager.trashFile = trashFile
	DataManager.trashLimit = trashLimit or 10
	DataManager.CheckDailyTasks()
end

-- Verifica e desmarca tasks diárias do dia anterior
function DataManager.CheckDailyTasks()
	local tasks = DataManager.GetTasks()
	local today = os.date("%Y-%m-%d")
	local changed = false
	
	for i = 1, #tasks do
		if tasks[i][DataManager.COL_DAILY] == DataManager.MARK then
			local taskDate = tasks[i][DataManager.COL_DATE] or ""
			if taskDate ~= today and tasks[i][DataManager.COL_CHECKBOX] == DataManager.MARK then
				-- Desmarca a tarefa se foi marcada em outro dia
				tasks[i][DataManager.COL_CHECKBOX] = ''
				changed = true
			end
			-- Atualiza a data
			tasks[i][DataManager.COL_DATE] = today
		end
	end
	
	if changed then
		DataManager.SaveTasks(tasks)
	end
end

-- Divide string por delimitador
function DataManager.Split(str, sep)
	sep = sep or '%|'
	local t = {}
	for field, s in string.gmatch(str, "([^"..sep.."]*)("..sep.."?)") do
		table.insert(t, field)
		if s == "" then return t end
	end
	return t
end

-- Lê todas as tasks do arquivo
function DataManager.GetTasks()
	local tasks = {}
	local file = io.open(DataManager.taskFile, "r")
	if not file then return tasks end
	
	for line in file:lines() do
		tasks[#tasks + 1] = DataManager.Split(line)
	end
	file:close()
	return tasks
end

-- Lê tasks deletadas (trash)
function DataManager.GetTrash()
	local trash = {}
	local file = io.open(DataManager.trashFile, "r")
	if not file then return trash end
	
	for line in file:lines() do
		trash[#trash + 1] = line
	end
	file:close()
	return trash
end

-- Salva tasks no arquivo
function DataManager.SaveTasks(tasks)
	local file = io.open(DataManager.taskFile, "w+")
	if not file then return false end
	
	for i = 1, #tasks do
		local line = table.concat(tasks[i], DataManager.DIVIDER)
		file:write(line, "\n")
	end
	file:close()
	return true
end

-- Adiciona nova task
function DataManager.AddTask(taskName)
	local file = io.open(DataManager.taskFile, "r")
	local content = file:read("*a")
	file:close()
	
	file = io.open(DataManager.taskFile, "w")
	file:write(content)
	file:write(taskName .. "||||", "\n")
	file:close()
	return true
end

-- Toggle estado de uma coluna (checkbox, recurring, important)
function DataManager.Toggle(lineNumber, columnIndex)
	local tasks = DataManager.GetTasks()
	
	if tasks[lineNumber] then
		if tasks[lineNumber][columnIndex] == DataManager.MARK then
			tasks[lineNumber][columnIndex] = ''
		else
			tasks[lineNumber][columnIndex] = DataManager.MARK
		end
		
		-- Se togglou o checkbox, reordena as tasks
		if columnIndex == DataManager.COL_CHECKBOX then
			tasks = DataManager.ReorderTasks(tasks)
		end
	end
	
	return DataManager.SaveTasks(tasks)
end

-- Reordena tasks: incompletas primeiro, completas no final
function DataManager.ReorderTasks(tasks)
	local incomplete = {}
	local complete = {}
	
	for i = 1, #tasks do
		if tasks[i][DataManager.COL_CHECKBOX] == DataManager.MARK then
			table.insert(complete, tasks[i])
		else
			table.insert(incomplete, tasks[i])
		end
	end
	
	-- Junta: incompletas primeiro, depois completas
	local reordered = {}
	for i = 1, #incomplete do
		table.insert(reordered, incomplete[i])
	end
	for i = 1, #complete do
		table.insert(reordered, complete[i])
	end
	
	return reordered
end

-- Muda ordem de duas tasks
function DataManager.ChangeOrder(currentLine, nextLine)
	if nextLine < 1 then return false end
	
	local tasks = DataManager.GetTasks()
	local temp = tasks[currentLine]
	tasks[currentLine] = tasks[nextLine]
	tasks[nextLine] = temp
	
	return DataManager.SaveTasks(tasks)
end

-- Remove task (move para trash)
function DataManager.RemoveTask(lineNumber)
	local tasks = DataManager.GetTasks()
	local taskName = tasks[lineNumber] and tasks[lineNumber][DataManager.COL_NAME] or ""
	
	-- Remove da lista
	table.remove(tasks, lineNumber)
	DataManager.SaveTasks(tasks)
	
	-- Adiciona ao trash
	DataManager.AddToTrash(taskName)
	
	-- Limita trash
	local trash = DataManager.GetTrash()
	if #trash > DataManager.trashLimit then
		DataManager.RemoveFromTrash(1)
	end
	
	return true
end

-- Adiciona item ao trash
function DataManager.AddToTrash(taskName)
	local file = io.open(DataManager.trashFile, "r")
	local content = file and file:read("*a") or ""
	if file then file:close() end
	
	file = io.open(DataManager.trashFile, "w")
	file:write(content)
	file:write(taskName, "\n")
	file:close()
	return true
end

-- Remove item do trash
function DataManager.RemoveFromTrash(lineNumber)
	local trash = DataManager.GetTrash()
	table.remove(trash, lineNumber)
	
	local file = io.open(DataManager.trashFile, "w+")
	for i = 1, #trash do
		file:write(trash[i], "\n")
	end
	file:close()
	return true
end

-- Restaura última task deletada
function DataManager.UndoDelete()
	local trash = DataManager.GetTrash()
	if #trash == 0 then return false end
	
	local lastTask = trash[#trash]
	DataManager.RemoveFromTrash(#trash)
	DataManager.AddTask(lastTask)
	return true
end

return DataManager
