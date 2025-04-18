obj/machinery/computer/general_air_control
	icon = 'icons/obj/computer.dmi'
	icon_state = "computer_generic"
	circuit_type = /obj/item/circuitboard/air_management
	name = "Computer"
	frequency = FREQ_AIR_ALARM_CONTROL

	var/list/sensors = list()

	var/list/sensor_information = list()

	light_r =0.6
	light_g = 1
	light_b = 0.1

	New()
		..()
		MAKE_DEFAULT_RADIO_PACKET_COMPONENT(null, null, frequency)

	special_deconstruct(obj/computerframe/frame as obj)
		frame.circuit.frequency = src.frequency

	attack_hand(mob/user)
		user.Browse(return_text(),"window=computer")
		src.add_dialog(user)
		onclose(user, "computer")

	process()
		..()

		src.updateDialog()

	receive_signal(datum/signal/signal)
		if(!signal || signal.encryption) return

		var/id_tag = signal.data["tag"]
		if(!id_tag || !sensors.Find(id_tag)) return

		sensor_information[id_tag] = signal.data

	proc/return_text()
		var/sensor_data
		if(sensors.len)
			for(var/id_tag in sensors)
				var/long_name = sensors[id_tag]
				var/list/data = sensor_information[id_tag]
				var/sensor_part = "<B>[long_name]</B>: "

				if(data)
					if(data["pressure"])
						sensor_part += "[data["pressure"]] kPa"
						if(data["temperature"])
							sensor_part += ", [data["temperature"]] K"
						sensor_part += "<BR>"
					else if(data["temperature"])
						sensor_part += "[data["temperature"]] K<BR>"

					if(data["oxygen"]||data["toxins"])
						sensor_part += "<B>[long_name] Composition</B>: <BR>"
						if(data["oxygen"])
							sensor_part += "[data["oxygen"]] %O2<BR>"
						if(data["toxins"])
							sensor_part += "[data["toxins"]] %TX<BR>"
						if(data["carbon_dioxide"])
							sensor_part += "[data["carbon_dioxide"]] %CO2<BR>"
						if(data["nitrogen"])
							sensor_part += "[data["nitrogen"]] %N2<BR>"
						if(data["other"])
							sensor_part += "[data["other"]] %OTHER<BR>"


				else
					sensor_part = "<FONT color='red'>[long_name] can not be found!</FONT><BR>"

				sensor_data += sensor_part

		else
			sensor_data = "No sensors connected."

		var/output = {"<B>[name]</B><HR>
<B>Sensor Data: <BR></B>
[sensor_data]<HR>"}

		return output

	large_tank_control
		icon = 'icons/obj/computer.dmi'
		icon_state = "tank"
		req_access = list(access_engineering_atmos)
		object_flags = CAN_REPROGRAM_ACCESS | NO_GHOSTCRITTER

		var/input_tag
		var/output_tag

		var/list/input_info
		var/list/output_info

		var/pressure_setting = ONE_ATMOSPHERE * 45

		return_text()
			var/output = ..()

			output += "<B>Tank Control System</B><BR>"
			if(input_info)
				var/power = (input_info["power"] == "on")
				var/volume_rate = input_info["volume_rate"]
				output += {"<B>Input</B>: [power?("Injecting"):("On Hold")] <A href='?src=\ref[src];in_refresh_status=1'>Refresh</A><BR>
Rate: [volume_rate] L/sec<BR>"}
				output += "Command: <A href='?src=\ref[src];in_toggle_injector=1'>Toggle Power</A><BR>"

			else
				output += "<FONT color='red'>ERROR: Can not find input port</FONT> <A href='?src=\ref[src];in_refresh_status=1'>Search</A><BR>"

			output += "<BR>"

			if(output_info)
				var/power = (output_info["power"] == "on")
				var/output_pressure = output_info["internal"]
				output += {"<B>Output</B>: [power?("Open"):("On Hold")] <A href='?src=\ref[src];out_refresh_status=1'>Refresh</A><BR>
Max Output Pressure: [output_pressure] kPa<BR>"}
				output += "Command: <A href='?src=\ref[src];out_toggle_power=1'>Toggle Power</A> <A href='?src=\ref[src];out_set_pressure=1'>Set Pressure</A><BR>"

			else
				output += "<FONT color='red'>ERROR: Can not find output port</FONT> <A href='?src=\ref[src];out_refresh_status=1'>Search</A><BR>"

			output += "Max Output Pressure Set: <A href='?src=\ref[src];adj_pressure=-100'>-</A> <A href='?src=\ref[src];adj_pressure=-1'>-</A> [pressure_setting] kPa <A href='?src=\ref[src];adj_pressure=1'>+</A> <A href='?src=\ref[src];adj_pressure=100'>+</A><BR>"

			return output

		receive_signal(datum/signal/signal)
			if(!signal || signal.encryption) return

			var/id_tag = signal.data["tag"]

			if(input_tag == id_tag)
				input_info = signal.data
			else if(output_tag == id_tag)
				output_info = signal.data
			else
				..(signal)

		Topic(href, href_list)
			if(..())
				return

			if(!allowed(usr))
				boutput(usr, SPAN_ALERT("Access Denied!"))
				return

			if(href_list["in_refresh_status"])
				input_info = null

				var/datum/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = input_tag
				signal.data["status"] = 1
				signal.data["command"] = "refresh"

				SEND_SIGNAL(src, COMSIG_MOVABLE_POST_RADIO_PACKET, signal)

			if(href_list["in_toggle_injector"])
				input_info = null

				var/datum/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = input_tag
				signal.data["command"] = "power_toggle"

				SEND_SIGNAL(src, COMSIG_MOVABLE_POST_RADIO_PACKET, signal)

			if(href_list["out_refresh_status"])
				output_info = null

				var/datum/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = output_tag
				signal.data["status"] = 1
				signal.data["command"] = "refresh"

				SEND_SIGNAL(src, COMSIG_MOVABLE_POST_RADIO_PACKET, signal)

			if(href_list["out_toggle_power"])
				output_info = null

				var/datum/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = output_tag
				signal.data["command"] = "power_toggle"

				SEND_SIGNAL(src, COMSIG_MOVABLE_POST_RADIO_PACKET, signal)

			if(href_list["out_set_pressure"])
				output_info = null

				var/datum/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = output_tag
				signal.data["command"] = "set_internal_pressure"
				signal.data["parameter"] = "[pressure_setting]"

				SEND_SIGNAL(src, COMSIG_MOVABLE_POST_RADIO_PACKET, signal)

			if(href_list["adj_pressure"])
				var/change = text2num_safe(href_list["adj_pressure"])
				pressure_setting = clamp(pressure_setting + change, 0, 50*ONE_ATMOSPHERE)

			SPAWN(0.7 SECONDS)
				attack_hand(usr)

	fuel_injection
		icon = 'icons/obj/computer.dmi'
		icon_state = "atmos"
		circuit_type = /obj/item/circuitboard/injector_control

		var/device_tag
		var/list/device_info

		var/automation = 0

		var/cutoff_temperature = 2000
		var/on_temperature = 1200

		special_deconstruct(obj/computerframe/frame as obj)
			frame.circuit.frequency = src.frequency

		process()
			if(automation)

				var/injecting = 0
				for(var/id_tag in sensor_information)
					var/list/data = sensor_information[id_tag]
					if(data["temperature"])
						if(data["temperature"] >= cutoff_temperature)
							injecting = 0
							break
						if(data["temperature"] <= on_temperature)
							injecting = 1

				var/datum/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = device_tag

				if(injecting)
					signal.data["command"] = "power_on"
				else
					signal.data["command"] = "power_off"

				SEND_SIGNAL(src, COMSIG_MOVABLE_POST_RADIO_PACKET, signal)

			..()

		return_text()
			var/output = ..()

			output += "<B>Fuel Injection System</B><BR>"
			if(device_info)
				var/power = device_info["power"]
				var/volume_rate = device_info["volume_rate"]
				output += {"Status: [power?("Injecting"):("On Hold")] <A href='?src=\ref[src];refresh_status=1'>Refresh</A><BR>
Rate: <A href='?src=\ref[src];change_vol=-10'>--</A> <A href='?src=\ref[src];change_vol=-1'>-</A> [volume_rate] L/sec <A href='?src=\ref[src];change_vol=1'>+</A> <A href='?src=\ref[src];change_vol=10'>++</A><BR>"}

				if(automation)
					output += "Automated Fuel Injection: <A href='?src=\ref[src];toggle_automation=1'>Engaged</A><BR>"
					output += "Injector Controls Locked Out<BR>"
				else
					output += "Automated Fuel Injection: <A href='?src=\ref[src];toggle_automation=1'>Disengaged</A><BR>"
					output += "Injector: <A href='?src=\ref[src];toggle_injector=1'>Toggle Power</A> <A href='?src=\ref[src];injection=1'>Inject (1 Cycle)</A><BR>"

			else
				output += "<FONT color='red'>ERROR: Can not find device</FONT> <A href='?src=\ref[src];refresh_status=1'>Search</A><BR>"

			return output

		receive_signal(datum/signal/signal)
			if(!signal || signal.encryption) return

			var/id_tag = signal.data["tag"]

			if(device_tag == id_tag)
				device_info = signal.data
			else
				..(signal)

		Topic(href, href_list)
			if(..())
				return

			if(href_list["refresh_status"])
				device_info = null

				var/datum/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = device_tag
				signal.data["status"] = 1
				signal.data["command"] = "refresh"

				SEND_SIGNAL(src, COMSIG_MOVABLE_POST_RADIO_PACKET, signal)

			if(href_list["toggle_automation"])
				automation = !automation

			if(href_list["toggle_injector"])
				device_info = null

				var/datum/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = device_tag
				signal.data["command"] = "power_toggle"

				SEND_SIGNAL(src, COMSIG_MOVABLE_POST_RADIO_PACKET, signal)

			if(href_list["injection"])

				var/datum/signal/signal = get_free_signal()
				signal.transmission_method = 1 //radio signal
				signal.source = src

				signal.data["tag"] = device_tag
				signal.data["command"] = "inject"

				SEND_SIGNAL(src, COMSIG_MOVABLE_POST_RADIO_PACKET, signal)

			if(href_list["change_vol"])
				var/amount = text2num_safe(href_list["change_vol"])
				var/datum/signal/signal = get_free_signal()
				var/volume_rate = device_info["volume_rate"]
				signal.transmission_method = 1 //radio
				signal.source = src
				signal.data["tag"] = device_tag
				signal.data["command"] = "set_volume_rate"
				signal.data["parameter"] = num2text(volume_rate + amount)
				SEND_SIGNAL(src, COMSIG_MOVABLE_POST_RADIO_PACKET, signal)

#define MAX_PRESSURE 20 * ONE_ATMOSPHERE
/obj/machinery/computer/atmosphere/mixercontrol
	name = "Gas Mixer Control"
	icon_state = "atmos"
	var/obj/machinery/atmospherics/trinary/mixer/mixerid
	var/mixer_information
	req_access = list(access_engineering_engine, access_tox_storage)
	object_flags = CAN_REPROGRAM_ACCESS | NO_GHOSTCRITTER
	circuit_type = /obj/item/circuitboard/air_management
	var/last_change = 0
	var/message_delay = 600

	frequency = FREQ_AIR_ALARM_CONTROL

	New()
		..()
		src.AddComponent( \
			/datum/component/packet_connected/radio, \
			null, \
			frequency, \
			null, \
			"receive_signal", \
			FALSE, \
			"mixercontrol", \
			FALSE \
	)

	special_deconstruct(obj/computerframe/frame as obj)
		frame.circuit.frequency = src.frequency

	attack_hand(mob/user)
		if(status & (BROKEN | NOPOWER))
			return

		ui_interact(user)

	receive_signal(datum/signal/signal)
		//boutput(world, "[id] actually can receive a signal!")
		if(!signal || signal.encryption) return

		var/id_tag = signal.data["tag"]
		if(!id_tag || mixerid != id_tag) return

		//boutput(world, "[id] received a signal from [id_tag]!")
		mixer_information = signal.data

		tgui_process.update_uis(src)

	ui_interact(mob/user, datum/tgui/ui)
		ui = tgui_process.try_update_ui(user, src, ui)
		if (!ui)
			ui = new(user, src, "GasMixer")
			ui.open()

	ui_data(mob/user)
		. = ..()
		.["name"] = name
		.["mixerid"] = mixerid
		.["MAX_PRESSURE"] = MAX_PRESSURE
		.["mixer_information"] = mixer_information
		.["allowed"] = src.allowed(user)

	ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
		. = ..()

		if (!src.allowed(usr))
			boutput(usr, SPAN_ALERT("Access denied!"))
			return FALSE

		var/datum/signal/signal = get_free_signal()
		if (!signal || !istype(signal))
			return FALSE

		signal.transmission_method = 1 //radio
		signal.source = src
		signal.data["tag"] = id

		switch (action)
			if ("toggle_pump")
				var/status = mixer_information["pump_status"]
				var/command
				if (status)
					if (status == "Offline")
						command = "power_on"
					else if (status == "Online")
						command = "power_off"

				if (command)
					signal.data["command"] = "toggle_pump"
					signal.data["parameter"] = command

			if ("pressure_set")
				var/target_pressure = params["target_pressure"]
				if ((BOUNDS_DIST(src, usr) > 0 && !issilicon(usr)) || !isliving(usr) || iswraith(usr) || isintangible(usr))
					return FALSE
				if (is_incapacitated(usr) || usr.restrained())
					return FALSE
				if (!src.allowed(usr))
					boutput(usr, SPAN_ALERT("Access denied!"))
					return FALSE
				if (!isnum_safe(target_pressure))
					return FALSE

				var/amount = clamp(target_pressure, 0, MAX_PRESSURE)

				signal.data["command"] = "set_pressure"
				signal.data["parameter"] = num2text(amount)

			if ("ratio")
				signal.data["command"] = "set_ratio"
				signal.data["parameter"] = params["ratio"]

				if (src.id == "pmix_control")
					if (((src.last_change + src.message_delay) <= world.time))
						src.last_change = world.time
						logTheThing(LOG_STATION, usr, "has just edited the plasma mixer at [log_loc(src)].")
						message_admins("[key_name(usr)] has just edited the plasma mixer at at [log_loc(src)].")

			if ("refresh_status")
				signal.data["status"] = 1

		if (signal)
			SEND_SIGNAL(src, COMSIG_MOVABLE_POST_RADIO_PACKET, signal)
			. = TRUE

#undef MAX_PRESSURE
