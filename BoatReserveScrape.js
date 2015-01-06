var jq = document.createElement('script');
jq.src = "//ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js";
document.getElementsByTagName('head')[0].appendChild(jq);

window.setTimeout(function() {
jQuery.getPastReservations = function() {
  var reservations = [];
  var previous_date = new Date(Date.parse("Jan 1, 2012"));

  jQuery('tr').each(function(i, tr) {
    var tds = jQuery(tr).find('td');

    if (6 <= tds.length) {
      var td = jQuery(tds[1]);
      if (-1 != td.text().indexOf("Sean Banks")) {
        var reservation = [];

        for (var i = 2; i < 6; ++i) {
          reservation.push(jQuery.fixText(jQuery(tds[i]).text()));
        }

        reservations.push(reservation);
      }
    }
  });

  for (var i = reservations.length - 1; 0 <= i; --i) {
    var r = reservations[i];
    var d = jQuery.getRealDate(r[2], previous_date.getFullYear());
    var month_prepend = "";

    if (d < previous_date) {
      d = jQuery.getRealDate(r[2], previous_date.getFullYear() + 1);
    }

    if (d.getMonth() < 9) {
      month_prepend = "0";
    }

    r.push(month_prepend + (d.getMonth() + 1) + "/" + d.getDate() + "/" + d.getFullYear());
    previous_date = new Date(d);

    console.log(r.join(","));
  }
};
jQuery.fixText = function(text) {
  return text.trim().replace(/\s+/g, " ").replace(/,/g, "");
};
jQuery.getRealDate = function(boat_string_date, year) {
  var nth_removed_string = boat_string_date.substring(0, boat_string_date.length - 2);
  var d = new Date(Date.parse(nth_removed_string + " " + year));

  return d;
};
}, 1000);
