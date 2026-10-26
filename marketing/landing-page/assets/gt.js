/* GoThere site analytics: PostHog (EU), cookieless.
 * persistence 'memory' = no cookies, no localStorage; a visitor is not recognised across page loads.
 * No autocapture, no session recording, no person profiles. Only the events below + pageviews.
 * Events: store_click {store, campaign, placement}, source_click {host}, move_nav {to}, api_click {to},
 * tool_descent_check {country, confidence, generations}, tool_income_calc {currency, period, meets}.
 */
(function () {
  var KEY = "phc_zdWSqHah9LiyNqn38H2i3E48XPv5acrWsXedfUWVGSLb";
  var HOST = "https://eu.i.posthog.com";
  var queue = [];

  function send(name, props) {
    props = props || {};
    props.page = location.pathname;
    if (window.posthog && window.posthog.__loaded) {
      window.posthog.capture(name, props, { transport: "sendBeacon" });
    } else {
      queue.push([name, props]);
    }
  }

  // Free tools report usage (no inputs) through this: tool_descent_check, tool_income_calc.
  window.gtTrack = send;

  function placement(a) {
    var box = a.closest(".cta-box, nav, footer, .footer, .hero, .country-card, .callout, .answer");
    return box ? (box.className.split(" ")[0] || box.tagName.toLowerCase()) : "body";
  }

  document.addEventListener("click", function (e) {
    var a = e.target.closest && e.target.closest("a[href]");
    if (!a) return;
    var url;
    try { url = new URL(a.href, location.href); } catch (err) { return; }
    if (url.hostname === "apps.apple.com") {
      send("store_click", { store: "ios", campaign: url.searchParams.get("ct") || "", placement: placement(a) });
    } else if (url.hostname === "play.google.com") {
      var ref = decodeURIComponent(url.searchParams.get("referrer") || "");
      var m = ref.match(/utm_campaign=([^&]+)/);
      send("store_click", { store: "android", campaign: m ? m[1] : "", placement: placement(a) });
    } else if (url.hostname === location.hostname && url.pathname.indexOf("/move/") === 0) {
      send("move_nav", { to: url.pathname });
    } else if (url.hostname === location.hostname && url.pathname.indexOf("/api/") === 0) {
      send("api_click", { to: url.pathname });
    } else if (url.hostname !== location.hostname && (a.classList.contains("src") || /nofollow/.test(a.rel))) {
      send("source_click", { host: url.hostname });
    }
  });

  var s = document.createElement("script");
  s.async = true;
  s.src = "https://eu-assets.i.posthog.com/static/array.js";
  s.onload = function () {
    if (!window.posthog || !window.posthog.init) return;
    window.posthog.init(KEY, {
      api_host: HOST,
      persistence: "memory",
      autocapture: false,
      capture_pageview: true,
      capture_pageleave: false,
      disable_session_recording: true,
      disable_surveys: true,
      person_profiles: "identified_only",
      loaded: function () {
        queue.forEach(function (q) { window.posthog.capture(q[0], q[1], { transport: "sendBeacon" }); });
        queue = [];
      }
    });
  };
  document.head.appendChild(s);
})();
