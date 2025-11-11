-- ========================================
-- Renderer.lua
-- Gera código INI para exibir tasks
-- ========================================

Renderer = {}

-- Configurações visuais
Renderer.config = {}

function Renderer.Initialize(config)
	Renderer.config = {
		fontFace = config.FONT_FACE or 'Inter',
		fontSize = config.FONT_SIZE or 12,
		buttonSize = config.BUTTON_SIZE or 16,
		skinWidth = config.SKIN_WIDTH or 300,
		whiteColor = config.WHITE_COLOR or '255,255,255,255',
		grayColor = config.COMLETED_TASK_COLOR or '255,255,255,170',
		buttonColor = config.BUTTON_COLOR or '255,255,255,255',
		showRecurring = config.SHOW_RECURRING or 1,
		showImportant = config.SHOW_IMPORTANT or 1
	}
end

-- Atualiza configurações dinâmicas
function Renderer.UpdateConfig(fontSize, buttonSize, skinWidth)
	Renderer.config.fontSize = fontSize
	Renderer.config.buttonSize = buttonSize
	
	-- Calcula quantos botões cabem
	local buttonCount = 3 -- checkbox, up/down, delete
	if Renderer.config.showRecurring == 1 then buttonCount = buttonCount + 1 end
	if Renderer.config.showImportant == 1 then buttonCount = buttonCount + 1 end
	
	-- Largura disponível para texto
	Renderer.config.taskWidth = skinWidth - (buttonCount * (buttonSize + 8)) - 30
end

-- Gera measures para verificar estado das tasks
function Renderer.GenerateMeasures(tasks)
	local output = {}
	
	for i = 1, #tasks do
		-- Measure para checkbox
		table.insert(output, "[MeasureTaskIcon"..i.."]")
		table.insert(output, "Measure=String")
		table.insert(output, "String=#check"..i.."state#")
		table.insert(output, "IfMatch=0")
		table.insert(output, "IfMatchAction=[!SetVariable check"..i.." mui-check]")
		table.insert(output, "IfNotMatchAction=[!SetVariable check"..i.." mui-checked]")
		table.insert(output, "IfMatchMode=1")
		table.insert(output, "DynamicVariables=1")
		
		-- Measure para importante
		if Renderer.config.showImportant == 1 then
			table.insert(output, "[MeasureImportantIcon"..i.."]")
			table.insert(output, "Measure=String")
			table.insert(output, "String=#important"..i.."state#")
			table.insert(output, "IfMatch=0")
			table.insert(output, "IfMatchAction=[!SetVariable important"..i.." 150,150,150,255]")
			table.insert(output, "IfNotMatchAction=[!SetVariable important"..i.." 255,80,80,255]")
			table.insert(output, "IfMatchMode=1")
			table.insert(output, "DynamicVariables=1")
		end
		
		-- Measure para diário
		if Renderer.config.showRecurring == 1 then
			table.insert(output, "[MeasureDailyIcon"..i.."]")
			table.insert(output, "Measure=String")
			table.insert(output, "String=#daily"..i.."state#")
			table.insert(output, "IfMatch=0")
			table.insert(output, "IfMatchAction=[!SetVariable daily"..i.." 150,150,150,255]")
			table.insert(output, "IfNotMatchAction=[!SetVariable daily"..i.." 100,200,255,255]")
			table.insert(output, "IfMatchMode=1")
			table.insert(output, "DynamicVariables=1")
		end
	end
	
	return output
end

