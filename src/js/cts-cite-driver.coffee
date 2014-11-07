FUSION_TABLES_URI = 'https://www.googleapis.com/fusiontables/v1'

cts_cite_collection_driver_config = {}
valid_urns = []
cite_collection = {}

default_cts_cite_collection_driver_config =
  google_client_id: '429515988667-jkk0s2375vu04vasnvpotbimddag4ih8.apps.googleusercontent.com'
  google_scope: 'https://www.googleapis.com/auth/fusiontables https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email'
  cts_endpoint: 'http://www.perseus.tufts.edu/hopper/CTS'
  cts_urn: 'urn:cts:greekLit:tlg1389.tlg001.perseus-grc1'
  cite_table_id: '11_Igu6u5961Dkz-cfbJOgKdYkQMwnoe3AQXw8T-K'
  cite_collection_editor_url: 'http://localhost:4001/'

google_oauth_parameters_for_fusion_tables =
  response_type: 'token'
  redirect_uri: window.location.href.replace("#{location.hash}",'')
  approval_prompt: 'auto'

google_oauth_url = ->
  "https://accounts.google.com/o/oauth2/auth?#{$.param(google_oauth_parameters_for_fusion_tables)}"

urn_to_id = (urn) ->
  urn.replace(/[:.-]/g,'_')

build_cts_ui = ->
  $('body').append $('<ul id="valid_urns">')
  for urn in valid_urns
    urn_li = $('<li>').attr('id',urn_to_id(urn)).text(urn)
    $('#valid_urns').append urn_li

    if urn == 'urn:cts:greekLit:tlg1389.tlg001.perseus-grc1:a.habaris'
      request_url = "#{cts_cite_collection_driver_config['cts_endpoint']}?#{$.param(
        request: 'GetPassage'
        urn: urn
      )}"
      $.ajax request_url,
        type: 'GET'
        dataType: 'xml'
        crossDomain: 'true'
        error: (jqXHR, textStatus, errorThrown) ->
          console.log "AJAX Error: #{textStatus}"
        success: (data) ->
          console.log(data)
          tei_document = $($($(data)[0]).children('TEI')[0])
          request_urn = tei_document.find('requestUrn').text()
          entry = tei_document.find('div[type="entry"]')
          urn_selector = "li##{urn_to_id(request_urn)}"
          $(urn_selector).append(entry)

# get all data from fusion table
get_cite_collection = (callback) ->
  console.log('get_cite_collection')
  fusion_tables_query "SELECT * FROM #{cts_cite_collection_driver_config['cite_table_id']}", (fusion_tables_result) ->
    cite_collection = fusion_tables_result
    callback() if callback?

get_valid_reff_xml_to_urn_list = (xml) ->
  leaf_nodes = $(xml).find('chunk').filter (index) -> (($(this).children('chunk').length) == 0)
  "#{cts_cite_collection_driver_config['cts_urn']}:#{$(chunk).parents('chunk').map((index) -> $(this).attr('n')).toArray().join('.')}.#{$(chunk).attr('n')}" for chunk in leaf_nodes

# construct a list of valid URN's and pass to callback function
get_valid_reff = (urn, callback = null) ->
  console.log('get_valid_reff')
  request_url = "#{cts_cite_collection_driver_config['cts_endpoint']}?#{$.param(
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
      console.log valid_urns.length
      callback() if callback?

check_table_access = (table_id, callback) ->
  # test table access
  if get_cookie 'access_token'
    $.ajax "#{FUSION_TABLES_URI}/tables/#{table_id}?access_token=#{get_cookie 'access_token'}",
      type: 'GET'
      dataType: 'json'
      crossDomain: true
      error: (jqXHR, textStatus, errorThrown) ->
        console.log "AJAX Error: #{textStatus}"
        # $('.container > h1').after $('<div>').attr('class','alert alert-error').attr('id','collection_access_error').append('You do not have permission to access this collection.')
        # disable_collection_form()
      success: (data) ->
        console.log data
      complete: (jqXHR, textStatus) ->
        callback() if callback?

# wrap values in single quotes and backslash-escape single-quotes
fusion_tables_escape = (value) ->
  "'#{value.replace(/'/g,"\\\'")}'"

fusion_tables_query = (query, callback) ->
  console.log "Query: #{query}"
  switch query.split(' ')[0]
    when 'INSERT'
      $.ajax "#{FUSION_TABLES_URI}/query?access_token=#{get_cookie 'access_token'}",
        type: 'POST'
        dataType: 'json'
        crossDomain: true
        data:
          sql: query
        error: (jqXHR, textStatus, errorThrown) ->
          console.log "AJAX Error: #{textStatus}"
          $('#collection_form').after $('<div>').attr('class','alert alert-error').attr('id','submit_error').append("Error submitting data: #{textStatus}")
          scroll_to_bottom()
          $('#submit_error').delay(1800).fadeOut 1800, ->
            $(this).remove()
            $('#collection_select').change()
        success: (data) ->
          console.log data
          if callback?
            callback(data)
    when 'SELECT'
      $.ajax "#{FUSION_TABLES_URI}/query?sql=#{query}&access_token=#{get_cookie 'access_token'}",
        type: 'GET'
        cache: false
        dataType: 'json'
        crossDomain: true
        error: (jqXHR, textStatus, errorThrown) ->
          console.log "AJAX Error: #{textStatus}"
        success: (data) ->
          console.log data
          if callback?
            callback(data)

