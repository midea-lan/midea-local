local bit = require "bit"
local JSON = require "cjson"
local keyT = {}
keyT["KEY_VERSION"] = "version"
keyT["KEY_POWER"] = "power"
keyT["KEY_STANDBY_CLEAN"] = "standby_clean"
keyT["KEY_ABILITY_TEST"] = "ability_test"
keyT["KEY_BUZZER"] = "buzzer"
keyT["KEY_NOWINDSENSE"] = "no_wind_sense"
keyT["KEY_DRY"] = "dry"
keyT["KEY_STRONG_WIND"] = "strong_wind"
keyT["KEY_MANUL_NEWWIND"] = "manul_fresh_air"
keyT["KEY_AUTO_NEWWIND"] = "fresh_air"
keyT["KEY_SWING_LR"] = "wind_swing_lr"
keyT["KEY_SWING_UD"] = "wind_swing_ud"
keyT["KEY_FORCE_COOL_MODE"] = "force_cool"
keyT["KEY_FORCE_AUTO_MODE"] = "force_auto"
keyT["KEY_PTC"] = "ptc"
keyT["KEY_PTC_DEPENDT4"] = "ptc_dependT4"
keyT["KEY_COOL_HOT_SENSE"] = "cool_hot_sense"
keyT["KEY_PREVENT_COLD"] = "prevent_cold"
keyT["KEY_WIND_STRAIGHT"] = "wind_straight"
keyT["KEY_WIND_AVOID"] = "wind_avoid"
keyT["KEY_DISINFECT"] = "disinfect"
keyT["KEY_ELEC_DUST_REMOVE"] = "elec_dust_remove"
keyT["KEY_SELFCLEAN"] = "self_clean"
keyT["KEY_ENERGY_SAVE"] = "energy_save"
keyT["KEY_AIR_OPTIMIZATION"] = "airoptimization"
keyT["KEY_NOBODY_ENERGY_SAVE"] = "nobody_energy_save"
keyT["KEY_AUTO_PURIFY"] = "inner_purifier"
keyT["KEY_MANUL_PURIFY"] = "manu_inner_purifier"
keyT["KEY_NO_WIND_SENSE_MODE"] = "no_wind_sense_mode"
keyT["KEY_RUN_TEST"] = "run_test"
keyT["KEY_FAST_CHECK"] = "fast_check"
keyT["KEY_AUTO_HUMI"] = "auto_humi"
keyT["KEY_MANUL_HUMI"] = "manul_humi"
keyT["KEY_WIND_STRENGTH"] = "wind_strength"
keyT["KEY_NEW_WIND_MACHINE"] = "new_wind_machine"
keyT["KEY_NEW_WIND_MACHINE_LINK"] = "new_wind_machine_link"
keyT["KEY_PROJECT_EVACUATE"] = "project_evacuate"
keyT["KEY_FOLLOW_BODY_SENSE"] = "follow_body_sense"
keyT["KEY_EXHAUST_STRENGTH"] = "exhaust_strength"
keyT["KEY_MODE"] = "mode"
keyT["KEY_TEMPERATURE"] = "temperature"
keyT["KEY_FANSPEED"] = "wind_speed"
keyT["KEY_DEHUMIDITY"] = "dehumidity"
keyT["KEY_PM25"] = "auto_purifier_on_pm"
keyT["KEY_CO2"] = "auto_fresh_on_co2"
keyT["KEY_HUMIDITY"] = "humidity"
keyT["KEY_NEWWIND_MODE"] = "fresh_air_setting_mode"
keyT["KEY_NEWWIND_FANSPEED"] = "fresh_air_fan_speed"
keyT["KEY_WATER_MODEL_POWER"] = "water_model_power"
keyT["KEY_WATER_MODEL_POWER_SAVE"] = "water_model_power_save"
keyT["KEY_WATER_MODEL_CLEAN"] = "water_model_clean"
keyT["KEY_WATER_MODEL_CLEAN_TIME"] = "water_model_clean_time"
keyT["KEY_WATER_MODEL_TEMPERATURE_AUTO"] = "water_model_temperature_auto"
keyT["KEY_WATER_MODEL_PTC"] = "water_model_ptc"
keyT["KEY_WATER_MODEL_GO_OUT"] = "water_model_go_out"
keyT["KEY_WATER_MODEL_TEMPERATURE_SET"] = "water_model_temperature_set"
keyT["KEY_WATER_MODEL_MODE_CLASH"] = "water_model_mode_clash"
keyT["KEY_HAS_HUIFENG"] = "has_huifeng"
keyT["KEY_HAS_CHUFENG"] = "has_chufeng"
keyT["KEY_HAS_WIND_LR"] = "has_wind_lr"
keyT["KEY_HAS_NO_WIND_SENSE"] = "has_no_wind_sense"
keyT["KEY_HAS_XINFENG"] = "has_xinfeng"
keyT["KEY_HAS_HUMIDIFER"] = "has_humidifer"
keyT["KEY_HAS_WATER_MODEL"] = "has_water_model"
keyT["KEY_AIR_OPTIMIZATION_TEMPERATURE"] = "airoptimization_temperature"
keyT["KEY_AIR_OPTIMIZATION_HUMIDITY"] = "airoptimization_humidity"
keyT["KEY_AIR_OPTIMIZATION_WIND"] = "airoptimization_speed"
keyT["KEY_SCREEN_DISPLAY"] = "screen_display"
keyT["KEY_FANSPEED_REAL"] = "wind_speed_real"
keyT["KEY_INDOOR_TEMPERATURE"] = "indoor_temperature"
keyT["KEY_OUTDOOR_TEMPERATURE"] = "outdoor_temperature"
keyT["KEY_INDOOR_PM24"] = "indoor_pm25"
keyT["KEY_INDOOR_CO2"] = "indoor_co2"
keyT["KEY_INDOOR_TVOC"] = "indoor_tvoc"
keyT["KEY_INDOOR_HUMIDITY"] = "indoor_humidity"
keyT["KEY_MODE_CLASH"] = "mode_clash"
keyT["KEY_FILTER_TIME"] = "filter_time"
keyT["KEY_PURIFY_FILTER_TIME"] = "purify_filter_time"
keyT["KEY_FRESH_FILTER_TIME"] = "fresh_filter_time"
keyT["KEY_FILTER_TIME_RESET"] = "filter_time_reset"
keyT["KEY_PURIFY_FILTER_TIME_RESET"] = "purify_filter_time_reset"
keyT["KEY_FRESH_FILTER_TIME_RESET"] = "fresh_filter_time_reset"
keyT["KEY_SELF_CLEAN_STATE"] = "self_clean_state"
keyT["KEY_SELF_CLEAN_RUN_TIME"] = "self_clean_run_time"
keyT["KEY_FRESH_LEVEL"] = "fresh_level"
keyT["KEY_PURIFIER_LEVEL"] = "purifier_level"
keyT["KEY_HUMIDITY_LEVEL"] = "humidity_level"
keyT["KEY_TEMPERATURE_LEVEL"] = "temperature_level"
keyT["KEY_TOVC_LEVEL"] = "tvoc_level"
keyT["KEY_TOTAL_AIR_LEVEL"] = "total_air_level"
keyT["KEY_FRESH_AIR_MACHINE_NUMBER"] = "fresh_air_machine_number"
keyT["KEY_HUMIDITY_MACHINE_NUMBER"] = "humidity_machine_number"
keyT["KEY_RETURN_AIR_PANEL_SELECT"] = "return_air_panel_select"
keyT["KEY_AIR_PANEL_SELECT"] = "air_panel_select"
keyT["KEY_NO_WIND_SENSE_SELECT"] = "no_wind_sense_select"
keyT["KEY_WIND_LEFT_RIGHT_SELECT"] = "wind_left_right_select"
keyT["KEY_POWER_OFF_TIMER"] = "power_off_timer"
keyT["KEY_POWER_ON_TIMER"] = "power_on_timer"
keyT["KEY_CLOSE_TIME"] = "power_off_time_value"
keyT["KEY_OPEN_TIME"] = "power_on_time_value"
local keyV = {}
keyV["VALUE_VERSION"] = 8
keyV["VALUE_FUNCTION_ON"] = "on"
keyV["VALUE_FUNCTION_OFF"] = "off"
keyV["VALUE_MODE_HEAT"] = "heat"
keyV["VALUE_MODE_COOL"] = "cool"
keyV["VALUE_MODE_AUTO"] = "auto"
keyV["VALUE_MODE_DRY"] = "dry"
keyV["VALUE_MODE_FAN"] = "fan"
keyV["VALUE_MODE_STANDBY"] = "standby"
keyV["VALUE_MODE_DRYCONSTANT"] = "dryconstant"
keyV["VALUE_MODE_DRYAUTO"] = "dryauto"
local deviceSubType = 0
local deviceSN8 = "00000000"
local keyB = {}
keyB["BYTE_DEVICE_TYPE"] = 0xAC
keyB["BYTE_CONTROL_REQUEST"] = 0x20
keyB["BYTE_CONTROL_RESET_REQUEST"] = 0xAB
keyB["BYTE_QUERYL_REQUEST"] = 0x11
keyB["BYTE_QUERY_RUN_REQUEST"] = 0x10
keyB["BYTE_QUERY_WATER_RUN_REQUEST"] = 0x12
keyB["BYTE_QUERY_OUT_RUN_REQUEST"] = 0x30
keyB["BYTE_PROTOCOL_HEAD"] = 0xAA
keyB["BYTE_PROTOCOL_LENGTH"] = 0x03
keyB["BYTE_COMMON_ON"] = 0x01
keyB["BYTE_COMMON_OFF"] = 0x00
keyB["BYTE_POWER_ON"] = 0x01
keyB["BYTE_POWER_OFF"] = 0x00
keyB["BYTE_MODE_AUTO"] = 0x04
keyB["BYTE_MODE_COOL"] = 0x00
keyB["BYTE_MODE_DRY"] = 0x01
keyB["BYTE_MODE_HEAT"] = 0x03
keyB["BYTE_MODE_FAN"] = 0x02
keyB["BYTE_MODE_STANDBY"] = 0x05
keyB["BYTE_MODE_DRYCONSTANT"] = 0x06
keyB["BYTE_MODE_DRYAUTO"] = 0x07
keyB["BYTE_FANSPEED_AUTO"] = 0x66
keyB["BYTE_FANSPEED_HIGH"] = 0x50
keyB["BYTE_FANSPEED_MID"] = 0x3C
keyB["BYTE_FANSPEED_LOW"] = 0x28
keyB["BYTE_FANSPEED_MUTE"] = 0x14
keyB["BYTE_CONTROL_CMD"] = 0x40
local keyP = {}
keyP["powerValue"] = 0
keyP["power"] = 0
keyP["standby_clean"] = 0
keyP["buzzerValue"] = 0
keyP["no_wind_sense"] = 0
keyP["dryValue"] = 0
keyP["strongWindValue"] = 0
keyP["manulNewWind"] = 0
keyP["autoNewWind"] = 0
keyP["swingLeftUDValue"] = 0
keyP["swingRightUDValue"] = 0
keyP["swingUpLRValue"] = 0
keyP["swingDownLRValue"] = 0
keyP["forceCoolMode"] = 0
keyP["forceAutoMode"] = 0
keyP["PTCValue"] = 0
keyP["PTCDependT4Value"] = 0
keyP["cool_hot_sense"] = 0
keyP["preventCold"] = 0
keyP["wind_straight"] = 0
keyP["wind_avoid"] = 0
keyP["disinfect"] = 0
keyP["elecDustRemove"] = 0
keyP["self_clean"] = 0
keyP["energySaveValue"] = 0
keyP["air_optimization"] = 0
keyP["nobody_energy_save"] = 0
keyP["autoPurify"] = 0
keyP["manuPurify"] = 0
keyP["no_wind_sense_mode"] = 0
keyP["run_test"] = 0
keyP["fast_check"] = 0
keyP["autoHumi"] = 0
keyP["manuHumi"] = 0
keyP["wind_strength"] = 0
keyP["new_wind_machine"] = 0
keyP["new_wind_machine_link"] = 0
keyP["project_evacuate"] = 0
keyP["follow_body_sense"] = 0
keyP["exhaust_strength"] = 0
keyP["modeValue"] = 0
keyP["temperature"] = 0
keyP["small_temperature"] = 0
keyP["fanspeedValue"] = 0
keyP["deHumidityValue"] = 0
keyP["pm25LowValue"] = 0
keyP["pm25HighValue"] = 0
keyP["co2LowValue"] = 0
keyP["co2HighValue"] = 0
keyP["humidityValue"] = 0
keyP["newWindModeValue"] = 0
keyP["newWindSpeedValue"] = 0
keyP["water_model_power"] = 0
keyP["water_model_power_save"] = 0
keyP["water_model_clean"] = 0
keyP["water_model_clean_time"] = 0
keyP["water_model_temperature_auto"] = 0
keyP["water_model_ptc"] = 0
keyP["water_model_go_out"] = 0
keyP["water_model_temperature_set"] = 0
keyP["water_model_mode_clash"] = 0
keyP["air_optimization_temperature"] = 0
keyP["air_optimization_humidity"] = 0
keyP["air_optimization_wind"] = 0
keyP["fanspeedRealValue"] = 0
keyP["indoorTemperature"] = 0
keyP["indoorPm25"] = 0
keyP["indoorCo2"] = 0
keyP["indoorTvoc"] = 0
keyP["indoorHumidity"] = 0
keyP["modeClashValue"] = 0
keyP["filterTime"] = 0
keyP["purifyFilterTime"] = 0
keyP["freshFilterTime"] = 0
keyP["filterTimeReset"] = 0
keyP["purifyFilterTimeReset"] = 0
keyP["freshFilterTimeReset"] = 0
keyP["selfCleanState"] = 0
keyP["selfCleanRunTime"] = 0
keyP["freshLevel"] = 0
keyP["purifierLevel"] = 0
keyP["humidityLevel"] = 0
keyP["temperatureLevel"] = 0
keyP["tvocLevel"] = 0
keyP["totalAirLevel"] = 0
keyP["returnAirPanelSelect"] = 0
keyP["airPanelSelect"] = 0
keyP["noWindSenseSelect"] = 0
keyP["windLeftRightSelect"] = 0
keyP["has_purifier"] = 0
keyP["humidifier_water_tank"] = 0
keyP["auto_piping"] = 0
keyP["force_drainage"] = 0
keyP["prevent_condensation"] = 0
keyP["water_tank_load"] = 0
keyP["humidifier_over_flow_protect"] = 0
keyP["heat_water_tank_protect"] = 0
keyP["voltage_protect"] = 0
keyP["ptc_protect"] = 0
keyP["electric_leakage_protect"] = 0
keyP["machine_electric_protect"] = 0
keyP["relay_bonding_fault"] = 0
keyP["humidifier_freezing_protect"] = 0
keyP["error_linking_fault"] = 0
keyP["zero_point_fault"] = 0
keyP["humidity_sensor_lock"] = 0
keyP["drain_valve_leakage"] = 0
keyP["hydrate_valve_leakage"] = 0
keyP["linking_humidifier_address"] = 0
keyP["humidifier_temp_low"] = 0
keyP["humidifier_temp_high"] = 0
keyP["humidity_drainage"] = 0
keyP["humidity_drainage_flag"] = 0
keyP["humidity_sensor_fault"] = 0
keyP["humidifier_communicate_fault"] = 0
keyP["pm_sensor_chosen"] = 0
keyP["co2_sensor_chosen"] = 0
keyP["tvoc_sensor_chosen"] = 0
keyP["pyroelectricity_sensor_chosen"] = 0
keyP["thermopile_sensor_chosen"] = 0
keyP["timer_enable"] = 0
keyP["outdoorTemperature"] = 0
keyP["freshAirMachineNumber"] = 0
keyP["humidityMachineNumber"] = 0
keyP["errorCode"] = 0
keyP["indoor_e"] = 0
keyP["indoor_e_parameter"] = 0
keyP["in_out_transport"] = 0
keyP["indoor_communication_lost"] = 0
keyP["indoor_fan_lose_speed"] = 0
keyP["indoor_new_wind_device"] = 0
keyP["outdoor_new_wind_device"] = 0
keyP["outdoor_e"] = 0
keyP["sensor_t3"] = 0
keyP["sensor_t4"] = 0
keyP["sensor_tp"] = 0
keyP["sensor_outdoor_ipm_temp"] = 0
keyP["sensor_refrigerant_pipe_temp"] = 0
keyP["sensor_cold_temp"] = 0
keyP["sensor_inhale_temp"] = 0
keyP["sensor_spray_enthalpy_enter_temp"] = 0
keyP["sensor_spray_enthalpy_out_temp"] = 0
keyP["sensor_high_pressure"] = 0
keyP["sensor_low_pressure"] = 0
keyP["sensor_t1"] = 0
keyP["sensor_t2"] = 0
keyP["new_wind_temp_sensor"] = 0
keyP["wire_controller_temp_sensor"] = 0
keyP["sensor_t2a_indoor"] = 0
keyP["sensor_t2b_indoor"] = 0
keyP["sensor_t2c_indoor"] = 0
keyP["sensor_t2d_indoor"] = 0
keyP["outdoor_fan_lose_speed"] = 0
keyP["four_way_valve_crossing"] = 0
keyP["wire_controller_indoor_transport"] = 0
keyP["indoor_smart_eye_transport"] = 0
keyP["indoor_pyroelectric_sensor"] = 0
keyP["indoor_return_panel_transport"] = 0
keyP["indoor_outlet_panel_transport"] = 0
keyP["refrigerant_leakage"] = 0
keyP["indoor_water_alarm"] = 0
keyP["indoor_smart_eye"] = 0
keyP["ammeter"] = 0
keyP["in_out_ability_mismatch"] = 0
keyP["outdoor_ipm"] = 0
keyP["voltage_protect_low"] = 0
keyP["voltage_protect_high"] = 0
keyP["out_voltage_protect"] = 0
keyP["voltage_protect"] = 0
keyP["compressor_temp_protect"] = 0
keyP["out_main_drive_transport"] = 0
keyP["compressor_current_circuit"] = 0
keyP["compressor_start"] = 0
keyP["phase_lost_protect"] = 0
keyP["compressor_zero_protect"] = 0
keyP["out_341_sync"] = 0
keyP["compressor_lose_speed_protect"] = 0
keyP["compressor_over_current"] = 0
keyP["compressor_position_protect"] = 0
keyP["compressor_high_temp_protect"] = 0
keyP["out_current_protect"] = 0
keyP["prevent_cold_wind_protect"] = 0
keyP["water_full_protect"] = 0
keyP["four_way_valve_crossing_protect"] = 0
keyP["pfc_switch_stop"] = 0
keyP["system_pressure_high_protect"] = 0
keyP["system_pressure_low_protect"] = 0
keyP["system_pressure_low_error"] = 0
keyP["system_pressure_high_error"] = 0
keyP["system_pressure_protect"] = 0
keyP["evaporator_temp_high_protect"] = 0
keyP["evaporator_temp_low_protect"] = 0
keyP["new_wind_pm_high_protect"] = 0
keyP["new_wind_out_temp_high_protect"] = 0
keyP["new_wind_out_temp_low_protect"] = 0
keyP["new_wind_anti_condensation_protect"] = 0
keyP["new_wind_low_anti_condensation_protect"] = 0
keyP["grid_protect"] = 0
keyP["refrigerant_tube_condensation"] = 0
keyP["indoor_hum_sensor"] = 0
keyP["new_wind_hum_sensor"] = 0
keyP["pm2_5_sensor"] = 0
keyP["co2_sensor"] = 0
keyP["tvoc_sensor"] = 0
keyP["new_wind_pm2_5_sensor"] = 0
keyP["evaporator_temp_fre_limit"] = 0
keyP["new_wind_pm_high"] = 0
keyP["new_wind_out_low_temp"] = 0
keyP["condenser_high_temp_fre_limit"] = 0
keyP["exhaust_high_temp_fre_limit"] = 0
keyP["voltage_fre_limit"] = 0
keyP["current_fre_limit"] = 0
keyP["pfc_fre_limit"] = 0
keyP["system_pressure_high_fre_limit"] = 0
keyP["system_pressure_low_fre_limit"] = 0
keyP["mode_conflict"] = 0
keyP["new_wind_transport"] = 0
keyP["outdoor_exhaust_high_temp_fault"] = 0
keyP["refrigerant_tube_condensation_fault"] = 0
keyP["system_pressure_low_pressure_fault"] = 0
keyP["indoor_e_water_heat"] = 0
keyP["indoor_e_parameter_water_heat"] = 0
keyP["in_out_transport_water_heat"] = 0
keyP["tr_out_fault"] = 0
keyP["tr_in_fault"] = 0
keyP["dc_pump_stall_protection"] = 0
keyP["water_switch_protection"] = 0
keyP["water_switch_fault"] = 0
keyP["tw_in_fault"] = 0
keyP["tw_out_fault"] = 0
keyP["tw1_fault"] = 0
keyP["tw1b_fault"] = 0
keyP["standby_anti_freezing_fault"] = 0
keyP["temp_sensor_drop_fault"] = 0
keyP["water_templow_protection"] = 0
keyP["standby_anti_freezing_protection"] = 0
keyP["humidity_enabling"] = 0
keyP["power_on_timer"] = 0
keyP["power_off_timer"] = 0
keyP["sn8_string"] = "00000000"
keyP["sn8_flag"] = 0
keyP["power_on_time_value"] = 0
keyP["power_off_time_value"] = 0
keyP["display_status"] = 0
keyP["mute_voice"] = 0
keyP["low_power_cost"] = 0
keyP["dry_clean"] = 0
keyP["communication_fault"] = 0
keyP["smart_eye"] = 0
keyP["horizontal_swing_left"] = 0
keyP["horizontal_swing_right"] = 0
keyP["vertical_swing_left"] = 0
keyP["vertical_swing_right"] = 0
keyP["ac_switch"] = 0
keyP["solar_eco"] = 0
keyP["force_defrost"] = 0
keyP["do_not_disturb"] = 0
keyP["remove_dust_full"] = 0
keyP["clear_filter_change_time"] = 0
keyP["self_wash"] = 0
keyP["advance_cold_hot"] = 0
keyP["rui_wind"] = 0
keyP["set_i_mode"] = 0
keyP["save_i_mode"] = 0
keyP["reset_electricity"] = 0
keyP["high_save_power"] = 0
keyP["elec_fast_check"] = 0
keyP["total_fast_check"] = 0
keyP["elec_dust_collect"] = 0
keyP["huanqi_function"] = 0
keyP["light_level"] = 0
keyP["natural_wind"] = 0
keyP["leave_home"] = 0
keyP["child_comfort_sleep"] = 0
keyP["try_run"] = 0
keyP["prevent_water_enable"] = 0
keyP["display_receive_control_button"] = 0
keyP["comfort_sleep"] = 0
keyP["pmv"] = 0
keyP["eco"] = 0
keyP["eight_degree_heat"] = 0
keyP["eight_degree_heat_remember"] = 0
keyP["buzzer_param"] = 1
keyP["display_wind_percent"] = 0
keyP["display_band_limited"] = 0
keyP["dr_function"] = 0
keyP["second_temperature_setting"] = 0
keyP["up_down_wind_direction"] = 0
keyP["left_right_wind_direction"] = 0
keyP["water_washing"] = 0
keyP["mosquito_repellent"] = 0
keyP["comfort_save"] = 0
keyP["x_fan_control"] = 0
keyP["prevent_straight_wind"] = 0
keyP["gentle_wind_sense"] = 0
keyP["child_prevent_cold_wind_child"] = 0
keyP["child_prevent_cold_wind_parent"] = 0
keyP["no_wind_sense_up"] = 0
keyP["no_wind_sense_down"] = 0
keyP["permanent_wind"] = 0
keyP["temperature_unit"] = 0
keyP["permanent_wind"] = 0
keyP["smart_wind_left_degree"] = 0
keyP["smart_wind_right_degree"] = 0
keyP["auto_water_washing"] = 0
keyP["manul_water_washing"] = 0
keyP["water_washing_control"] = 0
keyP["ud_wind_accelerate"] = 0
keyP["lr_wind_accelerate"] = 0
keyP["prevent_trip"] = 0
keyP["smart_temperature_control"] = 0
keyP["timer_message"] = 0
keyP["lock"] = 0
keyP["remote_control"] = 0
keyP["child_prevent_cold_wind"] = 0
keyP["double_water_washing"] = 0
keyP["deep_clean"] = 0
keyP["extreme_wind"] = 0
keyP["fn_no_wind_sense"] = 0
keyP["fresh_air_wind_precent"] = 0
keyP["auto_wash_time"] = 0
keyP["energy_save"] = 0
keyP["compressor"] = 0
keyP["four_way_value"] = 0
keyP["elec_heating_1"] = 0
keyP["elec_heating_2"] = 0
keyP["up_wind_machine_low"] = 0
keyP["up_wind_machine_medium"] = 0
keyP["up_wind_machine_high"] = 0
keyP["front_end_control_fc"] = 0
keyP["energy_save_xiaotiane"] = 0
keyP["ap_mode"] = 0
keyP["remove_arofene"] = 0
keyP["remove_peculiar_smell"] = 0
keyP["right_ud_wind"] = 0
keyP["no_wind_sense_left"] = 0
keyP["no_wind_sense_right"] = 0
keyP["wind_swing_left"] = 0
keyP["wind_swing_right"] = 0
keyP["comfort_fresh_air"] = 0
keyP["fresh_air_setting_mode"] = 0
keyP["remove_odor_time_low"] = 0
keyP["remove_odor_time_high"] = 0
keyP["scene_id"] = 0
keyP["down_wind_speed_level"] = 0
keyP["prevent_cold_child"] = 0
keyP["ability_test"] = 0
keyP["closeHour"] = 0
keyP["closeStepMintues"] = 0
keyP["closeMin"] = 0
keyP["closeTime"] = 0
keyP["openHour"] = 0
keyP["openStepMintues"] = 0
keyP["openMin"] = 0
keyP["openTime"] = 0
keyP["wind_speed_real"] = 0
keyP["wind_speed_real_ac"] = 0
keyP["tunnel_status"] = 0
keyP["category_tag"] = 0
keyP["filter_available_time"] = 0
keyP["filter_used_time"] = 0
keyP["t1_temp"] = 0
keyP["t2_temp"] = 0
keyP["t3_temp"] = 0
keyP["t4_temp"] = 0
keyP["disinfect_time"] = 0
keyP["wet_film_time"] = 0
keyP["filter_time"] = 0
keyP["disinfect_setting_time"] = 0
keyP["auto_purifier_on_pm"] = 0
keyP["auto_purifier_off_pm"] = 0
keyP["auto_fresh_on_co2"] = 0
keyP["auto_fresh_off_co2"] = 0
keyP["humi_on_value"] = 0
keyP["humi_off_value"] = 0
keyP["outdoor_pm"] = 0
keyP["manul_humi_value"] = 0
keyP["right_wind_speed"] = 0
keyP["left_wind_speed_target_value"] = 0
keyP["right_wind_speed_target_value"] = 0
keyP["humidity_value"] = 0
keyP["rfid_tunnel_0"] = 0
keyP["rfid_tunnel_1"] = 0
keyP["rfid_tunnel_2"] = 0
keyP["rfid_tunnel_3"] = 0
keyP["rfid_tunnel_4"] = 0
keyP["rfid_tunnel_5"] = 0
keyP["rfid_tunnel_tag_0"] = 0
keyP["rfid_tunnel_tag_1"] = 0
keyP["rfid_tunnel_tag_2"] = 0
keyP["rfid_tunnel_tag_3"] = 0
keyP["rfid_tunnel_tag_4"] = 0
keyP["rfid_tunnel_tag_5"] = 0
keyP["voice_control"] = 1
keyP["dust_co2"] = 0
keyP["co2_concentration"] = 0
keyP["prevent_straight_wind_lr"] = 0
keyP["down_wind_left_switch"] = 1
keyP["down_wind_right_switch"] = 1
keyP["auto_comfort_fresh_air"] = 0
keyP["ac_filter_time"] = 0
keyP["air_exhaust"] = 0
keyP["water_tank_board"] = 0
keyP["water_tank_water"] = 0
keyP["indoor_e0_fault"] = 0
keyP["indoor_ea_fault"] = 0
keyP["indoor_e3_fault"] = 0
keyP["indoor_e3_1_fault"] = 0
keyP["indoor_fe_fault"] = 0
keyP["outdoor_e51_fault"] = 0
keyP["outdoor_e52_fault"] = 0
keyP["outdoor_e53_fault"] = 0
keyP["outdoor_e54_fault"] = 0
keyP["indoor_e60_fault"] = 0
keyP["indoor_e61_fault"] = 0
keyP["indoor_e7_fault"] = 0
keyP["indoor_eb_fault"] = 0
keyP["rfid_fault"] = 0
keyP["pl_fault"] = 0
keyP["p1_fault"] = 0
keyP["p0_fault"] = 0
keyP["p2_fault"] = 0
keyP["p4_fault"] = 0
keyP["fresh_ptc_load"] = 0
keyP["total_air_level"] = 0
keyP["humidity_level"] = 0
keyP["purifier_level"] = 0
keyP["fresh_level"] = 0
keyP["tvoc_level"] = 0
keyP["acstrainer_sw"] = 0
keyP["outdoor_e7_fault"] = 0
keyP["indoor_eb1_fault"] = 0
keyP["defrosting"] = 0
keyP["down_humidity"] = 0
keyP["re_elec_heat"] = 0
keyP["eb1_fault"] = 0
keyP["humi_flag"] = 0
keyP["display_scene_id"] = 0
keyP["control_flag"] = 0
keyP["total_control"] = 0
keyP["version_number"] = 0
keyP["self_clean_time"] = 0
keyP["clean_running_stage"] = 0
keyP["scene_id_f1"] = 0
keyP["temp_algorithm"] = 0
keyP["humidity_algorithm"] = 0
keyP["pm2_5_algorithm"] = 0
keyP["co2_algorithm"] = 0
keyP["main_control_software_version"] = 0
keyP["main_control_parm_version"] = 0
keyP["out_machine_parm_version"] = 0
keyP["recommend_mode_switch"] = 0
keyP["current_wind_speed"] = 0
keyP["current_down_wind_speed"] = 0
keyP["full_time_hour"] = 0
keyP["full_time_min"] = 0
keyP["limit_dry_switch_set"] = 0
keyP["prevent_super_cool"] = 0
keyP["last_humidity"] = 0
keyP["rewarming_dry"] = 0
keyP["has_rewarming_dry"] = 0
keyP["has_xinfeng"] = 1
keyP["has_huifeng"] = 1
keyP["has_chufeng"] = 1
keyP["has_water_model"] = 1
local dataType = 0
local function print_lua_table(lua_table, indent)
    indent = indent or 0
    for k, v in pairs(lua_table) do
        if type(k) == "string" then k = string.format("%q", k) end
        local szSuffix = ""
        if type(v) == "table" then szSuffix = "{" end
        local szPrefix = string.rep("    ", indent)
        formatting = szPrefix .. "[" .. k .. "]" .. " = " .. szSuffix
        if type(v) == "table" then
            print(formatting)
            print_lua_table(v, indent + 1)
            print(szPrefix .. "},")
        else
            local szValue = ""
            if type(v) == "string" then
                szValue = string.format("%q", v)
            else
                szValue = tostring(v)
            end
            print(formatting .. szValue .. ",")
        end
    end