-- Gera meters visuais para cada task
function Renderer.GenerateTaskMeters(tasks, taskManager)
	local output = {}
	local cfg = Renderer.config
	
	for i = 1, #tasks do
		local task = tasks[i]
		local yPos = (i == 1) and "10" or "R"
		local isCompleted = (task[taskManager.COL_CHECKBOX] == taskManager.MARK)
		local taskColor = isCompleted and cfg.grayColor or cfg.whiteColor
		
		-- CHECKBOX
		table.insert(output, "[MeterTaskIcon"..i.."]")
		table.insert(output, "Meter=String")
		table.insert(output, "Group=DynamicTasks")
		table.insert(output, "MeasureName=MeasureTaskIcon"..i)
		table.insert(output, "Text=[#[#check"..i.."]]")
		table.insert(output, "FontFace=Material Icons")
		table.insert(output, "FontSize="..cfg.buttonSize)
		table.insert(output, "FontColor="..taskColor)
		table.insert(output, "SolidColor=0,0,0,1")
		table.insert(output, "Padding=2,2,2,2")
		table.insert(output, "AntiAlias=1")
		table.insert(output, "X=10")
		table.insert(output, "Y="..yPos)
		table.insert(output, "H=35")
		table.insert(output, "W="..(cfg.buttonSize + 4))
		table.insert(output, "LeftMouseUpAction=[!SetVariable check"..i.."state (1-#check"..i.."state#)][!CommandMeasure MeasureDynamicTasks \"Toggle("..i..",2)\"][!UpdateMeasure MeasureDynamicTasks][!UpdateMeter *][!Redraw]")
		table.insert(output, "DynamicVariables=1")
		
		-- TASK NAME
		table.insert(output, "[MeterTaskName"..i.."]")
		table.insert(output, "Meter=String")
		table.insert(output, "Group=DynamicTasks")
		table.insert(output, "Text="..task[taskManager.COL_NAME])
		table.insert(output, "FontFace="..cfg.fontFace)
		table.insert(output, "FontSize="..cfg.fontSize)
		table.insert(output, "FontColor="..taskColor)
		table.insert(output, "SolidColor=0,0,0,1")
		table.insert(output, "Padding=2,2,2,2")
		-- Adiciona strikethrough se estiver completa
		if isCompleted then
			table.insert(output, "StringStyle=Strikethrough")
		else
			table.insert(output, "StringStyle=Bold")
		end
		table.insert(output, "AntiAlias=1")
		table.insert(output, "ClipString=1")
		table.insert(output, "X=6R")
		table.insert(output, "Y=r")
		table.insert(output, "H=35")
		table.insert(output, "W="..cfg.taskWidth)
		
		-- IMPORTANT BUTTON (exclamação vermelha)
		if cfg.showImportant == 1 then
			table.insert(output, "[MeterImportant"..i.."]")
			table.insert(output, "Meter=String")
			table.insert(output, "Group=DynamicTasks")
			table.insert(output, "MeasureName=MeasureImportantIcon"..i)
			table.insert(output, "Text=[#mui-priority]")
			table.insert(output, "FontFace=Material Icons")
			table.insert(output, "FontSize="..cfg.buttonSize)
			table.insert(output, "FontColor=[#important"..i.."]")
			table.insert(output, "SolidColor=0,0,0,1")
			table.insert(output, "Padding=2,2,2,2")
			table.insert(output, "AntiAlias=1")
			table.insert(output, "X=6R")
			table.insert(output, "Y=r")
			table.insert(output, "H=35")
			table.insert(output, "W="..(cfg.buttonSize + 4))
			table.insert(output, "LeftMouseUpAction=[!SetVariable important"..i.."state (1-#important"..i.."state#)][!CommandMeasure MeasureDynamicTasks \"Toggle("..i..",3)\"][!UpdateMeasure MeasureDynamicTasks][!UpdateMeter *][!Redraw]")
			table.insert(output, "DynamicVariables=1")
		end
		
		-- DAILY BUTTON (refresh azul que desmarca no próximo dia)
		if cfg.showRecurring == 1 then
			table.insert(output, "[MeterDaily"..i.."]")
			table.insert(output, "Meter=String")
			table.insert(output, "Group=DynamicTasks")
			table.insert(output, "MeasureName=MeasureDailyIcon"..i)
			table.insert(output, "Text=[#mui-today]")
			table.insert(output, "FontFace=Material Icons")
			table.insert(output, "FontSize="..cfg.buttonSize)
			table.insert(output, "FontColor=[#daily"..i.."]")
			table.insert(output, "SolidColor=0,0,0,1")
			table.insert(output, "Padding=2,2,2,2")
			table.insert(output, "AntiAlias=1")
			table.insert(output, "X=6R")
			table.insert(output, "Y=r")
			table.insert(output, "H=35")
			table.insert(output, "W="..(cfg.buttonSize + 4))
			table.insert(output, "LeftMouseUpAction=[!SetVariable daily"..i.."state (1-#daily"..i.."state#)][!CommandMeasure MeasureDynamicTasks \"Toggle("..i..",4)\"][!UpdateMeasure MeasureDynamicTasks][!UpdateMeter *][!Redraw]")
			table.insert(output, "DynamicVariables=1")
		end
		
		-- UP BUTTON
		table.insert(output, "[MeterUp"..i.."]")
		table.insert(output, "Meter=String")
		table.insert(output, "Group=DynamicTasks")
		table.insert(output, "Text=[#mui-up]")
		table.insert(output, "FontFace=Material Icons")
		table.insert(output, "FontSize="..cfg.buttonSize)
		if i == 1 then
			table.insert(output, "FontColor=0,0,0,0")
		else
			table.insert(output, "FontColor="..cfg.buttonColor)
			table.insert(output, "SolidColor=0,0,0,1")
			table.insert(output, "Padding=2,2,2,2")
			table.insert(output, "AntiAlias=1")
			table.insert(output, "LeftMouseUpAction=[!CommandMeasure MeasureDynamicTasks \"ChangeOrder("..i..","..(i-1)..")\"][!UpdateMeasure MeasureDynamicTasks][!UpdateMeter *][!Redraw]")
		end
		table.insert(output, "X=6R")
		table.insert(output, "Y=r")
		table.insert(output, "H=35")
		table.insert(output, "W="..(cfg.buttonSize + 4))
		
		-- DOWN BUTTON
		table.insert(output, "[MeterDown"..i.."]")
		table.insert(output, "Meter=String")
		table.insert(output, "Group=DynamicTasks")
		table.insert(output, "Text=[#mui-down]")
		table.insert(output, "FontFace=Material Icons")
		table.insert(output, "FontSize="..cfg.buttonSize)
		if i == #tasks then
			table.insert(output, "FontColor=0,0,0,0")
		else
			table.insert(output, "FontColor="..cfg.buttonColor)
			table.insert(output, "SolidColor=0,0,0,1")
			table.insert(output, "Padding=2,2,2,2")
			table.insert(output, "AntiAlias=1")
			table.insert(output, "LeftMouseUpAction=[!CommandMeasure MeasureDynamicTasks \"ChangeOrder("..i..","..(i+1)..")\"][!UpdateMeasure MeasureDynamicTasks][!UpdateMeter *][!Redraw]")
		end
		table.insert(output, "X=2R")
		table.insert(output, "Y=r")
		table.insert(output, "H=35")
		table.insert(output, "W="..(cfg.buttonSize + 4))
		
		-- DELETE BUTTON (sempre aparece, não depende mais de recurring)
		table.insert(output, "[MeterDelete"..i.."]")
		table.insert(output, "Meter=String")
		table.insert(output, "Group=DynamicTasks")
		table.insert(output, "Text=[#mui-to-trash]")
		table.insert(output, "FontFace=Material Icons")
		table.insert(output, "FontSize="..cfg.buttonSize)
		table.insert(output, "FontColor="..cfg.buttonColor)
		table.insert(output, "SolidColor=0,0,0,1")
		table.insert(output, "Padding=0,0,4,0")
		table.insert(output, "AntiAlias=1")
		table.insert(output, "X=6R")
		table.insert(output, "Y=r")
		table.insert(output, "H=35")
		table.insert(output, "W="..(cfg.buttonSize + 4))
		table.insert(output, "LeftMouseUpAction=[!CommandMeasure MeasureDynamicTasks \"RemoveTask("..i..")\"][!UpdateMeasure MeasureDynamicTasks][!UpdateMeter *][!Redraw]")
	end
	
	return output
