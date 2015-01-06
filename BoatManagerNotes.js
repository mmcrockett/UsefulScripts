var jq = document.createElement('script');
jq.src = "//ajax.googleapis.com/ajax/libs/jquery/1/jquery.min.js";
document.getElementsByTagName('head')[0].appendChild(jq);

window.setTimeout(function() {
jQuery.twoDigitDate = function(v) {
  if (v < 10) {
    return '0' + v;
  } else {
    return v;
  }
};
jQuery.listBoatsByDate = function(start_date_string, end_date_string) {
  var url   = 'http://famanager.com/index.php';
  var params = {
    showpopup: 1
    ,f: 'add_reserv'
    ,res_member_id: 'B0007180'
  };
  var start = new Date(start_date_string);
  var end   = start;
  var current_date = start;
  var rows = [];

  if ((null != end_date_string) && (undefined != end_date_string)) {
    end = new Date(end_date_string);
  }

  while (current_date <= end) {
    params.resdate = jQuery.twoDigitDate(current_date.getMonth() + 1) + '-' + jQuery.twoDigitDate(current_date.getDate()) + '-' + current_date.getFullYear();

    jQuery.each(jQuery.boatTime(), function(i, v) {
      var d = new Date(current_date);
      params.restype = v;
      jQuery.ajax({
        type: 'POST',
        url: url,
        data: params,
        success: function(data) {
          data = data.slice(data.indexOf("<!DOCTYPE"));
          data = jQuery(data);
          jQuery.each(data.find('div[id=Layer1] .boat strong'), function(i, v) {
            rows.push({availableDate: d, boat: jQuery(v).text(), time: params.restype});
          });
        },
        async:false
      });
    });

    current_date.setDate(current_date.getDate() + 1);
  }

  console.log("Returning: " + rows.length);
  return rows;
};
jQuery.boatTime = function(type) {
  if ((null == type) || (undefined == type)) {
    return [1,2];
  } else if (true == jQuery.isNumeric(type)) {
    if (1 == type) {
      return 'Morning';
    } else {
      return 'Afternoon';
    }
  }
};
jQuery.addTable = function(rows) {
  var lastElem = jQuery('form:last');
  jQuery('.mikeadded').remove();
  jQuery.each(rows, function(i, v) {
    lastElem.append('<div class="mikeadded" style="clear:both;"></div>');
    lastElem.append('<div class="mikeadded" style="float:left;width:125px;margin:2px;">' + v.availableDate.toDateString() + '</div>');
    lastElem.append('<div class="mikeadded" style="float:left;width:80px;margin:2px;">' + jQuery.boatTime(v.time) + '</div>');
    lastElem.append('<div class="mikeadded" style="float:left;width:500px;margin:2px;">' + v.boat + '</div>');
  });
};
//jQuery.addTable(jQuery.listBoatsByDate("September 7, 2014", "September 8, 2014"));
}, 1000);
