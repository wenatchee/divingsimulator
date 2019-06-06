--[[
    Client.local.lua
        By Sven Kullaske

    Let me know if you're able to find any exploits, I pay depending on serverity.

]]--

local MarketplaceService = game:GetService('MarketplaceService')
local ReplicatedStorage = game:FindService('ReplicatedStorage')
local PlayersService = game:FindService('Players')
local HttpService = game:GetService('HttpService')
local Workspace = game:FindService('Workspace')

local Player = PlayersService.LocalPlayer

local ZonesFolder = Workspace:WaitForChild('Zones')
local NodesFolder = Workspace:WaitForChild('Nodes')
local TemplateFolder = script:WaitForChild('Template')
local EmojieFolder = TemplateFolder:WaitForChild('Emojie')
local SoundsFolder = TemplateFolder:WaitForChild('Sounds')
local ConnectionsFolder = ReplicatedStorage:WaitForChild('Connections')
local DataFolder = Player:WaitForChild('Data')

local ReplicatedSettings = require(ReplicatedStorage:WaitForChild('ReplicatedSettings'))

local XPInstance = DataFolder:WaitForChild('XP')
local CoinsInstance = DataFolder:WaitForChild('Coins')

local ScreenGui = script.Parent:WaitForChild('ScreenGui')
local InventoryFrame = ScreenGui:WaitForChild('Inventory')

local HUD = {}
local Shop = {}
local Zone = {}
local Zones = {}
local Music = {}
local Nodes = {}
local Levels = {}
local Sounds = {}
local SellAll = {}
local Upgrade = {}
local Effects = {}
local Teleport = {}
local Settings = {}
local Gamepass = {}
local Inventory = {}

local Cache = {}
local Connections = {}

local UpgradeShopPart = Workspace:WaitForChild('UpgradeShopPart')
local PawnShopPart = Workspace:WaitForChild('PawnShopPart')

local HUDFrame = ScreenGui:WaitForChild('HUD')

Cache.Nodes = {}
Cache.Shop = {}
Cache.Gamepass = {Opened = false}
Cache.Nodes.Instances = {}
Cache.Nodes.Prompted = {}
Cache.Shop.Prompted = {['Pawn'] = false, ['Upgrade'] = false}

Upgrade.Shop = {}
Upgrade.Gamepasses = {}
Upgrade.Gamepasses.Frame = ScreenGui:WaitForChild('Upgrade')
Upgrade.Gamepasses.Button = Upgrade.Gamepasses.Frame:WaitForChild('Button')

Teleport.Frame = ScreenGui:WaitForChild('Teleport')
Teleport.Button = Teleport.Frame:WaitForChild('Button')

SellAll.Frame = ScreenGui:WaitForChild('SellAll')
SellAll.Button = SellAll.Frame:WaitForChild('Button')
table.insert(Effects, SellAll)
table.insert(Effects, Teleport)
table.insert(Effects, Upgrade.Gamepasses)

Music.Songs = {
    ['Island - MBB'] = "rbxassetid://1555385825";
}

Cache.Emojies = {
    ["Shell"] = EmojieFolder.Shell.Value;
	["Small Treasure Chest"] = EmojieFolder["Small Treasure Chest"].Value
}

Settings.Tween = {
    ['NodePrompt'] = {
        StartPos = UDim2.new(0.5, -75, 1, 0);
        MidPos = UDim2.new(0.5, -75, 0.5, -100);
        Time = 0.2;
        EasingStyle = 'Quad';
        Direction = 'Out';
    };
    ['PawnShop'] = {
        StartPos = UDim2.new(0.5, -75, 1, 0);
        MidPos = UDim2.new(0.5, -75, 0.5, -100);
        Time = 0.2;
        EasingStyle = 'Quad';
        Direction = 'Out';
    };
    ['UpgradeShop'] = {
        StartPos = UDim2.new(0.5, -125, 1, 0 );
        MidPos = UDim2.new(0.5, -125, 0.5, -130);
        Time = 0.2;
        EasingStyle = 'Quad';
        Direction = 'Out';
    };
    ['Shop'] = {
        StartPos = UDim2.new(0.5, -125, 1, 0 );
        MidPos = UDim2.new(0.5, -125, 0.5, -140);
        Time = 0.2;
        EasingStyle = 'Quad';
        Direction = 'Out';
    };
}

