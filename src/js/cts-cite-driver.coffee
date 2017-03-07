---
---

FUSION_TABLES_URI = 'https://www.googleapis.com/fusiontables/v2'

cts_cite_collection_driver_config = {}
valid_urns = []
cite_collection = {}

default_cts_cite_collection_driver_config =
  google_api_key: 'AIzaSyCsBB8U6qfzFKFXWWpm8AN3iooxey_7lKU'
  cts_endpoint: '1_veTVGdKvI_WQ-8jU4al9ESWvjgTqjFzGreeAaKK'
  cts_urn: 'urn:cts:greekLit:tlg4040.lexicon.dc3'
  cite_table_id: '1Tv86Sn9h4CGug3I_Bp20yNT1wT4Ad2Ufp93zUiQP'
  cite_collection_editor_url: "//lyrical-flame-685.appspot.com/editor"

urn_to_id = (urn) ->
  urn.replace(/[:.,'-]/g,'_')

urn_to_head = (urn) ->
  urn.replace(/^.*:/,'').replace(/_/g,' ')

# add UI for a single translation
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

# add translations to UI for a given URN
# cite_collection.rows row[1] contains URN-commentedOn
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
    else
      $(urn_selector).addClass('no_translation')

# add UI for a single text URN, then add its translations afterward
set_cts_text = (urn, head, tlg) ->
  urn_selector = "li##{urn_to_id(urn)}"
  $(urn_selector).text('')
  editor_href = cts_cite_collection_driver_config['cite_collection_editor_url'] + '#' + $.param(
    'URN-commentedOn': urn
  )
  editor_link = $('<p>').append($('<a>').attr('target','_blank').attr('href',editor_href).text("Add translation for #{urn}"))
  source_text = $('<div>').attr('class','source_text')
  source_text.append $('<head>').text(head)
  tlg_link = $('<p>').append($('<a>').attr('target','_blank').attr('href',tlg).text("Open in TLG"))
  source_text.append tlg_link
  $(urn_selector).append(source_text)
  $(urn_selector).append(editor_link)
  add_translations(urn)

# sets passage from Fusion Tables result row
set_passage = (passage) ->
  urn = passage[0]
  head = passage[1]
  tlg = passage[2]

  set_cts_text(urn, head, tlg)
    
show_all = ->
  unless $('#all_entries_button').hasClass('active')
    $('#toggle_group button').removeClass('active')
    $('#all_entries_button').addClass('active')
    $('#valid_urns').remove()
    add_valid_urns()

show_untranslated = ->
  unless $('#untranslated_button').hasClass('active')
    $('#toggle_group button').removeClass('active')
    $('#untranslated_button').addClass('active')
    $('#valid_urns').remove()
    add_valid_urns()

show_translated = ->
  unless $('#translated_button').hasClass('active')
    $('#toggle_group button').removeClass('active')
    $('#translated_button').addClass('active')
    $('#valid_urns').remove()
    add_valid_urns()

cite_collection_contains_urn = (urn) ->
  if cite_collection.rows?
    matching_rows = cite_collection.rows.filter (row) -> row[1] == urn
    if matching_rows.length > 0
      return true
  return false

add_urn_li = (urn) ->
  urn_li = $('<li>').attr('id',urn_to_id(urn[0])).text(urn[0])
  $('#valid_urns').append urn_li

  set_passage(urn)

add_valid_urns = ->
  console.log('add_valid_urns')
  $('#translation_container').append $('<ul>').attr('id','valid_urns')
  translated_urns = 0
  for urn in valid_urns
    if $('#all_entries_button').hasClass('active')
      add_urn_li(urn)
    else if $('#untranslated_button').hasClass('active') && !cite_collection_contains_urn(urn[0])
      add_urn_li(urn)
    else if $('#translated_button').hasClass('active') && cite_collection_contains_urn(urn[0])
      add_urn_li(urn)
    
    if cite_collection_contains_urn(urn[0])
      translated_urns += 1

  return translated_urns

build_cts_ui = ->
  console.log('build_cts_ui')
  $('#all_entries_button').click(show_all)
  $('#translated_button').click(show_translated)
  $('#untranslated_button').click(show_untranslated)
  $('#translation_container').append $('<ul>').attr('id','valid_urns')

  translated_urns = add_valid_urns()
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

# construct a list of valid URN's and pass to callback function
get_valid_reff = (urn, callback = null) ->
  console.log('get_valid_reff')
  fusion_tables_query "SELECT URN,Headword,TLG FROM #{cts_cite_collection_driver_config['cts_endpoint']} WHERE URN STARTS WITH '#{urn}'", (fusion_tables_result) ->
    valid_urns = fusion_tables_result.rows
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
  # fetch CTS, fetch CITE, build UI
  get_valid_reff(cts_cite_collection_driver_config['cts_urn'], => get_cite_collection(build_cts_ui))

# main driver entry point
$(document).ready ->
  console.log('ready')
  $('#loadingDiv').hide()
  $(document).ajaxStart -> $('#loadingDiv').show()
  $(document).ajaxStop -> $('#loadingDiv').hide()
  cts_cite_collection_driver_config = $.extend({}, default_cts_cite_collection_driver_config, window.cts_cite_collection_driver_config)
  console.log(cts_cite_collection_driver_config['cite_collection_editor_url'])
  build_cts_cite_driver()
