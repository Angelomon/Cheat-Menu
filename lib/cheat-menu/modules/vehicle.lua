-- Cheat Menu -  Cheat menu for Grand Theft Auto SanAndreas
-- Copyright (C) 2019 Grinch_

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

local module = {}

module.tvehicle =
{
    aircraft =
    {
        camera = imgui.new.bool(fconfig.get('tvehicle.aircraft.camera',false)),
        index = fconfig.get('tvehicle.aircraft.index',2),
        spawn_in_air = imgui.new.bool(fconfig.get('tvehicle.aircraft.spawn_in_air',true)),
        zoom = { -5.0,-15.0,-20.0,-30.0,-40.0},
    },
    color =
    {
        default = -1,
        rgb     = imgui.new.float[3](0.0,0.0,0.0),
    },
    components =
    {
        images = {},
        list   = {},
        names  =
        {
            "Default",
            "wheel_rf_dummy",
            "wheel_lb_dummy",
            "wheel_lf_dummy",
            "wheel_rb_dummy",
            "chassis_dummy",
            "chassis_vlo",
            "exhaust_ok",
            "chassis",
            "ug_nitro",
            "door_lr_dummy",
            "bump_rear_dummy",
            "bonnet_dummy",
            "bump_front_dummy",
            "door_lf_dummy",
            "door_rf_dummy",
            "door_rr_dummy",
            "windscreen_dummy",
            "boot_dummy"
        },
        path   =  tcheatmenu.dir .. "vehicles\\components\\",
        saved = false,
        selected = imgui.new.int(0),
        value  = imgui.new.int(0),
    },
    doors = 
    {
        "Hood",
    	"Boot",
    	"Front left door",
    	"Front right door",
    	"Rear left door",
        "Rear right door",
        "All",
    },
    door_menu_button = imgui.new.int(0),
    heavy = imgui.new.bool(fconfig.get('tvehicle.heavy',false)),
    hydraulic = imgui.new.bool(false),
    images = {},
    lights = imgui.new.bool(fconfig.get('tvehicle.lights',false)),
    lock_doors = imgui.new.bool(false),
    lock_speed = imgui.new.bool(fconfig.get('tvehicle.lock_speed',false)),
    models = {},
    paintjobs  = 
    {
        path   =  tcheatmenu.dir .. "vehicles\\paintjobs\\",
        search_text = imgui.new.char[20](),
        images = {},
        texture = nil
    },
    no_damage = imgui.new.bool(fconfig.get('tvehicle.no_damage',false)),
    path = tcheatmenu.dir .. "vehicles\\",
    quick_spawn  = imgui.new.bool(fconfig.get('tvehicle.quick_spawn',false)),
    search_text = imgui.new.char[20](),
    spawn_inside = imgui.new.bool(fconfig.get('tvehicle.spawn_inside',true)),
    speed = imgui.new.int(fconfig.get('tvehicle.speed',0)),
    stay_on_bike = imgui.new.bool(fconfig.get('tvehicle.stay_on_bike',false)),
    trains =
    {
        ["449"]     = 9,
        ["400"]     = 9,
        ["537"]     = 10,
        ["569"]     = 10,
        ["538"]     = 11,
        ["570"]     = 11,
    },
    visual_damage = imgui.new.bool(fconfig.get('tvehicle.visual_damage',false)),

}

