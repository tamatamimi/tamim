/**
 * Jannatan Naturals — تحسينات واجهة خفيفة (بدون أي مكتبات خارجية)
 * 1) شريط "أضف للسلة" الثابت في صفحة المنتج
 * 2) زر البحث في الشريط السفلي
 * 3) عدّاد كمية (+/-) قابل للنقر
 * 4) تمييز التصنيف النشط في شريط التصنيفات
 */
(function () {
  'use strict';

  var ready = function (fn) {
    if (document.readyState !== 'loading') { fn(); }
    else { document.addEventListener('DOMContentLoaded', fn); }
  };

  ready(function () {

    /* ---- 1) شريط الشراء الثابت: يظهر بعد تمرير زر الشراء الأصلي ---- */
    var bar = document.querySelector('.jn-sticky-atc');
    var mainForm = document.querySelector('form.cart');
    var mainBtn = document.querySelector('form.cart .single_add_to_cart_button');

    if (bar && mainBtn) {
      var barBtn = bar.querySelector('.jn-sticky-atc__btn');

      barBtn.addEventListener('click', function (e) {
        e.preventDefault();
        // متغيّر لم يُختر بعد؟ مرّر المستخدم للخيارات بدل إرسال طلب فاشل.
        if (mainBtn.classList.contains('disabled') || mainBtn.disabled) {
          mainForm.scrollIntoView({ behavior: 'smooth', block: 'center' });
          return;
        }
        mainBtn.click();
      });

      if ('IntersectionObserver' in window) {
        var io = new IntersectionObserver(function (entries) {
          entries.forEach(function (entry) {
            bar.classList.toggle('is-visible', !entry.isIntersecting);
          });
        }, { rootMargin: '0px 0px -60px 0px' });
        io.observe(mainBtn);
      } else {
        bar.classList.add('is-visible');
      }
    }

    /* ---- 2) زر البحث في الشريط السفلي يفتح بحث Flatsome ---- */
    var searchLink = document.querySelector('[data-jn-search]');
    if (searchLink) {
      searchLink.addEventListener('click', function (e) {
        e.preventDefault();
        var trigger = document.querySelector('.header-search-form input[type="search"], .searchform input.search-field, .dgwt-wcas-search-input');
        var toggle = document.querySelector('a[href="#search-lightbox"], .search-form a.is-small');
        if (toggle) {
          toggle.click();
          setTimeout(function () {
            var f = document.querySelector('.mfp-content input[type="search"], .dgwt-wcas-search-input');
            if (f) { f.focus(); }
          }, 260);
        } else if (trigger) {
          trigger.scrollIntoView({ behavior: 'smooth', block: 'center' });
          trigger.focus();
        }
      });
    }

    /* ---- 3) أزرار +/- للكمية ---- */
    document.querySelectorAll('.quantity').forEach(function (wrap) {
      var input = wrap.querySelector('input.qty');
      if (!input || wrap.querySelector('.jn-qty-btn')) { return; }

      var mk = function (sign, cls) {
        var b = document.createElement('button');
        b.type = 'button';
        b.className = 'jn-qty-btn ' + cls;
        b.textContent = sign;
        b.setAttribute('aria-label', cls === 'plus' ? 'Increase quantity' : 'Decrease quantity');
        return b;
      };

      var minus = mk('−', 'minus');
      var plus = mk('+', 'plus');
      wrap.insertBefore(minus, input);
      wrap.appendChild(plus);

      var step = function (dir) {
        var step = parseFloat(input.step) || 1;
        var min = parseFloat(input.min) || 0;
        var max = parseFloat(input.max);
        var val = parseFloat(input.value) || min;
        var next = val + dir * step;
        if (next < min) { next = min; }
        if (!isNaN(max) && next > max) { next = max; }
        input.value = next;
        input.dispatchEvent(new Event('change', { bubbles: true }));
      };

      minus.addEventListener('click', function () { step(-1); });
      plus.addEventListener('click', function () { step(1); });
    });

    /* ---- 4) تمييز التصنيف الحالي في الشريط الأفقي ---- */
    var here = window.location.pathname.replace(/\/+$/, '');
    document.querySelectorAll('.jn-catbar a').forEach(function (a) {
      var p = a.getAttribute('href');
      if (!p) { return; }
      try { p = new URL(a.href).pathname.replace(/\/+$/, ''); } catch (err) { return; }
      if (p && p === here) { a.classList.add('is-active'); }
    });

  });
})();
