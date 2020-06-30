require 'muhkuh_cli_init'
local argparse = require 'argparse'

local atLogLevels = {
  'debug',
  'info',
  'warning',
  'error',
  'fatal'
}

local tParser = argparse('read trace messages', 'Read the netX ROM code trace messages to a file.')
tParser:argument('file')
  :description('Write the trace messages to FILE.')
  :argname('<FILE>')
  :target('strOutputFileName')
tParser:option('-v --verbose')
  :description(string.format('Set the verbosity level to LEVEL. Possible values for LEVEL are %s.', table.concat(atLogLevels, ', ')))
  :argname('<LEVEL>')
  :default('warning')
  :target('strLogLevel')

local tArgs = tParser:parse()

local tLogWriter = require 'log.writer.console.color'.new()
local tLog = require "log".new(
  tArgs.strLogLevel,
  tLogWriter,
  require "log.formatter.format".new()
)

_G.tester = require 'tester_cli'(tLog)
-- Ask the user to select a plugin.
_G.tester.fInteractivePluginSelection = true

-- Connect to the netX.
local tPlugin = _G.tester:getCommonPlugin(strPluginPattern)
if not tPlugin then
  error("No plugin selected, nothing to do!")
end

-- See which netX is connected.
local tAsicTyp = tPlugin:GetChiptyp()
local strAsicTyp = tostring(tPlugin:GetChiptypName(tAsicTyp))
local atNetxParameterAttributes = {
  [romloader.ROMLOADER_CHIPTYP_NETX50]        = false,
  [romloader.ROMLOADER_CHIPTYP_NETX100]       = false,
  [romloader.ROMLOADER_CHIPTYP_NETX500]       = false,
  [romloader.ROMLOADER_CHIPTYP_NETX10]        = false,
  [romloader.ROMLOADER_CHIPTYP_NETX56]        = false,
  [romloader.ROMLOADER_CHIPTYP_NETX56B]       = false,
--  [romloader.ROMLOADER_CHIPTYP_NETX90_MPW]    = { start=, size= },
  [romloader.ROMLOADER_CHIPTYP_NETX4000_FULL] = { start=0x050d0000, size=0x00010000 },
  [romloader.ROMLOADER_CHIPTYP_NETX90]        = { start=0x200a0000, size=0x00008000 },
  [romloader.ROMLOADER_CHIPTYP_NETX90B]       = { start=0x200a0000, size=0x00008000 }
}
local tAttr = atNetxParameterAttributes[tAsicTyp]
if tAttr==nil then
  tLog.error('The connected netX (%s) has an unknown type of %s.', strAsicTyp, tostring(tAsicTyp))
elseif tAttr==false then
  tLog.error('The connected netX (%s) does not provide trace messages.', strAsicTyp)
else
  tLog.info('Reading %s trace messages from [0x%08x,0x%08x]...', strAsicTyp, tAttr.start, tAttr.start+tAttr.size-1)
  local strData = _G.tester:stdRead(tPlugin, tAttr.start, tAttr.size)

  -- Write the data to a file.
  local strFilename = tArgs.strOutputFileName
  local tFile, strError = io.open(strFilename, 'wb')
  if tFile==nil then
    tLog.error('Failed to create the output file "%s": %s', strFilename, tostring(strError))
  else
    tFile:write(strData)
    tFile:close()
    tLog.info('Wrote the trace messages to the file "%s".', strFilename)
  end
end

tLog.info('')
tLog.info(' #######  ##    ## ')
tLog.info('##     ## ##   ##  ')
tLog.info('##     ## ##  ##   ')
tLog.info('##     ## #####    ')
tLog.info('##     ## ##  ##   ')
tLog.info('##     ## ##   ##  ')
tLog.info(' #######  ##    ## ')
tLog.info('')
