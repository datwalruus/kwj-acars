dataref("baro_alt", "sim/flightmodel/misc/h_ind2") --indicated altitude
dataref("agl_alt", "sim/flightmodel/position/y_agl") -- altitude above ground level
dataref("aal_alt", "sim/flightmodel/position/elevation") -- altitude above airport
dataref("gspd", "sim/flightmodel/position/groundspeed") -- ground speed
dataref("vs", "sim/flightmodel/position/vh_ind_fpm") -- vertical speed
dataref("flaps", "sim/cockpit2/controls/flap_handle_deploy_ratio") -- flaps
dataref("gear", "sim/cockpit/switches/gear_handle_status") -- gear
dataref("beacon", "sim/cockpit/electrical/beacon_lights_on")--beacon lights
dataref("taxi_lgt","sim/cockpit/electrical/taxi_light_on") -- taxi light
dataref("pax_sign", "sim/cockpit2/annunciators/fasten_seatbelt") -- seatbelt sign
dataref("strobes", "sim/cockpit/electrical/strobe_lights_on") -- strobe lights
dataref("ldg_lgts", "sim/cockpit/electrical/landing_lights_on") -- landing lights
dataref("touchdown", "sim/flightmodel/failures/onground_any")
dataref("xpdr","sim/cockpit/radios/transponder_mode") -- transponder
-- off=0, stdby=1, on (mode A)=2, alt (mode C)=3, test=4, GND (mode S)=5, ta_only (mode S)=6, ta/ra=7


eng_n2s = dataref_table("sim/flightmodel/engine/ENGN_N2_") --table of N2 values for each engine

on_ground = true
flight_running = false
add_macro("Open ACARS","create_acars()") -- adds button to the fly with lua menu
log_name = "" --Name of the file logging to
valid = true --used for error catching in the GUI
flight_id = "" --flightid used for naming files
flight_time = 0 -- time since flight started in seconds
add_macro("test position log", "log_pos()")

sofs = {"On Gate","Taxi","Climb","Climb(>10,000ft)","Cruise","Initial Descent","Final Descent/Initial Approach","Final Approach"}

function landing_rate() -- FINISHME
    if touchdown == 1 and not on_ground then
        on_ground = true
        return vs
    else
        return "not on ground"
    end
end

function config_check(sof) -- checks that the aircraft is in the correct config for the stage of flight
    -- FIXME: figure out whats going on with the lights in the config
    if sof == 0 then
        return true
    elseif sof == 1 then -- taxi
        return beacon and (xpdr >= 2) and taxi_lgt and pax_sign
    elseif sof == 2 then -- climb below 10k
        return pax_sign and ldg_lgts and beacon and strobes and (xpdr >= 3)
    elseif sof == 3 or sof == 5 then -- climb/descent >10k
        return strobes and beacon and --[[xdpr >=3 and]](flaps == 0) and not ldg_lgts
    elseif sof == 4 then -- cruise
        return strobes and (xpdr >= 3) and (flaps == 0) and not gear and not ldg_lgts
    elseif sof == 6 then --descent below 10k
        return pax_sign and ldg_lgts and beacon and strobes and xpdr >= 3
    elseif sof == 7 then --final
        return pax_sign and ldg_lgts and beacon and strobes and xpdr >= 3 and flaps == 1 and gear and not -1000 > vs > 1000
    end
end

function stage_of_flight() --checks what stage the flight is in

    if not (eng_n2s[0] >= 20 or eng_n2s[1] >=20) then
        return 0 -- on stand
    elseif touchdown == 1 then
        return 1 --taxi
    elseif vs > 100 and baro_alt < 10000 then
        return 2 --climb below 10k
    elseif vs >100 then
        return 3 -- climb >10k
    elseif (-100 < vs) and (vs < 100) then
        return 4 -- cruise
    elseif vs < 100 and aal_alt < 1000  then
        return 7 -- final
    elseif vs < 100 and baro_alt < 10000 then
        return 6 -- descent <10k
    elseif vs < 100 then
        return 5 -- descent >10k
    end

end

function log_pos(config) --logs position to flight log
    io.output(log)
    if config then
        log_entry = string.format("%s,%s,%s,%s,%s,%s,%s\n", flight_time, LONGITUDE, LATITUDE, gspd, baro_alt,stage_of_flight(), config_check(stage_of_flight()))
    else
        log_entry = string.format("%s,%s,%s,%s,%s,%s\n", flight_time, LONGITUDE, LATITUDE, gspd, baro_alt,stage_of_flight())
    end

    io.write(log_entry)
end

function every_frame() -- tasks to be done every frame.
    lr = landing_rate()
    if lr ~= "not on ground" then
        io.output(log)
        io.write("LR," .. lr .. "\n")
    end
end

function often() -- tasks to be done every second.
    flight_time = flight_time + 1

    if stage_of_flight() ~= 4 and stage_of_flight() ~= 0 and flight_time % 10 ~= 0 and stage_of_flight() ~= 7 then
        log_pos(false)

    end
    if stage_of_flight() == 7 then
        log_pos(true)

    end

end

function sometimes() -- tasks to be done every 10 seconds
    if stage_of_flight() ~= 7 then
        log_pos(true)

    end
end


do_sometimes("if flight_running then sometimes() end")
do_often("if flight_running then often() end")
--do_every_frame('')


------------------------------- MENU -----------------------------

function create_acars() --function to open the window
    ACARS_wnd = float_wnd_create(450, 130, 1, true)
    float_wnd_set_title(ACARS_wnd,"Kiwijet ACARS")
    float_wnd_set_imgui_builder(ACARS_wnd, "build_acars")
end

function build_acars(wnd, x, y) --function to draw the window

    imgui.TextUnformatted("Welcome To KiwiJet")
    if flight_running then
        button_txt = "End Flight"
    else
        button_txt = "Start Flight"
    end


    imgui.PushItemWidth(80)
    local changed, newText = imgui.InputTextWithHint("","Flight ID", flight_id, 255)
    if changed and not flight_running then
        flight_id = newText
        log_name = flight_id .. ".csv"
        valid = true
    elseif changed and flight_running then
        valid = false
        error_msg = "Flight Running, please end your flight before changing the ID"
    end

    if imgui.Button(button_txt) then

        if flight_id ~= "" then
            flight_running = not flight_running
            valid = true
        else
            valid = false
            error_msg = "Please Enter Flight ID"
        end

        if flight_running and valid then
            log = io.open(log_name, "w")
            --[[io.close(log)
            log = io.open(log_name, "a")]]
            io.output(log)
            flight_time = 0
        elseif not flight_running and valid then
            io.close(log)
        end

    end
    if not valid then
        imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF0000FF)
        imgui.TextUnformatted(error_msg)
        imgui.PopStyleColor()
    else
        imgui.TextUnformatted("")
    end

    imgui.PopItemWidth()

    if flight_running then
        imgui.TextUnformatted("Stage of Flight:" .. sofs[stage_of_flight() + 1])
        if not config_check(stage_of_flight()) then
            imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF0000FF)
            imgui.TextUnformatted("CHECK CONFIG")
            imgui.PopStyleColor()
        end
    end

end

function close_acars(wnd) --things to do when the window is closed

end