local Gamepasses = {
    {Name = "2X Coins", Icon="rbxassetid://3198829597", GamepassId = 6391420};
    {Name = "2X XP", Icon="rbxassetid://3198829631", GamepassId = 6391419};
    {Name = "2X Coins", Icon="rbxassetid://3198829597", GamepassId = 6391420};
    {Name = "2X XP", Icon="rbxassetid://3198829631", GamepassId = 6391419};
}

local XPAmount = 100
for i=1, 500 do
    Levels[i] = XPAmount
    XPAmount = XPAmount + 100*i + 500
end

for i,v in pairs(ConnectionsFolder:GetChildren()) do
    Connections[v.Name] = v
end

Inventory = Connections["InventoryGet"]:InvokeServer()
print(HttpService:JSONEncode(Inventory))

for i,SoundInstance in pairs(SoundsFolder:GetChildren()) do
    Sounds[SoundInstance.Name] = SoundInstance
end

for i,Node in pairs(NodesFolder:GetChildren()) do
    Cache.Nodes.Instances[Node] = Node.Available.Value
    Node.Available.Changed:Connect(function()
        Cache.Nodes.Instances[Node] = Node.Available.Value
    end)
end

function GetLevel()
    local PlayerLevel = 1
    for Level,XPAmount in pairs(Levels) do
        if XPAmount <= DataFolder.XP.Value then
            PlayerLevel = Level
        end
    end
    return PlayerLevel
end

function NextLevelPercentage()
    local PlayerLevel = GetLevel()
    local NextLevelXP = Levels[PlayerLevel + 1]
    local Percentage = (Levels[PlayerLevel] - DataFolder:WaitForChild('XP').Value)/(Levels[PlayerLevel] - NextLevelXP)
    return Percentage*100
end

spawn(function() -- Distance checking
    while wait(0.5) do
        for Node,Available in pairs(Cache.Nodes.Instances) do
            if (Player.Character.Humanoid.RootPart.Position - Node.Position).magnitude <= 15 and Available then
                Nodes:Prompt(Node)
            end
        end

        if (Player.Character.Humanoid.RootPart.Position - PawnShopPart.Position).magnitude <= 15 then
            Shop:PawnShop()
        end

        if (Player.Character.Humanoid.RootPart.Position - UpgradeShopPart.Position).magnitude <= 15 then
            Shop:UpgradeShop()
        end

    end
end)

