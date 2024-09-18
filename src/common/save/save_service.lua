local FilesystemSave = require("src.common.save.FilesystemSave")

local saveService = {}

saveService.newSave = FilesystemSave.new
saveService.newTempSave = FilesystemSave.newTempSave
saveService.loadSave = FilesystemSave.open
saveService.hasSave = FilesystemSave.exists
saveService.listSaves = FilesystemSave.list

return saveService
