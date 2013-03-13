# ==UserScript==
# @name        Bitmit
# @namespace   Bitmit
# @description Bitmit Auto Edit
# @include     about:addons
# @version     1
# ==/UserScript==

UKPKG = [
  6.55  #0oz
  6.55  #1
  6.55  #2
  9.45  #3
  9.45  #4
  12.75 #5
  12.75 #6
  12.75 #7
  12.75 #8
  14.90 #9
  14.90 #10
  14.90 #11
  14.90 #12
  16.75 #13
  16.75 #14
  16.75 #15
  16.75 #16
  18.60 #17
  18.60 #18
  18.60 #19
  18.60 #20
  20.45 #21
  20.45 #22
  20.45 #23
  20.45 #24
  22.30 #25
  22.30 #26
  22.30 #27
  22.30 #28
  24.15 #29
  24.15 #30
  24.15 #31
  24.15 #32
  26.00 #33
  26.00 #34
  26.00 #35
  26.00 #36
  27.85 #37
  27.85 #38
  27.85 #39
  27.85 #40
  29.70 #41
  29.70 #42
  29.70 #43
  29.70 #44
  31.55 #45
  31.55 #46
  31.55 #47
  31.55 #48
  33.40 #49
]

usps = (type, oz) ->
  switch type
    when 'ltt'
      return 0.45 if oz <= 1
      return 0.65 if oz <= 2
      return 0.85 if oz <= 3.5
      return usps('flt', oz)
    when 'flt'
      n = (oz - 1).toFixed(0)
      return 0.90 + n*0.20 if oz < 13
      return usps('pkg', oz)
    when 'pkg'
      n = (oz - 3).toFixed(0)
      n = 0 if n < 0
      return 1.95 + n*0.17
    when 'mda'
      p1 = usps('pkg', oz)
      n = (oz/16).toFixed(0)
      p2 = [2.38, 2.77, 3.16, 3.55, 3.94, 4.47, 4.99][n]
      unless p2
        p2 = 4.99 + (n-7)*0.40
      return p1 if p1 < p2
      return p2
    when 'ukpkg'
      n = oz.toFixed(0)
      return UKPKG[n] if n < 50
      return UKPKG[49]  + 0.4625*(n-49)

o =
  exp_date_value: '03/17/13 12:00'
  b2d: 32.29
  us: 0.961
  ww: 0.854
  auto: true # automatic submit and close
  codex: /\[\w+\|\d+\/\d+\]/
  submit: null
  note: null
  price: null
  delivery1: null
  delivery2: null
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

check_for_note = () ->
  go = false
  o.note = document.getElementById("txtareaInternalNote")?.innerHTML # .contentDocument?.body?.innerHTML
  go = true  if o.codex.test(o.note)  if o.note?
  if go
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
