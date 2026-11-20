-- Provisions: one macro per consumable type, always holding exactly one /use line
-- for the best item you have. Conjured (mage/warlock) items come first.
local P = "|cff69ccf0Provisions:|r "

local CATEGORIES = {
  { macro = "Prov Water", items = {
      8079, 8078, 8077, 3772, 2136, 2288, 5350,           -- Conjured water, best first
      8766, 1645, 1708, 1205, 1179, 159 } },              -- Bought water
  { macro = "Prov Food", items = {
      8076, 8075, 1487, 1114, 1113, 5349,                 -- Conjured food
      8950, 8952, 8932, 8953, 8957, 8948,                 -- lvl 45
      4601, 4599, 3927, 4602, 21552, 4608,                -- lvl 35
      4544, 3771, 1707, 4539, 4594, 4607,                 -- lvl 25
      4542, 3770, 422, 4538, 4593, 4606,                  -- lvl 15
      4541, 2287, 414, 4537, 4592, 4605,                  -- lvl 5
      4540, 117, 2070, 4536, 787, 4604 } },               -- lvl 1
  { macro = "Prov Stone", items = {
      9421, 5510, 5509, 5511, 5512 } },                   -- Healthstones
  { macro = "Prov Heal", items = {
      13446, 3928, 1710, 929, 858, 118 } },               -- Healing potions
  { macro = "Prov Mana", items = {
      13444, 13443, 6149, 3827, 3385, 2455 } },           -- Mana potions
  { macro = "Prov Bandage", items = {
      14530, 14529, 8545, 8544, 6451, 6450, 3531, 3530, 2581, 1251 } },
}

local GetCount = (C_Item and C_Item.GetItemCount) or GetItemCount
local IsUsable = (C_Item and C_Item.IsUsableItem) or IsUsableItem

local function Best(items)
  for _, id in ipairs(items) do
    if GetCount(id) > 0 and IsUsable(id) then return id end
  end
end

local pending = false
local lastBody = {}

local function UpdateOne(cat)
  local id = Best(cat.items)
  local index = GetMacroIndexByName(cat.macro)
  -- Don't spend a macro slot on a category you've never carried.
  if not id and index == 0 then return end
  local body = id and ("#showtooltip\n/use item:" .. id)
               or ("#showtooltip\n/run print('" .. P .. "no " .. cat.macro:sub(6):lower() .. " in bags')")
  if index > 0 and lastBody[cat.macro] == body then return end
  if index == 0 then
    local numGlobal = GetNumMacros()
    if numGlobal >= (MAX_ACCOUNT_MACROS or 120) then
      print(P .. "no free General macro slot for " .. cat.macro .. ".")
      return
    end
    CreateMacro(cat.macro, "INV_MISC_QUESTIONMARK", body, nil)
    print(P .. "created macro " .. cat.macro .. " - drag it from /macro to your bar.")
  else
    EditMacro(index, cat.macro, "INV_MISC_QUESTIONMARK", body)
  end
  lastBody[cat.macro] = body
end

local function Update()
  if InCombatLockdown() then pending = true return end
  pending = false
  for _, cat in ipairs(CATEGORIES) do UpdateOne(cat) end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_REGEN_ENABLED" and not pending then return end
  Update()
end)

SLASH_PROVISIONS1 = "/provisions"
SLASH_PROVISIONS2 = "/prov"
SlashCmdList.PROVISIONS = function()
  wipe(lastBody)
  Update()
  for _, cat in ipairs(CATEGORIES) do
    local id = Best(cat.items)
    print(P .. cat.macro .. " -> " .. (id and (select(2, GetItemInfo(id)) or ("item " .. id)) or "none"))
  end
end
