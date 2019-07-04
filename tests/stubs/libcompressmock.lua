-- Libs
local LibStub = _G.LibStub

local LibCompress = LibStub:NewLibrary("LibCompress", 90000)

local LibEncode = {}

function LibEncode:Encode(payload) return payload end
function LibEncode:Decode(payload) return payload end

function LibCompress:GetAddonEncodeTable() return LibEncode end

function LibCompress:CompressHuffman(payload) return payload end
function LibCompress:Decompress(payload) return payload end