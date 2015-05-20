---
---

FUSION_TABLES_URI = 'https://www.googleapis.com/fusiontables/v1'

cts_cite_collection_driver_config = {}
valid_urns = []
cite_collection = {}

default_cts_cite_collection_driver_config =
  google_api_key: 'AIzaSyACO-ZANrYxHFG44v8kqsfGb6taylh2aDk'
  google_client_id: '429515988667-jkk0s2375vu04vasnvpotbimddag4ih8.apps.googleusercontent.com'
  google_scope: 'https://www.googleapis.com/auth/fusiontables https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email'
  cts_endpoint: '1_DFxPLkDrZt2JTgFo04nI6zQ9AsnnqMNRlUBb2Sq'
  cts_urn: 'urn:cts:greekLit:tlg1389.tlg001.dc3'
  cite_table_id: '1YOwprxInXb03cho6DQ20jVefAHF6a3fqhj3SGIxk'
  cite_collection_editor_url: "http://#{window.location.hostname}/harpokration-cite/src/index.html"

google_oauth_parameters_for_fusion_tables =
  response_type: 'token'
  redirect_uri: window.location.href.replace("#{location.hash}",'')
  approval_prompt: 'auto'

google_oauth_url = ->
  "https://accounts.google.com/o/oauth2/auth?#{$.param(google_oauth_parameters_for_fusion_tables)}"