module.tvehicle.components.list  = imgui.new['const char*'][#module.tvehicle.components.names](module.tvehicle.components.names)

module.IsValidModForVehicle = ffi.cast('bool(*)(int model, int cvehicle)',0x49B010)
IsThisModelATrain = ffi.cast('bool(*)(int model)',0x4C5AD0)

for i = 401,611,1 do
    table.insert(module.tvehicle.models,i)
end

function module.CBaseModelInfo(name)

    local pInfo = allocateMemory(16)
    callFunction(0x004C5940,2,2,name,pInfo)
    local model = readMemory(pInfo,4,false)
    freeMemory(pInfo)

    if getNameOfVehicleModel(model) == name then
        return model
    else
        return 0
    end
end

function module.GiveVehicleToPlayer(model)
    if isModelAvailable(model) then
        x,y,z = getCharCoordinates(PLAYER_PED)
        if isCharInAnyCar(PLAYER_PED) and module.tvehicle.spawn_inside[0] then
            vehicle = storeCarCharIsInNoSave(PLAYER_PED)
            speed = getCarSpeed(vehicle)
            warpCharFromCarToCoord(PLAYER_PED,x,y,z)
            deleteCar(vehicle)
        end

        if module.tvehicle.aircraft.spawn_in_air[0] and (isThisModelAHeli(model) or isThisModelAPlane(model)) then
            z = 400
        end

        if IsThisModelATrain(model) == true then

            id = module.tvehicle.trains[tostring(model)]

            for key,value in pairs(module.tvehicle.trains) do
                if value == id and key ~= tostring(model) then
                    model2 = tonumber(key)
                    break
                end
            end

            deleteAllTrains()
            requestModel(model)
            requestModel(model2)
            loadAllModelsNow()
            if math.random(0,1) == 0 then
                vehicle = createMissionTrain(id,x,y,z)
            else
                vehicle = createMissionTrain(id,x,y,z,true)
            end
            removeCharElegantly(getDriverOfCar(vehicle))
            if module.tvehicle.spawn_inside[0] then
                warpCharIntoCar(PLAYER_PED,vehicle)
            end
            markMissionTrainAsNoLongerNeeded(vehicle)
            markModelAsNoLongerNeeded(model2)
        else
            requestModel(model)
            loadAllModelsNow()

            if not module.tvehicle.spawn_inside[0] then
                vehicle = spawnVehicleByCheating(model)
            else
                vehicle = createCar(model,x,y,z)
                setCarHeading(vehicle,getCharHeading(PLAYER_PED))
                warpCharIntoCar(PLAYER_PED,vehicle)
                setCarForwardSpeed(vehicle,speed)
            end

            markCarAsNoLongerNeeded(vehicle)
        end
        markModelAsNoLongerNeeded(model)
        fcommon.CheatActivated()
    end
end


function module.AddComponentToVehicle(component)

    if isCharInAnyCar(PLAYER_PED) then
        local car = storeCarCharIsInNoSave(PLAYER_PED)
        if isModelAvailable(component) then
            requestVehicleMod(component)
            loadAllModelsNow()
            addVehicleMod(car,component)
            printHelpString("Component ~g~added")
            markModelAsNoLongerNeeded(component)
        end
    end
end

function DoorMenu(func)

    local vehicle = storeCarCharIsInNoSave(PLAYER_PED)
    local seats   = getMaximumNumberOfPassengers(vehicle) + 1 -- passenger + driver 
    
    if seats == 4 then
        doors = 5
    else
        doors = 3
    end
    if imgui.Button(module.tvehicle.doors[7],imgui.ImVec2(fcommon.GetSize(1))) then
        for i=0,doors,1 do
            func(vehicle,i)
        end
    end
    for i=0,doors,1 do
        if imgui.Button(module.tvehicle.doors[i+1],imgui.ImVec2(fcommon.GetSize(2))) then
            func(vehicle,i)
        end
        if i%2 ~= 1 then
            imgui.SameLine()
        end
    end

end   

function module.ForEachCarComponent(func)
    if isCharInAnyCar(PLAYER_PED) then
        car = storeCarCharIsInNoSave(PLAYER_PED)
        for _, comp in ipairs(mad.get_all_vehicle_components(car)) do
            for _, obj in ipairs(comp:get_objects()) do
                for _, mat in ipairs(obj:get_materials()) do
                    func(mat,comp,car)
                end
            end
        end
        markCarAsNoLongerNeeded(car)
    else
        printHelpString("Player ~r~not ~w~in car")
    end
end

function module.AircraftCamera()
    if module.tvehicle.aircraft.camera[0] == true then
        while isCharInAnyHeli(PLAYER_PED)
        or isCharInAnyPlane(PLAYER_PED) do
            if module.tvehicle.aircraft.camera[0] == false then break end

            local vehicle = storeCarCharIsInNoSave(PLAYER_PED)
            local roll = getCarRoll(vehicle)

            attachCameraToVehicle(vehicle,0.0,module.tvehicle.aircraft.zoom[module.tvehicle.aircraft.index],2.5,0.0,0.0,0.0,(roll*-1),2)
            if isKeyDown(tkeys.aircraft_zoom) then
                while isKeyDown(tkeys.aircraft_zoom) do
                    wait(0)
                end
                module.tvehicle.aircraft.index = module.tvehicle.aircraft.index + 1
                if module.tvehicle.aircraft.index > #module.tvehicle.aircraft.zoom then
                    module.tvehicle.aircraft.index  = 0
                end
            end
            wait(0)
        end
        restoreCameraJumpcut()
    end
end

function module.GetTextureName(name)
    if name == nil then
        return ""
    else
        return name
    end
end

function module.ApplyTexture(filename)
    lua_thread.create(function()
        local fullpath = module.tvehicle.paintjobs.path .. filename .. ".png"
        module.tvehicle.paintjobs.texture = assert(mad.load_png_texture(fullpath))
        module.ForEachCarComponent(function(mat,comp,car)
            local r, g, b, old_a = mat:get_color()
            if module.tvehicle.components.selected[0] == 0 and (r == 0x3C and g == 0xFF and b == 0x00) or (r == 0xFF and g == 0x00 and b == 0xAF) then
                mat:set_texture(module.tvehicle.paintjobs.texture)
            end
            if comp.name == module.tvehicle.components.names[module.tvehicle.components.selected[0]+1] then
                mat:set_texture(module.tvehicle.paintjobs.texture)
            end
            module.tvehicle.color.default = getCarColours(car)
        end)
    end,filename)
end

function module.VehicleMain()
    imgui.Spacing()

    if imgui.Button("Repair vehicle",imgui.ImVec2(fcommon.GetSize(2))) then
        if isCharInAnyCar(PLAYER_PED) then
            car = storeCarCharIsInNoSave(PLAYER_PED)
            fixCar(car)
            fcommon.CheatActivated()
        end
    end
    imgui.SameLine()
    if imgui.Button("Unflip vehicle",imgui.ImVec2(fcommon.GetSize(2))) then
        if isCharInAnyCar(PLAYER_PED) then
            car = storeCarCharIsInNoSave(PLAYER_PED)
            setCarRoll(car,0)
            fcommon.CheatActivated()
        end
    end
    imgui.Spacing()
    if imgui.BeginTabBar("Vehicles") then

        if imgui.BeginTabItem("Checkbox") then
            imgui.Spacing()

            imgui.Columns(2,nil,false)
            
            fcommon.CheckBox({ address = 0x96914F,name = "Aggressive drivers"})
            fcommon.CheckBox({ address = 0x969153,name = "Boats fly"})
            fcommon.CheckBox({ address = 0x969160,name = "Cars fly"})
            fcommon.CheckBox({name = "Car heavy",var = module.tvehicle.heavy})
            if imgui.Checkbox("Car hydraulic",module.tvehicle.hydraulic) then
                if isCharInAnyCar(PLAYER_PED) then
                    if module.tvehicle.hydraulic[0] then
                        setCarHydraulics(car,true)
                        fcommon.CheatActivated()
                    else
                        setCarHydraulics(car,false)
                        fcommon.CheatDeactivated()
                    end
                end
            end
            fcommon.CheckBox({ address = 0x96917A,name = "Decreased traffic"})
            fcommon.CheckBox({name = "Dont fall off bike",var = module.tvehicle.stay_on_bike})
            fcommon.CheckBox({ address = 0x969152,name = "Drive on water"})
            fcommon.CheckBox({ address = 0x969166,name = "Float away when hit"})
            fcommon.CheckBox({ address = 0x96914E,name = "Green traffic lights"})

            imgui.NextColumn()


            fcommon.CheckBox({ address = 0x969165,name = "Have nitro"})
            fcommon.CheckBox({name = "Lights on",var = module.tvehicle.lights,func =
            function()
                if isCharInAnyCar(PLAYER_PED) then
                    car = storeCarCharIsInNoSave(PLAYER_PED)
                    if module.tvehicle.lights[0] == true then
                        forceCarLights(car,2)
                        addOneOffSound(x,y,z,1052)
                    else
                        forceCarLights(car,1)
                        addOneOffSound(x,y,z,1053)
                    end
                end
            end})

            fcommon.CheckBox({name = "Lock doors",var = module.tvehicle.lock_doors,func =
            function()
                if isCharInAnyCar(PLAYER_PED) then
                    if getCarDoorLockStatus(car) == 4 then
                        lockCarDoors(car,1)
                        fcommon.CheatDeactivated()
                    else
                        lockCarDoors(car,4)
                        fcommon.CheatActivated()
                    end
                end
            end})
 
            fcommon.CheckBox({name = "New aircraft camera",var = module.tvehicle.aircraft.camera})
            fcommon.CheckBox({name = "No damage",var = module.tvehicle.no_damage})
            fcommon.CheckBox({name = "No visual damage",var = module.tvehicle.visual_damage})
            fcommon.CheckBox({ address = 0x96914C,name = "Perfect handling"})
            fcommon.CheckBox({ address = 0x969164,name = "Tank mode"})
            fcommon.CheckBox({ address = 0x96914B,name = "Wheels only"})         
            
    
            imgui.Columns(1)

            imgui.Spacing()
            imgui.Separator()
            imgui.Spacing()
            imgui.Columns(2,nil,false)
            fcommon.RadioButton("Traffic color",{"Black","Pink"},{0x969151,0x969150})
            
            imgui.NextColumn()
            fcommon.RadioButton("Traffic type",{"Cheap","Country","Fast"},{0x96915E,0x96917B,0x96915F})
            imgui.Columns(1)
            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Menus") then
            if imgui.BeginChild("Menus") then
                fcommon.DropDownMenu("Doors",function()
                    
                    if isCharInAnyCar(PLAYER_PED) and not (isCharOnAnyBike(PLAYER_PED) or isCharInAnyBoat(PLAYER_PED) 
                    or isCharInAnyHeli(PLAYER_PED) or isCharInAnyPlane(PLAYER_PED)) then    
                        if imgui.RadioButtonIntPtr("Damage", module.tvehicle.door_menu_button,0) then end
                        imgui.SameLine()
                        if imgui.RadioButtonIntPtr("Fix", module.tvehicle.door_menu_button,1) then end
                        imgui.SameLine()
                        if imgui.RadioButtonIntPtr("Open", module.tvehicle.door_menu_button,2) then end
                        imgui.SameLine()
                        if imgui.RadioButtonIntPtr("Pop", module.tvehicle.door_menu_button,3) then end
                        imgui.Spacing()
                        imgui.Separator()
                        imgui.Spacing()

                        if module.tvehicle.door_menu_button[0] == 0 then
                            if module.tvehicle.visual_damage[0] == false then
                                DoorMenu(function(vehicle,door)
                                    damageCarDoor(vehicle,door)
                                end)
                            else
                                imgui.Text("No visual damage enabled")
                            end
                        end
                        if module.tvehicle.door_menu_button[0] == 1 then
                            DoorMenu(function(vehicle,door)
                                fixCarDoor(vehicle,door)
                            end)
                        end
                        if module.tvehicle.door_menu_button[0] == 2 then
                            DoorMenu(function(vehicle,door)
                                openCarDoor(vehicle,door)
                            end)
                        end
                        if module.tvehicle.door_menu_button[0] == 3 then
                            DoorMenu(function(vehicle,door)
                                popCarDoor(vehicle,door,true)
                            end)
                        end
                    else
                        imgui.Text("Player not in a car")
                    end
                    
                end)
                fcommon.DropDownMenu("Enter",function()
                    local vehicle,ped = storeClosestEntities(PLAYER_PED)
                    if vehicle ~= -1 then
                        local seats = getMaximumNumberOfPassengers(vehicle)
                        imgui.Spacing()
                        imgui.Text(string.format("Total seats %d",seats+1))
                        imgui.Spacing()
                        imgui.Separator()
                        imgui.Spacing()
                        if imgui.Button("Driver",imgui.ImVec2(fcommon.GetSize(2))) then
                            warpCharIntoCar(PLAYER_PED,vehicle)
                        end
                        for i=0,seats-1,1 do
                            if i%2 ~= 1 then
                                imgui.SameLine()
                            end
                            if imgui.Button("Passenger " .. tostring(i+1),imgui.ImVec2(fcommon.GetSize(2))) then
                                warpCharIntoCarAsPassenger(PLAYER_PED,vehicle,i)
                            end
                        end
                    else
                        imgui.Text("No near by vehicles")
                    end
                end)
                fcommon.DropDownMenu("Speed",function()
                    imgui.Columns(2,nil,false)
                    fcommon.CheckBox({name = "Lock speed",var = module.tvehicle.lock_speed})
                    imgui.NextColumn()
                    imgui.Columns(1)
                    if imgui.InputInt("Set",module.tvehicle.speed) then
                    end
                    if imgui.Button("Set speed",imgui.ImVec2(fcommon.GetSize(2))) then
                        if module.tvehicle.speed[0] > 500 then
                            module.tvehicle.speed[0] = 500
                        end
                        if isCharInAnyCar(PLAYER_PED) then
                            car = storeCarCharIsInNoSave(PLAYER_PED)
                            setCarForwardSpeed(car,module.tvehicle.speed[0])
                        end
                    end
                    imgui.SameLine()
                    if imgui.Button("Instant stop",imgui.ImVec2(fcommon.GetSize(2))) then
                        if isCharInAnyCar(PLAYER_PED) then
                            car = storeCarCharIsInNoSave(PLAYER_PED)
                            setCarForwardSpeed(car,0.0)
                        end
                    end
                end)
                fcommon.UpdateAddress({name = 'Vehicle density multiplier',address = 0x8A5B20,size = 4,min = 0,max = 10, default = 1,is_float = true})

                imgui.EndChild()
            end
            imgui.EndTabItem()
        end
        if imgui.BeginTabItem("Spawn") then

            imgui.Spacing()
            imgui.Columns(2,nil,false)
            fcommon.CheckBox({name = "Quick vehicle",var = module.tvehicle.quick_spawn,help_text = "Vehicle can be spawned from quick spawner using (Left Ctrl + Q). \n\nControls:\nEnter : Stop reading key press\nDelete : Erase full string\nBackspace : Erase last character"})
            fcommon.CheckBox({name = "Spawn inside",var = module.tvehicle.spawn_inside,help_text = "Spawn inside vehicle as driver"})

            imgui.NextColumn()
            fcommon.CheckBox({name = "Spawn aircraft in air",var = module.tvehicle.aircraft.spawn_in_air})
            imgui.Columns(1)

            imgui.Spacing()
            if imgui.BeginTabBar("Vehicles list") then
                imgui.Spacing()

                if imgui.BeginTabItem("List") then
                    if imgui.BeginChild("Vehicles") then
                        fcommon.ShowEntries("Airplanes",{592,577,511,512,593,520,553,476,519,460,513},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("Helicopters",{548,425,417,487,488,497,563,447,469},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("Boats",{472,473,493,595,484,430,453,452,446,454},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("Bikes",{581,509,481,462,521,463,510,522,461,448,468,586},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("2 door & compact cars",{602,496,401,518,527,589,419,587,533,526,474,545,517,410,600,436,439,549,491},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("4 door & luxury cars",{445,604,507,585,466,492,546,551,516,467,426,547,405,580,409,550,566,540,421,529},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("Civil service",{485,431,438,437,574,420,525,408,552},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("Government vehicles",{416,433,427,490,528,407,544,523,470,596,598,599,597,432,601,428},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("Heavy & utility truck",{499,609,498,524,532,578,486,406,573,455,403,423,414,443,515,514,531,456,588},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("Light trucks & vans",{459,422,482,605,530,418,572,582,413,440,543,583,478,554},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("SUVs & wagons",{579,400,404,489,505,479,442,458},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("Low riders",{536,575,534,567,535,576,412},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("Muscle cars",{402,542,603,475},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("RC vehicles",{441,464,594,501,465,564},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("Recreational",{568,424,504,457,483,508,571,500,444,556,557,471,495,539},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("Street racers",{429,541,542,415,480,562,565,434,494,502,503,411,559,561,560,506,451,558,555,477},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("Trailers",{435,450,584,591,606,607,608,610,611},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        fcommon.ShowEntries("Trains",{449,537,538},75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true)
                        imgui.EndChild()
                    end
                    imgui.EndTabItem()
                end 
                if imgui.BeginTabItem("Search") then
                    imgui.Spacing()
                    imgui.Columns(1)
                    if imgui.InputText("Search",module.tvehicle.search_text,ffi.sizeof(module.tvehicle.search_text)) then end
                    imgui.SameLine()
        
                    imgui.Spacing()
                    imgui.Text("Found entries :(" .. ffi.string(module.tvehicle.search_text) .. ")")
                    imgui.Separator()
                    imgui.Spacing()
                    if imgui.BeginChild("Vehicle entries") then
                        fcommon.ShowEntries(nil,module.tvehicle.models,75,100,module.tvehicle.images,module.tvehicle.path,".jpg", module.GiveVehicleToPlayer,getNameOfVehicleModel,true,module.tvehicle.search_text)
                        imgui.EndChild()
                    end
                    imgui.EndTabItem()
                end
                imgui.EndTabBar()
            end
            imgui.EndTabItem()
        end
        if imgui.BeginTabItem("Paint") then
            imgui.Spacing()
            imgui.Columns(1)
            if imgui.InputText("Search",module.tvehicle.paintjobs.search_text,ffi.sizeof(module.tvehicle.paintjobs.search_text)) then end
            imgui.SameLine()

            imgui.Spacing()
            imgui.Combo("Component",module.tvehicle.components.selected,module.tvehicle.components.list,#module.tvehicle.components.names)
            if imgui.ColorEdit3("Color",module.tvehicle.color.rgb) then
                module.ForEachCarComponent(function(mat,comp,car)
                    local r, g, b, old_a = mat:get_color()
                    fixCar(car)
                    if module.tvehicle.components.selected[0] == 0 and (r == 0x3C and g == 0xFF and b == 0x00) or (r == 0xFF and g == 0x00 and b == 0xAF) then
                        mat:set_color(module.tvehicle.color.rgb[0]*255, module.tvehicle.color.rgb[1]*255, module.tvehicle.color.rgb[2]*255, 255.0)
                        if module.tvehicle.paintjobs.texture ~= nil then
                            mat:set_texture(module.tvehicle.paintjobs.texture)
                        end
                    end
                    if comp.name == module.tvehicle.components.names[module.tvehicle.components.selected[0]+1] then
                        mat:set_color(module.tvehicle.color.rgb[0]*255, module.tvehicle.color.rgb[1]*255, module.tvehicle.color.rgb[2]*255, 255.0)
                        if module.tvehicle.paintjobs.texture ~= nil then
                            mat:set_texture(module.tvehicle.paintjobs.texture)
                        end
                    end
                    module.tvehicle.color.default = getCarColours(car)
                end)
            end
            imgui.Spacing()
            if imgui.Button("Reset color",imgui.ImVec2(fcommon.GetSize(2))) then
                module.ForEachCarComponent(function(mat,car)
                    mat:reset_color()
                    module.tvehicle.color.default = -1
                end)
            end
            imgui.SameLine()
            if imgui.Button("Reset texture",imgui.ImVec2(fcommon.GetSize(2))) then
                module.ForEachCarComponent(function(mat,car)
                    mat:reset_texture()
                    module.tvehicle.paintjobs.texture = nil
                end)
            end
            imgui.Spacing()
            imgui.Text("Found entries :(" .. ffi.string(module.tvehicle.paintjobs.search_text) .. ")")
            imgui.Separator()
            imgui.Spacing()

            
            local mask = module.tvehicle.paintjobs.path .. "*.png"
            local handle,file = findFirstFile(mask)
            local model_table = {}

            while handle and file do
                table.insert( model_table,#model_table+1,string.sub( file,1,-5))
                file = findNextFile(handle)
            end
        
            if imgui.BeginChild("Vehicle entries") then
              
                fcommon.ShowEntries(nil,model_table,80,100,module.tvehicle.paintjobs.images,module.tvehicle.paintjobs.path,".png", module.ApplyTexture,module.GetTextureName,true,module.tvehicle.paintjobs.search_text)
                imgui.EndChild()
            end

            imgui.EndTabItem()
        end
        if isCharInAnyCar(PLAYER_PED) then
            if imgui.BeginTabItem('Tune') then
                imgui.Spacing()
                if imgui.Button("Restore mods",imgui.ImVec2(150,25)) then
                    if isCharInAnyCar(PLAYER_PED) and module.tvehicle.components.saved then
                        callFunction(0x49B3C0,0,0)
                    end
                end
                imgui.SameLine()
                if imgui.Button("Save mods",imgui.ImVec2(150,25)) then
                    if isCharInAnyCar(PLAYER_PED) then
                        callFunction(0x49B280,0,0)
                        module.tvehicle.components.saved = true
                    end
                end
                fcommon.InformationTooltip("Left click to add component\nRight click to remove component")
                imgui.Spacing()
                if imgui.BeginChild("Tune") then
                    imgui.Spacing()
                    fcommon.ShowEntries("Bullbar",{1100,1109,1110,1115,1116,1123,1125},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,false)
                    fcommon.ShowEntries("Exhaust",{1018,1019,1020,1021,1022,1028,1029,1034,1037,1043,1044,1045,1046,1059,1064,1065,1066,1089,1092,1104,1105,1113,1114,1126,1127,1129,1132,1135,1136},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,false)
                    fcommon.ShowEntries("Front bumper",{1117,1152,1153,1155,1157,1160,1165,1166,1169,1170,1171,1172,1173,1174,1175,1179,1181,1182,1185,1188,1189,1190,1191},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,false)
                    fcommon.ShowEntries("Front sign",{1111,1112},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,false)                    fcommon.ShowEntries("Hood",{1004,1005,1011,1012},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,false)
                    fcommon.ShowEntries("Lamps",{1013,1024},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,false)
                    fcommon.ShowEntries("Misc",{1086,1087},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,false)
                    fcommon.ShowEntries("Nitros",{1008,1009,1010},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,false)
                    fcommon.ShowEntries("Rear bumper",{1140,1141,1148,1149,1150,1151,1154,1156,1159,1161,1167,1168,1176,1177,1178,1180,1183,1184,1186,1187,1192,1193},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,false)
                    fcommon.ShowEntries("Roof",{1006,1032,1033,1035,1038,1053,1054,1055,1061,1067,1068,1088,1091,1103,1028,1130,1131},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,false)
                    fcommon.ShowEntries("Sideskirt",{1007,1017,1026,1027,1030,1031,1036,1039,1040,1041,1042,1047,1048,1051,1052,1056,1057,1062,1063,1069,1070,1071,1072,1090,1093,1094,1095,1099,1101,1102,1106,1107,1108,1118,1119,1120,1121,1122,1124,1133,1134,1137},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,false)
                    fcommon.ShowEntries("Spoiler",{1000,1001,1002,1003,1014,1015,1016,1023,1049,1050,1058,1060,1138,1139,1146,1147,1158,1162,1163,1164},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,false)
                    fcommon.ShowEntries("Vents",{1142,1143,1144,1145},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,false)
                    fcommon.ShowEntries("Wheels",{1025,1073,1074,1075,1076,1077,1078,1079,1080,1081,1082,1083,1084,1085,1096,1097,1098},75,100,module.tvehicle.components.images,module.tvehicle.components.path,".jpg", module.AddComponentToVehicle,nil,true)
                    imgui.EndChild()
                end
                imgui.EndTabItem()
            end
        end
        imgui.EndTabBar()
    end
end

return module