function Nodes:Prompt(Node)
    if Cache.Nodes.Prompted[Player] == nil or Cache.Nodes.Prompted[Player] == false then -- I just notcied that I'm indexing player in a local script, I got a high IQ :^)
        Cache.Nodes.Prompted[Player] = true
        
        local Collecting = false

        local NodePromptClone = TemplateFolder.NodePrompt:Clone()
        NodePromptClone.Parent = ScreenGui
        NodePromptClone.Position = Settings.Tween['NodePrompt'].StartPos
        NodePromptClone:TweenPosition(Settings.Tween['NodePrompt'].MidPos, Settings.Tween['NodePrompt'].Direction, Settings.Tween['NodePrompt'].EasingStyle, Settings.Tween['NodePrompt'].Time)
        NodePromptClone.Title.Text = string.upper(Node.Name)
        NodePromptClone.Icon.Text = Cache.Emojies[Node.Name]
        NodePromptClone.Worth.Text = ('WORTH: '..Node.Worth.Value)

        NodePromptClone.Collect.MouseButton1Click:Connect(function()

            if Collecting == false then

                Collecting = true

                Sounds['Click']:Play()

                Connections['NodeInitiateCollect']:InvokeServer(Node)

                local WaitTime = (ReplicatedSettings.Timing[Node.Name] - (GetLevel()*0.10))
                NodePromptClone.Loading.Line:TweenPosition(UDim2.new(0,0,0,0), 'Out', 'Linear', WaitTime)
                wait(WaitTime)

                if (Connections['NodeCollect']:InvokeServer(Node)) then
                    NodePromptClone.Loading.Line.BackgroundColor3 = Color3.fromRGB(25, 255, 0)
                    table.insert(Inventory.Objects, {Name = Node.Name, Price = Node.Worth.Value})
                    HUD:UpdateInventoryCounter()
                    print(HttpService:JSONEncode(Inventory))
                else
                    NodePromptClone.Loading.Line.BackgroundColor3 = Color3.fromRGB(255, 3, 7)
                end

                wait(0.5)
                NodePromptClone:TweenPosition(Settings.Tween['NodePrompt'].StartPos, Settings.Tween['NodePrompt'].Direction, Settings.Tween['NodePrompt'].EasingStyle, Settings.Tween['NodePrompt'].Time)
                wait(Settings.Tween['NodePrompt'].Time)
                NodePromptClone:Destroy()
                Cache.Nodes.Prompted[Player] = false

                Collecting = false

            end

        end)

        while wait(0.5) do

            if (Player.Character.Humanoid.RootPart.Position - Node.Position).magnitude > 15 then

                if Cache.Nodes.Prompted[Player] == true and Collecting == false then
                    
                    NodePromptClone:TweenPosition(Settings.Tween['NodePrompt'].StartPos, Settings.Tween['NodePrompt'].Direction, Settings.Tween['NodePrompt'].EasingStyle, Settings.Tween['NodePrompt'].Time)
                    wait(Settings.Tween['NodePrompt'].Time)
                    NodePromptClone:Destroy()
                    Cache.Nodes.Prompted[Player] = false

                end

                break

            end
        end
    end
end

function Shop:PawnShop()
    if Cache.Shop.Prompted['Pawn'] == false then
        Cache.Shop.Prompted['Pawn'] = true

        local SoldAll = false

        local PawnShopClone = TemplateFolder:WaitForChild('PawnShop'):Clone()

        local InventoryWorth = 0
        local Objects = 0

        for i,Object in pairs(Inventory.Objects) do
            InventoryWorth = InventoryWorth + Object.Price
            Objects = Objects + 1
        end

        PawnShopClone.Parent = ScreenGui
        PawnShopClone:WaitForChild('Size').Text = (Objects .. "/".. Inventory.MaxInventory)
        PawnShopClone:WaitForChild('Worth').Text = InventoryWorth
        PawnShopClone.Position = Settings.Tween['PawnShop'].StartPos
        PawnShopClone:TweenPosition(Settings.Tween['PawnShop'].MidPos, Settings.Tween['PawnShop'].Direction, Settings.Tween['PawnShop'].EasingStyle, Settings.Tween['PawnShop'].Time)

        PawnShopClone.SellAll.MouseButton1Click:Connect(function()

            if SoldAll == false then
             
                SoldAll = true

                PawnShopClone.Loading.Line:TweenPosition(UDim2.new(0,0,0,0), 'Out', 'Linear', 2)
                wait(2)
                Connections['InventorySellAll']:InvokeServer()
                PawnShopClone.Loading.Line.BackgroundColor3 = Color3.fromRGB(25, 255, 0)
                wait(1)

                PawnShopClone:TweenPosition(Settings.Tween['PawnShop'].StartPos, Settings.Tween['PawnShop'].Direction, Settings.Tween['PawnShop'].EasingStyle, Settings.Tween['PawnShop'].Time)
                wait(Settings.Tween['PawnShop'].Time)
                PawnShopClone:Destroy()
                Cache.Shop.Prompted['Pawn'] = false

                Inventory = {MaxInventory = Inventory.MaxInventory, Objects = {}}
                HUD:UpdateInventoryCounter()
                Inventory = Connections['InventoryGet']:InvokeServer()

            end

        end)

        while wait(0.5) do

            if (Player.Character.Humanoid.RootPart.Position - PawnShopPart.Position).magnitude > 15 and SoldAll == false then

                PawnShopClone:TweenPosition(Settings.Tween['PawnShop'].StartPos, Settings.Tween['PawnShop'].Direction, Settings.Tween['PawnShop'].EasingStyle, Settings.Tween['PawnShop'].Time)
                wait(Settings.Tween['PawnShop'].Time)
                PawnShopClone:Destroy()
                Cache.Shop.Prompted['Pawn'] = false

                break

            end

            if SoldAll == true then
                break
            end

        end

    end
