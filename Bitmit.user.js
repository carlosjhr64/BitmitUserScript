var auction_price, base_pkg, base_prices, check_for_description, check_for_pkg, check_for_submit, check_for_variables, delivery_price, edit_form, modify, my_close, my_open, o, open_pages, price_format, run, us_price, usps, ww_price;

usps = function(type, oz) {
  var n, p1, p2;
  switch (type) {
    case 'ltt':
      if (oz <= 1) return 0.45;
      if (oz <= 2) return 0.65;
      if (oz <= 3.5) return 0.85;
      return usps('flt', oz);
    case 'flt':
      n = (oz - 1).toFixed(0);
      if (oz < 13) return 0.90 + n * 0.20;
      return usps('pkg', oz);
    case 'pkg':
      n = (oz - 3).toFixed(0);
      if (n < 0) n = 0;
      return 1.95 + n * 0.17;
    case 'mda':
      p1 = usps('pkg', oz);
      n = (oz / 16).toFixed(0);
      p2 = [2.38, 2.77, 3.16, 3.55, 3.94, 4.47, 4.99][n];
      if (!p2) p2 = 4.99 + (n - 7) * 0.40;
      if (p1 < p2) return p1;
      return p2;
    case 'ukpkg':
      n = (oz - 1).toFixed(0);
      if (oz < 9) return 3.00 + n * 0.78;
      if (oz < 13) return 10.03;
      n = (1 + (oz - 13) / 4).toFixed(0);
      return 10.03 * n * 1.57;
  }
};

o = {
  auto: false,
  codex: /\[\w+\|\d+\/\d+\]/,
  submit: null,
  description: null,
  price: null,
  delivery1: null,
  delivery2: null,
  b2d: 13.50,
  us: 0.959,
  ww: 0.78636,
  item_page: "https://www.bitmit.net/en/item/",
  sell_page: "https://www.bitmit.net/en/cp/se",
  interval: null,
  count: null,
  target: null,
  packages: {
    CD: true,
    MG: true,
    PB: true,
    BK: true,
    HH: true,
    PK: true,
    PKG: true
  },
  pkg: null,
  timeout: 5000
};

my_open = function(url, id) {
  window.focus();
  console.log("Trying to open new window " + id + ".");
  return o.target = window.open(url, id);
};

my_close = function() {
  var window_close;
  if (o.auto) {
    console.log("Trying to close window.");
    if (o.interval != null) clearInterval(o.interval);
    window_close = function() {
      return window.close();
    };
    return setTimeout(window_close, o.timeout);
  }
};

price_format = function(p) {
  return p.toFixed(3);
};

base_prices = function() {
  return (o.description.value.match(o.codex))[0].match(/\d+/g);
};

base_pkg = function() {
  return (o.description.value.match(o.codex))[0].match(/\w+/)[0];
};

us_price = function() {
  return parseFloat(base_prices()[0]) / 100.0;
};

ww_price = function() {
  return parseFloat(base_prices()[1]) / 100.0;
};

auction_price = function() {
  var us;
  us = us_price();
  us /= o.us;
  us /= o.b2d;
  console.log("auction start price=" + us);
  return us;
};

delivery_price = function(country) {
  var delivery;
  delivery = null;
  switch (country) {
    case "US":
      delivery = 0.0;
      break;
    default:
      delivery = ww_price();
      delivery /= o.ww;
      delivery /= o.b2d;
      delivery -= auction_price();
  }
  console.log("" + country + " delivery=" + delivery);
  return delivery;
};

modify = function(s, n) {
  n = price_format(n);
  if (parseFloat(s.value) === parseFloat(n)) return 0.;
  s.value = n;
  return 1;
};

edit_form = function() {
  var clickit, edits;
  edits = 0;
  edits += modify(o.price, auction_price());
  edits += modify(o.delivery1, delivery_price(document.getElementById("delivery1_country").value));
  edits += modify(o.delivery2, delivery_price(document.getElementById("delivery2_country").value));
  if (edits > 0) {
    console.log("There were " + edits + " edits.");
    if (o.auto) {
      clickit = function() {
        return o.submit.click();
      };
      return setTimeout(clikckit, o.timeout);
    }
  } else {
    console.log("There were no edits.");
    return my_close();
  }
};

check_for_variables = function() {
  var go;
  go = false;
  o.price = document.getElementById("price_auction");
  if (o.price.value != null) {
    o.delivery1 = document.getElementById("delivery1_price");
    o.delivery2 = document.getElementById("delivery2_price");
    if ((o.delivery1 != null) && (o.delivery2 != null)) go = true;
  }
  if (go) {
    return edit_form();
  } else {
    return alert("Missing form variables.");
  }
};

check_for_pkg = function() {
  var pkg;
  pkg = base_pkg();
  if (o.packages[pkg]) {
    o.pkg = pkg;
    return check_for_variables();
  } else {
    return alert("Unknown type " + pkg + ".");
  }
};

check_for_description = function() {
  var go;
  go = false;
  o.description = document.getElementById("description");
  if (o.description ? o.codex.test(o.description.value) : void 0) go = true;
  if (go) {
    return check_for_pkg();
  } else {
    return alert("Description is missing code.");
  }
};

open_pages = function(list) {
  var id;
  id = list[o.count];
  if (id == null) {
    return clearInterval(o.interval);
  } else {
    if (!(o.target != null) || o.target.closed) {
      id = id.match(/\d+/)[0];
      o.count += 1;
      return my_open("https://www.bitmit.net/en/cp/sell/edit/" + id, id);
    }
  }
};

check_for_submit = function() {
  var list, open_pages_list;
  o.submit = document.getElementById("formItemSellSubmit");
  if (o.submit) {
    clearInterval(o.interval);
    return check_for_description();
  } else {
    if (document.getElementById("active").className === "active") {
      list = document.getElementById("content");
      if (list) {
        list = list.innerHTML.match(/>\d+</g);
        if (list && (list.length > 0)) {
          clearInterval(o.interval);
          console.log("Opening " + list.length + " pages.");
          o.count = 0;
          open_pages_list = function() {
            return open_pages(list);
          };
          return o.interval = setInterval(open_pages_list, o.timeout);
        }
      }
    }
  }
};

run = function() {
  var href;
  href = location.href;
  console.log(href);
  switch (href.substring(0, o.item_page.length)) {
    case o.item_page:
      console.log("Closing...");
      return my_close();
    case o.sell_page:
      console.log("Checking...");
      return o.interval = setInterval(check_for_submit, o.timeout);
    default:
      return console.log("Nothing to do.");
  }
};

run();
