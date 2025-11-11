local outputFile = nil

function Initialize()
	-- Load dependent scripts after SKIN is available
	dofile(SKIN:MakePathAbsolute('@Resources\\DataManager.lua'))
	dofile(SKIN:MakePathAbsolute('@Resources\\Renderer.lua'))
	
	outputFile = SELF:GetOption('DynamicMeterFile')
	local taskFile = SELF:GetOption('TaskListFile')
	local trashFile = SELF:GetOption('TrashTaskListFile')
	local trashLimit = SELF:GetNumberOption('TRASH_LIMIT', 10)
	
	DataManager.Initialize(taskFile, trashFile, trashLimit)
	
	local config = {
		FONT_FACE = SELF:GetOption('FONT_FACE', 'Inter'),
		FONT_SIZE = SELF:GetNumberOption('FONT_SIZE', 12),
		BUTTON_SIZE = SELF:GetNumberOption('BUTTON_SIZE', 16),
		SKIN_WIDTH = tonumber(SKIN:GetVariable('SkinWidth')) or 300,
		WHITE_COLOR = SELF:GetOption('ACTIVE_TASK_COLOR', '255,255,255,255'),
		COMLETED_TASK_COLOR = SELF:GetOption('COMLETED_TASK_COLOR', '255,255,255,170'),
		BUTTON_COLOR = SELF:GetOption('BUTTON_COLOR', '255,255,255,255'),
		SHOW_RECURRING = SELF:GetNumberOption('SHOW_RECURRING', 1),
		SHOW_IMPORTANT = SELF:GetNumberOption('SHOW_IMPORTANT', 1)
	}
	
	Renderer.Initialize(config)
end

function Update()
	local fontSize = tonumber(SKIN:GetVariable('FONT_SIZE')) or 12
	local buttonSize = tonumber(SKIN:GetVariable('BUTTON_SIZE')) or 16
	local skinWidth = tonumber(SKIN:GetVariable('SkinWidth')) or 300
	
	Renderer.UpdateConfig(fontSize, buttonSize, skinWidth)
	
	local tasks = DataManager.GetTasks()
	local trash = DataManager.GetTrash()
	
	local output = {}
	
	local measures = Renderer.GenerateMeasures(tasks)
	for i = 1, #measures do
		table.insert(output, measures[i])
	end
	
	local meters = Renderer.GenerateTaskMeters(tasks, DataManager)
	for i = 1, #meters do
		table.insert(output, meters[i])
	end
	
	local vars = Renderer.GenerateVariables(tasks, DataManager)
	for i = 1, #vars do
		table.insert(output, vars[i])
	end
	
	local controls = Renderer.GenerateControlButtons(#trash > 0)
	for i = 1, #controls do
		table.insert(output, controls[i])
	end
	
	return WriteOutputFile(output)
end

function WriteOutputFile(lines)
	local file = io.open(outputFile, 'w')
	if not file then
		print('ERROR: Cannot write to ' .. outputFile)
		return false
	end
	
	local content = table.concat(lines, '\n')
	file:write(content)
	file:close()
	return true
end

function Toggle(lineNumber, columnIndex)
	return DataManager.Toggle(lineNumber, columnIndex)
end

function ChangeOrder(currentLine, nextLine)
	return DataManager.ChangeOrder(currentLine, nextLine)
end

function RemoveTask(lineNumber)
	return DataManager.RemoveTask(lineNumber)
end

function UndoDelete()
	return DataManager.UndoDelete()
end

function AddTask(taskName)
	return DataManager.AddTask(taskName)
end
