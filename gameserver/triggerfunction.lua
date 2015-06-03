local Util = require "gameserver.util"
local TriggerFunc = {
	TransferTo = function (self,avatar)
		--if self.disable then
		--	return
		--end
		local target_area = self.survive:GetArea(self.targetID)
		if target_area and  not target_area.Boomed then
			--self:Disable()
			--else
			avatar:TransferTo(self.targetPoint)
		end
	end,			
}

return TriggerFunc