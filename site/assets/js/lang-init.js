/* Runs before first paint: choose the saved or browser language, and mark that JavaScript is on. */
(function () {
  var lang = null;
  try {
    lang = window.localStorage.getItem('kk-lang');
  } catch (e) {
    /* Storage can be blocked; fall back to the browser language. */
  }
  if (lang !== 'en' && lang !== 'zh') {
    var preferred = (navigator.languages && navigator.languages[0]) || navigator.language || '';
    lang = /^zh\b/i.test(preferred) ? 'zh' : 'en';
  }
  var root = document.documentElement;
  root.setAttribute('data-lang', lang);
  root.setAttribute('lang', lang === 'zh' ? 'zh-CN' : 'en');
  root.classList.add('js');
})();