end
local function checkBoundary(data, min, max)
    if (not data) then data = 0 end
    data = tonumber(data)
    if (data == nil) then data = 0 end
    if ((data >= min) and (data <= max)) then
        return data
    else
        if (data < min) then
            return min
        else
            return max
        end
    end
end
local function table2string(cmd)
    local ret = ""
    local i
    for i = 1, #cmd do ret = ret .. string.char(cmd[i]) end
    return ret
end
local function string2table(hexstr)
    local tb = {}
    local i = 1
    local j = 1
    for i = 1, #hexstr - 1, 2 do
        local doublebytestr = string.sub(hexstr, i, i + 1)
        tb[j] = tonumber(doublebytestr, 16)
        j = j + 1
    end
    return tb
end
local function string2hexstring(str)
    local ret = ""
    for i = 1, #str do ret = ret .. string.format("%02x", str:byte(i)) end
    return ret
end
local function encode(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.encode(cmd)
    return tb
end
local function decode(cmd)
    local tb
    if JSON == nil then JSON = require "cjson" end
    tb = JSON.decode(cmd)
    return tb
end
local function makeSum(tmpbuf, start_pos, end_pos)
    local resVal = 0
    for si = start_pos, end_pos do
        resVal = resVal + tmpbuf[si]
        if resVal > 0xff then resVal = bit.band(resVal, 0xff) end
    end
    resVal = bit.band(255 - resVal + 1, 0xff)
    return resVal
end
local crc8_854_table = {
    0, 94, 188, 226, 97, 63, 221, 131, 194, 156, 126, 32, 163, 253, 31, 65, 157,
    195, 33, 127, 252, 162, 64, 30, 95, 1, 227, 189, 62, 96, 130, 220, 35, 125,
    159, 193, 66, 28, 254, 160, 225, 191, 93, 3, 128, 222, 60, 98, 190, 224, 2,
    92, 223, 129, 99, 61, 124, 34, 192, 158, 29, 67, 161, 255, 70, 24, 250, 164,
    39, 121, 155, 197, 132, 218, 56, 102, 229, 187, 89, 7, 219, 133, 103, 57,
    186, 228, 6, 88, 25, 71, 165, 251, 120, 38, 196, 154, 101, 59, 217, 135, 4,
    90, 184, 230, 167, 249, 27, 69, 198, 152, 122, 36, 248, 166, 68, 26, 153,
    199, 37, 123, 58, 100, 134, 216, 91, 5, 231, 185, 140, 210, 48, 110, 237,
    179, 81, 15, 78, 16, 242, 172, 47, 113, 147, 205, 17, 79, 173, 243, 112, 46,
    204, 146, 211, 141, 111, 49, 178, 236, 14, 80, 175, 241, 19, 77, 206, 144,
    114, 44, 109, 51, 209, 143, 12, 82, 176, 238, 50, 108, 142, 208, 83, 13,
    239, 177, 240, 174, 76, 18, 145, 207, 45, 115, 202, 148, 118, 40, 171, 245,
    23, 73, 8, 86, 180, 234, 105, 55, 213, 139, 87, 9, 235, 181, 54, 104, 138,
    212, 149, 203, 41, 119, 244, 170, 72, 22, 233, 183, 85, 11, 136, 214, 52,
    106, 43, 117, 151, 201, 74, 20, 246, 168, 116, 42, 200, 150, 21, 75, 169,
    247, 182, 232, 10, 84, 215, 137, 107, 53
}
local function crc8_854(dataBuf, start_pos, end_pos)
    local crc = 0
    for si = start_pos, end_pos do
        crc = crc8_854_table[bit.band(bit.bxor(crc, dataBuf[si]), 0xFF) + 1]
    end
    return crc
end
local function JsonToModel(jsonCmd, jsonType)
    local streams = jsonCmd
    if (streams["power"] ~= nil) then
        if (streams["power"] == "on") then
            keyP["power"] = 0x01
        else
            keyP["power"] = 0x00
        end
    end
    if (streams["power"] ~= nil and jsonType == "control") then
        if (streams["power"] == "on") then
            keyP["power"] = 0x01
            keyP["water_washing"] = 0
            keyP["PTCValue"] = 1
            keyP["standby_clean"] = 0
            keyP["power_on_timer"] = 0
        else
            keyP["power"] = 0x00
            keyP["fanspeedValue"] = 102
            keyP["right_wind_speed"] = 102
            keyP["up_down_wind_direction"] = 0
            keyP["left_right_wind_direction"] = 0
            keyP["strongWindValue"] = 0
            keyP["vertical_swing_left"] = 0
            keyP["vertical_swing_right"] = 0
            keyP["horizontal_swing_left"] = 0
            keyP["horizontal_swing_right"] = 0
            keyP["no_wind_sense_left"] = 0
            keyP["no_wind_sense_right"] = 0
            keyP["water_washing"] = 0
            keyP["PTCValue"] = 0
            keyP["try_run"] = 0
            keyP["power_off_timer"] = 0
            keyP["rewarming_dry"] = 0
        end
    end
    if (streams[keyT["KEY_STANDBY_CLEAN"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["standby_clean"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_STANDBY_CLEAN"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["standby_clean"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_STANDBY_CLEAN"]] == keyV["VALUE_FUNCTION_ON"] and
        jsonType == "control") then
        keyP["standby_clean"] = keyB["BYTE_COMMON_ON"]
        keyP["power"] = 0
        keyP["strongWindValue"] = 0
        keyP["vertical_swing_left"] = 0
        keyP["vertical_swing_right"] = 0
        keyP["horizontal_swing_left"] = 0
        keyP["horizontal_swing_right"] = 0
        keyP["no_wind_sense_left"] = 0
        keyP["no_wind_sense_right"] = 0
        keyP["PTCValue"] = 0
        keyP["power_off_timer"] = 0
        keyP["autoNewWind"] = 0
        keyP["huanqi_function"] = 0
        keyP["comfort_fresh_air"] = 0
        keyP["auto_comfort_fresh_air"] = 0
        keyP["autoHumi"] = 0
        keyP["manuHumi"] = 0
        keyP["autoPurify"] = 0
        keyP["manuPurify"] = 0
        keyP["disinfect"] = 0
        keyP["remove_arofene"] = 0
        keyP["remove_peculiar_smell"] = 0
        keyP["air_exhaust"] = 0
        keyP["water_washing"] = 0
        keyP["scene_id"] = 0
    elseif (streams[keyT["KEY_STANDBY_CLEAN"]] == keyV["VALUE_FUNCTION_OFF"] and
        jsonType == "control") then
        keyP["standby_clean"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_BUZZER"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["buzzerValue"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_BUZZER"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["buzzerValue"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_NOWINDSENSE"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["no_wind_sense"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_NOWINDSENSE"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["no_wind_sense"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_DRY"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["dryValue"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_DRY"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["dryValue"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_STRONG_WIND"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["strongWindValue"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_STRONG_WIND"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["strongWindValue"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_MANUL_NEWWIND"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["manulNewWind"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_MANUL_NEWWIND"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["manulNewWind"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_AUTO_NEWWIND"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["autoNewWind"] = keyB["BYTE_COMMON_ON"]
        keyP["water_washing"] = 0
        keyP["manuPurify"] = 1
        keyP["remove_arofene"] = 1
        keyP["air_exhaust"] = 0
        keyP["remove_peculiar_smell"] = 1
        keyP["standby_clean"] = 0
    elseif (streams[keyT["KEY_AUTO_NEWWIND"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["autoNewWind"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_SWING_UD"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["swingLeftUDValue"] = keyB["BYTE_COMMON_ON"]
        keyP["swingRightUDValue"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_SWING_UD"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["swingLeftUDValue"] = keyB["BYTE_COMMON_OFF"]
        keyP["swingRightUDValue"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_SWING_LR"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["swingUpLRValue"] = keyB["BYTE_COMMON_ON"]
        keyP["swingDownLRValue"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_SWING_LR"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["swingUpLRValue"] = keyB["BYTE_COMMON_OFF"]
        keyP["swingDownLRValue"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_FORCE_COOL_MODE"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["forceCoolMode"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_FORCE_COOL_MODE"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["forceCoolMode"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_FORCE_AUTO_MODE"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["forceAutoMode"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_FORCE_AUTO_MODE"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["forceAutoMode"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_PTC"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["PTCValue"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_PTC"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["PTCValue"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_PTC_DEPENDT4"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["PTCDependT4Value"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_PTC_DEPENDT4"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["PTCDependT4Value"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_COOL_HOT_SENSE"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["cool_hot_sense"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_COOL_HOT_SENSE"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["cool_hot_sense"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_PREVENT_COLD"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["preventCold"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_PREVENT_COLD"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["preventCold"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_WIND_STRAIGHT"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["wind_straight"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_WIND_STRAIGHT"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["wind_straight"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_WIND_AVOID"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["wind_avoid"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_WIND_AVOID"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["wind_avoid"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_DISINFECT"]] == keyV["VALUE_FUNCTION_ON"] and jsonType ==
        "control") then
        keyP["disinfect"] = keyB["BYTE_COMMON_ON"]
        keyP["water_washing"] = 0
        keyP["manuPurify"] = 1
        keyP["remove_arofene"] = 1
        keyP["air_exhaust"] = 0
        keyP["remove_peculiar_smell"] = 1
        keyP["standby_clean"] = 0
    elseif (streams[keyT["KEY_DISINFECT"]] == keyV["VALUE_FUNCTION_OFF"] and
        jsonType == "control") then
        keyP["disinfect"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_DISINFECT"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["disinfect"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_DISINFECT"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["disinfect"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_ELEC_DUST_REMOVE"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["elecDustRemove"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_ELEC_DUST_REMOVE"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["elecDustRemove"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_SELFCLEAN"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["self_clean"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_SELFCLEAN"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["self_clean"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_ENERGY_SAVE"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["energySaveValue"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_ENERGY_SAVE"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["energySaveValue"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_AIR_OPTIMIZATION"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["air_optimization"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_AIR_OPTIMIZATION"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["air_optimization"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_NOBODY_ENERGY_SAVE"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["nobody_energy_save"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_NOBODY_ENERGY_SAVE"]] ==
        keyV["VALUE_FUNCTION_OFF"]) then
        keyP["nobody_energy_save"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_AUTO_PURIFY"]] == keyV["VALUE_FUNCTION_ON"] and
        jsonType == "control") then
        keyP["autoPurify"] = keyB["BYTE_COMMON_ON"]
        keyP["water_washing"] = 0
        keyP["manuPurify"] = 1
        keyP["remove_arofene"] = 1
        keyP["air_exhaust"] = 0
        keyP["remove_peculiar_smell"] = 1
        keyP["standby_clean"] = 0
    elseif (streams[keyT["KEY_AUTO_PURIFY"]] == keyV["VALUE_FUNCTION_OFF"] and
        jsonType == "control") then
        keyP["autoPurify"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_AUTO_PURIFY"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["autoPurify"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_AUTO_PURIFY"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["autoPurify"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_MANUL_PURIFY"]] == keyV["VALUE_FUNCTION_ON"] and
        jsonType == "control") then
        keyP["manuPurify"] = keyB["BYTE_COMMON_ON"]
        keyP["water_washing"] = 0
        keyP["remove_arofene"] = 1
        keyP["air_exhaust"] = 0
        keyP["remove_peculiar_smell"] = 1
        keyP["standby_clean"] = 0
    elseif (streams[keyT["KEY_MANUL_PURIFY"]] == keyV["VALUE_FUNCTION_OFF"] and
        jsonType == "control") then
        keyP["manuPurify"] = keyB["BYTE_COMMON_OFF"]
        keyP["remove_peculiar_smell"] = 0
        keyP["autoPurify"] = 0
        keyP["remove_arofene"] = 0
        keyP["autoNewWind"] = 0
        keyP["huanqi_function"] = 0
        keyP["autoHumi"] = 0
        keyP["manuHumi"] = 0
        keyP["disinfect"] = 0
        keyP["comfort_fresh_air"] = 0
    end
    if (streams[keyT["KEY_MANUL_PURIFY"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["manuPurify"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_MANUL_PURIFY"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["manuPurify"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_NO_WIND_SENSE_MODE"]] ~= nil) then
        keyP["no_wind_sense_mode"] = checkBoundary(
                                         streams[keyT["KEY_NO_WIND_SENSE_MODE"]],
                                         0, 2)
    end
    if (streams[keyT["KEY_RUN_TEST"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["run_test"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_RUN_TEST"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["run_test"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_FAST_CHECK"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["fast_check"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_FAST_CHECK"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["fast_check"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_AUTO_HUMI"]] == keyV["VALUE_FUNCTION_ON"] and jsonType ==
        "control") then
        keyP["autoHumi"] = keyB["BYTE_COMMON_ON"]
        keyP["water_washing"] = 0
        keyP["manuPurify"] = 1
        keyP["remove_arofene"] = 1
        keyP["air_exhaust"] = 0
        keyP["remove_peculiar_smell"] = 1
        keyP["standby_clean"] = 0
    elseif (streams[keyT["KEY_AUTO_HUMI"]] == keyV["VALUE_FUNCTION_OFF"] and
        jsonType == "control") then
        keyP["autoHumi"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_AUTO_HUMI"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["autoHumi"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_AUTO_HUMI"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["autoHumi"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_MANUL_HUMI"]] == keyV["VALUE_FUNCTION_ON"] and
        jsonType == "control") then
        keyP["manuHumi"] = keyB["BYTE_COMMON_ON"]
        keyP["humi_flag"] = keyP["humi_flag"] + 1
        keyP["water_washing"] = 0
        keyP["manuPurify"] = 1
        keyP["remove_arofene"] = 1
        keyP["air_exhaust"] = 0
        keyP["remove_peculiar_smell"] = 1
        keyP["standby_clean"] = 0
    elseif (streams[keyT["KEY_MANUL_HUMI"]] == keyV["VALUE_FUNCTION_OFF"] and
        jsonType == "control") then
        keyP["manuHumi"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_MANUL_HUMI"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["manuHumi"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_MANUL_HUMI"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["manuHumi"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_WIND_STRENGTH"]] ~= nil) then
        keyP["wind_strength"] = checkBoundary(
                                    streams[keyT["KEY_WIND_STRENGTH"]], 0, 1)
    end
    if (streams[keyT["KEY_NEW_WIND_MACHINE"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["new_wind_machine"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_NEW_WIND_MACHINE"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["new_wind_machine"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_NEW_WIND_MACHINE_LINK"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["new_wind_machine_link"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_NEW_WIND_MACHINE_LINK"]] ==
        keyV["VALUE_FUNCTION_OFF"]) then
        keyP["new_wind_machine_link"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_PROJECT_EVACUATE"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["project_evacuate"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_PROJECT_EVACUATE"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["project_evacuate"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_FOLLOW_BODY_SENSE"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["follow_body_sense"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_FOLLOW_BODY_SENSE"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["follow_body_sense"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_EXHAUST_STRENGTH"]] ~= nil) then
        keyP["exhaust_strength"] = checkBoundary(
                                       streams[keyT["KEY_EXHAUST_STRENGTH"]], 0,
                                       1)
    end
    if (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_HEAT"]) then
        keyP["modeValue"] = keyB["BYTE_MODE_HEAT"]
    elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_COOL"]) then
        keyP["modeValue"] = keyB["BYTE_MODE_COOL"]
    elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_AUTO"]) then
        keyP["modeValue"] = keyB["BYTE_MODE_AUTO"]
    elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_DRY"]) then
        keyP["modeValue"] = keyB["BYTE_MODE_DRY"]
        keyP["humi_flag"] = keyP["humi_flag"] + 2
    elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_FAN"]) then
        keyP["modeValue"] = keyB["BYTE_MODE_FAN"]
    end
    if (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_HEAT"] and jsonType ==
        "control") then
        keyP["modeValue"] = keyB["BYTE_MODE_HEAT"]
        keyP["PTCValue"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_COOL"] and jsonType ==
        "control") then
        keyP["modeValue"] = keyB["BYTE_MODE_COOL"]
    elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_AUTO"] and jsonType ==
        "control") then
        keyP["modeValue"] = keyB["BYTE_MODE_AUTO"]
        keyP["PTCValue"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_DRY"] and jsonType ==
        "control") then
        keyP["modeValue"] = keyB["BYTE_MODE_DRY"]
        keyP["humi_flag"] = keyP["humi_flag"] + 3
    elseif (streams[keyT["KEY_MODE"]] == keyV["VALUE_MODE_FAN"] and jsonType ==
        "control") then
        keyP["modeValue"] = keyB["BYTE_MODE_FAN"]
    end
    if (streams[keyT["KEY_TEMPERATURE"]] ~= nil) then
        keyP["temperature"] = checkBoundary(streams[keyT["KEY_TEMPERATURE"]],
                                            16, 30)
    end
    if (streams["small_temperature"] ~= nil) then
        keyP["small_temperature"] = checkBoundary(streams["small_temperature"],
                                                  0, 0.5)
    end
    if (streams[keyT["KEY_FANSPEED"]] ~= nil) then
        keyP["fanspeedValue"] = checkBoundary(streams[keyT["KEY_FANSPEED"]], 1,
                                              103)
    end
    if (streams[keyT["KEY_DEHUMIDITY"]] ~= nil) then
        keyP["dehumidityValue"] = checkBoundary(streams[keyT["KEY_DEHUMIDITY"]],
                                                1, 101)
    end
    if (streams[keyT["KEY_HUMIDITY"]] ~= nil) then
        keyP["humidityValue"] = streams[keyT["KEY_HUMIDITY"]]
    end
    if (streams[keyT["KEY_PM25"]] ~= nil) then
        keyP["pm25LowValue"] = math.floor(streams[keyT["KEY_PM25"]] % 256)
        keyP["pm25HighValue"] = math.floor(streams[keyT["KEY_PM25"]] / 256)
    end
    if (streams[keyT["KEY_CO2"]] ~= nil) then
        keyP["co2LowValue"] = math.floor(streams[keyT["KEY_CO2"]] % 256)
        keyP["co2HighValue"] = math.floor(streams[keyT["KEY_CO2"]] / 256)
    end
    if (streams[keyT["KEY_NEWWIND_MODE"]] ~= nil) then
        keyP["newWindModeValue"] = checkBoundary(
                                       streams[keyT["KEY_NEWWIND_MODE"]], 0, 4)
    end
    if (streams[keyT["KEY_NEWWIND_FANSPEED"]] ~= nil) then
        keyP["newWindSpeedValue"] = checkBoundary(
                                        streams[keyT["KEY_NEWWIND_FANSPEED"]],
                                        1, 103)
    end
    if (streams[keyT["KEY_AIR_OPTIMIZATION_TEMPERATURE"]] ~= nil) then
        keyP["air_optimization_temperature"] = checkBoundary(
                                                   streams[keyT["KEY_AIR_OPTIMIZATION_TEMPERATURE"]],
                                                   16, 30)
    end
    if (streams[keyT["KEY_AIR_OPTIMIZATION_HUMIDITY"]] ~= nil) then
        keyP["air_optimization_humidity"] = checkBoundary(
                                                streams[keyT["KEY_AIR_OPTIMIZATION_HUMIDITY"]],
                                                1, 100)
    end
    if (streams[keyT["KEY_AIR_OPTIMIZATION_WIND"]] ~= nil) then
        keyP["air_optimization_wind"] = checkBoundary(
                                            streams[keyT["KEY_AIR_OPTIMIZATION_WIND"]],
                                            1, 102)
    end
    if (streams[keyT["KEY_WATER_MODEL_POWER"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["water_model_power"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_WATER_MODEL_POWER"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["water_model_power"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_WATER_MODEL_POWER_SAVE"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["water_model_power_save"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_WATER_MODEL_POWER_SAVE"]] ==
        keyV["VALUE_FUNCTION_OFF"]) then
        keyP["water_model_power_save"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_WATER_MODEL_CLEAN"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["water_model_clean"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_WATER_MODEL_CLEAN"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["water_model_clean"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_WATER_MODEL_TEMPERATURE_AUTO"]] ==
        keyV["VALUE_FUNCTION_ON"]) then
        keyP["water_model_temperature_auto"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_WATER_MODEL_TEMPERATURE_AUTO"]] ==
        keyV["VALUE_FUNCTION_OFF"]) then
        keyP["water_model_temperature_auto"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_WATER_MODEL_PTC"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["water_model_ptc"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_WATER_MODEL_PTC"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["water_model_ptc"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_WATER_MODEL_GO_OUT"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["water_model_go_out"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_WATER_MODEL_GO_OUT"]] ==
        keyV["VALUE_FUNCTION_OFF"]) then
        keyP["water_model_go_out"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_WATER_MODEL_TEMPERATURE_SET"]] ~= nil) then
        keyP["water_model_temperature_set"] = checkBoundary(
                                                  streams[keyT["KEY_WATER_MODEL_TEMPERATURE_SET"]],
                                                  25, 60)
    end
    if (streams[keyT["KEY_SCREEN_DISPLAY"]] ~= nil) then
        if (streams[keyT["KEY_SCREEN_DISPLAY"]] == keyV["VALUE_FUNCTION_ON"]) then
            keyP["screen_display"] = 0x64
        elseif (streams[keyT["KEY_SCREEN_DISPLAY"]] ==
            keyV["VALUE_FUNCTION_OFF"]) then
            keyP["screen_display"] = 0x00
        end
    end
    if (streams[keyT["KEY_FILTER_TIME_RESET"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["filterTimeReset"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_FILTER_TIME_RESET"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["filterTimeReset"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_PURIFY_FILTER_TIME_RESET"]] ==
        keyV["VALUE_FUNCTION_ON"]) then
        keyP["purifyFilterTimeReset"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_PURIFY_FILTER_TIME_RESET"]] ==
        keyV["VALUE_FUNCTION_OFF"]) then
        keyP["purifyFilterTimeReset"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams[keyT["KEY_FRESH_FILTER_TIME_RESET"]] ==
        keyV["VALUE_FUNCTION_ON"]) then
        keyP["freshFilterTimeReset"] = keyB["BYTE_COMMON_ON"]
    elseif (streams[keyT["KEY_FRESH_FILTER_TIME_RESET"]] ==
        keyV["VALUE_FUNCTION_OFF"]) then
        keyP["freshFilterTimeReset"] = keyB["BYTE_COMMON_OFF"]
    end
    if (streams["humidity_drainage"] == 0x01) then
        keyP["humidity_drainage"] = 0x01
        keyP["water_washing"] = 0x01
    elseif (streams["humidity_drainage"] == 0x00) then
        keyP["humidity_drainage"] = 0x00
    end
    if (jsonType == "control" and streams["humidity_drainage"] ~= nil) then
        keyP["humidity_drainage_flag"] = 1
    end
    if (streams[keyT["KEY_POWER_ON_TIMER"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["power_on_timer"] = 0x01
    elseif (streams[keyT["KEY_POWER_ON_TIMER"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["power_on_timer"] = 0x00
    end
    if (streams[keyT["KEY_POWER_OFF_TIMER"]] == keyV["VALUE_FUNCTION_ON"]) then
        keyP["power_off_timer"] = 0x01
    elseif (streams[keyT["KEY_POWER_OFF_TIMER"]] == keyV["VALUE_FUNCTION_OFF"]) then
        keyP["power_off_timer"] = 0x00
    end
    if (streams[keyT["KEY_CLOSE_TIME"]] ~= nil) then
        keyP["power_off_time_value"] = streams[keyT["KEY_CLOSE_TIME"]]
    end
    if (streams[keyT["KEY_OPEN_TIME"]] ~= nil) then
        keyP["power_on_time_value"] = streams[keyT["KEY_OPEN_TIME"]]
    end
    if (jsonType == "control" and (streams[keyT["KEY_POWER_ON_TIMER"]] ~= nil or
        streams[keyT["KEY_POWER_OFF_TIMER"]] ~= nil)) then
        keyP["timer_enable"] = 1
    else
        keyP["timer_enable"] = 0
    end
    if (streams["sn8_string"] == "00000001") then
        if (jsonType == "control") then keyP["sn8_flag"] = 1 end
    end
    if (streams["remove_dust_full"] ~= nil) then
        keyP["remove_dust_full"] = streams["remove_dust_full"]
    end
    if (streams["remove_peculiar_smell"] ~= nil and jsonType == "control") then
        keyP["remove_peculiar_smell"] = streams["remove_peculiar_smell"]
        if (streams["remove_peculiar_smell"] == 1) then
            keyP["water_washing"] = 0
            keyP["manuPurify"] = 1
            keyP["remove_arofene"] = 1
            keyP["air_exhaust"] = 0
            keyP["standby_clean"] = 0
        end
        if (streams["remove_peculiar_smell"] == 0) then
            keyP["manuPurify"] = 0
            keyP["autoPurify"] = 0
            keyP["remove_arofene"] = 0
            keyP["autoNewWind"] = 0
            keyP["huanqi_function"] = 0
            keyP["autoHumi"] = 0
            keyP["manuHumi"] = 0
            keyP["disinfect"] = 0
            keyP["comfort_fresh_air"] = 0
        end
    end
    if (streams["remove_peculiar_smell"] ~= nil) then
        keyP["remove_peculiar_smell"] = streams["remove_peculiar_smell"]
    end
    if (streams["remove_arofene"] ~= nil and jsonType == "control") then
        keyP["remove_arofene"] = streams["remove_arofene"]
        if (streams["remove_arofene"] == 1) then
            keyP["water_washing"] = 0
            keyP["manuPurify"] = 1
            keyP["air_exhaust"] = 0
            keyP["remove_peculiar_smell"] = 1
            keyP["standby_clean"] = 0
        end
        if (streams["remove_arofene"] == 0) then
            keyP["manuPurify"] = 0
            keyP["autoPurify"] = 0
            keyP["remove_peculiar_smell"] = 0
            keyP["autoNewWind"] = 0
            keyP["huanqi_function"] = 0
            keyP["autoHumi"] = 0
            keyP["manuHumi"] = 0
            keyP["disinfect"] = 0
            keyP["comfort_fresh_air"] = 0
        end
    end
    if (streams["remove_arofene"] ~= nil) then
        keyP["remove_arofene"] = streams["remove_arofene"]
    end
    if (streams["no_wind_sense_left"] ~= nil) then
        keyP["no_wind_sense_left"] = streams["no_wind_sense_left"]
        if (keyP["no_wind_sense_left"] == 1 and jsonType == "control") then
            keyP["vertical_swing_left"] = 0
            keyP["fanspeedValue"] = 102
        end
    end
    if (streams["no_wind_sense_right"] ~= nil) then
        keyP["no_wind_sense_right"] = streams["no_wind_sense_right"]
        if (keyP["no_wind_sense_right"] == 1 and jsonType == "control") then
            keyP["vertical_swing_right"] = 0
            keyP["right_wind_speed"] = 102
        end
    end
    if (streams["wind_swing_right"] ~= nil) then
        keyP["wind_swing_right"] = streams["wind_swing_right"]
    end
    if (streams["wind_swing_left"] ~= nil) then
        keyP["wind_swing_left"] = streams["wind_swing_left"]
    end
    if (streams["air_exhaust"] ~= nil and jsonType == "control") then
        keyP["air_exhaust"] = streams["air_exhaust"]
        if (keyP["air_exhaust"] == 1) then
            keyP["water_washing"] = 0
            keyP["autoNewWind"] = 0
            keyP["huanqi_function"] = 0
            keyP["comfort_fresh_air"] = 0
            keyP["autoHumi"] = 0
            keyP["manuHumi"] = 0
            keyP["autoPurify"] = 0
            keyP["manuPurify"] = 0
            keyP["remove_arofene"] = 0
            keyP["remove_peculiar_smell"] = 0
            keyP["standby_clean"] = 0
            keyP["disinfect"] = 0
        end
    end
    if (streams["air_exhaust"] ~= nil) then
        keyP["air_exhaust"] = streams["air_exhaust"]
    end
    if (streams["comfort_fresh_air"] ~= nil and jsonType == "control") then
        keyP["comfort_fresh_air"] = streams["comfort_fresh_air"]
        if (streams["comfort_fresh_air"] == 1) then
            keyP["water_washing"] = 0
            keyP["manuPurify"] = 1
            keyP["remove_arofene"] = 1
            keyP["air_exhaust"] = 0
            keyP["remove_peculiar_smell"] = 1
            keyP["standby_clean"] = 0
        end
    end
    if (streams["comfort_fresh_air"] ~= nil) then
        keyP["comfort_fresh_air"] = streams["comfort_fresh_air"]
    end
    if (streams["fresh_air_setting_mode"] ~= nil) then
        keyP["fresh_air_setting_mode"] = streams["fresh_air_setting_mode"]
    end
    if (streams["huanqi_function"] ~= nil and jsonType == "control") then
        keyP["huanqi_function"] = streams["huanqi_function"]
        if (streams["huanqi_function"] == 1) then
            keyP["water_washing"] = 0
            keyP["manuPurify"] = 1
            keyP["remove_arofene"] = 1
            keyP["air_exhaust"] = 0
            keyP["remove_peculiar_smell"] = 1
            keyP["standby_clean"] = 0
        end
    end
    if (streams["huanqi_function"] ~= nil) then
        keyP["huanqi_function"] = streams["huanqi_function"]
    end
    if (streams["vertical_swing_left"] ~= nil) then
        keyP["vertical_swing_left"] = streams["vertical_swing_left"]
        if (streams["vertical_swing_left"] == 1) then
            keyP["left_right_wind_direction"] = 0
            keyP["no_wind_sense_left"] = 0
        end
    end
    if (streams["vertical_swing_right"] ~= nil) then
        keyP["vertical_swing_right"] = streams["vertical_swing_right"]
        if (streams["vertical_swing_right"] == 1) then
            keyP["left_right_wind_direction"] = 0
            keyP["no_wind_sense_right"] = 0
        end
    end
    if (streams["horizontal_swing_left"] ~= nil) then
        keyP["horizontal_swing_left"] = streams["horizontal_swing_left"]
        if (streams["horizontal_swing_left"] == 1) then
            keyP["up_down_wind_direction"] = 0
        end
    end
    if (streams["horizontal_swing_right"] ~= nil) then
        keyP["horizontal_swing_right"] = streams["horizontal_swing_right"]
        if (streams["horizontal_swing_right"] == 1) then
            keyP["up_down_wind_direction"] = 0
        end
    end
    if (streams["down_wind_speed_level"] ~= nil) then
        keyP["down_wind_speed_level"] = streams["down_wind_speed_level"]
    end
    if (streams["water_washing"] ~= nil) then
        if (streams["water_washing"] == 1) then
            keyP["water_washing"] = streams["water_washing"]
            keyP["power"] = 0
            keyP["strongWindValue"] = 0
            keyP["vertical_swing_left"] = 0
            keyP["vertical_swing_right"] = 0
            keyP["horizontal_swing_left"] = 0
            keyP["horizontal_swing_right"] = 0
            keyP["no_wind_sense_left"] = 0
            keyP["no_wind_sense_right"] = 0
            keyP["PTCValue"] = 0
            keyP["power_off_timer"] = 0
            keyP["autoNewWind"] = 0
            keyP["huanqi_function"] = 0
            keyP["comfort_fresh_air"] = 0
            keyP["auto_comfort_fresh_air"] = 0
            keyP["autoHumi"] = 0
            keyP["manuHumi"] = 0
            keyP["autoPurify"] = 0
            keyP["manuPurify"] = 0
            keyP["disinfect"] = 0
            keyP["remove_arofene"] = 0
            keyP["remove_peculiar_smell"] = 0
            keyP["air_exhaust"] = 0
            keyP["standby_clean"] = 0
            keyP["try_run"] = 0
            keyP["scene_id"] = 0
            keyP["left_right_wind_direction"] = 0
            keyP["up_down_wind_direction"] = 0
        else
            keyP["water_washing"] = streams["water_washing"]
        end
    end
    if (streams["dry_clean"] ~= nil) then
        keyP["dry_clean"] = streams["dry_clean"]
    end
    if (streams["disinfect_setting_time"] ~= nil) then
        keyP["disinfect_setting_time"] = streams["disinfect_setting_time"]
    end
    if (streams["auto_purifier_on_pm"] ~= nil) then
        keyP["auto_purifier_on_pm"] = streams["auto_purifier_on_pm"]
    end
    if (streams["auto_purifier_off_pm"] ~= nil) then
        keyP["auto_purifier_off_pm"] = streams["auto_purifier_off_pm"]
    end
    if (streams["auto_fresh_on_co2"] ~= nil) then
        keyP["auto_fresh_on_co2"] = streams["auto_fresh_on_co2"]
    end
    if (streams["auto_fresh_off_co2"] ~= nil) then
        keyP["auto_fresh_off_co2"] = streams["auto_fresh_off_co2"]
    end
    if (streams["humi_on_value"] ~= nil) then
        keyP["humi_on_value"] = streams["humi_on_value"]
    end
    if (streams["humi_off_value"] ~= nil) then
        keyP["humi_off_value"] = streams["humi_off_value"]
    end
    if (streams["outdoor_pm"] ~= nil) then
        keyP["outdoor_pm"] = streams["outdoor_pm"]
    end
    if (streams["manul_humi_value"] ~= nil) then
        keyP["manul_humi_value"] = streams["manul_humi_value"]
    end
    if (streams["right_wind_speed"] ~= nil) then
        keyP["right_wind_speed"] = streams["right_wind_speed"]
    end
    if (streams["left_wind_speed_target_value"] ~= nil) then
        keyP["left_wind_speed_target_value"] =
            streams["left_wind_speed_target_value"]
    end
    if (streams["right_wind_speed_target_value"] ~= nil) then
        keyP["right_wind_speed_target_value"] =
            streams["right_wind_speed_target_value"]
    end
    if (streams["voice_control"] ~= nil) then
        keyP["voice_control"] = streams["voice_control"]
    end
    if (streams["prevent_straight_wind_lr"] ~= nil) then
        keyP["prevent_straight_wind_lr"] = streams["prevent_straight_wind_lr"]
    end
    if (streams["down_wind_left_switch"] ~= nil) then
        keyP["down_wind_left_switch"] = streams["down_wind_left_switch"]
    end
    if (streams["down_wind_right_switch"] ~= nil) then
        keyP["down_wind_right_switch"] = streams["down_wind_right_switch"]
    end
    if (streams["auto_comfort_fresh_air"] ~= nil) then
        keyP["auto_comfort_fresh_air"] = streams["auto_comfort_fresh_air"]
    end
    if (streams["solar_eco"] ~= nil) then
        keyP["solar_eco"] = streams["solar_eco"]
    end
    if (streams["clear_filter_change_time"] ~= nil) then
        keyP["clear_filter_change_time"] = streams["clear_filter_change_time"]
    end
    if (streams["remove_dust_full"] ~= nil) then
        keyP["remove_dust_full"] = streams["remove_dust_full"]
    end
    if (streams["up_down_wind_direction"] ~= nil) then
        keyP["up_down_wind_direction"] = streams["up_down_wind_direction"]
        if (streams["up_down_wind_direction"] == 1) then
            keyP["horizontal_swing_left"] = 0
            keyP["horizontal_swing_right"] = 0
        end
    end
    if (streams["left_right_wind_direction"] ~= nil) then
        keyP["left_right_wind_direction"] = streams["left_right_wind_direction"]
        if (streams["left_right_wind_direction"] == 1) then
            keyP["vertical_swing_left"] = 0
            keyP["vertical_swing_right"] = 0
            keyP["no_wind_sense_left"] = 0
            keyP["no_wind_sense_right"] = 0
        end
    end
    if (streams["scene_id"] ~= nil) then
        keyP["scene_id"] = streams["scene_id"]
    end
    if (streams["total_control"] ~= nil and jsonType == "control") then
        keyP["total_control"] = streams["total_control"]
        keyP["control_flag"] = 1
    end
    if (streams["eight_degree_heat"] ~= nil and jsonType == "control") then
        keyP["eight_degree_heat"] = streams["eight_degree_heat"]
    end
    if (streams["eight_degree_heat"] ~= nil) then
        keyP["eight_degree_heat"] = streams["eight_degree_heat"]
    end
    if (streams["eight_degree_heat_remember"] ~= nil) then
        keyP["eight_degree_heat_remember"] =
            streams["eight_degree_heat_remember"]
    end
    if (streams["scene_id_f1"] ~= nil and jsonType == "control") then
        keyP["scene_id_f1"] = streams["scene_id_f1"]
        keyP["control_flag"] = 2
    end
    if (streams["total_time_switch"] ~= nil) then
        keyP["total_time_switch"] = streams["total_time_switch"]
    end
    if (streams["pm2_5_algorithm"] ~= nil) then
        keyP["pm2_5_algorithm"] = streams["pm2_5_algorithm"]
    end
    if (streams["co2_algorithm"] ~= nil) then
        keyP["co2_algorithm"] = streams["co2_algorithm"]
    end
    if (streams["temp_algorithm"] ~= nil) then
        keyP["temp_algorithm"] = streams["temp_algorithm"]
    end
    if (streams["humidity_algorithm"] ~= nil) then
        keyP["humidity_algorithm"] = streams["humidity_algorithm"]
    end
    if (streams["recommend_mode_switch"] ~= nil) then
        keyP["recommend_mode_switch"] = streams["recommend_mode_switch"]
    end
    if (streams["current_wind_speed"] ~= nil) then
        keyP["current_wind_speed"] = streams["current_wind_speed"]
    end
    if (streams["current_down_wind_speed"] ~= nil) then
        keyP["current_down_wind_speed"] = streams["current_down_wind_speed"]
    end
    if ((streams["total_time_switch"] ~= nil or streams["pm2_5_algorithm"] ~=
        nil or streams["co2_algorithm"] ~= nil or streams["temp_algorithm"] ~=
        nil or streams["humidity_algorithm"] ~= nil or
        streams["recommend_mode_switch"] ~= nil) and jsonType == "control") then
        keyP["control_flag"] = 2
    end
    if (streams["limit_dry_switch_set"] ~= nil) then
        keyP["limit_dry_switch_set"] = streams["limit_dry_switch_set"]
    end
    if (streams["limit_dry_switch_set"] ~= nil and jsonType == "control") then
        keyP["control_flag"] = 3
    end
    if (streams["prevent_super_cool"] ~= nil) then
        keyP["prevent_super_cool"] = streams["prevent_super_cool"]
    end
    if (streams["last_humidity"] ~= nil) then
        keyP["last_humidity"] = streams["last_humidity"]
    end
    if (streams["rewarming_dry"] ~= nil) then
        keyP["rewarming_dry"] = streams["rewarming_dry"]
    end
end
local function binToModel(binData)
    local messageBytes = binData
    if (dataType == 0xFF) then
        if (#binData < 15) then return nil end
        keyP["modeValue"] = messageBytes[0]
        keyP["fanspeedValue"] = messageBytes[2]
        keyP["ability_test"] = messageBytes[3]
        keyP["humidity"] = messageBytes[4]
        keyP["standby_clean"] = bit.band(messageBytes[5], 0x01)
        keyP["display_status"] = bit.rshift(bit.band(messageBytes[5], 0x02), 1)
        keyP["mute_voice"] = bit.rshift(bit.band(messageBytes[5], 0x04), 2)
        keyP["cool_hot_sense"] = bit.rshift(bit.band(messageBytes[5], 0x08), 3)
        keyP["low_power_cost"] = bit.rshift(bit.band(messageBytes[5], 0x10), 4)
        keyP["dry_clean"] = bit.rshift(bit.band(messageBytes[5], 0x20), 5)
        keyP["strongWindValue"] = bit.rshift(bit.band(messageBytes[5], 0x40), 6)
        keyP["communication_fault"] = bit.rshift(
                                          bit.band(messageBytes[5], 0x80), 7)
        keyP["smart_eye"] = bit.band(messageBytes[6], 0x03)
        keyP["horizontal_swing_left"] = bit.rshift(
                                            bit.band(messageBytes[6], 0x04), 2)
        keyP["horizontal_swing_right"] = bit.rshift(
                                             bit.band(messageBytes[6], 0x08), 3)
        keyP["vertical_swing_left"] = bit.rshift(
                                          bit.band(messageBytes[6], 0x10), 4)
        keyP["vertical_swing_right"] = bit.rshift(
                                           bit.band(messageBytes[6], 0x20), 5)
        keyP["power"] = bit.rshift(bit.band(messageBytes[6], 0x40), 6)
        keyP["solar_eco"] = bit.rshift(bit.band(messageBytes[6], 0x80), 7)
        keyP["force_cool"] = bit.band(messageBytes[7], 0x01)
        keyP["force_auto"] = bit.rshift(bit.band(messageBytes[7], 0x02), 1)
        keyP["force_defrost"] = bit.rshift(bit.band(messageBytes[7], 0x04), 2)
        keyP["ptc_dependT4"] = bit.rshift(bit.band(messageBytes[7], 0x08), 3)
        keyP["ptc"] = bit.rshift(bit.band(messageBytes[7], 0x10), 4)
        keyP["do_not_disturb"] = bit.rshift(bit.band(messageBytes[7], 0x20), 5)
        keyP["remove_dust_full"] =
            bit.rshift(bit.band(messageBytes[7], 0x40), 6)
        keyP["clear_filter_change_time"] = bit.rshift(
                                               bit.band(messageBytes[7], 0x80),
                                               7)
        keyP["self_wash"] = bit.band(messageBytes[8], 0x01)
        keyP["energy_save"] = bit.rshift(bit.band(messageBytes[8], 0x02), 1)
        keyP["advance_cold_hot"] =
            bit.rshift(bit.band(messageBytes[8], 0x04), 2)
        keyP["rui_wind"] = bit.rshift(bit.band(messageBytes[8], 0x08), 3)
        keyP["set_i_mode"] = bit.rshift(bit.band(messageBytes[8], 0x10), 4)
        keyP["save_i_mode"] = bit.rshift(bit.band(messageBytes[8], 0x20), 5)
        keyP["reset_electricity"] = bit.rshift(bit.band(messageBytes[8], 0x40),
                                               6)
        keyP["high_save_power"] = bit.rshift(bit.band(messageBytes[8], 0x80), 7)
        keyP["fast_check"] = bit.band(messageBytes[9], 0x01)
        keyP["elec_fast_check"] = bit.rshift(bit.band(messageBytes[9], 0x02), 1)
        keyP["total_fast_check"] =
            bit.rshift(bit.band(messageBytes[9], 0x04), 2)
        keyP["elec_dust_collect"] = bit.rshift(bit.band(messageBytes[9], 0x08),
                                               3)
        keyP["huanqi_function"] = bit.rshift(bit.band(messageBytes[9], 0x10), 4)
        keyP["light_level"] = bit.rshift(bit.band(messageBytes[9], 0x20), 5)
        keyP["natural_wind"] = bit.rshift(bit.band(messageBytes[9], 0x40), 6)
        keyP["leave_home"] = bit.rshift(bit.band(messageBytes[9], 0x80), 7)
        keyP["prevent_cold_child"] = bit.band(messageBytes[10], 0x01)
        keyP["prevent_cold"] = bit.rshift(bit.band(messageBytes[10], 0x02), 1)
        keyP["child_comfort_sleep"] = bit.rshift(
                                          bit.band(messageBytes[10], 0x04), 2)
        keyP["energy_save_xiaotiane"] = bit.rshift(
                                            bit.band(messageBytes[10], 0x08), 3)
        keyP["no_wind_sense"] = bit.rshift(bit.band(messageBytes[10], 0x10), 4)
        keyP["try_run"] = bit.rshift(bit.band(messageBytes[10], 0x20), 5)
        keyP["prevent_water_enable"] = bit.rshift(
                                           bit.band(messageBytes[10], 0x40), 6)
        keyP["display_receive_control_button"] =
            bit.rshift(bit.band(messageBytes[10], 0x80), 7)
        keyP["comfort_sleep"] = bit.band(messageBytes[11], 0x0F)
        keyP["pmv"] = bit.rshift(bit.band(messageBytes[11], 0xF0), 4)
        keyP["eco"] = bit.band(messageBytes[12], 0x0F)
        keyP["eight_degree_heat"] = bit.rshift(bit.band(messageBytes[12], 0xF0),
                                               4)
        keyP["buzzer"] = bit.band(messageBytes[13], 0x0F)
        keyP["buzzer_param"] = bit.rshift(bit.band(messageBytes[13], 0xF0), 4)
        keyP["display_wind_percent"] = messageBytes[14]
        keyP["display_band_limited"] = messageBytes[15]
        keyP["dr_function"] = messageBytes[16]
        keyP["second_temperature_setting"] = messageBytes[17]
        keyP["up_down_wind_direction"] = bit.band(messageBytes[18], 0x0F)
        keyP["left_right_wind_direction"] =
            bit.rshift(bit.band(messageBytes[18], 0xF0), 4)
        keyP["mosquito_repellent"] = bit.rshift(
                                         bit.band(messageBytes[19], 0x02), 1)
        keyP["comfort_save"] = bit.rshift(bit.band(messageBytes[19], 0x04), 2)
        keyP["x_fan_control"] = bit.rshift(bit.band(messageBytes[19], 0x08), 3)
        keyP["prevent_straight_wind"] = bit.rshift(
                                            bit.band(messageBytes[19], 0x10), 4)
        keyP["gentle_wind_sense"] = bit.rshift(bit.band(messageBytes[19], 0x20),
                                               5)
        keyP["child_prevent_cold_wind_child"] =
            bit.rshift(bit.band(messageBytes[19], 0x40), 6)
        keyP["child_prevent_cold_wind_parent"] =
            bit.rshift(bit.band(messageBytes[19], 0x80), 7)
        keyP["no_wind_sense_up"] = bit.band(messageBytes[20], 0x01)
        keyP["no_wind_sense_down"] = bit.rshift(
                                         bit.band(messageBytes[20], 0x02), 1)
        keyP["permanent_wind"] = bit.rshift(bit.band(messageBytes[20], 0x04), 2)
        keyP["temperature_unit"] = bit.rshift(bit.band(messageBytes[20], 0x08),
                                              3)
        keyP["smart_wind_left_degree"] = messageBytes[21]
        keyP["smart_wind_right_degree"] = messageBytes[22]
        keyP["auto_water_washing"] = bit.band(messageBytes[23], 0x01)
        keyP["manul_water_washing"] = bit.rshift(
                                          bit.band(messageBytes[23], 0x02), 1)
        keyP["water_washing_control"] = bit.rshift(
                                            bit.band(messageBytes[23], 0x0C), 2)
        keyP["ud_wind_accelerate"] = bit.rshift(
                                         bit.band(messageBytes[23], 0x10), 4)
        keyP["lr_wind_accelerate"] = bit.rshift(
                                         bit.band(messageBytes[23], 0x20), 5)
        keyP["prevent_trip"] = bit.rshift(bit.band(messageBytes[23], 0x40), 6)
        keyP["smart_temperature_control"] =
            bit.rshift(bit.band(messageBytes[23], 0x80), 7)
        keyP["timer_message"] = bit.band(messageBytes[24], 0x01)
        keyP["lock"] = bit.rshift(bit.band(messageBytes[24], 0x02), 1)
        keyP["remote_control"] = bit.rshift(bit.band(messageBytes[24], 0x04), 2)
        keyP["child_prevent_cold_wind"] = bit.rshift(
                                              bit.band(messageBytes[24], 0x08),
                                              3)
        keyP["double_water_washing"] = bit.rshift(
                                           bit.band(messageBytes[24], 0x10), 4)
        keyP["deep_clean"] = bit.rshift(bit.band(messageBytes[24], 0x20), 5)
        keyP["extreme_wind"] = bit.rshift(bit.band(messageBytes[24], 0xC0), 6)
        keyP["remove_arofene"] = bit.rshift(bit.band(messageBytes[32], 0x08), 3)
        keyP["remove_peculiar_smell"] = bit.rshift(
                                            bit.band(messageBytes[32], 0x10), 4)
        keyP["down_wind_speed_level"] = messageBytes[34]
    end
    if (dataType == 0x11 or dataType == 0xF1) then
        if (#binData < 15) then return nil end
        keyP["powerValue"] = bit.band(messageBytes[0], 0x01)
        keyP["standby_clean"] = bit.rshift(bit.band(messageBytes[0], 0x02), 1)
        keyP["no_wind_sense"] = bit.rshift(bit.band(messageBytes[0], 0x08), 3)
        keyP["dryValue"] = bit.rshift(bit.band(messageBytes[0], 0x10), 4)
        keyP["strongWindValue"] = bit.rshift(bit.band(messageBytes[0], 0x20), 5)
        keyP["huanqi_function"] = bit.rshift(bit.band(messageBytes[0], 0x40), 6)
        keyP["autoNewWind"] = bit.rshift(bit.band(messageBytes[0], 0x80), 7)
        keyP["horizontal_swing_left"] = bit.band(messageBytes[1], 0x01)
        keyP["horizontal_swing_right"] = bit.rshift(
                                             bit.band(messageBytes[1], 0x02), 1)
        keyP["vertical_swing_left"] = bit.rshift(
                                          bit.band(messageBytes[1], 0x04), 2)
        keyP["vertical_swing_right"] = bit.rshift(
                                           bit.band(messageBytes[1], 0x08), 3)
        keyP["forceCoolMode"] = bit.rshift(bit.band(messageBytes[1], 0x10), 4)
        keyP["forceAutoMode"] = bit.rshift(bit.band(messageBytes[1], 0x20), 5)
        keyP["PTCValue"] = bit.rshift(bit.band(messageBytes[1], 0x40), 6)
        keyP["PTCDependT4Value"] =
            bit.rshift(bit.band(messageBytes[1], 0x80), 7)
        keyP["cool_hot_sense"] = bit.band(messageBytes[2], 0x01)
        keyP["preventCold"] = bit.rshift(bit.band(messageBytes[2], 0x02), 1)
        keyP["wind_straight"] = bit.rshift(bit.band(messageBytes[2], 0x04), 2)
        keyP["wind_avoid"] = bit.rshift(bit.band(messageBytes[2], 0x08), 3)
        keyP["disinfect"] = bit.rshift(bit.band(messageBytes[2], 0x10), 4)
        keyP["elecDustRemove"] = bit.rshift(bit.band(messageBytes[2], 0x20), 5)
        keyP["water_washing"] = bit.rshift(bit.band(messageBytes[2], 0x40), 6)
        keyP["self_clean"] = bit.rshift(bit.band(messageBytes[2], 0x40), 6)
        keyP["energySaveValue"] = bit.rshift(bit.band(messageBytes[2], 0x80), 7)
        keyP["air_optimization"] = bit.band(messageBytes[3], 0x01)
        keyP["nobody_energy_save"] = bit.rshift(bit.band(messageBytes[3], 0x02),
                                                1)
        keyP["autoPurify"] = bit.rshift(bit.band(messageBytes[3], 0x04), 2)
        keyP["manuPurify"] = bit.rshift(bit.band(messageBytes[3], 0x08), 3)
        keyP["no_wind_sense_mode"] = bit.rshift(bit.band(messageBytes[3], 0x30),
                                                4)
        keyP["run_test"] = bit.rshift(bit.band(messageBytes[3], 0x40), 6)
        keyP["fast_check"] = bit.rshift(bit.band(messageBytes[3], 0x80), 7)
        keyP["autoHumi"] = bit.band(messageBytes[4], 0x01)
        keyP["manuHumi"] = bit.rshift(bit.band(messageBytes[4], 0x02), 1)
        keyP["wind_strength"] = bit.rshift(bit.band(messageBytes[4], 0x04), 2)
        keyP["new_wind_machine"] =
            bit.rshift(bit.band(messageBytes[4], 0x08), 3)
        keyP["new_wind_machine_link"] = bit.rshift(
                                            bit.band(messageBytes[4], 0x10), 4)
        keyP["project_evacuate"] =
            bit.rshift(bit.band(messageBytes[4], 0x20), 5)
        keyP["follow_body_sense"] = bit.rshift(bit.band(messageBytes[4], 0x40),
                                               6)
        keyP["exhaust_strength"] =
            bit.rshift(bit.band(messageBytes[4], 0x80), 7)
        keyP["modeValue"] = messageBytes[5]
        keyP["temperature"], keyP["small_temperature"] = math.modf(
                                                             (messageBytes[6] -
                                                                 30) / 2)
        keyP["fanspeedValue"] = messageBytes[7]
        keyP["deHumidityValue"] = messageBytes[8]
        keyP["pm25LowValue"] = messageBytes[9]
        keyP["pm25HighValue"] = messageBytes[10]
        keyP["co2LowValue"] = messageBytes[11]
        keyP["co2HighValue"] = messageBytes[12]
        keyP["manul_humi_value"] = messageBytes[13]
        keyP["newWindModeValue"] = messageBytes[15]
        keyP["newWindSpeedValue"] = messageBytes[16]
        keyP["water_model_power"] = bit.band(messageBytes[17], 0x01)
        keyP["water_model_power_save"] = bit.rshift(
                                             bit.band(messageBytes[17], 0x02), 1)
        keyP["water_model_clean"] = bit.rshift(bit.band(messageBytes[17], 0x04),
                                               2)
        keyP["water_model_temperature_auto"] =
            bit.rshift(bit.band(messageBytes[17], 0x08), 3)
        keyP["water_model_ptc"] =
            bit.rshift(bit.band(messageBytes[17], 0x10), 4)
        keyP["water_model_go_out"] = bit.rshift(
                                         bit.band(messageBytes[17], 0x80), 7)
        keyP["water_model_temperature_set"] = (messageBytes[19] - 50) / 2
        keyP["has_huifeng"] = bit.band(messageBytes[20], 0x01)
        keyP["has_chufeng"] = bit.rshift(bit.band(messageBytes[20], 0x02), 1)
        keyP["has_wind_lr"] = bit.rshift(bit.band(messageBytes[20], 0x04), 2)
        keyP["has_no_wind_sense"] = bit.rshift(bit.band(messageBytes[20], 0x08),
                                               3)
        keyP["has_xinfeng"] = bit.rshift(bit.band(messageBytes[20], 0x10), 4)
        keyP["has_humidifer"] = bit.rshift(bit.band(messageBytes[20], 0x20), 5)
        keyP["has_water_model"] =
            bit.rshift(bit.band(messageBytes[20], 0x40), 6)
        keyP["air_optimization_temperature"] = (messageBytes[21] - 30) / 2
        keyP["down_wind_speed_level"] = messageBytes[22]
        keyP["temperatureLevel"] = messageBytes[23]
        keyP["humidityLevel"] = messageBytes[24]
        keyP["purifierLevel"] = messageBytes[25]
        keyP["freshLevel"] = messageBytes[26]
        keyP["tvocLevel"] = messageBytes[27]
        keyP["totalAirLevel"] = messageBytes[28]
        keyP["rfid_tunnel_0"] = bit.band(messageBytes[29], 0x01)
        keyP["rfid_tunnel_1"] = bit.rshift(bit.band(messageBytes[29], 0x02), 1)
        keyP["rfid_tunnel_2"] = bit.rshift(bit.band(messageBytes[29], 0x04), 2)
        keyP["rfid_tunnel_3"] = bit.rshift(bit.band(messageBytes[29], 0x08), 3)
        keyP["rfid_tunnel_4"] = bit.rshift(bit.band(messageBytes[29], 0x10), 4)
        keyP["rfid_tunnel_5"] = bit.rshift(bit.band(messageBytes[29], 0x20), 5)
        keyP["down_wind_left_switch"] = bit.rshift(
                                            bit.band(messageBytes[29], 0x40), 6)
        keyP["down_wind_right_switch"] = bit.rshift(
                                             bit.band(messageBytes[29], 0x80), 7)
        keyP["rfid_tunnel_tag_0"] = messageBytes[30]
        keyP["rfid_tunnel_tag_1"] = messageBytes[31]
        keyP["rfid_tunnel_tag_2"] = messageBytes[32]
        keyP["rfid_tunnel_tag_3"] = messageBytes[33]
        keyP["rfid_tunnel_tag_4"] = messageBytes[34]
        keyP["rfid_tunnel_tag_5"] = messageBytes[35]
        if (#binData > 40) then
            keyP["air_exhaust"] = messageBytes[41]
            keyP["auto_comfort_fresh_air"] = messageBytes[40]
        else
            keyP["air_exhaust"] = 0
            keyP["auto_comfort_fresh_air"] = 0
        end
        if (#binData > 44) then
            keyP["p0_fault"] = bit.rshift(bit.band(messageBytes[44], 0x04), 2)
            keyP["p2_fault"] = bit.rshift(bit.band(messageBytes[44], 0x20), 5)
            keyP["p1_fault"] = bit.rshift(bit.band(messageBytes[44], 0x10), 4)
            keyP["p4_fault"] = bit.rshift(bit.band(messageBytes[44], 0x80), 7)
            keyP["indoor_eb_fault"] = messageBytes[45]
        else
            keyP["p0_fault"] = 0
            keyP["p2_fault"] = 0
            keyP["p1_fault"] = 0
            keyP["p4_fault"] = 0
            keyP["indoor_eb_fault"] = 0
        end
        if (#binData > 46) then
            keyP["no_wind_sense_left"] = messageBytes[46]
            keyP["no_wind_sense_right"] = messageBytes[47]
            keyP["scene_id"] = messageBytes[48]
            keyP["acstrainer_sw"] = messageBytes[49]
        else
            keyP["no_wind_sense_left"] = 0
            keyP["no_wind_sense_right"] = 0
            keyP["scene_id"] = 0
            keyP["acstrainer_sw"] = 0
        end
        if (#binData > 50) then
            keyP["left_right_wind_direction"] = messageBytes[50]
            keyP["up_down_wind_direction"] = messageBytes[51]
            keyP["display_scene_id"] = messageBytes[52]
        end
        if (#binData > 53) then
            keyP["eb1_fault"] = messageBytes[53]
        else
            keyP["eb1_fault"] = 0
        end
        if (#binData > 54) then
            keyP["total_control"] = messageBytes[55]
            keyP["version_number"] = messageBytes[54]
        else
            keyP["total_control"] = 0
            keyP["version_number"] = 0
        end
        if (#binData > 55) then
            keyP["self_clean_time"] = messageBytes[56]
        else
            keyP["self_clean_time"] = 0
        end
        if (#binData > 57) then
            keyP["humidity_algorithm"] = bit.band(messageBytes[57], 0x01)
            keyP["pm2_5_algorithm"] = bit.rshift(
                                          bit.band(messageBytes[57], 0x02), 1)
            keyP["co2_algorithm"] = bit.rshift(bit.band(messageBytes[57], 0x04),
                                               2)
            keyP["temp_algorithm"] = bit.rshift(
                                         bit.band(messageBytes[57], 0x08), 3)
            keyP["total_time_switch"] = bit.rshift(
                                            bit.band(messageBytes[57], 0x10), 4)
            keyP["eight_degree_heat"] = messageBytes[58]
            keyP["eight_degree_heat_remember"] = messageBytes[59]
            keyP["limit_dry_switch_set"] = bit.rshift(
                                               bit.band(messageBytes[57], 0x20),
                                               5)
            keyP["prevent_super_cool"] = bit.rshift(
                                             bit.band(messageBytes[57], 0x40), 6)
        else
            keyP["eight_degree_heat"] = 0
            keyP["eight_degree_heat_remember"] = 0
        end
        if (#binData > 59) then
            keyP["main_control_software_version"] =
                bit.band(bit.lshift(messageBytes[61], 8), messageBytes[60])
            keyP["main_control_parm_version"] =
                bit.band(bit.lshift(messageBytes[63], 8), messageBytes[62])
            keyP["out_machine_parm_version"] =
                bit.band(bit.lshift(messageBytes[65], 8), messageBytes[64])
            if (#binData > 68) then
                keyP["current_wind_speed"] = messageBytes[68]
                keyP["current_down_wind_speed"] = messageBytes[69]
            end
        else
            keyP["main_control_software_version"] = 0
            keyP["main_control_parm_version"] = 0
            keyP["out_machine_parm_version"] = 0
        end
        if (#binData > 67) then
            if (bit.band(messageBytes[67], 0x80) == 0x80) then
                keyP["down_humidity"] = (0 -
                                            bit.band(
                                                bit.bnot(
                                                    messageBytes[67] * 256 +
                                                        messageBytes[66]) + 1,
                                                0xffff)) / 100
            else
                keyP["down_humidity"] = (messageBytes[66] + messageBytes[67] *
                                            256) / 100
            end
        end
        if (#binData > 69) then
            keyP["full_time_hour"] = bit.bor(bit.bor(
                                                 bit.bor(messageBytes[70],
                                                         bit.lshift(
                                                             messageBytes[71], 8)),
                                                 bit.lshift(messageBytes[72], 16)),
                                             bit.lshift(messageBytes[73], 24))
            keyP["full_time_min"] = messageBytes[74]
        end
        if (#binData > 75) then
            keyP["humidityValue"] = messageBytes[75]
            keyP["last_humidity"] = messageBytes[76]
        end
        if (#binData > 76) then
            keyP["rewarming_dry"] = bit.band(messageBytes[77], 0x01)
            keyP["has_rewarming_dry"] = bit.rshift(
                                            bit.band(messageBytes[77], 0x02), 1)
        end
        keyP["voice_control"] = messageBytes[36]
        keyP["right_wind_speed"] = messageBytes[37]
        keyP["humi_on_value"] = messageBytes[38]
        keyP["comfort_fresh_air"] = messageBytes[39]
        keyP["remove_peculiar_smell"] = messageBytes[42]
        keyP["remove_arofene"] = messageBytes[43]
    end
    if (dataType == 0x10) then
        if (#binData < 15) then return nil end
        keyP["fanspeedRealValue"] = messageBytes[5]
        if (bit.band(messageBytes[8], 0x80) == 0x80) then
            keyP["indoorTemperature"] = (0 -
                                            bit.band(
                                                bit.bnot(
                                                    messageBytes[8] * 256 +
                                                        messageBytes[7]) + 1,
                                                0xffff)) / 100
        else
            keyP["indoorTemperature"] =
                (messageBytes[7] + messageBytes[8] * 256) / 100
        end
        keyP["modeClashValue"] = bit.rshift(bit.band(messageBytes[17], 0x04), 2)
        keyP["indoorPm25"] = (messageBytes[24] + messageBytes[25] * 256)
        keyP["indoorTvoc"] = (messageBytes[26] + messageBytes[27] * 256)
        keyP["indoorCo2"] = (messageBytes[28] + messageBytes[29] * 256)
        keyP["indoorHumidity"] = messageBytes[30]
        keyP["filterTime"] = messageBytes[32]
        keyP["humidity_enabling"] = bit.rshift(bit.band(messageBytes[33], 0x08),
                                               3)
        keyP["purifyFilterTime"] = messageBytes[34]
        keyP["freshFilterTime"] = messageBytes[63]
        keyP["returnAirPanelSelect"] = bit.band(messageBytes[64], 0x01)
        keyP["airPanelSelect"] = bit.rshift(bit.band(messageBytes[64], 0x02), 1)
        keyP["windLeftRightSelect"] = bit.rshift(
                                          bit.band(messageBytes[64], 0x04), 2)
        keyP["noWindSenseSelect"] = bit.rshift(bit.band(messageBytes[64], 0x08),
                                               3)
        keyP["has_purifier"] = bit.rshift(bit.band(messageBytes[64], 0x20), 5)
        keyP["selfCleanState"] = messageBytes[71]
        keyP["selfCleanRunTime"] = messageBytes[72]
        keyP["humidifier_water_tank"] = bit.band(messageBytes[73], 0x0F)
        keyP["auto_piping"] = bit.rshift(bit.band(messageBytes[73], 0x10), 4)
        keyP["force_drainage"] = bit.rshift(bit.band(messageBytes[73], 0x20), 5)
        keyP["prevent_condensation"] = bit.rshift(
                                           bit.band(messageBytes[73], 0x40), 6)
        keyP["water_tank_load"] =
            bit.rshift(bit.band(messageBytes[73], 0x80), 7)
        keyP["humidifier_over_flow_protect"] = bit.band(messageBytes[74], 0x01)
        keyP["heat_water_tank_protect"] = bit.rshift(
                                              bit.band(messageBytes[74], 0x02),
                                              1)
        keyP["voltage_protect"] =
            bit.rshift(bit.band(messageBytes[74], 0x04), 2)
        keyP["ptc_protect"] = bit.rshift(bit.band(messageBytes[74], 0x08), 3)
        keyP["electric_leakage_protect"] = bit.rshift(
                                               bit.band(messageBytes[74], 0x10),
                                               4)
        keyP["machine_electric_protect"] = bit.rshift(
                                               bit.band(messageBytes[74], 0x20),
                                               5)
        keyP["relay_bonding_fault"] = bit.rshift(
                                          bit.band(messageBytes[74], 0x40), 6)
        keyP["humidifier_freezing_protect"] =
            bit.rshift(bit.band(messageBytes[74], 0x80), 7)
        keyP["error_linking_fault"] = bit.band(messageBytes[75], 0x01)
        keyP["zero_point_fault"] = bit.rshift(bit.band(messageBytes[75], 0x02),
                                              1)
        keyP["humidity_sensor_lock"] = bit.rshift(
                                           bit.band(messageBytes[75], 0x04), 2)
        keyP["drain_valve_leakage"] = bit.rshift(
                                          bit.band(messageBytes[75], 0x08), 3)
        keyP["hydrate_valve_leakage"] = bit.rshift(
                                            bit.band(messageBytes[75], 0x10), 4)
        keyP["humidity_sensor_fault"] = bit.rshift(
                                            bit.band(messageBytes[75], 0x20), 5)
        keyP["humidifier_communicate_fault"] =
            bit.rshift(bit.band(messageBytes[75], 0x40), 6)
        keyP["linking_humidifier_address"] = messageBytes[76]
        keyP["humidifier_temp_low"] = messageBytes[77]
        keyP["humidifier_temp_high"] = messageBytes[78]
        keyP["pm_sensor_chosen"] = bit.band(messageBytes[79], 0x01)
        keyP["co2_sensor_chosen"] = bit.rshift(bit.band(messageBytes[79], 0x02),
                                               1)
        keyP["tvoc_sensor_chosen"] = bit.rshift(
                                         bit.band(messageBytes[79], 0x04), 2)
        keyP["pyroelectricity_sensor_chosen"] =
            bit.rshift(bit.band(messageBytes[79], 0x08), 3)
        keyP["thermopile_sensor_chosen"] = bit.rshift(
                                               bit.band(messageBytes[79], 0x10),
                                               4)
        keyP["temperatureLevel"] = bit.band(messageBytes[86], 0x03)
        keyP["humidityLevel"] = bit.rshift(bit.band(messageBytes[86], 0x0C), 2)
        keyP["purifierLevel"] = bit.rshift(bit.band(messageBytes[86], 0x30), 4)
        keyP["freshLevel"] = bit.rshift(bit.band(messageBytes[86], 0xC0), 6)
        keyP["tvocLevel"] = bit.band(messageBytes[87], 0x03)
        keyP["totalAirLevel"] = bit.rshift(bit.band(messageBytes[87], 0x0C), 2)
        if (messageBytes[80] == 0x31) then
            keyP["sn8_string"] = "00000001"
        else
            keyP["sn8_string"] = "00000000"
        end
        keyP["indoor_return_panel_transport"] =
            bit.rshift(bit.band(messageBytes[15], 0x02), 1)
        keyP["indoor_outlet_panel_transport"] =
            bit.rshift(bit.band(messageBytes[15], 0x04), 2)
        keyP["indoor_pyroelectric_sensor"] =
            bit.rshift(bit.band(messageBytes[15], 0x40), 6)
        keyP["tvoc_sensor"] = bit.band(messageBytes[16], 0x01)
        keyP["sensor_t1"] = bit.rshift(bit.band(messageBytes[16], 0x02), 1)
        keyP["sensor_t2"] = bit.rshift(bit.band(messageBytes[16], 0x04), 2)
        keyP["sensor_t2b_indoor"] = bit.rshift(bit.band(messageBytes[16], 0x08),
                                               3)
        keyP["indoor_fan_lose_speed"] = bit.rshift(
                                            bit.band(messageBytes[16], 0x10), 4)
        keyP["indoor_hum_sensor"] = bit.rshift(bit.band(messageBytes[16], 0x20),
                                               5)
        keyP["indoor_e"] = bit.rshift(bit.band(messageBytes[16], 0x40), 6)
        keyP["indoor_e_parameter"] = bit.rshift(
                                         bit.band(messageBytes[16], 0x80), 7)
        keyP["ammeter"] = bit.band(messageBytes[17], 0x01)
        keyP["co2_sensor"] = bit.rshift(bit.band(messageBytes[17], 0x02), 1)
        keyP["mode_conflict"] = bit.rshift(bit.band(messageBytes[17], 0x04), 2)
        keyP["prevent_cold_wind_protect"] =
            bit.rshift(bit.band(messageBytes[17], 0x10), 4)
        keyP["sensor_t2c_indoor"] = bit.rshift(bit.band(messageBytes[17], 0x20),
                                               5)
        keyP["sensor_t2d_indoor"] = bit.rshift(bit.band(messageBytes[17], 0x40),
                                               6)
        keyP["sensor_t2a_indoor"] = bit.rshift(bit.band(messageBytes[17], 0x80),
                                               7)
        keyP["evaporator_temp_high_protect"] =
            bit.rshift(bit.band(messageBytes[18], 0x04), 2)
        keyP["evaporator_temp_fre_limit"] =
            bit.rshift(bit.band(messageBytes[18], 0x08), 3)
        keyP["new_wind_anti_condensation_protect"] =
            bit.rshift(bit.band(messageBytes[18], 0x10), 4)
        keyP["new_wind_out_temp_low_protect"] =
            bit.rshift(bit.band(messageBytes[18], 0x20), 5)
        keyP["new_wind_out_temp_high_protect"] =
            bit.rshift(bit.band(messageBytes[18], 0x40), 6)
        keyP["new_wind_pm_high_protect"] = bit.rshift(
                                               bit.band(messageBytes[18], 0x80),
                                               7)
        keyP["new_wind_out_low_temp"] = bit.band(messageBytes[21], 0x01)
        keyP["new_wind_low_anti_condensation_protect"] =
            bit.rshift(bit.band(messageBytes[21], 0x02), 1)
        keyP["new_wind_pm_high"] = bit.rshift(bit.band(messageBytes[21], 0x04),
                                              2)
        keyP["indoor_smart_eye"] = bit.rshift(bit.band(messageBytes[21], 0x08),
                                              3)
        keyP["new_wind_temp_sensor"] = bit.rshift(
                                           bit.band(messageBytes[21], 0x10), 4)
        keyP["new_wind_hum_sensor"] = bit.rshift(
                                          bit.band(messageBytes[21], 0x20), 5)
        keyP["new_wind_pm2_5_sensor"] = bit.rshift(
                                            bit.band(messageBytes[21], 0x40), 6)
        keyP["outdoor_fan_lose_speed"] = bit.rshift(
                                             bit.band(messageBytes[22], 0x02), 1)
        keyP["water_full_protect"] = bit.rshift(
                                         bit.band(messageBytes[22], 0x40), 6)
    end
    if (dataType == 0x12) then
        if (#binData < 15) then return nil end
        keyP["water_model_mode_clash"] = bit.rshift(
                                             bit.band(messageBytes[4], 0x02), 1)
        keyP["water_model_clean_time"] = messageBytes[30]
        keyP["tr_out_fault"] = bit.rshift(bit.band(messageBytes[1], 0x02), 1)
        keyP["tr_in_fault"] = bit.rshift(bit.band(messageBytes[1], 0x04), 2)
        keyP["standby_anti_freezing_protection"] =
            bit.rshift(bit.band(messageBytes[1], 0x10), 4)
        keyP["dc_pump_stall_protection"] = bit.band(messageBytes[2], 0x01)
        keyP["water_switch_fault"] = bit.rshift(bit.band(messageBytes[2], 0x06),
                                                1)
        keyP["tw_in_fault"] = bit.rshift(bit.band(messageBytes[2], 0x08), 3)
        keyP["tw_out_fault"] = bit.rshift(bit.band(messageBytes[2], 0x10), 4)
        keyP["tw1_fault"] = bit.rshift(bit.band(messageBytes[2], 0x20), 5)
        keyP["indoor_e"] = bit.rshift(bit.band(messageBytes[2], 0x40), 6)
        keyP["indoor_e_parameter"] = bit.rshift(bit.band(messageBytes[2], 0x80),
                                                7)
        keyP["tw1b_fault"] = bit.band(messageBytes[3], 0x01)
        keyP["temp_sensor_drop_fault"] = bit.rshift(
                                             bit.band(messageBytes[3], 0x20), 5)
        keyP["water_templow_protection"] = bit.rshift(
                                               bit.band(messageBytes[3], 0x40),
                                               6)
    end
    if (dataType == 0x40) then
        if (#binData < 15) then return nil end
        if (bit.band(messageBytes[6], 0x80) == 0x80) then
            keyP["outdoorTemperature"] = (0 -
                                             bit.band(
                                                 bit.bnot(
                                                     messageBytes[6] * 256 +
                                                         messageBytes[5]) + 1,
                                                 0xffff)) / 100
        else
            keyP["outdoorTemperature"] =
                (messageBytes[5] + messageBytes[6] * 256) / 100
        end
        keyP["freshAirMachineNumber"] = messageBytes[73]
        keyP["humidityMachineNumber"] = messageBytes[74]
        keyP["outdoor_e"] = bit.band(messageBytes[19], 0x01)
        keyP["sensor_t3"] = bit.rshift(bit.band(messageBytes[19], 0x02), 1)
        keyP["sensor_t4"] = bit.rshift(bit.band(messageBytes[19], 0x04), 2)
        keyP["sensor_tp"] = bit.rshift(bit.band(messageBytes[19], 0x08), 3)
        keyP["sensor_refrigerant_pipe_temp"] =
            bit.rshift(bit.band(messageBytes[19], 0x10), 4)
        keyP["voltage_protect"] =
            bit.rshift(bit.band(messageBytes[19], 0x20), 5)
        keyP["compressor_temp_protect"] = bit.rshift(
                                              bit.band(messageBytes[19], 0x80),
                                              7)
        keyP["out_main_drive_transport"] = bit.band(messageBytes[20], 0x01)
        keyP["compressor_current_circuit"] =
            bit.rshift(bit.band(messageBytes[20], 0x02), 1)
        keyP["compressor_start"] = bit.rshift(bit.band(messageBytes[20], 0x04),
                                              2)
        keyP["phase_lost_protect"] = bit.rshift(
                                         bit.band(messageBytes[20], 0x08), 3)
        keyP["compressor_zero_protect"] = bit.rshift(
                                              bit.band(messageBytes[20], 0x10),
                                              4)
        keyP["out_341_sync"] = bit.rshift(bit.band(messageBytes[20], 0x20), 5)
        keyP["compressor_lose_speed_protect"] =
            bit.rshift(bit.band(messageBytes[20], 0x40), 6)
        keyP["compressor_position_protect"] =
            bit.rshift(bit.band(messageBytes[20], 0x80), 7)
        keyP["compressor_over_current"] = bit.rshift(
                                              bit.band(messageBytes[21], 0x02),
                                              1)
        keyP["outdoor_ipm"] = bit.rshift(bit.band(messageBytes[21], 0x04), 2)
        keyP["out_current_protect"] = bit.rshift(
                                          bit.band(messageBytes[21], 0x40), 6)
        keyP["refrigerant_tube_condensation"] =
            bit.rshift(bit.band(messageBytes[21], 0x80), 7)
        keyP["exhaust_high_temp_fre_limit"] = bit.band(messageBytes[22], 0x01)
        keyP["compressor_high_temp_protect"] =
            bit.rshift(bit.band(messageBytes[22], 0x02), 1)
        keyP["condenser_high_temp_fre_limit"] =
            bit.rshift(bit.band(messageBytes[22], 0x04), 2)
        keyP["grid_protect"] = bit.rshift(bit.band(messageBytes[22], 0x08), 3)
        keyP["system_pressure_high_fre_limit"] =
            bit.rshift(bit.band(messageBytes[22], 0x10), 4)
        keyP["system_pressure_high_protect"] =
            bit.rshift(bit.band(messageBytes[22], 0x20), 5)
        keyP["system_pressure_low_fre_limit"] =
            bit.rshift(bit.band(messageBytes[22], 0x40), 6)
        keyP["system_pressure_low_protect"] =
            bit.rshift(bit.band(messageBytes[22], 0x80), 7)
        keyP["voltage_fre_limit"] = bit.band(messageBytes[23], 0x01)
        keyP["current_fre_limit"] = bit.rshift(bit.band(messageBytes[23], 0x02),
                                               1)
        keyP["pfc_switch_stop"] =
            bit.rshift(bit.band(messageBytes[23], 0x04), 2)
        keyP["pfc_fre_limit"] = bit.rshift(bit.band(messageBytes[23], 0x08), 3)
        keyP["sensor_high_pressure"] = bit.rshift(
                                           bit.band(messageBytes[25], 0x02), 1)
        keyP["sensor_low_pressure"] = bit.rshift(
                                          bit.band(messageBytes[25], 0x04), 2)
        keyP["sensor_inhale_temp"] = bit.rshift(
                                         bit.band(messageBytes[25], 0x08), 3)
        keyP["sensor_cold_temp"] = bit.rshift(bit.band(messageBytes[25], 0x10),
                                              4)
        keyP["sensor_refrigerant_pipe_temp"] =
            bit.rshift(bit.band(messageBytes[25], 0x20), 5)
        keyP["new_wind_transport"] = bit.rshift(
                                         bit.band(messageBytes[25], 0x80), 7)
        keyP["four_way_valve_crossing_protect"] =
            bit.band(messageBytes[26], 0x01)
        keyP["four_way_valve_crossing"] = bit.rshift(
                                              bit.band(messageBytes[26], 0x02),
                                              1)
        keyP["system_pressure_protect"] = bit.rshift(
                                              bit.band(messageBytes[26], 0x10),
                                              4)
        keyP["sensor_spray_enthalpy_enter_temp"] =
            bit.rshift(bit.band(messageBytes[26], 0x20), 5)
        keyP["sensor_spray_enthalpy_out_temp"] =
            bit.rshift(bit.band(messageBytes[26], 0x40), 6)
    end
    if (dataType == 0x30) then
        if (bit.band(messageBytes[1], 0x80) == 0x80) then
            keyP["t1_temp"] = (0 -
                                  bit.band(
                                      bit.bnot(
                                          messageBytes[1] * 256 +
                                              messageBytes[0]) + 1, 0xffff)) /
                                  100
        else
            keyP["t1_temp"] = (messageBytes[0] + messageBytes[1] * 256) / 100
        end
        if (bit.band(messageBytes[3], 0x80) == 0x80) then
            keyP["t2_temp"] = (0 -
                                  bit.band(
                                      bit.bnot(
                                          messageBytes[3] * 256 +
                                              messageBytes[2]) + 1, 0xffff)) /
                                  100
        else
            keyP["t2_temp"] = (messageBytes[2] + messageBytes[3] * 256) / 100
        end
        if (bit.band(messageBytes[5], 0x80) == 0x80) then
            keyP["t3_temp"] = (0 -
                                  bit.band(
                                      bit.bnot(
                                          messageBytes[5] * 256 +
                                              messageBytes[4]) + 1, 0xffff)) /
                                  100
        else
            keyP["t3_temp"] = (messageBytes[4] + messageBytes[5] * 256) / 100
        end
        if (bit.band(messageBytes[7], 0x80) == 0x80) then
            keyP["t4_temp"] = (0 -
                                  bit.band(
                                      bit.bnot(
                                          messageBytes[7] * 256 +
                                              messageBytes[6]) + 1, 0xffff)) /
                                  100
        else
            keyP["t4_temp"] = (messageBytes[6] + messageBytes[7] * 256) / 100
        end
        keyP["dust_co2"] = bit.bor(bit.lshift(messageBytes[47], 8),
                                   messageBytes[46])
        keyP["co2_concentration"] = bit.bor(bit.lshift(messageBytes[58], 8),
                                            messageBytes[57])
        keyP["wind_speed_real_ac"] = messageBytes[16]
        keyP["indoor_e0_fault"] =
            bit.rshift(bit.band(messageBytes[17], 0x04), 2)
        keyP["indoor_ea_fault"] =
            bit.rshift(bit.band(messageBytes[21], 0x20), 5)
        keyP["indoor_e3_fault"] =
            bit.rshift(bit.band(messageBytes[17], 0x08), 3)
        keyP["indoor_fe_fault"] =
            bit.rshift(bit.band(messageBytes[18], 0x20), 5)
        keyP["outdoor_e51_fault"] = bit.band(messageBytes[26], 0x01)
        keyP["outdoor_e52_fault"] = bit.rshift(bit.band(messageBytes[26], 0x02),
                                               1)
        keyP["outdoor_e53_fault"] = bit.rshift(bit.band(messageBytes[26], 0x04),
                                               2)
        keyP["outdoor_e54_fault"] = bit.rshift(bit.band(messageBytes[26], 0x08),
                                               3)
        keyP["indoor_e60_fault"] = bit.band(messageBytes[17], 0x01)
        keyP["indoor_e61_fault"] = bit.rshift(bit.band(messageBytes[17], 0x02),
                                              1)
        keyP["outdoor_e7_fault"] = bit.rshift(bit.band(messageBytes[26], 0x40),
                                              6)
        keyP["rfid_fault"] = bit.rshift(bit.band(messageBytes[22], 0x20), 5)
        keyP["indoor_eb1_fault"] = bit.rshift(bit.band(messageBytes[22], 0x10),
                                              4)
        keyP["pl_fault"] = bit.rshift(bit.band(messageBytes[18], 0x02), 1)
        keyP["fresh_ptc_load"] = bit.rshift(bit.band(messageBytes[25], 0x80), 7)
        keyP["defrosting"] = bit.band(messageBytes[23], 0x01)
        keyP["re_elec_heat"] = bit.rshift(bit.band(messageBytes[23], 0x02), 1)
    end
    if (dataType == 0x31) then keyP["humidity_value"] = messageBytes[58] end
    if (dataType == 0x20) then
        if (bit.band(messageBytes[13], 0x80) == 0x80) then
            keyP["down_humidity"] = (0 -
                                        bit.band(
                                            bit.bnot(
                                                messageBytes[13] * 256 +
                                                    messageBytes[12]) + 1,
                                            0xffff)) / 100
        else
            keyP["down_humidity"] =
                (messageBytes[12] + messageBytes[13] * 256) / 100
        end
    end
    if (dataType == 0x32) then
        keyP["wind_speed_real"] = messageBytes[12]
        keyP["disinfect_time"] = bit.bor(bit.lshift(messageBytes[15], 8),
                                         messageBytes[14])
        keyP["wet_film_time"] = bit.bor(bit.lshift(messageBytes[17], 8),
                                        messageBytes[16])
        keyP["filter_time"] = bit.bor(bit.lshift(messageBytes[19], 8),
                                      messageBytes[18])
        keyP["ac_filter_time"] = messageBytes[33]
        keyP["water_tank_water"] = bit.rshift(bit.band(messageBytes[22], 0x04),
                                              2)
        keyP["water_tank_board"] = bit.rshift(bit.band(messageBytes[22], 0x08),
                                              3)
        keyP["indoor_e3_1_fault"] = bit.rshift(bit.band(messageBytes[6], 0x02),
                                               1)
        keyP["clean_running_stage"] = bit.band(messageBytes[21], 0x07)
    end
    if (dataType == 0xC0) then
        keyP["ambition_tunnel"] = messageBytes[0]
        keyP["tunnel_status"] = messageBytes[1]
        keyP["category_tag"] = bit.bor(bit.lshift(messageBytes[7], 8),
                                       messageBytes[6])
        keyP["filter_available_time"] = string.char(messageBytes[15],
                                                    messageBytes[16],
                                                    messageBytes[17])
        keyP["filter_available_time"] =
            tonumber(keyP["filter_available_time"]) * 100
        keyP["filter_used_time"] = bit.bor(bit.lshift(messageBytes[35], 8),
                                           messageBytes[34])
    end
end
local function getAcMsg(bodyData, cType)
    local bodyLength = #bodyData
    local msgLength = bodyLength + 0x0A + 1
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = 0xAA
    msgBytes[1] = bodyLength + 0x0A + 1
    msgBytes[2] = 0xAC
    msgBytes[8] = 0x02
    if (cType == keyB["BYTE_QUERYL_REQUEST"] or cType ==
        keyB["BYTE_QUERY_RUN_REQUEST"] or cType ==
        keyB["BYTE_QUERY_OUT_RUN_REQUEST"] or cType ==
        keyB["BYTE_QUERY_WATER_RUN_REQUEST"]) then
        msgBytes[9] = 0x03
    else
        msgBytes[9] = 0x02
    end
    for i = 0, bodyLength do msgBytes[i + 0x0A] = bodyData[i] end
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    local msgFinal = {}
    for i = 1, msgLength + 1 do msgFinal[i] = msgBytes[i - 1] end
    return msgFinal
end
local function getTotalMsg(bodyData, cType)
    local bodyLength = 0
    if (bodyData ~= nil) then bodyLength = #bodyData end
    local msgLength = bodyLength + 3 + 2
    if (bodyData == nil) then msgLength = 7 end
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = keyB["BYTE_PROTOCOL_HEAD"]
    msgBytes[1] = cType
    msgBytes[2] = msgLength + 1
    if (bodyData ~= nil) then
        for i = 0, bodyLength do msgBytes[i + 3] = bodyData[i] end
    end
    msgBytes[msgLength - 1] = crc8_854(msgBytes, 0, msgLength - 2)
    msgBytes[msgLength] = makeSum(msgBytes, 1, msgLength - 1)
    return getAcMsg(msgBytes, cType)
end
local function getQueryMsg(bodyData, cType)
    local bodyLength = 0
    if (bodyData ~= nil) then bodyLength = #bodyData end
    local msgLength = bodyLength + keyB["BYTE_PROTOCOL_LENGTH"] + 2
    if (bodyData == nil) then msgLength = 7 end
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = keyB["BYTE_PROTOCOL_HEAD"]
    msgBytes[1] = msgLength + 1
    msgBytes[2] = 0x00
    msgBytes[3] = 0xFF
    msgBytes[4] = 0xFF
    msgBytes[5] = cType
    if (bodyData ~= nil) then
        for i = 0, bodyLength do
            msgBytes[i + keyB["BYTE_PROTOCOL_LENGTH"]] = bodyData[i]
        end
    end
    msgBytes[msgLength - 1] = crc8_854(msgBytes, 0, msgLength - 2)
    msgBytes[msgLength] = makeSum(msgBytes, 0, msgLength - 1)
    return getAcMsg(msgBytes, cType)
end
local function getStatusMsg(bodyData, cType)
    local bodyLength = 0
    local tempData = {}
    if (cType == 0x11) then
        for i = 0, 6 do tempData[i] = 0 end
    else
        for i = 0, 7 do tempData[i] = 0 end
    end
    if (tempData ~= nil) then bodyLength = #tempData end
    local msgLength = bodyLength + 3 + 2
    if (tempData == nil) then msgLength = 7 end
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = keyB["BYTE_PROTOCOL_HEAD"]
    msgBytes[1] = cType
    msgBytes[2] = msgLength + 1
    if (tempData ~= nil) then
        for i = 0, bodyLength do
            msgBytes[i + keyB["BYTE_PROTOCOL_LENGTH"]] = tempData[i]
        end
    end
    msgBytes[msgLength - 1] = crc8_854(msgBytes, 0, msgLength - 2)
    msgBytes[msgLength] = makeSum(msgBytes, 0, msgLength - 1)
    return getAcMsg(msgBytes, cType)
end
local function getMachineMsg(bodyData, cType, tag)
    local bodyLength = 0
    local tempData = {}
    for i = 0, 6 do tempData[i] = 0 end
    if (tempData ~= nil) then bodyLength = #tempData end
    local msgLength = bodyLength + 3 + 2
    if (tempData == nil) then msgLength = 7 end
    local msgBytes = {}
    for i = 0, msgLength do msgBytes[i] = 0 end
    msgBytes[0] = keyB["BYTE_PROTOCOL_HEAD"]
    msgBytes[1] = cType
    msgBytes[2] = msgLength + 1
    msgBytes[3] = tag
    if (tempData ~= nil) then
        for i = 0, bodyLength do msgBytes[i + 4] = tempData[i] end
    end
    msgBytes[msgLength - 1] = crc8_854(msgBytes, 0, msgLength - 2)
    msgBytes[msgLength] = makeSum(msgBytes, 0, msgLength - 1)
    return getAcMsg(msgBytes, cType)
end
function jsonToData(jsonCmd)
    if (#jsonCmd == 0) then return nil end
    local infoM = {}
    local json = decode(jsonCmd)
    deviceSubType = json["deviceinfo"]["deviceSubType"]
    local deviceSN = json["deviceinfo"]["deviceSN"]
    if deviceSN ~= nil then deviceSN8 = string.sub(deviceSN, 4, 8) end
    local query = json["query"]
    local control = json["control"]
    local status = json["status"]
    keyP["control_flag"] = 0
    if (query) then
        local queryType = nil
        if (type(query) == "table") then queryType = query["query_type"] end
        if (queryType == "run_status") then
            infoM = getQueryMsg(nil, keyB["BYTE_QUERY_RUN_REQUEST"])
        elseif (queryType == "out_run_status") then
            infoM = getQueryMsg(nil, keyB["BYTE_QUERY_OUT_RUN_REQUEST"])
        elseif (queryType == "water_model_run_status") then
            infoM = getQueryMsg(nil, keyB["BYTE_QUERY_WATER_RUN_REQUEST"])
        elseif (queryType == "module_c0") then
            infoM = getTotalMsg(nil, 0xC0)
        elseif (queryType == "module_30") then
            infoM = getStatusMsg(nil, 0x30)
        elseif (queryType == "module_31") then
            infoM = getStatusMsg(nil, 0x31)
        elseif (queryType == "module_32") then
            infoM = getStatusMsg(nil, 0x32)
        elseif (queryType == "module_c0_0") then
            infoM = getMachineMsg(nil, 0xC0, 0)
        elseif (queryType == "module_c0_1") then
            infoM = getMachineMsg(nil, 0xC0, 1)
        elseif (queryType == "module_c0_2") then
            infoM = getMachineMsg(nil, 0xC0, 2)
        elseif (queryType == "module_c0_3") then
            infoM = getMachineMsg(nil, 0xC0, 3)
        elseif (queryType == "module_c0_4") then
            infoM = getMachineMsg(nil, 0xC0, 4)
        elseif (queryType == "module_c0_5") then
            infoM = getMachineMsg(nil, 0xC0, 5)
        elseif (queryType == "module_c2_0") then
            infoM = getMachineMsg(nil, 0xC2, 0)
        elseif (queryType == "module_c2_1") then
            infoM = getMachineMsg(nil, 0xC2, 1)
        elseif (queryType == "module_c2_2") then
            infoM = getMachineMsg(nil, 0xC2, 2)
        elseif (queryType == "module_c2_3") then
            infoM = getMachineMsg(nil, 0xC2, 3)
        elseif (queryType == "module_c2_4") then
            infoM = getMachineMsg(nil, 0xC2, 4)
        elseif (queryType == "module_c2_5") then
            infoM = getMachineMsg(nil, 0xC2, 5)
        else
            infoM = getStatusMsg(nil, keyB["BYTE_QUERYL_REQUEST"])
        end
    elseif (control) then
        if (status) then JsonToModel(status, "status") end
        if (control) then JsonToModel(control, "control") end
        if (keyP["filterTimeReset"] == 0x01 or keyP["purifyFilterTimeReset"] ==
            0x01 or keyP["freshFilterTimeReset"] == 0x01) then
            local bodyBytes = {}
            for i = 0, 1 do bodyBytes[i] = 0 end
            bodyBytes[0] = bit.bor(bit.lshift(keyP["filterTimeReset"], 6),
                                   bodyBytes[0])
            bodyBytes[0] = bit.bor(bit.lshift(keyP["purifyFilterTimeReset"], 7),
                                   bodyBytes[0])
            bodyBytes[1] = bit.bor(keyP["freshFilterTimeReset"], bodyBytes[1])
            infoM = getTotalMsg(bodyBytes, keyB["BYTE_CONTROL_RESET_REQUEST"])
            keyP["filterTimeReset"] = 0
            keyP["purifyFilterTimeReset"] = 0
            keyP["freshFilterTimeReset"] = 0
            local ret = table2string(infoM)
            ret = string2hexstring(ret)
            return ret
        end
        local bodyBytes = {}
        if (keyP["control_flag"] == 1) then
            bodyBytes[0] = 0x01
            bodyBytes[1] = 0x01
            bodyBytes[2] = 0x00
            bodyBytes[3] = 0x01
            bodyBytes[4] = keyP["total_control"]
            infoM = getTotalMsg(bodyBytes, 0xF1)
        elseif (keyP["control_flag"] == 2) then
            bodyBytes[0] = 0x01
            bodyBytes[1] = 0x02
            bodyBytes[2] = 0x00
            bodyBytes[3] = 0x01
            bodyBytes[4] = 0x00
            bodyBytes[4] = bit.bor(keyP["humidity_algorithm"], bodyBytes[4])
            bodyBytes[4] = bit.bor(bit.lshift(keyP["pm2_5_algorithm"], 1),
                                   bodyBytes[4])
            bodyBytes[4] = bit.bor(bit.lshift(keyP["co2_algorithm"], 2),
                                   bodyBytes[4])
            bodyBytes[4] = bit.bor(bit.lshift(keyP["temp_algorithm"], 3),
                                   bodyBytes[4])
            bodyBytes[4] = bit.bor(bit.lshift(keyP["total_time_switch"], 4),
                                   bodyBytes[4])
            bodyBytes[4] = bit.bor(bit.lshift(keyP["recommend_mode_switch"], 5),
                                   bodyBytes[4])
            infoM = getTotalMsg(bodyBytes, 0xF1)
        elseif (keyP["control_flag"] == 3) then
            bodyBytes[0] = 0x01
            bodyBytes[1] = 0x03
            bodyBytes[2] = 0x00
            bodyBytes[3] = 0x01
            bodyBytes[4] = keyP["limit_dry_switch_set"]
            infoM = getTotalMsg(bodyBytes, 0xF1)
        else
            for i = 0, 59 do bodyBytes[i] = 0 end
            bodyBytes[0] = keyP["modeValue"]
            bodyBytes[1] =
                (keyP["temperature"] + keyP["small_temperature"]) * 2 + 30
            bodyBytes[2] = keyP["fanspeedValue"]
            bodyBytes[3] = keyP["ability_test"]
            bodyBytes[4] = keyP["humidityValue"]
            bodyBytes[5] = bit.bor(keyP["standby_clean"], bodyBytes[5])
            bodyBytes[5] = bit.bor(bit.lshift(keyP["display_status"], 1),
                                   bodyBytes[5])
            bodyBytes[5] = bit.bor(bit.lshift(keyP["mute_voice"], 2),
                                   bodyBytes[5])
            bodyBytes[5] = bit.bor(bit.lshift(keyP["cool_hot_sense"], 3),
                                   bodyBytes[5])
            bodyBytes[5] = bit.bor(bit.lshift(keyP["low_power_cost"], 4),
                                   bodyBytes[5])
            bodyBytes[5] = bit.bor(bit.lshift(keyP["dry_clean"], 5),
                                   bodyBytes[5])
            bodyBytes[5] = bit.bor(bit.lshift(keyP["strongWindValue"], 6),
                                   bodyBytes[5])
            bodyBytes[5] = bit.bor(bit.lshift(keyP["communication_fault"], 7),
                                   bodyBytes[5])
            bodyBytes[6] = bit.bor(keyP["smart_eye"], bodyBytes[6])
            bodyBytes[6] = bit.bor(bit.lshift(keyP["horizontal_swing_left"], 2),
                                   bodyBytes[6])
            bodyBytes[6] = bit.bor(
                               bit.lshift(keyP["horizontal_swing_right"], 3),
                               bodyBytes[6])
            bodyBytes[6] = bit.bor(bit.lshift(keyP["vertical_swing_left"], 4),
                                   bodyBytes[6])
            bodyBytes[6] = bit.bor(bit.lshift(keyP["vertical_swing_right"], 5),
                                   bodyBytes[6])
            bodyBytes[6] = bit.bor(bit.lshift(keyP["power"], 6), bodyBytes[6])
            bodyBytes[6] = bit.bor(bit.lshift(keyP["solar_eco"], 7),
                                   bodyBytes[6])
            bodyBytes[7] = bit.bor(keyP["forceCoolMode"], bodyBytes[7])
            bodyBytes[7] = bit.bor(bit.lshift(keyP["forceAutoMode"], 1),
                                   bodyBytes[7])
            bodyBytes[7] = bit.bor(bit.lshift(keyP["force_defrost"], 2),
                                   bodyBytes[7])
            bodyBytes[7] = bit.bor(bit.lshift(keyP["PTCDependT4Value"], 3),
                                   bodyBytes[7])
            bodyBytes[7] =
                bit.bor(bit.lshift(keyP["PTCValue"], 4), bodyBytes[7])
            bodyBytes[7] = bit.bor(bit.lshift(keyP["do_not_disturb"], 5),
                                   bodyBytes[7])
            bodyBytes[7] = bit.bor(bit.lshift(keyP["remove_dust_full"], 6),
                                   bodyBytes[7])
            bodyBytes[7] = bit.bor(bit.lshift(keyP["clear_filter_change_time"],
                                              7), bodyBytes[7])
            bodyBytes[8] = bit.bor(keyP["self_wash"], bodyBytes[8])
            bodyBytes[8] = bit.bor(bit.lshift(keyP["energySaveValue"], 1),
                                   bodyBytes[8])
            bodyBytes[8] = bit.bor(bit.lshift(keyP["advance_cold_hot"], 2),
                                   bodyBytes[8])
            bodyBytes[8] =
                bit.bor(bit.lshift(keyP["rui_wind"], 3), bodyBytes[8])
            bodyBytes[8] = bit.bor(bit.lshift(keyP["set_i_mode"], 4),
                                   bodyBytes[8])
            bodyBytes[8] = bit.bor(bit.lshift(keyP["save_i_mode"], 5),
                                   bodyBytes[8])
            bodyBytes[8] = bit.bor(bit.lshift(keyP["reset_electricity"], 6),
                                   bodyBytes[8])
            bodyBytes[8] = bit.bor(bit.lshift(keyP["high_save_power"], 7),
                                   bodyBytes[8])
            bodyBytes[9] = bit.bor(keyP["fast_check"], bodyBytes[9])
            bodyBytes[9] = bit.bor(bit.lshift(keyP["elec_fast_check"], 1),
                                   bodyBytes[9])
            bodyBytes[9] = bit.bor(bit.lshift(keyP["total_fast_check"], 2),
                                   bodyBytes[9])
            bodyBytes[9] = bit.bor(bit.lshift(keyP["elec_dust_collect"], 3),
                                   bodyBytes[9])
            bodyBytes[9] = bit.bor(bit.lshift(keyP["huanqi_function"], 4),
                                   bodyBytes[9])
            bodyBytes[9] = bit.bor(bit.lshift(keyP["light_level"], 5),
                                   bodyBytes[9])
            bodyBytes[9] = bit.bor(bit.lshift(keyP["natural_wind"], 6),
                                   bodyBytes[9])
            bodyBytes[9] = bit.bor(bit.lshift(keyP["leave_home"], 7),
                                   bodyBytes[9])
            bodyBytes[10] = bit.bor(keyP["prevent_cold_child"], bodyBytes[10])
            bodyBytes[10] = bit.bor(bit.lshift(keyP["preventCold"], 1),
                                    bodyBytes[10])
            bodyBytes[10] = bit.bor(bit.lshift(keyP["child_comfort_sleep"], 2),
                                    bodyBytes[10])
            bodyBytes[10] = bit.bor(
                                bit.lshift(keyP["energy_save_xiaotiane"], 3),
                                bodyBytes[10])
            bodyBytes[10] = bit.bor(bit.lshift(keyP["no_wind_sense"], 4),
                                    bodyBytes[10])
            bodyBytes[10] = bit.bor(bit.lshift(keyP["try_run"], 5),
                                    bodyBytes[10])
            bodyBytes[10] = bit.bor(bit.lshift(keyP["prevent_water_enable"], 6),
                                    bodyBytes[10])
            bodyBytes[10] = bit.bor(bit.lshift(
                                        keyP["display_receive_control_button"],
                                        7), bodyBytes[10])
            bodyBytes[11] = bit.bor(keyP["comfort_sleep"], bodyBytes[11])
            bodyBytes[11] = bit.bor(bit.lshift(keyP["pmv"], 4), bodyBytes[11])
            bodyBytes[12] = bit.bor(keyP["eco"], bodyBytes[12])
            bodyBytes[12] = bit.bor(bit.lshift(keyP["eight_degree_heat"], 4),
                                    bodyBytes[12])
            bodyBytes[13] = bit.bor(keyP["buzzerValue"], bodyBytes[13])
            bodyBytes[13] = bit.bor(bit.lshift(keyP["buzzer_param"], 4),
                                    bodyBytes[13])
            bodyBytes[14] = bit.bor(keyP["display_wind_percent"], bodyBytes[14])
            bodyBytes[15] = bit.bor(keyP["display_band_limited"], bodyBytes[15])
            bodyBytes[16] = bit.bor(keyP["dr_function"], bodyBytes[16])
            bodyBytes[17] = bit.bor(keyP["second_temperature_setting"],
                                    bodyBytes[17])
            bodyBytes[18] = bit.bor(keyP["up_down_wind_direction"],
                                    bodyBytes[18])
            bodyBytes[18] = bit.bor(bit.lshift(
                                        keyP["left_right_wind_direction"], 4),
                                    bodyBytes[18])
            bodyBytes[19] = bit.bor(keyP["water_washing"], bodyBytes[19])
            bodyBytes[19] = bit.bor(bit.lshift(keyP["mosquito_repellent"], 1),
                                    bodyBytes[19])
            bodyBytes[19] = bit.bor(bit.lshift(keyP["comfort_save"], 2),
                                    bodyBytes[19])
            bodyBytes[19] = bit.bor(bit.lshift(keyP["x_fan_control"], 3),
                                    bodyBytes[19])
            bodyBytes[19] = bit.bor(
                                bit.lshift(keyP["prevent_straight_wind"], 4),
                                bodyBytes[19])
            bodyBytes[19] = bit.bor(bit.lshift(keyP["gentle_wind_sense"], 5),
                                    bodyBytes[19])
            bodyBytes[19] = bit.bor(bit.lshift(
                                        keyP["child_prevent_cold_wind_child"], 6),
                                    bodyBytes[19])
            bodyBytes[19] = bit.bor(bit.lshift(
                                        keyP["child_prevent_cold_wind_parent"],
                                        7), bodyBytes[19])
            bodyBytes[20] = bit.bor(keyP["no_wind_sense_up"], bodyBytes[20])
            bodyBytes[20] = bit.bor(bit.lshift(keyP["no_wind_sense_down"], 1),
                                    bodyBytes[20])
            bodyBytes[20] = bit.bor(bit.lshift(keyP["permanent_wind"], 2),
                                    bodyBytes[20])
            bodyBytes[20] = bit.bor(bit.lshift(keyP["temperature_unit"], 3),
                                    bodyBytes[20])
            bodyBytes[21] = keyP["smart_wind_left_degree"]
            bodyBytes[22] = keyP["smart_wind_right_degree"]
            bodyBytes[23] = bit.bor(keyP["auto_water_washing"], bodyBytes[23])
            bodyBytes[23] = bit.bor(bit.lshift(keyP["manul_water_washing"], 1),
                                    bodyBytes[23])
            bodyBytes[23] = bit.bor(
                                bit.lshift(keyP["water_washing_control"], 2),
                                bodyBytes[23])
            bodyBytes[23] = bit.bor(bit.lshift(keyP["ud_wind_accelerate"], 4),
                                    bodyBytes[23])
            bodyBytes[23] = bit.bor(bit.lshift(keyP["lr_wind_accelerate"], 5),
                                    bodyBytes[23])
            bodyBytes[23] = bit.bor(bit.lshift(keyP["prevent_trip"], 6),
                                    bodyBytes[23])
            bodyBytes[23] = bit.bor(bit.lshift(keyP["prevent_super_cool"], 7),
                                    bodyBytes[23])
            bodyBytes[24] = bit.bor(keyP["timer_message"], bodyBytes[24])
            bodyBytes[24] = bit.bor(bit.lshift(keyP["lock"], 1), bodyBytes[24])
            bodyBytes[24] = bit.bor(bit.lshift(keyP["remote_control"], 2),
                                    bodyBytes[24])
            bodyBytes[24] = bit.bor(bit.lshift(keyP["child_prevent_cold_wind"],
                                               3), bodyBytes[24])
            bodyBytes[24] = bit.bor(bit.lshift(keyP["double_water_washing"], 4),
                                    bodyBytes[24])
            bodyBytes[24] = bit.bor(bit.lshift(keyP["deep_clean"], 5),
                                    bodyBytes[24])
            bodyBytes[24] = bit.bor(bit.lshift(keyP["extreme_wind"], 6),
                                    bodyBytes[24])
            bodyBytes[25] = keyP["fn_no_wind_sense"]
            bodyBytes[26] = keyP["fresh_air_wind_precent"]
            bodyBytes[27] = keyP["auto_wash_time"]
            bodyBytes[28] = bit.bor(bit.lshift(keyP["autoNewWind"], 1),
                                    bodyBytes[28])
            bodyBytes[28] = bit.bor(bit.lshift(keyP["disinfect"], 5),
                                    bodyBytes[28])
            bodyBytes[33] = bit.bor(keyP["right_ud_wind"], bodyBytes[33])
            bodyBytes[33] = bit.bor(bit.lshift(keyP["wind_swing_left"], 1),
                                    bodyBytes[33])
            bodyBytes[33] = bit.bor(bit.lshift(keyP["wind_swing_right"], 2),
                                    bodyBytes[33])
            bodyBytes[33] = bit.bor(bit.lshift(keyP["no_wind_sense_left"], 3),
                                    bodyBytes[33])
            bodyBytes[33] = bit.bor(bit.lshift(keyP["no_wind_sense_right"], 4),
                                    bodyBytes[33])
            bodyBytes[33] = bit.bor(bit.lshift(keyP["autoHumi"], 5),
                                    bodyBytes[33])
            bodyBytes[33] = bit.bor(bit.lshift(keyP["air_exhaust"], 6),
                                    bodyBytes[33])
            bodyBytes[33] = bit.bor(bit.lshift(keyP["manuHumi"], 7),
                                    bodyBytes[33])
            bodyBytes[34] = keyP["down_wind_speed_level"]
            bodyBytes[35] = bit.bor(keyP["comfort_fresh_air"], bodyBytes[35])
            bodyBytes[35] = bit.bor(
                                bit.lshift(keyP["fresh_air_setting_mode"], 1),
                                bodyBytes[35])
            bodyBytes[35] = bit.bor(bit.lshift(keyP["autoPurify"], 2),
                                    bodyBytes[35])
            bodyBytes[35] = bit.bor(bit.lshift(keyP["manuPurify"], 3),
                                    bodyBytes[35])
            bodyBytes[32] = bit.bor(bit.lshift(keyP["remove_arofene"], 2),
                                    bodyBytes[32])
            bodyBytes[32] = bit.bor(
                                bit.lshift(keyP["remove_peculiar_smell"], 3),
                                bodyBytes[32])
            bodyBytes[32] = bit.bor(
                                bit.lshift(keyP["auto_comfort_fresh_air"], 7),
                                bodyBytes[32])
            bodyBytes[36] = bit.band(keyP["disinfect_setting_time"], 0xff)
            bodyBytes[37] = bit.band(bit.rshift(keyP["disinfect_setting_time"],
                                                8), 0xff)
            bodyBytes[38] = bit.band(keyP["auto_purifier_on_pm"], 0xff)
            bodyBytes[39] = bit.band(bit.rshift(keyP["auto_purifier_on_pm"], 8),
                                     0xff)
            bodyBytes[40] = bit.band(keyP["auto_purifier_off_pm"], 0xff)
            bodyBytes[41] = bit.band(
                                bit.rshift(keyP["auto_purifier_off_pm"], 8),
                                0xff)
            bodyBytes[42] = bit.band(keyP["auto_fresh_on_co2"], 0xff)
            bodyBytes[43] = bit.band(bit.rshift(keyP["auto_fresh_on_co2"], 8),
                                     0xff)
            bodyBytes[44] = bit.band(keyP["auto_fresh_off_co2"], 0xff)
            bodyBytes[45] = bit.band(bit.rshift(keyP["auto_fresh_off_co2"], 8),
                                     0xff)
            bodyBytes[46] = bit.band(keyP["humi_on_value"], 0xff)
            bodyBytes[47] =
                bit.band(bit.rshift(keyP["humi_off_value"], 8), 0xff)
            bodyBytes[48] = bit.band(keyP["outdoor_pm"], 0xff)
            bodyBytes[49] = bit.band(bit.rshift(keyP["outdoor_pm"], 8), 0xff)
            bodyBytes[50] = bit.band(keyP["manul_humi_value"], 0xff)
            bodyBytes[51] = bit.band(keyP["right_wind_speed"], 0xff)
            bodyBytes[52] = bit.band(keyP["left_wind_speed_target_value"], 0xff)
            bodyBytes[53] =
                bit.band(keyP["right_wind_speed_target_value"], 0xff)
            bodyBytes[54] = bit.band(keyP["scene_id"], 0xff)
            bodyBytes[30] = bit.bor(keyP["voice_control"], bodyBytes[30])
            bodyBytes[30] = bit.bor(
                                bit.lshift(keyP["prevent_straight_wind_lr"], 1),
                                bodyBytes[30])
            keyP["closeHour"] = math.floor(keyP["power_off_time_value"] / 60)
            keyP["closeStepMintues"] = math.floor(
                                           (keyP["power_off_time_value"] % 60) /
                                               15)
            keyP["closeMin"] = math.floor(
                                   ((keyP["power_off_time_value"] % 60) % 15))
            keyP["openHour"] = math.floor(keyP["power_on_time_value"] / 60)
            keyP["openStepMintues"] = math.floor(
                                          (keyP["power_on_time_value"] % 60) /
                                              15)
            keyP["openMin"] = math.floor(
                                  ((keyP["power_on_time_value"] % 60) % 15))
            if (keyP["power_on_timer"] == 0x01) then
                bodyBytes[55] = bit.bor(bit.bor(keyP["power_on_timer"],
                                                bit.lshift(keyP["openHour"], 2)),
                                        keyP["openStepMintues"])
            elseif (keyP["power_on_timer"] == 0x00) then
                bodyBytes[55] = 0x7F
            end
            if (keyP["power_off_timer"] == 0x01) then
                bodyBytes[56] = bit.bor(bit.bor(keyP["power_off_timer"],
                                                bit.lshift(keyP["closeHour"], 2)),
                                        keyP["closeStepMintues"])
            elseif (keyP["power_off_timer"] == 0x00) then
                bodyBytes[56] = 0x7F
            end
            bodyBytes[59] =
                bit.bor(keyP["down_wind_left_switch"], bodyBytes[59])
            bodyBytes[59] = bit.bor(
                                bit.lshift(keyP["down_wind_right_switch"], 1),
                                bodyBytes[59])
            bodyBytes[59] = bit.bor(bit.lshift(keyP["rewarming_dry"], 5),
                                    bodyBytes[59])
            infoM = getTotalMsg(bodyBytes, keyB["BYTE_CONTROL_REQUEST"])
        end
    end
    local ret = table2string(infoM)
    ret = string2hexstring(ret)
    return ret
end
function dataToJson(jsonCmd)
    if (not jsonCmd) then return nil end
    local json = decode(jsonCmd)
    local deviceinfo = json["deviceinfo"]
    deviceSubType = deviceinfo["deviceSubType"]
    local deviceSN = json["deviceinfo"]["deviceSN"]
    if deviceSN ~= nil then deviceSN8 = string.sub(deviceSN, 4, 8) end
    local status = json["status"]
    if (status) then JsonToModel(status, "status") end
    local binData = json["msg"]["data"]
    local info = {}
    local acInfo = {}
    local msgBytes = {}
    local bodyBytes = {}
    local msgLength = 0
    local bodyLength = 0
    acInfo = string2table(binData)
    local infoLenth = 0
    infoLenth = acInfo[2] - 10 - 2
    for k = 1, infoLenth do info[k] = acInfo[k + 10] end
    for i = 1, #info do msgBytes[i - 1] = info[i] end
    dataType = info[2];
    msgLength = msgBytes[2]
    bodyLength = msgLength - keyB["BYTE_PROTOCOL_LENGTH"] - 1
    for i = 0, bodyLength do
        bodyBytes[i] = msgBytes[i + keyB["BYTE_PROTOCOL_LENGTH"]]
    end
    binToModel(bodyBytes)
    local streams = {}
    streams[keyT["KEY_VERSION"]] = keyV["VALUE_VERSION"]
    if (dataType == 0x11 or dataType == 0xF1) then
        if (keyP["powerValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_POWER"]] = "on"
        elseif (keyP["powerValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_POWER"]] = "off"
        end
        if (keyP["standby_clean"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_STANDBY_CLEAN"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["standby_clean"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_STANDBY_CLEAN"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["no_wind_sense"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_NOWINDSENSE"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["no_wind_sense"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_NOWINDSENSE"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["dryValue"] == keyB["BYTE_COMMON_ON"] or
            (keyP["modeValue"] == keyB["BYTE_MODE_DRY"])) then
            streams[keyT["KEY_DRY"]] = keyV["VALUE_FUNCTION_ON"]
        else
            streams[keyT["KEY_DRY"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["strongWindValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_STRONG_WIND"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["strongWindValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_STRONG_WIND"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["manulNewWind"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_MANUL_NEWWIND"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["manulNewWind"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_MANUL_NEWWIND"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["autoNewWind"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_AUTO_NEWWIND"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["autoNewWind"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_AUTO_NEWWIND"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["swingLeftUDValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_SWING_UD"]] = keyV["VALUE_FUNCTION_OFF"]
        else
            streams[keyT["KEY_SWING_UD"]] = keyV["VALUE_FUNCTION_ON"]
        end
        if (keyP["swingUpLRValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_SWING_LR"]] = keyV["VALUE_FUNCTION_OFF"]
        else
            streams[keyT["KEY_SWING_LR"]] = keyV["VALUE_FUNCTION_ON"]
        end
        if (keyP["forceCoolMode"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_FORCE_COOL_MODE"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["forceCoolMode"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_FORCE_COOL_MODE"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["forceAutoMode"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_FORCE_AUTO_MODE"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["forceAutoMode"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_FORCE_AUTO_MODE"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["PTCValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_PTC"]] = keyV["VALUE_FUNCTION_ON"]
        else
            streams[keyT["KEY_PTC"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["PTCDependT4Value"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_PTC_DEPENDT4"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["PTCDependT4Value"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_PTC_DEPENDT4"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["cool_hot_sense"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_COOL_HOT_SENSE"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["cool_hot_sense"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_COOL_HOT_SENSE"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["preventCold"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_PREVENT_COLD"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["preventCold"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_PREVENT_COLD"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["wind_straight"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_WIND_STRAIGHT"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["wind_straight"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_WIND_STRAIGHT"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["wind_avoid"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_WIND_AVOID"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["wind_avoid"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_WIND_AVOID"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["disinfect"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_DISINFECT"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["disinfect"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_DISINFECT"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["elecDustRemove"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_ELEC_DUST_REMOVE"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["elecDustRemove"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_ELEC_DUST_REMOVE"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["energySaveValue"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_ENERGY_SAVE"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["energySaveValue"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_ENERGY_SAVE"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["air_optimization"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_AIR_OPTIMIZATION"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["air_optimization"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_AIR_OPTIMIZATION"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["nobody_energy_save"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_NOBODY_ENERGY_SAVE"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["nobody_energy_save"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_NOBODY_ENERGY_SAVE"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["autoPurify"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_AUTO_PURIFY"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["autoPurify"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_AUTO_PURIFY"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["manuPurify"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_MANUL_PURIFY"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["manuPurify"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_MANUL_PURIFY"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["no_wind_sense_mode"] ~= nil) then
            streams[keyT["KEY_NO_WIND_SENSE_MODE"]] = keyP["no_wind_sense_mode"]
        end
        if (keyP["run_test"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_RUN_TEST"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["run_test"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_RUN_TEST"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["fast_check"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_FAST_CHECK"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["fast_check"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_FAST_CHECK"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["autoHumi"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_AUTO_HUMI"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["autoHumi"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_AUTO_HUMI"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["manuHumi"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_MANUL_HUMI"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["manuHumi"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_MANUL_HUMI"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["wind_strength"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_WIND_STRENGTH"]] = 0x01
        elseif (keyP["wind_strength"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_WIND_STRENGTH"]] = 0x00
        end
        if (keyP["new_wind_machine"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_NEW_WIND_MACHINE"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["new_wind_machine"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_NEW_WIND_MACHINE"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["new_wind_machine_link"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_NEW_WIND_MACHINE_LINK"]] =
                keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["new_wind_machine_link"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_NEW_WIND_MACHINE_LINK"]] =
                keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["project_evacuate"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_PROJECT_EVACUATE"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["project_evacuate"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_PROJECT_EVACUATE"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["follow_body_sense"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_FOLLOW_BODY_SENSE"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["follow_body_sense"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_FOLLOW_BODY_SENSE"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["exhaust_strength"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_EXHAUST_STRENGTH"]] = 0x01
        elseif (keyP["exhaust_strength"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_EXHAUST_STRENGTH"]] = 0x00
        end
        if (keyP["modeValue"] == keyB["BYTE_MODE_HEAT"]) then
            streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_HEAT"]
        elseif (keyP["modeValue"] == keyB["BYTE_MODE_COOL"]) then
            streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_COOL"]
        elseif (keyP["modeValue"] == keyB["BYTE_MODE_AUTO"]) then
            streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_AUTO"]
        elseif (keyP["modeValue"] == keyB["BYTE_MODE_DRY"]) then
            streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_DRY"]
        elseif (keyP["modeValue"] == keyB["BYTE_MODE_FAN"]) then
            streams[keyT["KEY_MODE"]] = keyV["VALUE_MODE_FAN"]
        else
            streams[keyT["KEY_MODE"]] = "off"
        end
        streams[keyT["KEY_TEMPERATURE"]] = keyP["temperature"]
        streams["small_temperature"] = keyP["small_temperature"]
        streams[keyT["KEY_FANSPEED"]] = keyP["fanspeedValue"]
        streams[keyT["KEY_DEHUMIDITY"]] = keyP["deHumidityValue"]
        streams[keyT["KEY_PM25"]] = keyP["pm25HighValue"] * 256 +
                                        keyP["pm25LowValue"]
        streams[keyT["KEY_CO2"]] = keyP["co2HighValue"] * 256 +
                                       keyP["co2LowValue"]
        streams[keyT["KEY_HUMIDITY"]] = keyP["humidityValue"]
        streams[keyT["KEY_NEWWIND_MODE"]] = keyP["newWindModeValue"]
        streams[keyT["KEY_NEWWIND_FANSPEED"]] = keyP["newWindSpeedValue"]
        if (keyP["water_model_power"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_WATER_MODEL_POWER"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["water_model_power"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_WATER_MODEL_POWER"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["water_model_power_save"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_WATER_MODEL_POWER_SAVE"]] =
                keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["water_model_power_save"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_WATER_MODEL_POWER_SAVE"]] =
                keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["water_model_clean"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_WATER_MODEL_CLEAN"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["water_model_clean"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_WATER_MODEL_CLEAN"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["water_model_temperature_auto"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_WATER_MODEL_TEMPERATURE_AUTO"]] =
                keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["water_model_temperature_auto"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_WATER_MODEL_TEMPERATURE_AUTO"]] =
                keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["water_model_ptc"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_WATER_MODEL_PTC"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["water_model_ptc"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_WATER_MODEL_PTC"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["water_model_go_out"] == keyB["BYTE_COMMON_ON"]) then
            streams[keyT["KEY_WATER_MODEL_GO_OUT"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["water_model_go_out"] == keyB["BYTE_COMMON_OFF"]) then
            streams[keyT["KEY_WATER_MODEL_GO_OUT"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        streams[keyT["KEY_WATER_MODEL_TEMPERATURE_SET"]] =
            keyP["water_model_temperature_set"]
        streams[keyT["KEY_HAS_HUIFENG"]] = keyP["has_huifeng"]
        streams[keyT["KEY_HAS_CHUFENG"]] = keyP["has_chufeng"]
        streams[keyT["KEY_HAS_WIND_LR"]] = keyP["has_wind_lr"]
        streams[keyT["KEY_HAS_NO_WIND_SENSE"]] = keyP["has_no_wind_sense"]
        streams[keyT["KEY_HAS_XINFENG"]] = keyP["has_xinfeng"]
        streams[keyT["KEY_HAS_HUMIDIFER"]] = keyP["has_humidifer"]
        streams[keyT["KEY_HAS_WATER_MODEL"]] = keyP["has_water_model"]
        streams[keyT["KEY_AIR_OPTIMIZATION_TEMPERATURE"]] =
            keyP["air_optimization_temperature"]
        streams[keyT["KEY_AIR_OPTIMIZATION_HUMIDITY"]] =
            keyP["air_optimization_humidity"]
        streams[keyT["KEY_AIR_OPTIMIZATION_WIND"]] =
            keyP["air_optimization_wind"]
        if (keyP["power_on_timer"] == 0x01) then
            streams[keyT["KEY_POWER_ON_TIMER"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["power_on_timer"] == 0x00) then
            streams[keyT["KEY_POWER_ON_TIMER"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        if (keyP["power_off_timer"] == 0x01) then
            streams[keyT["KEY_POWER_OFF_TIMER"]] = keyV["VALUE_FUNCTION_ON"]
        elseif (keyP["power_off_timer"] == 0x00) then
            streams[keyT["KEY_POWER_OFF_TIMER"]] = keyV["VALUE_FUNCTION_OFF"]
        end
        streams["timer_enable"] = keyP["timer_enable"]
        streams[keyT["KEY_OPEN_TIME"]] = keyP["power_on_time_value"]
        streams[keyT["KEY_CLOSE_TIME"]] = keyP["power_off_time_value"]
        if (keyP["remove_arofene"] ~= nil) then
            streams["remove_arofene"] = keyP["remove_arofene"]
        end
        if (keyP["remove_peculiar_smell"] ~= nil) then
            streams["remove_peculiar_smell"] = keyP["remove_peculiar_smell"]
        end
        streams["display_status"] = keyP["display_status"]
        streams["scene_id"] = keyP["scene_id"]
        streams["remove_odor_time_high"] = keyP["remove_odor_time_high"]
        streams["remove_odor_time_low"] = keyP["remove_odor_time_low"]
        streams["comfort_fresh_air"] = keyP["comfort_fresh_air"]
        streams["no_wind_sense_right"] = keyP["no_wind_sense_right"]
        streams["no_wind_sense_left"] = keyP["no_wind_sense_left"]
        streams["right_ud_wind"] = keyP["right_ud_wind"]
        streams["ap_mode"] = keyP["ap_mode"]
        streams["energy_save_xiaotiane"] = keyP["energy_save_xiaotiane"]
        streams["front_end_control_fc"] = keyP["front_end_control_fc"]
        streams["up_wind_machine_high"] = keyP["up_wind_machine_high"]
        streams["up_wind_machine_medium"] = keyP["up_wind_machine_medium"]
        streams["up_wind_machine_low"] = keyP["up_wind_machine_low"]
        streams["elec_heating_2"] = keyP["elec_heating_2"]
        streams["elec_heating_1"] = keyP["elec_heating_1"]
        streams["four_way_value"] = keyP["four_way_value"]
        streams["compressor"] = keyP["compressor"]
        streams["energy_save"] = keyP["energy_save"]
        streams["auto_wash_time"] = keyP["auto_wash_time"]
        streams["fresh_air_wind_precent"] = keyP["fresh_air_wind_precent"]
        streams["fn_no_wind_sense"] = keyP["fn_no_wind_sense"]
        streams["extreme_wind"] = keyP["extreme_wind"]
        streams["deep_clean"] = keyP["deep_clean"]
        streams["double_water_washing"] = keyP["double_water_washing"]
        streams["child_prevent_cold_wind"] = keyP["child_prevent_cold_wind"]
        streams["remote_control"] = keyP["remote_control"]
        streams["lock"] = keyP["lock"]
        streams["timer_message"] = keyP["timer_message"]
        streams["prevent_super_cool"] = keyP["prevent_super_cool"]
        streams["prevent_trip"] = keyP["prevent_trip"]
        streams["lr_wind_accelerate"] = keyP["lr_wind_accelerate"]
        streams["ud_wind_accelerate"] = keyP["ud_wind_accelerate"]
        streams["water_washing_control"] = keyP["water_washing_control"]
        streams["manul_water_washing"] = keyP["manul_water_washing"]
        streams["auto_water_washing"] = keyP["auto_water_washing"]
        streams["smart_wind_right_degree"] = keyP["smart_wind_right_degree"]
        streams["smart_wind_left_degree"] = keyP["smart_wind_left_degree"]
        streams["permanent_wind"] = keyP["permanent_wind"]
        streams["temperature_unit"] = keyP["temperature_unit"]
        streams["no_wind_sense_down"] = keyP["no_wind_sense_down"]
        streams["no_wind_sense_up"] = keyP["no_wind_sense_up"]
        streams["child_prevent_cold_wind_parent"] =
            keyP["child_prevent_cold_wind_parent"]
        streams["child_prevent_cold_wind_child"] =
            keyP["child_prevent_cold_wind_child"]
        streams["gentle_wind_sense"] = keyP["gentle_wind_sense"]
        streams["prevent_straight_wind"] = keyP["prevent_straight_wind"]
        streams["x_fan_control"] = keyP["x_fan_control"]
        streams["comfort_save"] = keyP["comfort_save"]
        streams["mosquito_repellent"] = keyP["mosquito_repellent"]
        streams["water_washing"] = keyP["water_washing"]
        streams["left_right_wind_direction"] = keyP["left_right_wind_direction"]
        streams["up_down_wind_direction"] = keyP["up_down_wind_direction"]
        streams["second_temperature_setting"] =
            keyP["second_temperature_setting"]
        streams["dr_function"] = keyP["dr_function"]
        streams["buzzer_param"] = keyP["buzzer_param"]
        streams["eight_degree_heat"] = keyP["eight_degree_heat"]
        streams["eight_degree_heat_remember"] =
            keyP["eight_degree_heat_remember"]
        streams["eco"] = keyP["eco"]
        streams["pmv"] = keyP["pmv"]
        streams["comfort_sleep"] = keyP["comfort_sleep"]
        streams["prevent_water_enable"] = keyP["prevent_water_enable"]
        streams["try_run"] = keyP["try_run"]
        streams["child_comfort_sleep"] = keyP["child_comfort_sleep"]
        streams["leave_home"] = keyP["leave_home"]
        streams["natural_wind"] = keyP["natural_wind"]
        streams["light_level"] = keyP["light_level"]
        streams["huanqi_function"] = keyP["huanqi_function"]
        streams["elec_dust_collect"] = keyP["elec_dust_collect"]
        streams["total_fast_check"] = keyP["total_fast_check"]
        streams["elec_fast_check"] = keyP["elec_fast_check"]
        streams["high_save_power"] = keyP["high_save_power"]
        streams["reset_electricity"] = keyP["reset_electricity"]
        streams["save_i_mode"] = keyP["save_i_mode"]
        streams["set_i_mode"] = keyP["set_i_mode"]
        streams["rui_wind"] = keyP["rui_wind"]
        streams["advance_cold_hot"] = keyP["advance_cold_hot"]
        streams["self_wash"] = keyP["self_wash"]
        streams["clear_filter_change_time"] = keyP["clear_filter_change_time"]
        streams["remove_dust_full"] = keyP["remove_dust_full"]
        streams["do_not_disturb"] = keyP["do_not_disturb"]
        streams["force_defrost"] = keyP["force_defrost"]
        streams["solar_eco"] = keyP["solar_eco"]
        streams["ac_switch"] = keyP["ac_switch"]
        streams["vertical_swing_right"] = keyP["vertical_swing_right"]
        streams["vertical_swing_left"] = keyP["vertical_swing_left"]
        streams["horizontal_swing_right"] = keyP["horizontal_swing_right"]
        streams["horizontal_swing_left"] = keyP["horizontal_swing_left"]
        streams["smart_eye"] = keyP["smart_eye"]
        streams["communication_fault"] = keyP["communication_fault"]
        streams["dry_clean"] = keyP["dryValue"]
        streams["low_power_cost"] = keyP["low_power_cost"]
        streams["mute_voice"] = keyP["mute_voice"]
        streams["down_wind_speed_level"] = keyP["down_wind_speed_level"]
        streams["disinfect_setting_time"] = keyP["disinfect_setting_time"]
        streams["auto_purifier_off_pm"] = keyP["auto_purifier_off_pm"]
        streams["auto_fresh_off_co2"] = keyP["auto_fresh_off_co2"]
        streams["humi_on_value"] = keyP["humi_on_value"]
        streams["humi_off_value"] = keyP["humi_off_value"]
        streams["outdoor_pm"] = keyP["outdoor_pm"]
        streams["manul_humi_value"] = keyP["manul_humi_value"]
        streams["right_wind_speed"] = keyP["right_wind_speed"]
        streams["left_wind_speed_target_value"] =
            keyP["left_wind_speed_target_value"]
        streams["right_wind_speed_target_value"] =
            keyP["right_wind_speed_target_value"]
        streams["rfid_tunnel_0"] = keyP["rfid_tunnel_0"]
        streams["rfid_tunnel_1"] = keyP["rfid_tunnel_1"]
        streams["rfid_tunnel_2"] = keyP["rfid_tunnel_2"]
        streams["rfid_tunnel_3"] = keyP["rfid_tunnel_3"]
        streams["rfid_tunnel_4"] = keyP["rfid_tunnel_4"]
        streams["rfid_tunnel_5"] = keyP["rfid_tunnel_5"]
        streams["rfid_tunnel_tag_0"] = keyP["rfid_tunnel_tag_0"]
        streams["rfid_tunnel_tag_1"] = keyP["rfid_tunnel_tag_1"]
        streams["rfid_tunnel_tag_2"] = keyP["rfid_tunnel_tag_2"]
        streams["rfid_tunnel_tag_3"] = keyP["rfid_tunnel_tag_3"]
        streams["rfid_tunnel_tag_4"] = keyP["rfid_tunnel_tag_4"]
        streams["rfid_tunnel_tag_5"] = keyP["rfid_tunnel_tag_5"]
        streams["down_wind_left_switch"] = keyP["down_wind_left_switch"]
        streams["down_wind_right_switch"] = keyP["down_wind_right_switch"]
        streams["air_exhaust"] = keyP["air_exhaust"]
        streams["auto_comfort_fresh_air"] = keyP["auto_comfort_fresh_air"]
        streams["voice_control"] = keyP["voice_control"]
        streams["p1_fault"] = keyP["p1_fault"]
        streams["p0_fault"] = keyP["p0_fault"]
        streams["p2_fault"] = keyP["p2_fault"]
        streams["p4_fault"] = keyP["p4_fault"]
        streams["indoor_eb_fault"] = keyP["indoor_eb_fault"]
        streams["total_air_level"] = keyP["totalAirLevel"]
        streams["humidity_level"] = keyP["humidityLevel"]
        streams["purifier_level"] = keyP["purifierLevel"]
        streams["fresh_level"] = keyP["freshLevel"]
        streams["tvoc_level"] = keyP["tvocLevel"]
        streams["acstrainer_sw"] = keyP["acstrainer_sw"]
        streams["display_scene_id"] = keyP["display_scene_id"]
        streams["eb1_fault"] = keyP["eb1_fault"]
        streams["version_number"] = keyP["version_number"]
        streams["total_control"] = keyP["total_control"]
        streams["self_clean_time"] = keyP["self_clean_time"]
        streams["main_control_software_version"] =
            keyP["main_control_software_version"]
        streams["main_control_parm_version"] = keyP["main_control_parm_version"]
        streams["out_machine_parm_version"] = keyP["out_machine_parm_version"]
        streams["humidity_algorithm"] = keyP["humidity_algorithm"]
        streams["pm2_5_algorithm"] = keyP["pm2_5_algorithm"]
        streams["co2_algorithm"] = keyP["co2_algorithm"]
        streams["temp_algorithm"] = keyP["temp_algorithm"]
        streams["total_time_switch"] = keyP["total_time_switch"]
        streams["recommend_mode_switch"] = keyP["recommend_mode_switch"]
        streams["down_humidity"] = keyP["down_humidity"]
        streams["current_wind_speed"] = keyP["current_wind_speed"]
        streams["current_down_wind_speed"] = keyP["current_down_wind_speed"]
        streams["full_time_hour"] = keyP["full_time_hour"]
        streams["full_time_min"] = keyP["full_time_min"]
        streams["limit_dry_switch_set"] = keyP["limit_dry_switch_set"]
        streams["last_humidity"] = keyP["last_humidity"]
        streams["rewarming_dry"] = keyP["rewarming_dry"]
        streams["has_rewarming_dry"] = keyP["has_rewarming_dry"]
    end
    if (dataType == 0x30) then
        streams["t1_temp"] = keyP["t1_temp"]
        streams["t2_temp"] = keyP["t2_temp"]
        streams["t3_temp"] = keyP["t3_temp"]
        streams["t4_temp"] = keyP["t4_temp"]
        streams["dust_co2"] = keyP["dust_co2"]
        streams["co2_concentration"] = keyP["co2_concentration"]
        streams["indoor_e0_fault"] = keyP["indoor_e0_fault"]
        streams["indoor_ea_fault"] = keyP["indoor_ea_fault"]
        streams["indoor_e3_fault"] = keyP["indoor_e3_fault"]
        streams["indoor_fe_fault"] = keyP["indoor_fe_fault"]
        streams["outdoor_e51_fault"] = keyP["outdoor_e51_fault"]
        streams["outdoor_e52_fault"] = keyP["outdoor_e52_fault"]
        streams["outdoor_e53_fault"] = keyP["outdoor_e53_fault"]
        streams["outdoor_e54_fault"] = keyP["outdoor_e54_fault"]
        streams["indoor_e60_fault"] = keyP["indoor_e60_fault"]
        streams["indoor_e61_fault"] = keyP["indoor_e61_fault"]
        streams["indoor_e7_fault"] = keyP["indoor_e7_fault"]
        streams["fresh_ptc_load"] = keyP["fresh_ptc_load"]
        streams["outdoor_e7_fault"] = keyP["outdoor_e7_fault"]
        streams["indoor_eb1_fault"] = keyP["indoor_eb1_fault"]
        streams["defrosting"] = keyP["defrosting"]
        streams["re_elec_heat"] = keyP["re_elec_heat"]
        streams["rfid_fault"] = keyP["rfid_fault"]
        streams["pl_fault"] = keyP["pl_fault"]
        streams["wind_speed_real_ac"] = keyP["wind_speed_real_ac"]
    end
    if (dataType == 0x31) then
        streams["humidity_value"] = keyP["humidity_value"]
    end
    if (dataType == 0x20) then
        streams["down_humidity"] = keyP["down_humidity"]
    end
    if (dataType == 0x32) then
        streams["disinfect_time"] = keyP["disinfect_time"]
        streams["wet_film_time"] = keyP["wet_film_time"]
        streams["filter_time"] = keyP["filter_time"]
        streams["ac_filter_time"] = keyP["ac_filter_time"]
        streams["indoor_e3_1_fault"] = keyP["indoor_e3_1_fault"]
        streams["water_tank_water"] = keyP["water_tank_water"]
        streams["water_tank_board"] = keyP["water_tank_board"]
        streams["clean_running_stage"] = keyP["clean_running_stage"]
        streams["wind_speed_real"] = keyP["wind_speed_real"]
    end
    if (dataType == 0xc0) then
        streams["tunnel_status"] = keyP["tunnel_status"]
        streams["category_tag"] = keyP["category_tag"]
        streams["filter_available_time"] = keyP["filter_available_time"]
        streams["filter_used_time"] = keyP["filter_used_time"]
    end
    local retTable = {}
    retTable["status"] = streams
    local ret = encode(retTable)
    return ret
end
