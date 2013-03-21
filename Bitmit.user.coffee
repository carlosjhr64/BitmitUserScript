# ==UserScript==
# @name        Bitmit
# @namespace   Bitmit
# @description Bitmit Auto Edit
# @include     about:addons
# @version     1
# ==/UserScript==

usps = (type, oz) ->
  n = oz.toFixed(0)
  f = p = m = s = null
  switch type
    when 'pkg'
      f = USPKG[n]?['First-Class']
      s = USPKG[n]?['Standard Post']
    when 'mda'
      f = USPKG[n]?['First-Class']
      m = USPKG[n]?['Media Mail']
      s = USPKG[n]?['Standard Post']
    when 'ukpkg'
      f = UKPKG[n]?['First-Class']
      p = UKPKG[n]?['Priority Mail']
  price = 1000.0 # rediculously high most of the time
  price = f if f? and price > f
  price = p if p? and price > p
  price = m if m? and price > m
  price = s if s? and price > s
  return price

o =
  exp_date_value: '03/24/13 12:00'
  b2d: 56.65
  us: 0.9626
  ww: 0.8573
  gb: 0.9699
  auto: true # automatic submit and close
  codex: /\[\w+\|\d+\/\d+\]/
  submit: null
  note: null
  price: null
  delivery1: null
  delivery2: null
  delivery3: null # optional
  exp_date: null
  item_page: "https://www.bitmit.net/en/item/"
  sell_page: "https://www.bitmit.net/en/cp/se"
  interval: null
  count: null
  target: null
  packages:
    CD: true
    MG: true
    PB: true
    BK: true
    HH: true
    PK: true
    PKG: true
    pkg: true
    mda: true

  pkg: null
  timeout: 5000

my_open = (url, id) ->
  window.focus()
  console.log "Trying to open new window #{id}."
  o.target = window.open(url, id)
  #window.focus(); # TODO :-??

my_close = () ->
  if o.auto
    console.log "Trying to close window."
    clearInterval(o.interval)  if o.interval?
    window_close = () -> window.close()
    setTimeout(window_close, o.timeout)

price_format = (p) ->
  p.toFixed(4)

base_pkg = () ->
  ((o.note.match(o.codex))[0]).match(/\w+/)[0]

base_prices = () ->
  prices = ((o.note.match(o.codex))[0]).match(/\d+/g)
  if base_pkg() is 'pkg'
    oz = parseFloat(prices[0])
    us = usps('pkg', oz)
    uk = usps('ukpkg', oz)
    prices = [us, uk]
  else if base_pkg() is 'mda'
    oz = parseFloat(prices[0])
    us = usps('mda', oz)
    uk = usps('ukpkg', oz)
    prices = [us, uk]
  else
    prices = prices.map((p) -> parseFloat(p)/100.0)
  prices

us_price = () -> base_prices()[0]

ww_price = () -> base_prices()[1]

auction_price = () ->
  us = us_price()
  us /= o.us
  us /= o.b2d
  console.log("auction start price=#{us}")
  us

delivery_price = (country) ->
  delivery = null
  switch country
    when "US"
      delivery = 0.0
    when "GB"
      delivery = ww_price()
      delivery /= o.gb
      delivery /= o.b2d
      delivery -= auction_price()
    else
      delivery = ww_price()
      delivery /= o.ww
      delivery /= o.b2d
      delivery -= auction_price()
  console.log("#{country} delivery=#{delivery}")
  delivery

modify_n = (s, n) ->
  n = price_format(n)
  # Check if it actually needs to be modified
  return (0)  if parseFloat(s.value) is parseFloat(n)
  s.value = n
  1

modify_t = (s, t) ->
  return (0)  if s.value is t
  s.value = t
  1