urn_to_id = (urn) ->
  urn.replace(/[:.'-]/g,'_')

urn_to_head = (urn) ->
  urn.replace(/^.*:/,'').replace(/_/g,' ')

add_translation = (translation) ->
  translation_div = $('<div>').attr('class','translation')
  edit_translation_link = cts_cite_collection_driver_config['cite_collection_editor_url'] + '#' + $.param(
    'URN': translation[0]
  )
  edit_translation_a = $('<a>').attr('target','_blank').attr('href',edit_translation_link).text(translation[0])
  translation_div.append $('<span>').attr('class','urn').append(edit_translation_a)
  translation_div.append $('<span>').attr('class','author').text(translation[2])
  # translation_div.append $('<span>').attr('class','timestamp').text(translation[3])
  translation_div.append $('<span>').attr('class','entry_text').text(translation[4])
  translation_div.append $('<span>').attr('class','translation_text').text(translation[5])
  $("li##{urn_to_id(translation[1])}").append translation_div

add_translations = (urn) ->
  urn_selector = "li##{urn_to_id(urn)}"
  if cite_collection.rows?
    matching_rows = cite_collection.rows.filter (row) -> row[1] == urn
    if matching_rows.length > 0
      $(urn_selector).addClass('has_translation')
      # $(urn_selector).prepend ' \u2713'
      $(urn_selector).append $('<br>')
      $(urn_selector).append $('<p>').text('Translations:')
      for matching_row in matching_rows
        do (matching_row) ->
          add_translation(matching_row)

set_cts_text = (urn, head, body) ->
  localStorage["#{urn}[head]"] ?= head
  localStorage["#{urn}[body]"] ?= body
  urn_selector = "li##{urn_to_id(urn)}"
  $(urn_selector).text('')
  editor_href = cts_cite_collection_driver_config['cite_collection_editor_url'] + '#' + $.param(
    'URN-commentedOn': urn
    'Text': encodeURIComponent("#{head}: #{body}")
  )
  editor_link = $('<a>').attr('target','_blank').attr('href',editor_href).text(urn)
  $(urn_selector).append(editor_link)
  source_text = $('<div>').attr('class','source_text')
  source_text.append $('<head>').text(head)
  source_text.append $('<p>').text(body)
  $(urn_selector).append source_text
  add_translations(urn)

get_passage = (urn) ->
  console.log("get_passage #{urn}")
  fusion_tables_query "SELECT * FROM #{cts_cite_collection_driver_config['cts_endpoint']} WHERE URN = #{fusion_tables_escape(urn)}", (fusion_tables_result) ->
    # console.log fusion_tables_result
    passage = fusion_tables_result.rows[0]
    # 0 = URN
    # 1 = Perseus
    # 2 = text
    # 3 = SOL
    request_urn = passage[0]
    head = urn_to_head(request_urn)
    set_cts_text(request_urn, head, passage[2])
    # call set_cts_text(request_urn, head, body)
    
show_all = ->
  $('#toggle_group button').removeClass('active')
  $('#all_entries_button').addClass('active')
  $('li').show()

show_untranslated = ->
  $('#toggle_group button').removeClass('active')
  $('#untranslated_button').addClass('active')
  $('.has_translation').hide()
  $('li:not(.has_translation)').show()

show_translated = ->
  $('#toggle_group button').removeClass('active')
  $('#translated_button').addClass('active')
  $('li:not(.has_translation)').hide()
  $('.has_translation').show()

cite_collection_contains_urn = (urn) ->
  if cite_collection.rows?
    matching_rows = cite_collection.rows.filter (row) -> row[1] == urn
    if matching_rows.length > 0
      return true
  return false

build_cts_ui = ->
  $('#all_entries_button').click(show_all)
  $('#translated_button').click(show_translated)
  $('#untranslated_button').click(show_untranslated)
  $('#translation_container').append $('<ul>').attr('id','valid_urns')
  translated_urns = 0
  get_passage_delay = 0
  for urn in valid_urns
    urn_li = $('<li>').attr('id',urn_to_id(urn)).text(urn)
    $('#valid_urns').append urn_li

    if localStorage["#{urn}[head]"]?
      set_cts_text(urn, localStorage["#{urn}[head]"], localStorage["#{urn}[body]"])
    else
      setTimeout(get_passage(urn),get_passage_delay * 30)
      get_passage_delay += 1
    
    if cite_collection_contains_urn(urn)
      translated_urns += 1

  progress = translated_urns/valid_urns.length * 100.0
  console.log("Progress: #{progress}")
  $('#translation_progress').attr('style',"width: #{progress}%;")

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
  # WHERE URN STARTS WITH '#{urn}'
  fusion_tables_query "SELECT URN FROM #{cts_cite_collection_driver_config['cts_endpoint']} WHERE URN STARTS WITH '#{urn}'", (fusion_tables_result) ->
    valid_urns = (urn[0] for urn in fusion_tables_result.rows)
    # console.log(valid_urns)
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
        # console.log data
      complete: (jqXHR, textStatus) ->
        callback() if callback?

# wrap values in single quotes and backslash-escape single-quotes
fusion_tables_escape = (value) ->
  "'#{value.replace(/'/g,"\\\'")}'"

fusion_tables_query = (query, callback) ->
  console.log "Query: #{query}"
  switch query.split(' ')[0]
    when 'INSERT'
      $.ajax "#{FUSION_TABLES_URI}/query?key=#{cts_cite_collection_driver_config['google_api_key']}",
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
          # console.log data
          if callback?
            callback(data)
    when 'SELECT'
      $.ajax "#{FUSION_TABLES_URI}/query?sql=#{query}&key=#{cts_cite_collection_driver_config['google_api_key']}",
        type: 'GET'
        cache: false
        dataType: 'json'
        crossDomain: true
        error: (jqXHR, textStatus, errorThrown) ->
          console.log "AJAX Error: #{textStatus}"
        success: (data) ->
          # console.log data
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
  get_valid_reff(cts_cite_collection_driver_config['cts_urn'], => get_cite_collection(build_cts_ui))

# main driver entry point
$(document).ready ->
  console.log('ready')
  cts_cite_collection_driver_config = $.extend({}, default_cts_cite_collection_driver_config, window.cts_cite_collection_driver_config)
  console.log(cts_cite_collection_driver_config['cite_collection_editor_url'])
  build_cts_cite_driver()
  # google_oauth_parameters_for_fusion_tables['client_id'] = cts_cite_collection_driver_config['google_client_id']
  # google_oauth_parameters_for_fusion_tables['scope'] = cts_cite_collection_driver_config['google_scope']

  # set_access_token_cookie(filter_url_params(parse_query_string()),build_cts_cite_driver)
