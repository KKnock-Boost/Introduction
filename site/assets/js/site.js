/* Language toggle, example due labels in the app's format, header shadow and scroll reveal. */
(function () {
  'use strict';

  var root = document.documentElement;
  var MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  function currentLang() {
    return root.getAttribute('data-lang') === 'zh' ? 'zh' : 'en';
  }

  function applyLang(lang) {
    root.setAttribute('data-lang', lang);
    root.setAttribute('lang', lang === 'zh' ? 'zh-CN' : 'en');
    var title = root.getAttribute('data-title-' + lang);
    if (title) document.title = title;
    var buttons = document.querySelectorAll('[data-set-lang]');
    for (var i = 0; i < buttons.length; i++) {
      buttons[i].setAttribute('aria-pressed', String(buttons[i].getAttribute('data-set-lang') === lang));
    }
  }

  document.addEventListener('click', function (event) {
    var button = event.target.closest ? event.target.closest('[data-set-lang]') : null;
    if (!button) return;
    var lang = button.getAttribute('data-set-lang') === 'zh' ? 'zh' : 'en';
    applyLang(lang);
    try {
      window.localStorage.setItem('kk-lang', lang);
    } catch (e) {
      /* The choice still applies to this page view. */
    }
  });

  // data-due="1@18:00" (days ahead), "tonight@19:00" (tomorrow once the evening has started)
  // or "mon@09:00" (next Monday). Rendered the way the app shows due times.
  function dueDate(spec, now) {
    var parts = spec.split('@');
    var time = parts[1].split(':');
    var date = new Date(now.getFullYear(), now.getMonth(), now.getDate(), +time[0], +time[1]);
    if (parts[0] === 'tonight') {
      if (now.getHours() >= 18) date.setDate(date.getDate() + 1);
    } else if (parts[0] === 'mon') {
      date.setDate(date.getDate() + ((8 - date.getDay()) % 7 || 7));
    } else {
      date.setDate(date.getDate() + (+parts[0] || 0));
    }
    return date;
  }

  function two(value) {
    return value < 10 ? '0' + value : String(value);
  }

  function formatEn(date) {
    var hours = date.getHours();
    var hour12 = hours % 12 || 12;
    return MONTHS[date.getMonth()] + ' ' + date.getDate() + ' · ' + hour12 + ':' + two(date.getMinutes()) +
      (hours < 12 ? ' AM' : ' PM');
  }

  function formatZh(date) {
    return (date.getMonth() + 1) + '月' + date.getDate() + '日 ' + two(date.getHours()) + ':' + two(date.getMinutes());
  }

  function renderDue() {
    var now = new Date();
    var nodes = document.querySelectorAll('[data-due]');
    for (var i = 0; i < nodes.length; i++) {
      var date = dueDate(nodes[i].getAttribute('data-due'), now);
      var en = nodes[i].querySelector('[lang="en"]');
      var zh = nodes[i].querySelector('[lang="zh-CN"]');
      if (en) en.textContent = formatEn(date);
      if (zh) zh.textContent = formatZh(date);
    }
  }

  function setupHeader() {
    var nav = document.querySelector('.nav');
    if (!nav) return;
    var update = function () {
      nav.classList.toggle('is-scrolled', window.scrollY > 8);
    };
    window.addEventListener('scroll', update, { passive: true });
    update();
  }

  function setupReveal() {
    var items = document.querySelectorAll('.reveal');
    var i;
    if (!('IntersectionObserver' in window)) {
      for (i = 0; i < items.length; i++) items[i].classList.add('is-in');
      return;
    }
    var observer = new IntersectionObserver(function (entries) {
      for (var j = 0; j < entries.length; j++) {
        if (entries[j].isIntersecting) {
          entries[j].target.classList.add('is-in');
          observer.unobserve(entries[j].target);
        }
      }
    }, { rootMargin: '0px 0px -6% 0px', threshold: 0.06 });
    for (i = 0; i < items.length; i++) observer.observe(items[i]);
  }

  applyLang(currentLang());
  renderDue();
  setupHeader();
  setupReveal();
})();
