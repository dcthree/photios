FUSION_TABLES_URI = 'https://www.googleapis.com/fusiontables/v1'

default_cts_cite_collection_driver_config =
  google_client_id: '891199912324.apps.googleusercontent.com'
  cts_endpoint: 'http://www.perseus.tufts.edu/hopper/CTS'
  cts_urn: 'urn:cts:greekLit:tlg1389.tlg001.perseus-grc1'

get_valid_reff_xml_to_urn_list = (xml) ->
  leaf_nodes = $(xml).find('chunk').filter (index) -> (($(this).children('chunk').length) == 0)
  "#{default_cts_cite_collection_driver_config['cts_urn']}:#{$(chunk).parents('chunk').map((index) -> $(this).attr('n')).toArray().join('.')}.#{$(chunk).attr('n')}" for chunk in leaf_nodes

# construct a list of valid URN's and pass to callback function
get_valid_reff = (urn, callback = null) ->
  console.log('get_valid_reff')
  request_url = "#{default_cts_cite_collection_driver_config['cts_endpoint']}?#{$.param(
    request: 'GetValidReff'
    urn: urn
  )}"
  console.log(request_url)
  $.ajax request_url,
    type: 'GET'
    dataType: 'xml'
    crossDomain: true
    error: (jqXHR, textStatus, errorThrown) ->
      console.log "AJAX Error: #{textStatus}"
    success: (data) ->
      console.log(data)
      valid_urns = get_valid_reff_xml_to_urn_list($($(data)[0]).children('contents')[0])
      console.log valid_urns
      if callback?
        callback(valid_urns)

build_cts_cite_driver = ->
  console.log('build')
  get_valid_reff(default_cts_cite_collection_driver_config['cts_urn'])

# main driver entry point
$(document).ready ->
  console.log('ready')
  build_cts_cite_driver()