end

-- Gera variáveis dinâmicas
function Renderer.GenerateVariables(tasks, taskManager)
	local output = {"[Variables]"}
	
	for i = 1, #tasks do
		local task = tasks[i]
		
		-- Checkbox state
		if task[taskManager.COL_CHECKBOX] == taskManager.MARK then
			table.insert(output, "check"..i.."state=1")
			table.insert(output, "check"..i.."=mui-checked")
		else
			table.insert(output, "check"..i.."state=0")
			table.insert(output, "check"..i.."=mui-check")
		end
		
		-- Important state (vermelho quando ativo, cinza quando inativo)
		if task[taskManager.COL_IMPORTANT] == taskManager.MARK then
			table.insert(output, "important"..i.."state=1")
			table.insert(output, "important"..i.."=255,80,80,255")
		else
			table.insert(output, "important"..i.."state=0")
			table.insert(output, "important"..i.."=150,150,150,255")
		end
		
		-- Daily state (azul quando ativo, cinza quando inativo)
		if task[taskManager.COL_DAILY] == taskManager.MARK then
			table.insert(output, "daily"..i.."state=1")
			table.insert(output, "daily"..i.."=100,200,255,255")
		else
			table.insert(output, "daily"..i.."state=0")
			table.insert(output, "daily"..i.."=150,150,150,255")
		end
	end
	
	return output
