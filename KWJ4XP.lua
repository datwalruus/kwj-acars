dataref("baro_alt", "sim/flightmodel/misc/h_ind2")
dataref("agl_alt", "sim/flightmodel/position/y_agl")
dataref("aal_alt", "sim/flightmodel/position/elevation")
dataref("gspd", "sim/flightmodel/position/groundspeed")
dataref("vs", "sim/flightmodel/position/vh_ind_fpm")
eng_n2s = dataref_table("sim/flightmodel/engine/ENGN_N2_")
flight_running = false
add_macro("Open ACARS","create_acars()")
log_name = ""
valid = true
flight_id = ""
function stage_of_flight() --checks what stage the flight is in

    if not (eng_n2s[0] >= 20 or eng_n2s[1] >=20) then
        return 0 -- on stand
    elseif agl_alt < 20 then
        return 1 --taxi
    elseif vs > 100 then
        return 2 --climb
    elseif -100 < vs < 100 then
        return 3 -- cruise
    elseif vs < 100 and aal_alt < 1000  then
        return 5 -- final
    elseif vs < 100 then
        return 4 --descent
    end

end

function every_frame() -- tasks to be done every frame.

end

function often() -- tasks to be done every second

end

function sometimes() -- tasks to be done every 10 seconds

end



-- MENU

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
    end
    if not valid then
        imgui.PushStyleColor(imgui.constant.Col.Text, 0xFF0000FF)
        imgui.TextUnformatted(error_msg)
        imgui.PopStyleColor()
    end
    imgui.PopItemWidth()

end

function close_acars(wnd) --things to do when the window is closed

end

