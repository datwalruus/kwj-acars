const e75l = ["kwl", "kwj", "kwm"]
const e75lcallsigns = ["KWJ1"]
const acftOptions = []
document.getElementById("callsign").onchange = function () { change() };

function change() {
    var callsign = document.getElementById("callsign").value;
    var acft = document.getElementById("reg");
    acftOptions = [];
    let options = acftOptions.length;
    if (e75lcallsigns.includes(callsign)) {
        for (let x in e75l) {
            acftOptions[x] = e75l[x];
        }
        let options = acftOptions.length;
    }


    for (let x in acftOptions) {
        let option = document.createElement(e75l[x]);
        option.text = e75l[x];
        option.value = e75l[x];
        acft.add(option);

    }
    
}