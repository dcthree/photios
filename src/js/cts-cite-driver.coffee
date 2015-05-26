---
---

FUSION_TABLES_URI = 'https://www.googleapis.com/fusiontables/v1'

cts_cite_collection_driver_config = {}
valid_urns = []
cite_collection = {}

default_cts_cite_collection_driver_config =
  google_api_key: 'AIzaSyACO-ZANrYxHFG44v8kqsfGb6taylh2aDk'
  cts_endpoint: '1_DFxPLkDrZt2JTgFo04nI6zQ9AsnnqMNRlUBb2Sq'
  cts_urn: 'urn:cts:greekLit:tlg1389.tlg001.dc3'
  cite_table_id: '1YOwprxInXb03cho6DQ20jVefAHF6a3fqhj3SGIxk'
  cite_collection_editor_url: "http://cite-harpokration.appspot.com/editor"

urn_to_id = (urn) ->
  urn.replace(/[:.'-]/g,'_')

urn_to_head = (urn) ->
  urn.replace(/^.*:/,'').replace(/_/g,' ')

add_translation = (translation) ->
  translation_div = $('<div>').attr('class','translation')
  edit_translation_link = cts_cite_collection_driver_config['cite_collection_editor_url'] + '#' + $.param(
    'URN': translation[0]
  )
  edit_translation_a = $('<a>').attr('target','_blank').attr('href',edit_translation_link).text("Add a new version of translation #{translation[0]}")
  # <a rel="license" href="http://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/80x15.png" /></a>
  license_a = $('<a>',
    rel: 'license'
    href: 'http://creativecommons.org/licenses/by/4.0/')
  license_a.append $('<img>',
    alt: 'Creative Commons License'
    style: 'border-width:0'
    src: 'https://i.creativecommons.org/l/by/4.0/80x15.png')
  translation_div.append $('<span>', {style: 'float:right'}).append(license_a)
  translation_div.append $('<span>').attr('class','urn').append(edit_translation_a)
  translation_div.append $('<span>').attr('class','author').text(translation[2])
  # translation_div.append $('<span>').attr('class','timestamp').text(translation[3])
  canonical_translation = $("li##{urn_to_id(translation[1])} .source_text p").text()
  if translation[4].trim() != canonical_translation.trim()
    console.log("Canonical: #{canonical_translation}")
    translation_div.append $('<span>').attr('class','entry_text').text(translation[4])
  translation_div.append $('<span>').attr('class','translation_text').text(translation[5])
  if translation[6]?.length
    translation_div.append $('<span>').attr('class','note').text("Notes: #{translation[6]}")
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

set_cts_text = (urn, head, body, perseus, sol) ->
  localStorage["#{urn}[head]"] ?= head
  localStorage["#{urn}[body]"] ?= body
  localStorage["#{urn}[perseus]"] ?= perseus
  localStorage["#{urn}[sol]"] ?= sol
  urn_selector = "li##{urn_to_id(urn)}"
  $(urn_selector).text('')
  editor_href = cts_cite_collection_driver_config['cite_collection_editor_url'] + '#' + $.param(
    'URN-commentedOn': urn
    'Text': encodeURIComponent("#{head}: #{body}")
  )
  editor_link = $('<p>').append($('<a>').attr('target','_blank').attr('href',editor_href).text("Add translation for #{urn}"))
  $(urn_selector).append(editor_link)
  perseus_link = $('<p>').append($('<a>').attr('target','_blank').attr('href',"http://data.perseus.org/citations/#{perseus}").text("Open #{perseus} in Perseus"))
  $(urn_selector).append(perseus_link)
  if sol?.length
    [sol1, sol2] = sol.split(',')
    sol_link = $('<p>').append($('<a>').attr('target','_blank').attr('href',"http://www.stoa.org/sol-entries/#{sol1}/#{sol2}").text("Open Adler number #{sol1} #{sol2} in the Suda On Line"))
    $(urn_selector).append(sol_link)
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
    request_urn = passage[0]
    perseus = passage[1]
    text = passage[2]
    sol = passage[3]
    head = urn_to_head(request_urn)
    set_cts_text(request_urn, head, text, perseus, sol)
    
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
  for urn in valid_urns
    urn_li = $('<li>').attr('id',urn_to_id(urn)).text(urn)
    $('#valid_urns').append urn_li

    if localStorage["#{urn}[head]"]?
      set_cts_text(urn, localStorage["#{urn}[head]"], localStorage["#{urn}[body]"], localStorage["#{urn}[perseus]"], localStorage["#{urn}[sol]"])
    else
      get_passage(urn)
    
    if cite_collection_contains_urn(urn)
      translated_urns += 1

  progress = translated_urns/valid_urns.length * 100.0
  console.log("Progress: #{progress}")
  $('#translation_progress').attr('style',"width: #{progress}%;")
  $('#translation_progress').append $('<span>').text("#{translated_urns} / #{valid_urns.length} entries translated")

# get all data from fusion table
get_cite_collection = (callback) ->
  console.log('get_cite_collection')
  fusion_tables_query "SELECT * FROM #{cts_cite_collection_driver_config['cite_table_id']}", (fusion_tables_result) ->
    cite_collection = fusion_tables_result
    callback() if callback?
  , ->
    $('#translation_container').append $('<div>').attr('class','alert alert-danger').text('Error in response from Google Fusion Tables for translation collection.')

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
  , ->
    $('#translation_container').append $('<div>').attr('class','alert alert-danger').text('Error in response from Google Fusion Tables for text collection.')

# wrap values in single quotes and backslash-escape single-quotes
fusion_tables_escape = (value) ->
  "'#{value.replace(/'/g,"\\\'")}'"

fusion_tables_query = (query, callback, error_callback) ->
  console.log "Query: #{query}"
  switch query.split(' ')[0]
    when 'SELECT'
      $.ajax "#{FUSION_TABLES_URI}/query?sql=#{query}&key=#{cts_cite_collection_driver_config['google_api_key']}",
        type: 'GET'
        cache: false
        dataType: 'json'
        crossDomain: true
        error: (jqXHR, textStatus, errorThrown) ->
          console.log "AJAX Error: #{textStatus}"
          error_callback() if error_callback?
        success: (data) ->
          # console.log data
          if callback?
            callback(data)

build_cts_cite_driver = ->
  console.log('build')
  get_valid_reff(cts_cite_collection_driver_config['cts_urn'], => get_cite_collection(build_cts_ui))

# main driver entry point
$(document).ready ->
  console.log('ready')
  cts_cite_collection_driver_config = $.extend({}, default_cts_cite_collection_driver_config, window.cts_cite_collection_driver_config)
  console.log(cts_cite_collection_driver_config['cite_collection_editor_url'])
  build_cts_cite_driver()
