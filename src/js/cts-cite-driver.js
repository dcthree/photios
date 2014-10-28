// Generated by CoffeeScript 1.6.3
(function() {
  var FUSION_TABLES_URI, build_cts_cite_driver, default_cts_cite_collection_driver_config, get_valid_reff, get_valid_reff_xml_to_urn_list;

  FUSION_TABLES_URI = 'https://www.googleapis.com/fusiontables/v1';

  default_cts_cite_collection_driver_config = {
    google_client_id: '891199912324.apps.googleusercontent.com',
    cts_endpoint: 'http://www.perseus.tufts.edu/hopper/CTS',
    cts_urn: 'urn:cts:greekLit:tlg1389.tlg001.perseus-grc1'
  };

  get_valid_reff_xml_to_urn_list = function(xml) {
    var chunk, leaf_nodes, _i, _len, _results;
    leaf_nodes = $(xml).find('chunk').filter(function(index) {
      return ($(this).children('chunk').length) === 0;
    });
    _results = [];
    for (_i = 0, _len = leaf_nodes.length; _i < _len; _i++) {
      chunk = leaf_nodes[_i];
      _results.push("" + default_cts_cite_collection_driver_config['cts_urn'] + ":" + ($(chunk).parents('chunk').map(function(index) {
        return $(this).attr('n');
      }).toArray().join('.')) + "." + ($(chunk).attr('n')));
    }
    return _results;
  };

  get_valid_reff = function(urn, callback) {
    var request_url;
    if (callback == null) {
      callback = null;
    }
    console.log('get_valid_reff');
    request_url = "" + default_cts_cite_collection_driver_config['cts_endpoint'] + "?" + ($.param({
      request: 'GetValidReff',
      urn: urn
    }));
    console.log(request_url);
    return $.ajax(request_url, {
      type: 'GET',
      dataType: 'xml',
      crossDomain: true,
      error: function(jqXHR, textStatus, errorThrown) {
        return console.log("AJAX Error: " + textStatus);
      },
      success: function(data) {
        var valid_urns;
        console.log(data);
        valid_urns = get_valid_reff_xml_to_urn_list($($(data)[0]).children('contents')[0]);
        console.log(valid_urns);
        if (callback != null) {
          return callback(valid_urns);
        }
      }
    });
  };

  build_cts_cite_driver = function() {
    console.log('build');
    return get_valid_reff(default_cts_cite_collection_driver_config['cts_urn']);
  };

  $(document).ready(function() {
    console.log('ready');
    return build_cts_cite_driver();
  });

}).call(this);
