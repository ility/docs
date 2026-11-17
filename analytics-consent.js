// Docs analytics consent. Mintlify sends analytics, PostHog included, only
// while localStorage holds the key and value in docs.json
// `integrations.cookies`. Set it unless the browser sends Do Not Track or
// Global Privacy Control, so docs.ilitylabs.com honors both, as
// ilitylabs.com and app.ilitylabs.com do.
//
// Mintlify runs this file on every page, after the page is interactive. A
// visitor's very first page view can be missed while the key is not yet set.
(function () {
  try {
    var optedOut = navigator.doNotTrack === "1" || navigator.globalPrivacyControl === true;
    if (optedOut) localStorage.removeItem("ility-analytics");
    else localStorage.setItem("ility-analytics", "on");
  } catch (error) {
    // Storage blocked: no key, so no analytics.
  }
})();