# set the author name using Google profile information
set_author_name = (callback) ->
  if get_cookie 'author_name'
    $('input[data-type=authuser]').attr('value',get_cookie 'author_name')
    $('input[data-type=authuser]').prop('disabled',true)
  else if get_cookie 'access_token'
    $.ajax "https://www.googleapis.com/oauth2/v1/userinfo?access_token=#{get_cookie 'access_token'}",
      type: 'GET'
      dataType: 'json'
      crossDomain: true
      error: (jqXHR, textStatus, errorThrown) ->
        console.log "AJAX Error: #{textStatus}"
        # $('.container > h1').after $('<div>').attr('class','alert alert-warning').append('Error retrieving profile info.')
      success: (data) ->
        set_cookie('author_name',"#{data['name']} <#{data['email']}>",3600)
        $('input[data-type=authuser]').attr('value',get_cookie('author_name'))
        $('input[data-type=authuser]').prop('disabled',true)
      complete: (jqXHR, textStatus) ->
        callback() if callback?

# parse URL hash parameters into an associative array object
parse_query_string = (query_string) ->
  query_string ?= location.hash.substring(1)
  params = {}
  if query_string.length > 0
    regex = /([^&=]+)=([^&]*)/g
    while m = regex.exec(query_string)
      params[decodeURIComponent(m[1])] = decodeURIComponent(m[2])
  return params

# filter URL parameters out of the window URL using replaceState 
# returns the original parameters
filter_url_params = (params, filtered_params) ->
  rewritten_params = []
  filtered_params ?= ['access_token','expires_in','token_type']
  for key, value of params
    unless _.include(filtered_params,key)
      rewritten_params.push "#{key}=#{value}"
  if rewritten_params.length > 0
    hash_string = "##{rewritten_params.join('&')}"
  else
    hash_string = ''
  history.replaceState(null,'',window.location.href.replace("#{location.hash}",hash_string))
  return params

expires_in_to_date = (expires_in) ->
  cookie_expires = new Date
  cookie_expires.setTime(cookie_expires.getTime() + expires_in * 1000)
  return cookie_expires

set_cookie = (key, value, expires_in) ->
  cookie = "#{key}=#{value}; "
  cookie += "expires=#{expires_in_to_date(expires_in).toUTCString()}; "
  cookie += "path=#{window.location.pathname.substring(0,window.location.pathname.lastIndexOf('/')+1)}"
  document.cookie = cookie

delete_cookie = (key) ->
  set_cookie key, null, -1

get_cookie = (key) ->
  key += "="
  for cookie_fragment in document.cookie.split(';')
    cookie_fragment = cookie_fragment.replace(/^\s+/, '')
    return cookie_fragment.substring(key.length, cookie_fragment.length) if cookie_fragment.indexOf(key) == 0
  return null

# write a Google OAuth access token into a cached cookie that should expire when the access token does
set_access_token_cookie = (params, callback) ->
  console.log('set_access_token_cookie')
  if params['state']?
    console.log "Replacing hash with state: #{params['state']}"
    history.replaceState(null,'',window.location.href.replace("#{location.hash}","##{params['state']}"))
  if params['access_token']?
    # validate the token per https://developers.google.com/accounts/docs/OAuth2UserAgent#validatetoken
    $.ajax "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=#{params['access_token']}",
      type: 'GET'
      dataType: 'json'
      crossDomain: true
      error: (jqXHR, textStatus, errorThrown) ->
        console.log "Access Token Validation Error: #{textStatus}"
      success: (data) ->
        set_cookie('access_token',params['access_token'],params['expires_in'])
        set_cookie('access_token_expires_at',expires_in_to_date(params['expires_in']).getTime(),params['expires_in'])
        $('#collection_select').change()
      complete: (jqXHR, textStatus) ->
        callback() if callback?
   else
     callback() if callback?

set_cookie_expiration_callback = ->
  if get_cookie('access_token_expires_at')
    expires_in = get_cookie('access_token_expires_at') - (new Date()).getTime()
    console.log(expires_in)
    setTimeout ( ->
        console.log("cookie expired")
        window.location.reload()
      ), expires_in

build_cts_cite_driver = ->
  console.log('build')
  if get_cookie 'access_token'
    set_cookie_expiration_callback()
    get_valid_reff(cts_cite_collection_driver_config['cts_urn'], => get_cite_collection(build_cts_ui))
  else
    window.location = google_oauth_url()

# main driver entry point
$(document).ready ->
  console.log('ready')
  cts_cite_collection_driver_config = $.extend({}, default_cts_cite_collection_driver_config, window.cts_cite_collection_driver_config)
  google_oauth_parameters_for_fusion_tables['client_id'] = cts_cite_collection_driver_config['google_client_id']
  google_oauth_parameters_for_fusion_tables['scope'] = cts_cite_collection_driver_config['google_scope']

  set_access_token_cookie(filter_url_params(parse_query_string()),build_cts_cite_driver)
