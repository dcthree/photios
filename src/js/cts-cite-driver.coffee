---
---

FUSION_TABLES_URI = 'https://www.googleapis.com/fusiontables/v2'

cts_cite_collection_driver_config = {}
valid_urns = []
cite_collection = {}
headword_mapping = {}
urn_mapping = {}
cite_fields = ["URN","'URN-commentedOn'","Author","TranslatedBy","Text","Date","Translation","Notes","VettingStatus"]
md =  new Markdown.Converter()

default_cts_cite_collection_driver_config =
  google_api_key: 'AIzaSyCsBB8U6qfzFKFXWWpm8AN3iooxey_7lKU'
  cts_endpoint: '1_veTVGdKvI_WQ-8jU4al9ESWvjgTqjFzGreeAaKK'
  cts_urn: 'urn:cts:greekLit:tlg4040.lexicon.dc3'
  cite_table_id: '1Tv86Sn9h4CGug3I_Bp20yNT1wT4Ad2Ufp93zUiQP'
  cite_collection_editor_url: "//lyrical-flame-685.appspot.com/editor"
  cite_collection_editor_url_for_editors: "//dcthree.github.io/cite-collection-editor/"

urn_to_id = (urn) ->
  urn.replace(/[:.,'-]/g,'_')

urn_to_head = (urn) ->
  urn.replace(/^.*:/,'').replace(/_/g,' ')

# add UI for a single translation
# returns updated urn_li
add_translation = (translation, urn_li) ->
  translation_div = document.createElement('div')
  translation_div.setAttribute('class','translation')
  translation_div.setAttribute('id', urn_to_id(translation[cite_fields.indexOf('URN')]))
  edit_translation_link = cts_cite_collection_driver_config['cite_collection_editor_url'] + '#' + $.param(
    'URN': translation[cite_fields.indexOf('URN')]
  )
  edit_translation_a = document.createElement('a')
  edit_translation_a.setAttribute('target','_blank')
  edit_translation_a.setAttribute('class','disabled')
  # edit_translation_a.setAttribute('href',edit_translation_link)
  edit_translation_a.textContent = "Add a new version of translation #{translation[cite_fields.indexOf('URN')]}"

  license_a = document.createElement('a')
  license_a.setAttribute('rel','license')
  license_a.setAttribute('href','http://creativecommons.org/licenses/by/4.0/')

  license_img = document.createElement('img')
  license_img.setAttribute('alt','Creative Commons License')
  license_img.setAttribute('style','border-width:0')
  license_img.setAttribute('src','https://i.creativecommons.org/l/by/4.0/80x15.png')
  license_a.appendChild license_img

  license_span = document.createElement('span')
  license_span.setAttribute('style','float:right')
  license_span.appendChild(license_a)
  translation_div.appendChild(license_span)

  edit_span = document.createElement('span')
  edit_span.setAttribute('class','urn')
  edit_span.appendChild(edit_translation_a)
  translation_div.appendChild(edit_span)

  entered_span = document.createElement('span')
  entered_span.setAttribute('class','author')
  entered_span.textContent = 'Entered By: ' + translation[cite_fields.indexOf('Author')]
  translation_div.appendChild(entered_span)

  translated_by = translation[cite_fields.indexOf('TranslatedBy')]
  if translated_by?.length
    translated_by_span = document.createElement('span')
    translated_by_span.setAttribute('class','author')
    translated_by_span.textContent = 'Translated By: ' + translated_by
    translation_div.appendChild(translated_by_span)

  vetting_status = translation[cite_fields.indexOf('VettingStatus')]
  vetting_status = if vetting_status?.length then vetting_status else 'Not Peer Reviewed'
  vetting_span = document.createElement('span')
  vetting_span.setAttribute('class','vettingStatus')
  vetting_span.textContent = 'Peer Review Status: ' + vetting_status
  translation_div.appendChild(vetting_span)

  translation_div.appendChild(document.createElement('br'))
  # translation_div.append $('<span>').attr('class','timestamp').text(translation[3])
  # TODO: port canonical_text change detection into pure JS DOM
  # canonical_text = $("li##{urn_to_id(translation[cite_fields.indexOf("'URN-commentedOn'")])} .source_text p").text()
  # if translation[cite_fields.indexOf('Text')].trim() != canonical_text.trim()
  #   console.log("Canonical text: #{canonical_text}")
  #   translation_div.append $('<span>').attr('class','entry_text').text(translation[cite_fields.indexOf('Text')])
  # translation_div.append $('<span>').attr('class','translation_text').html(md.makeHtml(translation[cite_fields.indexOf('Translation')]))
  markdown_span = document.createElement('span')
  markdown_span.setAttribute('class','translation_text')
  markdown_span.innerHTML = md.makeHtml(translation[cite_fields.indexOf('Translation')])
  translation_div.appendChild(markdown_span)

  if translation[cite_fields.indexOf('Notes')]?.length
    translation_div.appendChild(document.createElement('br'))
    note_span = document.createElement('span')
    note_span.setAttribute('class','note')
    note_span.innerHTML = "Notes: #{md.makeHtml(translation[cite_fields.indexOf('Notes')])}"
    translation_div.appendChild(note_span)
  urn_li.appendChild(translation_div)
  return urn_li

# add translations to UI for a given URN
# cite_collection.rows row[1] contains URN-commentedOn
add_translations = (urn, urn_li) ->
  if cite_collection.rows?
    matching_rows = urn_mapping[urn]
    if matching_rows? and matching_rows.length > 0
      unless urn_li.getAttribute('class')? and (urn_li.getAttribute('class') == 'has_translation')
        urn_li.setAttribute('class', 'has_translation')
        urn_li.appendChild document.createElement('br')
        translations_p = document.createElement('p')
        translations_p.textContent = 'Translations'
        urn_li.appendChild translations_p
      for matching_row in matching_rows
        do (matching_row) ->
          unless document.getElementById(urn_to_id(matching_row[cite_fields.indexOf('URN')]))?
            urn_li = add_translation(matching_row, urn_li)
    else
      urn_li.setAttribute('class', 'no_translation')
  return urn_li

create_urn_li = (urn) ->
  # console.log("create_urn_li: #{urn}")
  urn_li = document.createElement('li')
  urn_li.setAttribute('id',urn_to_id(urn))
  urn_li.textContent = urn
  return urn_li

# add UI for a single text URN, then add its translations afterward
# returns urn_li
set_cts_text = (urn, head, tlg, urn_li) ->
  unless urn_li?
    urn_li = create_urn_li(urn)
    urn_li.textContent = ''

    source_text = document.createElement('div')
    source_text.setAttribute('class','source_text')
    source_text_head = document.createElement('strong')
    source_text_head_a = document.createElement('a')
    source_text_head_a.setAttribute('href',"https://dcthree.github.io/photios/entry##{encodeURIComponent(urn_to_id(urn))}")
    source_text_head_a.setAttribute('target','_blank')
    source_text_head_a.textContent = head
    source_text_head.appendChild source_text_head_a
    source_text.appendChild source_text_head
    urn_li.appendChild source_text
    urn_li.appendChild document.createElement('br')

    urn_components = urn.split(':')
    reference = 'photios;' + urn_components[-2..].join(';')
    if headword_mapping[reference]
      image_href = "https://dcthree.github.io/photios-images/#nanogallery/photios/pages/#{headword_mapping[reference]}"
      image_link = document.createElement('p')
      image_link_a = document.createElement('a')
      image_link_a.setAttribute('target','_blank')
      image_link_a.setAttribute('href',image_href)
      image_link_a.textContent = "Page image"
      image_link.appendChild image_link_a
      urn_li.appendChild image_link

    tlg_link = document.createElement('p')
    tlg_link_a = document.createElement('a')
    tlg_link_a.setAttribute('target','_blank')
    tlg_link_a.setAttribute('href',tlg)
    tlg_link_a.textContent = 'Open in TLG'
    tlg_link.appendChild tlg_link_a
    urn_li.append tlg_link

    editor_href = cts_cite_collection_driver_config['cite_collection_editor_url'] + '#' + $.param(
      'URN-commentedOn': urn
    )
    editor_link = document.createElement('p')
    editor_link_a = document.createElement('a')
    editor_link_a.setAttribute('target','_blank')
    editor_link_a.setAttribute('class','disabled')
    # editor_link_a.setAttribute('href',editor_href)
    editor_link_a.textContent = "Add translation for #{urn}"
    editor_link.appendChild editor_link_a
    urn_li.appendChild editor_link

  add_translations(urn, urn_li)

# sets passage from Fusion Tables result row
# returns urn_li
set_passage = (passage, urn_li) ->
  urn = passage[0]
  head = passage[1]
  tlg = passage[2]

  set_cts_text(urn, head, tlg, urn_li)

is_single_entry = ->
  return (window.location.pathname.match(/([^\/]*)\/*$/)[1] == 'entry') && window.location.hash && !(parse_query_string()['editor']?)

show_all = ->
  unless $('#all_entries_button').hasClass('active')
    $('#toggle_group button').removeClass('active')
    $('#all_entries_button').addClass('active')
    $('#valid_urns').remove()
    if is_single_entry()
      window.location.href = '{{ site.baseurl }}/' + window.location.hash
    else
      add_valid_urns()

show_untranslated = ->
  unless $('#untranslated_button').hasClass('active')
    $('#toggle_group button').removeClass('active')
    $('#untranslated_button').addClass('active')
    $('#valid_urns').remove()
    if is_single_entry()
      console.log('navigating to untranslated entries from single entry')
      window.history.pushState({},'Photios On Line', '{{ site.baseurl }}/' + window.location.hash)
      $('#translation_progress').empty()
      urn_mapping = {}
      build_cts_cite_driver()
    else
      add_valid_urns()

show_translated = ->
  unless $('#translated_button').hasClass('active')
    $('#toggle_group button').removeClass('active')
    $('#translated_button').addClass('active')
    $('#valid_urns').remove()
    if is_single_entry()
      console.log('navigating to translated entries from single entry')
      window.history.pushState({},'Photios On Line', '{{ site.baseurl }}/' + window.location.hash)
      $('#translation_progress').empty()
      urn_mapping = {}
      build_cts_cite_driver()
    else
      add_valid_urns()

cite_collection_contains_urn = (urn) ->
  if cite_collection.rows?
    matching_rows = urn_mapping[urn]
    if matching_rows? and matching_rows.length > 0
      return true
  return false

# returns constructed urn_li
add_urn_li = (urn, urn_li) ->
  set_passage(urn, urn_li)

shift_window = ->
  scrollBy(0, -60)

scroll_to_entry = ->
  if window.location.hash && !(parse_query_string()['editor']?) && document.getElementById('valid_urns')?
    urn_id = decodeURIComponent(window.location.hash)
    console.log 'scrolling to', urn_id
    if $(urn_id)? && $(urn_id).is(":visible")
      window.scrollTo(0,$(urn_id).position().top - 60)

add_valid_urns = ->
  console.log('add_valid_urns')
  has_existing_urns = true
  valid_urns_ul = document.getElementById('valid_urns')
  unless valid_urns_ul?
    valid_urns_ul = document.createElement('ul')
    valid_urns_ul.setAttribute('id','valid_urns')
    has_existing_urns = false
  translated_urns = 0
  for urn in valid_urns
    urn_li = document.getElementById(urn_to_id(urn[0]))
    has_existing_urn_li = urn_li?
    if $('#all_entries_button').hasClass('active')
      urn_li = add_urn_li(urn,urn_li)
      valid_urns_ul.appendChild(urn_li) unless has_existing_urn_li
    else if $('#untranslated_button').hasClass('active') && !cite_collection_contains_urn(urn[0])
      urn_li = add_urn_li(urn,urn_li)
      valid_urns_ul.appendChild(urn_li) unless has_existing_urn_li
    else if $('#translated_button').hasClass('active') && cite_collection_contains_urn(urn[0])
      urn_li = add_urn_li(urn,urn_li)
      valid_urns_ul.appendChild(urn_li) unless has_existing_urn_li

    if cite_collection_contains_urn(urn[0])
      translated_urns += 1

  unless has_existing_urns
    document.getElementById('translation_container').appendChild(valid_urns_ul)
    scroll_to_entry()
  return translated_urns

set_progress = (translated_urns, total_urns) ->
  progress = translated_urns/total_urns * 100.0
  console.log("Progress: #{progress}")
  $('#translation_progress').attr('style',"width: #{progress}%;")
  $('#translation_progress').append $('<span>').text("#{translated_urns} / #{total_urns} entries translated")

build_cts_ui = (callback = null) ->
  console.log('build_cts_ui')
  $('#all_entries_button').off('click').click(show_all)
  $('#translated_button').off('click').click(show_translated)
  $('#untranslated_button').off('click').click(show_untranslated)

  translated_urns = add_valid_urns()
  set_progress(translated_urns, valid_urns.length)
  callback() if callback?

# get headword mapping JSON
get_headword_mapping = (callback) ->
  console.log('get_headword_mapping')
  $.ajax '{{ site.baseurl }}/data/headword_mapping.json',
    type: 'GET'
    dataType: 'json'
    error: (jqXHR, textStatus, errorThrown) ->
      console.log "AJAX Error: #{textStatus}"
      callback() if callback?
    success: (data) ->
      headword_mapping = data
      callback() if callback?

# get all data from fusion table
get_cite_collection = (additional_criteria, callback) ->
  console.log('get_cite_collection')
  cite_collection_query = "SELECT #{cite_fields.join(', ')} FROM #{cts_cite_collection_driver_config['cite_table_id']} #{additional_criteria}"
  fusion_tables_query cite_collection_query, (fusion_tables_result) ->
    cite_collection = fusion_tables_result
    if cite_collection.rows?
      for row in cite_collection.rows
        do (row) ->
          urn = row[cite_fields.indexOf("'URN-commentedOn'")]
          urn_mapping[urn] ?= []
          urn_mapping[urn].push(row)
    callback() if callback?
  , ->
    $('#translation_container').append $('<div>').attr('class','alert alert-danger').text('Error in response from Google Fusion Tables for translation collection.')

# construct a list of valid URN's and pass to callback function
get_valid_reff = (urn, urn_comparison = 'STARTS WITH', callback = null) ->
  console.log('get_valid_reff')
  fusion_tables_query "SELECT URN,Headword,TLG FROM #{cts_cite_collection_driver_config['cts_endpoint']} WHERE URN #{urn_comparison} '#{urn}'", (fusion_tables_result) ->
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
          console.log data
          if callback?
            callback(data)

# parse URL hash parameters into an associative array object
parse_query_string = (query_string) ->
  query_string ?= location.hash.substring(1)
  params = {}
  if query_string.length > 0
    regex = /([^&=]+)=([^&]*)/g
    while m = regex.exec(query_string)
      params[decodeURIComponent(m[1])] = decodeURIComponent(m[2])
  return params

build_cts_cite_driver = ->
  console.log('build')
  # fetch CTS, fetch CITE, build UI
  base_urn = cts_cite_collection_driver_config['cts_urn']
  if is_single_entry()
    base_urn = base_urn + ':' + decodeURIComponent(window.location.hash).replace(/^#/,'').split('_').slice(-2).join(':')
    console.log "Rendering single entry:", base_urn
    get_valid_reff(base_urn, '=', -> get_cite_collection("WHERE 'URN-commentedOn' = '#{base_urn}'", -> get_headword_mapping( -> build_cts_ui( -> $('#toggle_group button').removeClass('active')))))
  else
    get_valid_reff(base_urn, 'STARTS WITH', -> get_cite_collection('', -> get_headword_mapping(build_cts_ui)))

# main driver entry point
$(document).ready ->
  console.log('ready')
  $('#loadingDiv').hide()
  $(document).ajaxStart -> $('#loadingDiv').show()
  $(document).ajaxStop -> $('#loadingDiv').hide()
  window.addEventListener("hashchange", shift_window)
  if (window.location.hash) && !(window.location.hash.startsWith('editor')) && document.getElementById('valid_urns')?
    shift_window()
  cts_cite_collection_driver_config = $.extend({}, default_cts_cite_collection_driver_config, window.cts_cite_collection_driver_config)
  if parse_query_string()['editor']?
    cts_cite_collection_driver_config['cite_collection_editor_url'] = cts_cite_collection_driver_config['cite_collection_editor_url_for_editors']
  console.log(cts_cite_collection_driver_config['cite_collection_editor_url'])
  set_progress(4011, 16296)
  # build_cts_cite_driver()