end

function Shop:UpgradeShop()

    if Cache.Shop.Prompted['Upgrade'] == false then
        Cache.Shop.Prompted['Upgrade'] = true

        local UpgradeShopClone = TemplateFolder:WaitForChild('UpgradeShop'):Clone()
        UpgradeShopClone.Position = Settings.Tween['UpgradeShop'].StartPos
        UpgradeShopClone.Parent = ScreenGui

        local InventoryUpgradePrice = (math.floor((((Inventory['MaxInventory']+5)*1.5)^2)/100)*100) -- It took me so long to come up with this...
        UpgradeShopClone.InventoryPrice.Text = ("PRICE: "..InventoryUpgradePrice)
        UpgradeShopClone.InventorySize.Text = ("CURRENT SIZE: "..Inventory['MaxInventory'])

        UpgradeShopClone.InventoryUpgrade.MouseButton1Click:Connect(function()

            Sounds['Click']:Play()

            local Result = Connections['InventoryUpgrade']:InvokeServer()
            print(Result)
            if Result then
                Inventory['MaxInventory'] = Inventory['MaxInventory'] + 5
                local InventoryUpgradePrice = (math.floor((((Inventory['MaxInventory']+5)*1.5)^2)/100)*100)
                UpgradeShopClone.InventoryPrice.Text = ("PRICE: "..InventoryUpgradePrice)
                UpgradeShopClone.InventorySize.Text = ("CURRENT SIZE: "..Inventory['MaxInventory'])
                HUD:UpdateInventoryCounter()
            end
        end)

        local SpeedUpgradePrice = math.floor((DataFolder.Speed.Value*.5)^3)
        UpgradeShopClone.SpeedCurrent.Text = ("CURRENT SPEED: ".. DataFolder.Speed.Value)
        UpgradeShopClone.SpeedPrice.Text = ("PRICE: ".. SpeedUpgradePrice)
        print(SpeedUpgradePrice)
        

        UpgradeShopClone.SpeedUpgrade.MouseButton1Click:Connect(function()

            Sounds['Click']:Play()

            local Result = Connections['SpeedUpgrade']:InvokeServer()
            if Result then
                local SpeedUpgradePrice = math.floor((DataFolder.Speed.Value*.5)^3)
                UpgradeShopClone.SpeedCurrent.Text = ("CURRENT SPEED: ".. DataFolder.Speed.Value)
                UpgradeShopClone.SpeedPrice.Text = ("PRICE: ".. SpeedUpgradePrice)
            end
        end)

        UpgradeShopClone:TweenPosition(Settings.Tween['UpgradeShop'].MidPos, Settings.Tween['UpgradeShop'].Direction, Settings.Tween['UpgradeShop'].EasingStyle, Settings.Tween['UpgradeShop'].Time)
        wait(Settings.Tween['UpgradeShop'].Time)

        while wait(0.5) do

            if (Player.Character.Humanoid.RootPart.Position - UpgradeShopPart.Position).magnitude > 15 then

                UpgradeShopClone:TweenPosition(Settings.Tween['UpgradeShop'].StartPos, Settings.Tween['UpgradeShop'].Direction, Settings.Tween['UpgradeShop'].EasingStyle, Settings.Tween['UpgradeShop'].Time)
                wait(Settings.Tween['UpgradeShop'].Time)
                UpgradeShopClone:Destroy()
                Cache.Shop.Prompted['Upgrade'] = false

                break

            end

        end

    end

end

HUDFrame.Level.Text = ("LEVEL: "..GetLevel())
HUDFrame.XP.Bar.Position = UDim2.new(0, (-200 + NextLevelPercentage()*2), 0, 0)
HUDFrame.Coins.Text = DataFolder.Coins.Value
Player.Character.Humanoid.WalkSpeed = DataFolder.Speed.Value

