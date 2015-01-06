jQuery.getTimes = function() {
  var date_string = null;

  jQuery('.number').each(function(i, elem) {
    var t = jQuery(elem).text();

    if (null == date_string) {
      date_string = t;
    } else {
      var d = new Date(Date.parse(date_string));
      date_string = null;
      console.log((d.getMonth() + 1) + "/" + d.getDate() + "/" + d.getFullYear() + " " + t);
    }
  });
};