end

-- Gera botões de controle (refresh, add, undo)
function Renderer.GenerateControlButtons(hasTrash)
	local output = {}
	local cfg = Renderer.config
	
	-- Include icons
	table.insert(output, "@Include=#@#MUI.inc")
	
	-- Refresh button
	table.insert(output, "[MeterRefresh]")
	table.insert(output, "Meter=String")
	table.insert(output, "Group=DynamicTasks")
	table.insert(output, "Text=#mui-refresh#")
	table.insert(output, "FontFace=Material Icons")
	table.insert(output, "FontSize="..cfg.buttonSize)
	table.insert(output, "FontColor="..cfg.buttonColor)
	table.insert(output, "SolidColor=0,0,0,1")
	table.insert(output, "Padding=2,2,2,2")
	table.insert(output, "AntiAlias=1")
	table.insert(output, "X=10")
	table.insert(output, "Y=15R")
	table.insert(output, "LeftMouseUpAction=[!Refresh]")
	
	-- Add button
	table.insert(output, "[MeterAddTask]")
	table.insert(output, "Meter=String")
	table.insert(output, "Group=DynamicTasks")
	table.insert(output, "Text=#mui-create#")
	table.insert(output, "FontFace=Material Icons")
	table.insert(output, "FontSize="..cfg.buttonSize)
	table.insert(output, "FontColor="..cfg.buttonColor)
	table.insert(output, "SolidColor=0,0,0,1")
	table.insert(output, "Padding=2,2,2,2")
	table.insert(output, "AntiAlias=1")
	table.insert(output, "X=4R")
	table.insert(output, "Y=r")
	table.insert(output, "LeftMouseUpAction=[!CommandMeasure MeasureInput \"ExecuteBatch 1\"]")
	
	-- Settings button
	table.insert(output, "[MeterSettingsBtn]")
	table.insert(output, "Meter=String")
	table.insert(output, "Group=DynamicTasks")
	table.insert(output, "Text=#mui-settings#")
	table.insert(output, "FontFace=Material Icons")
	table.insert(output, "FontSize="..cfg.buttonSize)
	table.insert(output, "FontColor="..cfg.buttonColor)
	table.insert(output, "SolidColor=0,0,0,1")
	table.insert(output, "Padding=2,2,2,2")
	table.insert(output, "AntiAlias=1")
	table.insert(output, "X=4R")
	table.insert(output, "Y=r")
	table.insert(output, "LeftMouseUpAction=[!SetVariable ShowSettings 1][!WriteKeyValue Variables ShowSettings 1][!UpdateMeasure MeasureWatchSettings][!Update]")
	
	-- Undo button (only if has trash)
	if hasTrash then
		table.insert(output, "[MeterUndo]")
		table.insert(output, "Meter=String")
		table.insert(output, "Group=DynamicTasks")
		table.insert(output, "Text=#mui-from-trash#")
		table.insert(output, "FontFace=Material Icons")
		table.insert(output, "FontSize="..cfg.buttonSize)
		table.insert(output, "FontColor="..cfg.buttonColor)
		table.insert(output, "SolidColor=0,0,0,1")
		table.insert(output, "Padding=2,2,2,2")
		table.insert(output, "AntiAlias=1")
		table.insert(output, "X=4R")
		table.insert(output, "Y=r")
		table.insert(output, "LeftMouseUpAction=[!CommandMeasure MeasureDynamicTasks \"UndoDelete()\"][!UpdateMeasure MeasureDynamicTasks][!UpdateMeter *][!Redraw]")
	end
	
	return output
end

return Renderer