DataFolder.XP.Changed:Connect(function()

    HUDFrame.Level.Text = ("LEVEL: "..GetLevel())
    HUDFrame.XP.Bar:TweenPosition(UDim2.new(0, (-200 + NextLevelPercentage()*2), 0, 0), 'Out', 'Linear', 0.2)

end)

DataFolder.Coins.Changed:Connect(function()

    HUDFrame.Coins.Text = (DataFolder.Coins.Value)

end)

DataFolder.Speed.Changed:Connect(function()

    Player.Character.Humanoid.WalkSpeed = DataFolder.Speed.Value

end)

function HUD:UpdateInventoryCounter()
    InventoryFrame:WaitForChild('Size').Text = (#Inventory.Objects.."/"..Inventory.MaxInventory)
    local PercentageFull = (#Inventory.Objects/Inventory.MaxInventory)*100
    InventoryFrame.Bar.Line:TweenPosition(UDim2.new(0,-200 + (PercentageFull*2),0,0), 'Out', 'Linear', 0.1)
end

HUD:UpdateInventoryCounter()

for i,Effect in pairs(Effects) do
    Effect.Button.MouseButton1Click:Connect(function()
        Sounds['Click']:Play()
        Effect.Button:TweenPosition(UDim2.new(0,0,0,5), 'Out', 'Linear', 0.2)
        Effect.Frame.Upgrade:TweenPosition(UDim2.new(0,0,0,5), 'Out', 'Linear', 0.2)
        spawn(function()
            wait(0.4)
            Effect.Button:TweenPosition(UDim2.new(0,0,0,0), 'Out', 'Linear', 0.2)
            Effect.Frame.Upgrade:TweenPosition(UDim2.new(0,0,0,0), 'Out', 'Linear', 0.2)
        end)
    end)
end

Gamepass = Connections['GamepassGet']:InvokeServer()
--print(HttpService:JSONEncode(Gamepass))

SellAll.Button.MouseButton1Click:Connect(function()

    Sounds['Click']:Play()

    if MarketplaceService:UserOwnsGamePassAsync(Player.UserId, 6391435) then
        if (Connections['InventorySellAll']:InvokeServer()) then
            Inventory = {MaxInventory = Inventory.MaxInventory, Objects = {}}
            HUD:UpdateInventoryCounter()  
            Inventory = Connections['InventoryGet']:InvokeServer()
        end
    else
        MarketplaceService:PromptGamePassPurchase(Player, 6391435)
    end
end)

local LastCoinAmount = DataFolder.Coins.Value
local LastXpAmount = DataFolder.XP.Value

DataFolder.Coins.Changed:Connect(function()
    local NewAmount = DataFolder.Coins.Value - LastCoinAmount
    LastCoinAmount = DataFolder.Coins.Value
    if NewAmount > 0 then
        local CoinCardClone = TemplateFolder:WaitForChild('CoinCard'):Clone()
        CoinCardClone.Amount.Text = ("+"..NewAmount)
        local x = math.random(250,430)
        local y = math.random(80,100)/100
        CoinCardClone.Position = UDim2.new(0,x,y,0)
        CoinCardClone.Parent = ScreenGui
        CoinCardClone:TweenPosition(UDim2.new(0,x,0,-75), 'In', 'Quad', 1.2)
        wait(1.2)
        CoinCardClone:Destroy()
    end
end)

Cache.Gamepass.ShopFrameClone = nil
Cache.Gamepass.Debounce = false

for i, GamepassInfo in pairs(Gamepasses) do
    GamepassInfo['ProductInfo'] = MarketplaceService:GetProductInfo(GamepassInfo.GamepassId, Enum.InfoType.GamePass)
end

ScreenGui.Upgrade.Button.MouseButton1Click:Connect(function()
    if Cache.Gamepass.Opened == false and Cache.Gamepass.Debounce == false then

        Cache.Gamepass.Opened = true
        Cache.Gamepass.Debounce = true

        Cache.Gamepass.ShopFrameClone = TemplateFolder:WaitForChild('Shop'):Clone()

        local x,y = 1,0

        print(#Gamepasses)

        for i, GamepassInfo in pairs(Gamepasses) do
            
            --print(HttpService:JSONEncode(GamepassInfo))

            local ShopCardClone = TemplateFolder:WaitForChild('ShopCard'):Clone()
            ShopCardClone.Parent = Cache.Gamepass.ShopFrameClone.Upgrades

            if x == 1 then
                ShopCardClone.Position = UDim2.new(0,10,0,y)
                x = 2
            elseif x == 2 then
                ShopCardClone.Position = UDim2.new(1,-120,0,y)
                x = 1
                y = y + 140
            end

            ShopCardClone.Icon.Image = GamepassInfo.Icon
            ShopCardClone.MouseEnter:Connect(function()
                for i=0,1.25,0.25 do
                    ShopCardClone.Icon.ImageTransparency = i
                    wait()
                end
            end)

            ShopCardClone.MouseLeave:Connect(function()
                for i=1,-.25,-0.25 do
                    ShopCardClone.Icon.ImageTransparency = i
                    wait()
                end
            end)

            ShopCardClone.Buy.MouseButton1Click:Connect(function()
                MarketplaceService:PromptGamePassPurchase(Player, GamepassInfo.GamepassId)
            end)

            ShopCardClone.Description.Text = GamepassInfo['ProductInfo']["Description"]
            ShopCardClone.Buy.TextLabel.Text = ("R$"..GamepassInfo['ProductInfo']['PriceInRobux'])

        end

        Cache.Gamepass.ShopFrameClone.Upgrades.CanvasSize = UDim2.new(0,0,0,y+10)

        Cache.Gamepass.ShopFrameClone.Parent = ScreenGui
        Cache.Gamepass.ShopFrameClone.Position = Settings.Tween['Shop'].StartPos
        Cache.Gamepass.ShopFrameClone:TweenPosition(Settings.Tween['Shop'].MidPos, Settings.Tween['Shop'].Direction, Settings.Tween['Shop'].EasingStyle, Settings.Tween['Shop'].Time)
    
        wait(Settings.Tween['Shop'].Time + 0)
        Cache.Gamepass.Debounce = false

    elseif Cache.Gamepass.Debounce == false then
        Cache.Gamepass.Opened = false
        Cache.Gamepass.Debounce = true

        Cache.Gamepass.ShopFrameClone:TweenPosition(Settings.Tween['Shop'].StartPos, Settings.Tween['Shop'].Direction, Settings.Tween['Shop'].EasingStyle, Settings.Tween['Shop'].Time)
        
        wait(Settings.Tween['Shop'].Time + 0)
        Cache.Gamepass.Debounce = false
        Cache.Gamepass.ShopFrameClone:Destroy()

    end
end)

function Music:Player()

    spawn(function()
        
        local Sound = Instance.new('Sound')
        Sound.Parent = ScreenGui
        for MusicName,MusicId in pairs(Music.Songs) do
            Sound.SoundId = MusicId
            Sound:Play()
            wait(1)
            wait(Sound.TimeLength)
            Sound:Stop()
        end
        
    end)

end

Music:Player()

Zones.Unlocked = Connections['ZonesGetUnlocked']:InvokeServer()

for i,Zone in pairs(ZonesFolder:GetChildren()) do

    if not Zones.Unlocked[Zone.Name] then

        local ZoneSurfaceGuiClone = TemplateFolder:WaitForChild('ZoneSurfaceGui'):Clone()

        ZoneSurfaceGuiClone.InfoFrame.ZoneName.Text = Zone.Name
        ZoneSurfaceGuiClone.InfoFrame.Price.Text = Zone.Price.Value
        ZoneSurfaceGuiClone.Parent = Zone

        ZoneSurfaceGuiClone.InfoFrame.Upgrade.MouseButton1Click:Connect(function()
            local Response = Connections['ZonesUnlock']:InvokeServer(Zone)
            print(Response)
            if Response then
                Zone:Destroy()
            end
        end)
    
    else

        Zone:Destroy()

    end

end