edit_form = () ->
  edits = 0
  edits += modify_n(o.price, auction_price())
  edits += modify_n(o.delivery1,
  delivery_price(document.getElementById("delivery1_country").value))
  edits += modify_n(o.delivery2,
  delivery_price(document.getElementById("delivery2_country").value))
  if o.delivery3
    edits += modify_n(o.delivery3,
    delivery_price(document.getElementById("delivery3_country").value))
  edits += modify_t(o.exp_date, o.exp_date_value)
  if edits > 0
    console.log "There were #{edits} edits."
    if o.auto
      clickit = () -> o.submit.click()
      setTimeout(clickit, o.timeout)
  else
    console.log("There were no edits.")
    my_close()

check_for_variables = () ->
  go = false
  o.price = document.getElementById("price_auction")
  if o.price.value?
    o.delivery1 = document.getElementById("delivery1_price")
    o.delivery2 = document.getElementById("delivery2_price")
    o.delivery3 = document.getElementById("delivery3_price") # Optional
    o.exp_date = document.getElementById("itemDurationEndtimeCalendar")
    go = true  if (o.delivery1?) and (o.delivery2?) and (o.exp_date?)
  if go
    edit_form()
  else
    alert("Missing form variables.")

check_for_pkg = () ->
  pkg = base_pkg()
  if o.packages[pkg]
    o.pkg = pkg
    check_for_variables()
  else
    alert("Unknown type #{pkg}.")

best_guess_for_oz = (p1,p2) ->
  n1 = 0
  n2 = 0
  e1 = e2 = 1000.0 # big error
  n = 0
  type = 'pkg'
  loop
    n += 1
    fd = USPKG[n]?['First-Class']
    sp = USPKG[n]?['Standard Post']
    mm = USPKG[n]?['Media Mail']
    for us in [mm,fd,sp] when us and (e1 > us-p1 >= 0.0)
      e1 = us-p1
      n1 = n
      if us is mm
        type = 'mda'
      else
        type = 'pkg'
    fi = UKPKG[n]?['First-Class']
    mp = UKPKG[n]?['Priority Mail']
    for uk in [fi,mp] when uk and (e2 > uk-p2 >= 0)
      e2 = uk-p2
      n2 = n
    break unless fd or sp or mm or fi or mp
  n = n1
  n = n2 if n2 > n
  return [type,n]

check_for_note = () ->
  go = false
  if o.note = document.getElementById("txtareaInternalNote")
    # We're going to fix the note b/4 proceeding
    if md = o.note.value.match(/\[(\w+)\|(\d+)\/(\d+)\]/)
      if price2 = parseFloat(md[3])/100.0
        price1 = parseFloat(md[2])/100.0
        if price1? and price1 > 0.0 and price2 > 0.0
          if oz = best_guess_for_oz(price1, price2)
            o.note.value = "[#{oz[0]}|#{oz[1]}/0]#{md[1]}"
    o.note = o.note.value
    if o.codex.test(o.note)
      check_for_pkg()
    else
      alert("Internal note code missing.")

open_pages = (list) ->
  id = list[o.count]
  unless id?
    clearInterval o.interval
  else
    if not o.target? or o.target.closed
      id = id.match(/\d+/)[0]
      o.count += 1
      my_open("https://www.bitmit.net/en/cp/sell/edit/#{id}", id)

check_for_submit = () ->
  o.submit = document.getElementById("formItemSellSubmit")
  if o.submit
    clearInterval(o.interval)
    check_for_note()
  else
    if document.getElementById("active").className is "active"
      list = document.getElementById("content")
      if list
        list = list.innerHTML.match(/>\d+</g)
        if (list) and (list.length > 0)
          clearInterval(o.interval)
          console.log("Opening #{list.length} pages.")
          o.count = 0
          open_pages_list = () -> open_pages(list)
          o.interval = setInterval(open_pages_list, o.timeout)

run = () ->
  href = location.href
  console.log href
  switch href.substring(0, o.item_page.length)
    when o.item_page
      console.log("Closing...")
      my_close()
    when o.sell_page
      console.log("Checking...")
      o.interval = setInterval(check_for_submit, o.timeout)
    else
      console.log "Nothing to do."

run()
