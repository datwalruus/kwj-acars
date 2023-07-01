dataref("baro_alt", "sim/flightmodel/misc/h_ind2")
dataref("agl_alt", "sim/flightmodel/position/y_agl")
dataref("aal_alt", "sim/flightmodel/position/elevation")
dataref("gspd", "sim/flightmodel/position/groundspeed")
dataref("vs", "sim/flightmodel/position/vh_ind_fpm")

function stage_of_flight() --checks what stage the flight is in

    if gspd <= 5 then
        return 0 -- on stand/stopped
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
