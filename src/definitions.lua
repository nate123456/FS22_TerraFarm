---@class NodeLine
---@field startNode number
---@field endNode number
LineNode = {}

---@class Position
---@field x number
---@field y number
---@field z number
Position = {}

---@class LinePosition
---@field x1 number
---@field y1 number
---@field z1 number
---@field x2 number
---@field y2 number
---@field z2 number
LinePosition = {}

---@class MachineSpec
---@field type MachineType
---@field name string
---@field filePath string
---@field machine TerraFarmMachine
---@field actionEvents table
---@field machineConfig MachineXMLConfiguration
MachineSpec = {}

---@class MachineRootNodes
---@field terraform number
---@field collision number
---@field discharge number
---@field rotation number
---@field paint number
MachineRootNodes = {}

---@alias InputActionBindingName string | "'enableState'" | "'openMenu'" | "'toggleTerraformMode'" | "'toggleDischargeMode'"

---@alias InputActionText string | "'enableMachine'" | "'disableMachine'" | "'openMenu'" | "'toggleTerraformMode'" | "'toggleDischargeMode'"