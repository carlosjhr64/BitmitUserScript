# ==UserScript==
# @name        Bitmit
# @namespace   Bitmit
# @description Bitmit Auto Edit
# @include     about:addons
# @version     1
# ==/UserScript==

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
      n = (oz - 1).toFixed(0)
      return 3.00 + n*0.78 if oz < 9
      return 10.03 if oz < 13
      n = (1 + (oz - 13)/4).toFixed(0)
      return 10.03 * n*1.57

o =
  auto: false # automatic submit and close
  codex: /\[\w+\|\d+\/\d+\]/
  submit: null
  description: null
  price: null
  delivery1: null
  delivery2: null
  b2d: 13.50
  us: 0.959
  ww: 0.78636
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
  p.toFixed(3)

base_prices = () ->
  ((o.description.value.match(o.codex))[0]).match(/\d+/g)

base_pkg = () ->
  ((o.description.value.match(o.codex))[0]).match(/\w+/)[0]

us_price = () -> parseFloat(base_prices()[0]) / 100.0

ww_price = () -> parseFloat(base_prices()[1]) / 100.0

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

modify = (s, n) ->
  n = price_format(n)
  # Check if it actually needs to be modified
  return (0)  if parseFloat(s.value) is parseFloat(n)
  s.value = n
  1

edit_form = () ->
  edits = 0
  edits += modify(o.price, auction_price())
  edits += modify(o.delivery1,
  delivery_price(document.getElementById("delivery1_country").value))
  edits += modify(o.delivery2,
  delivery_price(document.getElementById("delivery2_country").value))
  if edits > 0
    console.log "There were #{edits} edits."
    if o.auto
      clickit = () -> o.submit.click()
      setTimeout(clikckit, o.timeout)
  else
    console.log("There were no edits.")
    my_close()

check_for_variables = () ->
  go = false
  o.price = document.getElementById("price_auction")
  if o.price.value?
    o.delivery1 = document.getElementById("delivery1_price")
    o.delivery2 = document.getElementById("delivery2_price")
    go = true  if (o.delivery1?) and (o.delivery2?)
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

check_for_description = () ->
  go = false
  o.description = document.getElementById("description")
  go = true  if o.codex.test(o.description.value)  if o.description
  if go
    check_for_pkg()
  else
    alert("Description is missing code.")

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
    check_for_description()
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
