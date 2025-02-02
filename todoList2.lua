shell.run("label set ToDo")
local periList = peripheral.getNames()
local mon = term.native()
for i = 1, #periList do
    if peripheral.getType(periList[i]) == "monitor" then
        mon = peripheral.wrap(periList[i])
        print("Monitor wrapped as... " .. periList[i])
    end
end

term.redirect(mon)

local currentPage = 1
local width, height = mon.getSize()
local line = height - 3

function textCol(color)
    if mon.isColor() then
        term.setTextColor(color)
    end
end

local todo = {} -- Initialize the 'todo' table as an empty table

function openTODO()
    local file = fs.open("todolist", "r")
    if file ~= nil then
        local data = file.readAll()
        file.close()
        if textutils.unserialize(data) == nil then
            todo[1] = {text = "Make a todo list", status = "Not Completed"}
        else
            todo = textutils.unserialize(data)
            -- Ensure "status" is set for older tasks
            for _, task in pairs(todo) do
                task.status = task.status or "Not Completed"
            end
        end
    else
        todo[1] = {text = "Make a todo list", status = "Not Completed"}
    end
end

function saveTODO()
    local file = fs.open("todolist", "w")
    file.write(textutils.serialize(todo))
    file.close()
end

function displayPage(p)
    textCol(colors.white)
    term.setCursorPos(1, 2)
    for i = (1 + (p - 1) * line), (p * line) do
        if todo[i] ~= nil then
            local status = todo[i].status
            local textColor = colors.white
            if status == "Completed" then
                textColor = colors.green
            elseif status == "In Progress" then
                textColor = colors.orange
            end
            textCol(textColor)
            term.write("[" .. status .. "] ")
            textCol(colors.gray)
            print(" " .. todo[i].text)
        end
    end
end

function printButtons()
    local buttonY = height - 1

    -- Add Item Button
    term.setCursorPos(2, buttonY)
    textCol(colors.green)
    term.write("[ Add Item ]")

    -- Remove Completed Button
    term.setCursorPos(20, buttonY)
    textCol(colors.red)
    term.write("[ Remove Completed ]")

    -- Cycle Page Button
    term.setCursorPos(width - 14, buttonY)
    textCol(colors.yellow)
    term.write("[ Cycle Page ]")
end

function addItem()
    term.clear()
    term.setCursorPos(2, 2)
    print("Please enter a new item:")
    local input = read()
    local newItem = {text = input, status = "Not Completed"}

    table.insert(todo, 1, newItem)
    saveTODO()

    term.clear()
    term.setCursorPos(2, 2)
    textCol(colors.white)
    print("Thanks! Item added.")
    os.sleep(2)
end

function removeCompletedTasks()
    local newTodo = {}  -- Create a new table for non-completed tasks
    for i = 1, #todo do
        if todo[i].status ~= "Completed" then
            table.insert(newTodo, todo[i])
        end
    end
    todo = newTodo  -- Update the 'todo' table with the filtered list
    saveTODO()
end

openTODO()

-- Initial printing
term.clear()
printButtons()
displayPage(1)

while true do
    local event, but, x, y

    if mon == term.native() then
        event, but, x, y = os.pullEvent("mouse_click")
    else
        event, _, x, y = os.pullEvent("monitor_touch")
    end

    if y == height - 1 then
        if x <= 13 then
            addItem()
        elseif x >= 20 and x <= 36 then
            removeCompletedTasks()
        elseif x >= width - 14 then
            if currentPage >= #todo / line then
                currentPage = 1
            else
                currentPage = currentPage + 1
            end
        end
    elseif y >= 2 and y <= height - 3 then
        local itm = (currentPage - 1) * line + y - 1
        if todo[itm] ~= nil then
            if todo[itm].status == "Not Completed" then
                todo[itm].status = "In Progress"
            elseif todo[itm].status == "In Progress" then
                todo[itm].status = "Completed"
            else
                todo[itm].status = "Not Completed"
            end
            saveTODO()
        end
    end

    term.clear()
    printButtons()
    term.setCursorPos(1, 1)
    displayPage(currentPage)
end
