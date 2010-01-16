-- $Id$
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    featuredefs.lua
--  brief:   featuredef parser
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local featureDefs = {}

local shared = {} -- shared amongst the lua featuredef enviroments

local preProcFile  = 'gamedata/featuredefs_pre.lua'
local postProcFile = 'gamedata/featuredefs_post.lua'

local TDF = TDFparser or VFS.Include('gamedata/parse_tdf.lua')

local system = VFS.Include('gamedata/system.lua')

local function isbool(x)   return (type(x) == 'boolean') end
local function istable(x)  return (type(x) == 'table')   end
local function isnumber(x) return (type(x) == 'number')  end
local function isstring(x) return (type(x) == 'string')  end

local mapEnergyMult   = 0 --Used to normalize map features to a mod-specific scale
local mapMetalMult    = 0
local mapReclaimMult  = 1

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Run a pre-processing script if one exists
--

if (VFS.FileExists(preProcFile)) then
  Shared = shared  -- make it global
  FeatureDefs = featureDefs  -- make it global
  VFS.Include(preProcFile)
  FeatureDefs = nil
  Shared = nil
end



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Used in file processing
--

local modFeatures = {} --VFS.MAP vs. VFS.MOD broken as of May 2008

local function ProcessFeature(name, fd, archive)
  fd.filename = filename
  featureDefs[name] = fd
  --if archive == 'map' then
  if not modFeatures[name] then
    fd.reclaimTime = (fd.reclaimTime or ((fd.energy or 0) + (fd.metal or 0))) * mapReclaimMult
    if tonumber(fd.energy) then fd.energy = fd.energy * mapEnergyMult end
    if tonumber(fd.metal) then fd.metal = fd.metal * mapMetalMult end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Load the TDF featuredef files
--

local tdfFiles = RecursiveFileSearch('features/', '*.tdf') 

for _, filename in ipairs(tdfFiles) do
  local fds, err = TDF.Parse(filename)
  if (fds == nil) then
    Spring.Echo('Error parsing ' .. filename .. ': ' .. err)
  else
    for name, fd in pairs(fds) do
      fd.filename = filename
      featureDefs[name] = fd
    end
  end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Load the raw LUA format featuredef files
--  (these will override the TDF versions)
--

local luaFiles = RecursiveFileSearch('features/', '*.lua')

for _, filename in ipairs(luaFiles) do
  local fdEnv = {}
  fdEnv._G = fdEnv
  fdEnv.Shared = shared
  fdEnv.GetFilename = function() return filename end
  setmetatable(fdEnv, { __index = system })
  local success, fds = pcall(VFS.Include, filename, fdEnv)
  if (not success) then
    Spring.Echo('Error parsing ' .. filename .. ': ' .. fd)
  elseif (fds == nil) then
    Spring.Echo('Missing return table from: ' .. filename)
  else
    for fdName, fd in pairs(fds) do
      if ((type(fdName) == 'string') and (type(fd) == 'table')) then
        fd.filename = filename
        featureDefs[fdName] = fd
      end
    end
  end  
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  Run a post-processing script if one exists
--

if (VFS.FileExists(postProcFile)) then
  Shared = shared  -- make it global
  FeatureDefs = featureDefs  -- make it global
  VFS.Include(postProcFile)
  FeatureDefs = nil
  Shared = nil
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return featureDefs

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
