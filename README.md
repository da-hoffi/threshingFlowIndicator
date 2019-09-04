# threshingFlowIndicator
lua script for FS19 to visualize the current threshing flow

Author: 		  HoFFi (modding-welt.com)
Remarks:		  Thanks to Zetor6245 for testing and providing his Claas Jaguar 800 Pack as guinea pig
				      Thanks to antonis78 who had the initial idea for this script and who gave me the motivation to continue with lua


Description: 	script to visualize the current threshing flow

Version: 		  1.0.2.0

Changelog: 		2019-08-08 	- initial release
				      2019-08-12 	- added more complex way of showing the current load (indicator bar with 13 lights)
				      2019-08-27 	- hud / help window text, has been improved
							- cutter load depends on…: fruit type, current speed, used width of cutter
							- max. speed of each fruit is easily adjustable in below
							- engine dies, warn sound is played and warning text is showed when driving too fast (allowed fruit speed + tolerance)
							- tolerance adjustable via xml (default 2kmh/mph)
							- “hardStop” (engine dies) can be turned off in xml


--------------------------------------------------------------------------------------------------
Mod-XML:

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
	showInHud = if true, current flow will be displayed in hud (help menu)
	hardStop = if true, motor stops if current speed is higher than allowed maximum speed for a fruit + maxSpeedOffset
	maxSpeedOffset = this value is added to the maximum allowed speed per fruit as tolerance before motor stops 
