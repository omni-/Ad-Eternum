--StartDebug()
local mod = RegisterMod("Ad Eternum", 1)

local redcap_id = Isaac.GetItemIdByName("Red Cap")
local weirdrock_id = Isaac.GetItemIdByName("Weird Rock")
local sledge_id = Isaac.GetTrinketIdByName("Lil Sledge")

local displayCustomHUD = false

local TextToRender = ""

function mod:cacheUpdate(player, cacheFlag)
  player = Isaac.GetPlayer(0)
  
  --red cap
  if player:HasCollectible(redcap_id) then
    if cacheFlag == CacheFlag.CACHE_DAMAGE then
      player.Damage = 1 + (player.Damage * 1.1)
    end
    
    if cacheFlag == CacheFlag.CACHE_FIREDELAY then
      player.FireDelay = player.MaxFireDelay - 1
    end
  end
  --weird rock
  if player:HasCollectible(weirdrock_id) then
    if cacheFlag == CacheFlag.CACHE_SPEED then
      player.MoveSpeed = player.MoveSpeed + .2
    end
    if cacheFlag == CacheFlag.CACHE_LUCK then
      player.Luck = player.Luck + 5
    end
  end
end

local function PlaySoundAtPos(soundEffect, volume, pos)
    local soundDummy = Isaac.Spawn(EntityType.ENTITY_FLY, 0, 0, pos, Vector(0,0), Isaac.GetPlayer(0));
    local soundDummyNPC = soundDummy:ToNPC();
    soundDummyNPC:PlaySound(soundEffect, volume, 0, false, 1.0);
    soundDummy:Remove();
end

function mod:weirdrock_update()
  local player = Isaac.GetPlayer(0)
  if player:HasCollectible(weirdrock_id) then
    local game = Game();
    local room = game:GetRoom();
    for i=0, room:GetGridSize() do
        local gridentity = room:GetGridEntity(i)
        if gridentity ~= nil then
          local rock = gridentity:ToRock()
          if rock ~= nil and gridentity.State == 2 and gridentity.VarData ~= 100 then
            gridentity.VarData = 100
            --todo: random explosion/gas/pheremones
            local pos = gridentity.Position
            local radius = 5.5
            local action = {
              [0] = function(type) Game():Fart(pos, radius, player, 1.0, type) end,
              [1] = function(type) Game():CharmFart(pos, radius, player) end,
              [2] = function(type) Game():ButterBeanFart(pos, radius, player, true) end
            }
            local num = math.random(0, 3)
            TextToRender = tostring(num)
            action[0](num)
          end
        end
    end
  end
end 

function mod:sledge_update()
  local player = Isaac.GetPlayer(0)
  if player:HasTrinket(sledge_id) then
    local game = Game();
    local room = game:GetRoom();
    local entities = Isaac.GetRoomEntities();
    for i=0, #entities do
        if (entities[i] ~= nil) then   
            if (entities[i].Type == EntityType.ENTITY_TEAR) then
                local nextPos = entities[i].Position;
                local rockIndex = room:GetGridIndex(nextPos);
                local grid = room:GetGridEntity(rockIndex);
                if (grid ~= nil) then
                    local rock = grid:ToRock();
                    if ((rock ~= nil) and (grid.State == 1)) then
                        if math.random(0, 3) == 1 then
                          room:DestroyGrid(rockIndex);
                          Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.ROCK_PARTICLE, 0, nextPos, Vector(0,0), player);
                          PlaySoundAtPos(SoundEffect.SOUND_ROCK_CRUMBLE, 0.33, nextPos);
                        end
                        entities[i].Remove()
                    end
                end
            end
        end
    end
  end
end

function mod:init()
  if Game():GetFrameCount() == 1 then
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, redcap_id, Vector(320, 300), Vector(0, 0), nil)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, weirdrock_id, Vector(400, 200), Vector(0, 0), nil)
    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, sledge_id, Vector (352, 332), Vector(0, 0), nil)
  end
end

function mod:update()
  --todo: move things here
end

function mod:draw()
  Isaac.RenderText(TextToRender, 50, 35, 255, 255, 255, 100)
  if displayCustomHUD then
    local player = Isaac.GetPlayer(0)
    Isaac.RenderText("dmg: " .. tostring(player.Damage), 10, 100, 255, 255, 255, 255)
    Isaac.RenderText("tears: " .. tostring(player.MaxFireDelay), 10, 110, 255, 255, 255, 255)
    Isaac.RenderText("speed: " .. tostring(player.MoveSpeed), 10, 120, 255, 255, 255, 255)
    Isaac.RenderText("luck: " .. tostring(player.Luck), 10, 130, 255, 255, 255, 255)
    Isaac.RenderText("shot: " .. tostring(player.ShotSpeed), 10, 140, 255, 255, 255, 255)
  end
end

mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.cacheUpdate)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.weirdrock_update)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.init)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.sledge_update)
--mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.update)
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.draw)
