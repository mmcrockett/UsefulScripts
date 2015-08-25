var jq = document.createElement('script');
jq.src = "//ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js";
document.getElementsByTagName('head')[0].appendChild(jq);

window.setTimeout(function() {
jQuery.createReservation = function(tds) {
  var reservation = {
    member    : '?',
    id        : '?',
    vehicle   : '?',
    datestr   : '?',
    timestr   : '?',
    action    : '?',
    date_as_str : function() {
      var month_prepend = '';

      if (this.d.getMonth() < 9) {
        month_prepend = '0';
      }

      return month_prepend + (this.d.getMonth() + 1) + "/" + this.d.getDate() + "/" + this.d.getFullYear();
    },
    date      : function(year) {
      var dstr_length = this.datestr.length;

      if (3 <= dstr_length) {
        var nth_removed_string = this.datestr.substring(0, dstr_length - 2);
        this.d = new Date(Date.parse(nth_removed_string + " " + year));

        return this.d;
      } else {
        console.warn("datestr is not expected style - '" + this.datestr + "'.");
        return new Date();
      }
    },
    active    : function() { return ((true == this.valid()) && (0 <= this.action.indexOf('Review'))); },
    complete  : function() { return ((true == this.valid()) && (false == this.active()) && (true == jQuery.isNumeric(this.id))); },
    cancelled : function() { return ((true == this.valid()) && (false == this.active()) && (false == this.complete())); },
    note      : function() { 
      if (false == this.valid()) {
        return 'Invalid';
      } else if (true == this.active()) {
        return 'Active';
      } else if (true == this.complete()) {
        return 'Complete';
      } else if (true == this.cancelled()) {
        return 'Cancelled';
      } else {
        return '???';
      }
    },
    valid     : function() { return (0 <= this.member.indexOf('Sean Banks')); },
    to_a      : function() {
      return [this.note(), this.id, this.vehicle, this.datestr, this.timestr, this.date_as_str()];
    },
    to_tsv    : function() {
      return this.to_a().join("\t");
    },
    to_csv    : function() {
      return this.to_a().join(',');
    }
  };

  if (6 <= tds.length) {
    reservation.member = jQuery.fixText(jQuery(tds[1]).text());

    if (true == reservation.valid()) {
      reservation.id      = jQuery.fixText(jQuery(tds[2]).text());
      reservation.vehicle = jQuery.fixText(jQuery(tds[3]).text());
      reservation.datestr = jQuery.fixText(jQuery(tds[4]).text());
      reservation.timestr = jQuery.fixText(jQuery(tds[5]).text());
      reservation.action  = jQuery.fixText(jQuery(tds[6]).text());
    }
  }

  return reservation;
};
jQuery.getPastReservations = function() {
  var reservations = [];
  var dates = {
    active    : new Date(),
    complete  : new Date(Date.parse("Jan 1, 2012")),
    cancelled : new Date(Date.parse("Jan 1, 2012")),
  }

  jQuery('tr').each(function(i, tr) {
    var reservation = jQuery.createReservation(jQuery(tr).find('td'));

    if (true == reservation.valid()) {
      reservations.push(reservation);
    }
  });

  jQuery(reservations.reverse()).each(function(i, reservation) {
    if (true == reservation.active()) {
      var d = reservation.date(dates.active.getFullYear());

      if (d < dates.active) {
        reservation.date(dates.active.getFullYear() + 1);
      }
    } else if (true == reservation.complete()) {
      var d = reservation.date(dates.complete.getFullYear());

      if (d < dates.complete) {
        dates.complete = reservation.date(dates.complete.getFullYear() + 1);
      } else {
        dates.complete = d;
      }
    } else if (true == reservation.cancelled()) {
      var d = reservation.date(dates.cancelled.getFullYear());
    }
  });

  jQuery(reservations.reverse()).each(function(i, reservation) {
    console.log(reservation.to_tsv());
  });
};
jQuery.fixText = function(text) {
  return text.trim().replace(/\s+/g, " ").replace(/,/g, "");
};
}, 1000);
