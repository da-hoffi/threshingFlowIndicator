--[[ threshingFlowIndicator 

Author: 		HoFFi (modding-welt.com)
Remarks:		Thanks to Zetor6245 for testing and providing his Claas Jaguar 800 Pack as guinea pig
				Thanks to antonis78 who had the initial idea for this script and who gave me the motivation to continue with lua


Description: 	script to visualize the current threshing flow

Version: 		1.0.2.0

Changelog: 		2019-08-08 	- initial release
				2019-08-12 	- added more complex way of showing the current load (indicator bar with 13 lights)
				2019-08-27 	- hud / help window text, has been improved
							- cutter load depends on…: fruit type, current speed, used width of cutter
							- max. speed of each fruit is easily adjustable in below
							- engine dies, warn sound is played and warning text is showed when driving too fast (allowed fruit speed + tolerance)
							- tolerance adjustable via xml (default 2kmh/mph)
							- “hardStop” (engine dies) can be turned off in xml


--------------------------------------------------------------------------------------------------

XML:
	<threshingFlowIndicator indicatorBarNode="name of bar in i3d" showInHud="true" hardStop="true" maxSpeedOffset="2">
		<lights light1="greenstarON01" light2="greenstarON02" light3="greenstarON03" light4="greenstarON04" light5="greenstarON05" light6="greenstarON06" light7="greenstarON07" light8="greenstarON08" light9="greenstarON09" light10="greenstarON10" light11="greenstarON11" light12="greenstarON12" light13="greenstarON13" />
	</threshingFlowIndicator>
	
Moddesc:
	<specializations>
        <specialization name="threshingFlowIndicator" className="threshingFlowIndicator" filename="threshingFlowIndicator.lua"/>
    </specializations>
	
	<vehicleTypes>
		<type name="newVehicleTypeName" parent="...." filename="$dataS/scripts/vehicles/Vehicle.lua">
			....
			<specialization name="threshingFlowIndicator" />
		</type>
	</vehicleTypes>
	
	<l10n>
		<text name="TFIspeed"><en>Max. speed:</en><de>Max. Geschw.:</de></text>
		<text name="TFIcutterLoad"><en>Load (cutter):</en><de>Auslastung (Schneidwerk):</de></text>
		<text name="TFItooFast"><en>You drove too fast. Engine died.</en><de>Du bist zu schnell gefahren. Motor abgesoffen.</de></text>
	</l10n>
	
Explaination:
	indicatorBarNode = visual object (bar) to be scaled
	showInHud = if true, current flow will be displayed in hud (left upper corner)
	hardStop = if true, motor stops if current speed is higher than allowed maximum speed for a fruit + maxSpeedOffset
	maxSpeedOffset = this value is added to the maximum allowed speed per fruit as tolerance before motor stops

]]


threshingFlowIndicator = {};

threshingFlowIndicator.modDir = g_currentModDirectory;
threshingFlowIndicator.currentModName = g_currentModName;

function threshingFlowIndicator.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(Combine, specializations); 
end;

function threshingFlowIndicator.registerEventListeners(vehicleType)
	for _, spec in pairs({"onLoad", "onDelete", "onUpdate", "onDraw", "onReadStream", "onWriteStream"}) do
		SpecializationUtil.registerEventListener(vehicleType, spec, threshingFlowIndicator)
	end
end

function threshingFlowIndicator:onLoad(savegame)
	--Please only change the following values
	self.maxSpeedBARLEY = 8
	self.maxSpeedCANOLA = 8
	self.maxSpeedCOTTON = 6
	self.maxSpeedDRYGRASS = 11
	self.maxSpeedGRASS = 11
	self.maxSpeedGRASSWINDROW = 11
	self.maxSpeedMAIZE = 7
	self.maxSpeedOAT = 8
	self.maxSpeedPOPPLAR = 6    --not supported so far
	self.maxSpeedPOTATO = 6    --not tested
	self.maxSPeedSTRAW = 12
	self.maxSpeedSUGARBEET = 6    --not tested
	self.maxSpeedSUGARCANE = 6    --not tested
	self.maxSpeedSUNFLOWER = 11
	self.maxSpeedWHEAT = 8
	--Please DO NOT change the following values
	self.currentFruitSpeedLimit = 10
	self.lastFT = FruitType.UNKNOWN

	self.indicatorBarNode = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator#indicatorBarNode"), self.i3dMappings);
	self.showInHud = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.threshingFlowIndicator#showInHud"), true);
	self.hardStop = Utils.getNoNil(getXMLBool(self.xmlFile, "vehicle.threshingFlowIndicator#hardStop"), true);
	self.maxSpeedOffset = Utils.getNoNil(getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator#maxSpeedOffset"), "2");
	self.currentFlow = 0
	
	self.light1 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator.lights#light1"), self.i3dMappings);
	self.light2 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator.lights#light2"), self.i3dMappings);
	self.light3 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator.lights#light3"), self.i3dMappings);
	self.light4 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator.lights#light4"), self.i3dMappings);
	self.light5 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator.lights#light5"), self.i3dMappings);
	self.light6 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator.lights#light6"), self.i3dMappings);
	self.light7 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator.lights#light7"), self.i3dMappings);
	self.light8 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator.lights#light8"), self.i3dMappings);
	self.light9 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator.lights#light9"), self.i3dMappings);
	self.light10 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator.lights#light10"), self.i3dMappings);
	self.light11 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator.lights#light11"), self.i3dMappings);
	self.light12 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator.lights#light12"), self.i3dMappings);
	self.light13 = I3DUtil.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.threshingFlowIndicator.lights#light13"), self.i3dMappings);
	
	self.sampleWarn = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.threshingFlowIndicator", "warnSound", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
end;


function threshingFlowIndicator:onUpdate(dt)
	self.currentFruitSpeedLimit = 10;
	local spec = self.spec_combine
    if spec ~= nil then
		setVisibility(self.light1, false);
		setVisibility(self.light2, false);
		setVisibility(self.light3, false);
		setVisibility(self.light4, false);
		setVisibility(self.light5, false);
		setVisibility(self.light6, false);
		setVisibility(self.light7, false);
		setVisibility(self.light8, false);
		setVisibility(self.light9, false);
		setVisibility(self.light10, false);
		setVisibility(self.light11, false);
		setVisibility(self.light12, false);
		setVisibility(self.light13, false);
		setScale(self.indicatorBarNode, 1, 1, 0);
        if spec.numAttachedCutters > 0 then
			self.lastFT = spec.lastValidInputFruitType
            for cutter, _ in pairs(spec.attachedCutters) do
                if cutter.getCutterLoad ~= nil then
					if self.lastFT == FillType.BARLEY then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedBARLEY + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedBARLEY
					elseif self.lastFT == FillType.CANOLA then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedCANOLA + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedCANOLA
					elseif self.lastFT == FillType.COTTON then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedCOTTON + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedCOTTON
					elseif self.lastFT == FillType.DRYGRASS then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedDRYGRASS + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedDRYGRASS
					elseif self.lastFT == FillType.GRASS then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedGRASS + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedGRASS
					elseif self.lastFT == FillType.GRASSWINDROW then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedGRASSWINDROW + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedGRASSWINDROW
					elseif self.lastFT == FillType.MAIZE then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedMAIZE + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedMAIZE
					elseif self.lastFT == FillType.OAT then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedOAT + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedOAT
					elseif self.lastFT == FillType.POPPLAR then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedPOPPLAR + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedPOPPLAR
					elseif self.lastFT == FillType.POTATO then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedPOTATO + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedPOTATO
					elseif self.lastFT == FillType.STRAW then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedSTRAW + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedSUGARBEET
					elseif self.lastFT == FillType.SUGARBEET then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedSUGARBEET + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedSUGARBEET
					elseif self.lastFT == FillType.SUGARCANE then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedSUGARCANE + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedSUGARCANE
					elseif self.lastFT == FillType.SUNFLOWER then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedSUNFLOWER + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedSUNFLOWER
					elseif self.lastFT == FillType.WHEAT then
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (self.maxSpeedWHEAT + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = self.maxSpeedWHEAT
					else
						self.currentFlow = cutter:getCutterLoad() * (self:getLastSpeed() / (10 + self.maxSpeedOffset))
						self.currentFruitSpeedLimit = 10
						self.lastFT = FruitType.UNKNOWN
					end
						
					-- scale indicator bar according to current cutter flow
					if self.currentFlow > 1 then
						setScale(self.indicatorBarNode, 1, 1, 1);
					else
						setScale(self.indicatorBarNode, 1, 1, self.currentFlow);
					end
			
					-- turn on idicator LEDs according to current cutter flow
					if self.currentFlow > 0.09 then
						setVisibility(self.light1, true);
					end
					if self.currentFlow >= 0.18 then
						setVisibility(self.light2, true);
					end
					if self.currentFlow >= 0.27 then
						setVisibility(self.light3, true);
					end
					if self.currentFlow >= 0.36 then
						setVisibility(self.light4, true);
					end
					if self.currentFlow >= 0.45 then
						setVisibility(self.light5, true);
					end
					if self.currentFlow >= 0.54 then
						setVisibility(self.light6, true);
					end
					if self.currentFlow >= 0.63 then
						setVisibility(self.light7, true);
					end
					if self.currentFlow >= 0.72 then
						setVisibility(self.light8, true);
					end
					if self.currentFlow >= 0.81 then
						setVisibility(self.light9, true);
					end
					if self.currentFlow >= 0.9 then
						setVisibility(self.light10, true);
					end
					if self.currentFlow >= 0.93 then
						setVisibility(self.light11, true);
					end
					if self.currentFlow >= 0.96 then
						setVisibility(self.light12, true);
					end
					if self.currentFlow >= 1 then
						setVisibility(self.light13, true);
					end
							
					-- stop Motor if flow is too high
					if self.hardStop and self:getIsTurnedOn() then
						if self.currentFruitSpeedLimit ~= nil and self.currentFruitSpeedLimit > 0 then
							if self:getLastSpeed() > self.currentFruitSpeedLimit + self.maxSpeedOffset then
								if self.currentFlow > 0.1 then -- prevent motor from dieing if no fruit is been processed currently
									self:stopMotor()
									g_soundManager:playSample(self.spec_honk.sample)
									g_soundManager:stopSample(self.spec_honk.sample)
									g_currentMission:showBlinkingWarning(g_i18n:getText("TFItooFast"), 2000)
								end
							end
						end
					end
                end
            end
        end
    end
end;

function threshingFlowIndicator:onDelete()
end;

function threshingFlowIndicator:onReadStream(streamId, connection)
end;

function threshingFlowIndicator:onWriteStream(streamId, connection)
end;

function threshingFlowIndicator:onDraw(isActiveForInput, isSelected)
	if self.isClient then
		if isSelected then
			if self.showInHud then
				if fruitTypeIndex > 0 then
				--if self.lastFT ~= nil or self.lastFT ~= 0 then
					local fruitTypehud = g_fruitTypeManager:getFruitTypeByIndex(self.lastFT)
					if fruitTypehud ~= nil or fruitTypehud ~= 0 then
						text1 = fruitTypehud.fillType.title
					else
						text1 = " "
					end
				else
					text1 = " "
				end
				g_currentMission:addExtraPrintText(g_i18n:getText("TFIspeed") .. " " .. self.currentFruitSpeedLimit .. "km/h" .. " (" .. text1 .. ")" .. "    " .. g_i18n:getText("TFIcutterLoad") .. " " .. MathUtil.round(self.currentFlow*100, 1) .. "%")
			end
		end
	end
end