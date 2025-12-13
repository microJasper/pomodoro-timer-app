/*
  script.js
  Vanilla JS for support page: i18n, form validation, submission (Formspree + mailto fallback), file checks, copy-to-clipboard.
*/

/*
  script.js — updated
  Vanilla JS for support page: i18n, form validation, submission (Formspree + mailto fallback), file checks, copy-to-clipboard.
  CONFIG.FORMSPREE_ENDPOINT set to the provided endpoint.
*/

const CONFIG = {
  SUPPORT_EMAIL: 'support@microjasper.com',
  FORMSPREE_ENDPOINT: 'https://formspree.io/f/xvgelbdl',
  MAX_FILE_BYTES: 10 * 1024 * 1024,
  ALLOWED_EXT: ['.txt', '.log', '.json'],
  REDIRECT_ON_SUCCESS: true, // true ise başarı halinde SUCCESS_PAGE'e yönlendirir
  SUCCESS_PAGE: 'thank-you.html', // başarı sonrası açılacak sayfa (relatif)
  SHOW_INLINE_SUCCESS: true // true ise kısa onay mesajı gösterir (aynı sayfada)
};

// i18n dictionary — includes keys for all translatable UI strings
const DICT = {
  tr: {
    introTitle: 'Hızlı Destek',
    introText: 'Uygulama sürümleri, destek saatleri ve ortalama cevap süresi burada. Genellikle 24-48 saat içinde yanıtlıyoruz.',
    troubleshootingTitle: 'Hızlı Çözümler',
    consentText: "Gizlilik Politikası'nı okudum ve kabul ediyorum.",
    supportEmailTitle: 'Support Email',
    supportEmailValue: 'support@microjasper.com',
    supportHoursTitle: 'Destek Saatleri',
    supportHoursValue: 'Hafta içi 09:00–18:00 (UTC+2)',
    ts_issue_title: 'Uygulama açılmıyor / Çöküyor',
    ts_issue_step1: 'Kapatıp yeniden başlatın.',
    ts_issue_step2: 'Telefonu yeniden başlatın.',
    ts_issue_step3: 'Uygulamayı güncelleyin (App Store / Play Store).',
    ts_issue_step4: 'Sorun devam ederse kayıtları ekleyerek destek talebi gönderin.',
    ts_notifications_title: 'Bildirimler gelmiyor',
    ts_notifications_step1: 'Bildirim izinlerini kontrol edin.',
    ts_notifications_step2: 'Uygulama ayarlarında bildirimleri etkinleştirin.',
    ts_notifications_step3: 'Do Not Disturb modunu kapatın.',
    ts_sync_title: 'Hesap / senkronizasyon sorunları',
    ts_sync_step1: 'İnternet bağlantınızı kontrol edin.',
    ts_sync_step2: 'Hesaptan çıkış yapıp tekrar giriş yapın.',
    ts_sync_step3: 'Gerekirse uygulama verilerini yeniden senkronize edin.',
    ts_cache_title: 'Önbellek / reset adımları',
    ts_cache_step1: 'Ayarlar → Uygulama → Önbelleği temizle.',
    ts_cache_step2: 'Gerekirse verileri sıfırlayın (uygulama içi yedekleme yapın).',
    faqTitle: 'SSS',
    faq_q1: 'Soru: Uygulama sürümü nasıl öğrenilir?',
    faq_a1: 'Cevap: Ayarlar > Hakkında bölümünden uygulama sürümünü görebilirsiniz.',
    faq_q2: 'Soru: Verilerim yedekleniyor mu?',
    faq_a2: 'Cevap: Evet, seçtiğiniz senkronizasyon ayarlarına bağlı olarak buluta kaydedilir.',
    faq_q3: 'Soru: Bildirim sesleri nereden değiştirilir?',
    faq_a3: 'Cevap: Ayarlar > Bildirimler bölümünden ses seçebilirsiniz.',
    faq_q4: 'Soru: Uygulama ücretli mi?',
    faq_a4: 'Cevap: Uygulamanın temel özellikleri ücretsizdir; ekstra özellikler uygulama içi satın alımla gelmektedir.',
    contactTitle: 'İletişim',
    nameLabel: 'İsim',
    namePlaceholder: '',
    emailLabel: 'E-posta',
    emailPlaceholder: '',
    appVersionLabel: 'App Version',
    deviceLabel: 'Device',
    devicePlaceholder: 'e.g. iPhone 12, Android 11',
    subjectLabel: 'Konu',
    subjectPlaceholder: '',
    messageLabel: 'Mesaj',
    messagePlaceholder: 'Lütfen sorununuzu mümkün olduğunca detaylandırın.',
    logsLabel: 'Attach Logs (opsiyonel)',
    fileHelp: 'Desteklenen: .txt, .log, .json — Maks 10MB',
    submitButton: 'Gönder',
    mailFallbackButton: 'E‑posta ile gönder',
    privacyLink: 'Privacy Policy',
    appStoreLink: 'App Store',
    footerSupport: 'Support:'
  },
  en: {
    introTitle: 'Quick Support',
    introText: 'App versions, support hours and expected reply times. We usually respond within 24–48 hours.',
    troubleshootingTitle: 'Quick Fixes',
    consentText: 'I have read and agree to the Privacy Policy.',
    supportEmailTitle: 'Support Email',
    supportEmailValue: 'support@microjasper.com',
    supportHoursTitle: 'Support Hours',
    supportHoursValue: 'Weekdays 09:00–18:00 (UTC+2)',
    ts_issue_title: 'App won\'t open / Crashes',
    ts_issue_step1: 'Force close and reopen the app.',
    ts_issue_step2: 'Restart your device.',
    ts_issue_step3: 'Update the app from the App Store / Play Store.',
    ts_issue_step4: 'If the issue continues, attach logs and submit a support request.',
    ts_notifications_title: 'Notifications not arriving',
    ts_notifications_step1: 'Check notification permissions.',
    ts_notifications_step2: 'Enable notifications in the app settings.',
    ts_notifications_step3: 'Disable Do Not Disturb mode.',
    ts_sync_title: 'Account / sync issues',
    ts_sync_step1: 'Check your internet connection.',
    ts_sync_step2: 'Sign out and sign back in to your account.',
    ts_sync_step3: 'Resync app data if needed.',
    ts_cache_title: 'Cache / reset steps',
    ts_cache_step1: 'Settings → Apps → Clear cache.',
    ts_cache_step2: 'If necessary, reset data (make an in-app backup first).',
    faqTitle: 'FAQ',
    faq_q1: 'Q: How do I find the app version?',
    faq_a1: 'A: You can find the version in Settings > About.',
    faq_q2: 'Q: Are my data backed up?',
    faq_a2: 'A: Yes, data are backed up to the cloud depending on your sync settings.',
    faq_q3: 'Q: How do I change notification sounds?',
    faq_a3: 'A: Change sounds in Settings > Notifications.',
    faq_q4: 'Q: Is the app paid?',
    faq_a4: 'A: The app is free with optional in-app purchases for extra features.',
    contactTitle: 'Contact',
    nameLabel: 'Name',
    namePlaceholder: '',
    emailLabel: 'Email',
    emailPlaceholder: '',
    appVersionLabel: 'App Version',
    deviceLabel: 'Device',
    devicePlaceholder: 'e.g. iPhone 12, Android 11',
    subjectLabel: 'Subject',
    subjectPlaceholder: '',
    messageLabel: 'Message',
    messagePlaceholder: 'Please describe your issue in detail.',
    logsLabel: 'Attach Logs (optional)',
    fileHelp: 'Supported: .txt, .log, .json — Max 10MB',
    submitButton: 'Send',
    mailFallbackButton: 'Send by email',
    privacyLink: 'Privacy Policy',
    appStoreLink: 'App Store',
    footerSupport: 'Support:'
  }
};

// Utilities
const $ = sel => document.querySelector(sel);
const $$ = sel => Array.from(document.querySelectorAll(sel));

function setLang(lang){
  // set document language and update visible label to show CURRENT language (TR or EN)
  document.documentElement.lang = (lang === 'en') ? 'en' : 'tr';
  const btn = document.getElementById('lang-toggle');
  if(btn){
    btn.textContent = (lang || 'tr').toUpperCase();
    btn.setAttribute('aria-pressed', lang === 'en');
  }
  // set textContent for elements with data-i18n
  document.querySelectorAll('[data-i18n]').forEach(el=>{
    const key = el.getAttribute('data-i18n');
    if(DICT[lang] && DICT[lang][key]) el.textContent = DICT[lang][key];
  });

  // set placeholders for inputs with data-i18n-placeholder
  document.querySelectorAll('[data-i18n-placeholder]').forEach(el=>{
    const key = el.getAttribute('data-i18n-placeholder');
    if(DICT[lang] && DICT[lang][key]) el.setAttribute('placeholder', DICT[lang][key]);
  });

  // set element values/text for data-i18n-value
  document.querySelectorAll('[data-i18n-value]').forEach(el=>{
    const key = el.getAttribute('data-i18n-value');
    if(DICT[lang] && DICT[lang][key]) el.textContent = DICT[lang][key];
  });

  // set label main text for elements with data-i18n-label (keeps children like span/input)
  document.querySelectorAll('[data-i18n-label]').forEach(label=>{
    const key = label.getAttribute('data-i18n-label');
    if(DICT[lang] && DICT[lang][key]){
      // find first text node child and replace it
      let textNode = Array.from(label.childNodes).find(n => n.nodeType === Node.TEXT_NODE);
      if(textNode){
        textNode.nodeValue = DICT[lang][key] + ' ';
      }else{
        label.insertBefore(document.createTextNode(DICT[lang][key] + ' '), label.firstChild);
      }
    }
  });

  // set alt attributes
  document.querySelectorAll('[data-i18n-alt]').forEach(el=>{
    const key = el.getAttribute('data-i18n-alt');
    if(DICT[lang] && DICT[lang][key]) el.setAttribute('alt', DICT[lang][key]);
  });

  // update buttons that use dedicated keys
  const submitBtn = document.querySelector('button[type="submit"]');
  if(submitBtn && DICT[lang] && DICT[lang].submitButton) submitBtn.textContent = DICT[lang].submitButton;
  const mailBtn = document.getElementById('mail-fallback');
  if(mailBtn && DICT[lang] && DICT[lang].mailFallbackButton) mailBtn.textContent = DICT[lang].mailFallbackButton;
}

function copyEmailButtons(){
  $$('[data-email]').forEach(btn => {
    btn.addEventListener('click', async e => {
      const email = btn.dataset.email;
      try{
        await navigator.clipboard.writeText(email);
        showStatus('E‑posta adresi panoya kopyalandı.');
      }catch(err){
        // fallback
        const range = document.createRange();
        const textNode = document.createTextNode(email);
        document.body.appendChild(textNode);
        range.selectNodeContents(textNode);
        const sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(range);
        document.execCommand('copy');
        sel.removeAllRanges();
        document.body.removeChild(textNode);
        showStatus('E‑posta adresi panoya kopyalandı.');
      }
    });
  });
}

function showStatus(msg, isError=false){
  const st = $('#form-status');
  st.textContent = msg;
  st.style.color = isError ? 'crimson' : 'inherit';
}

function getAppVersion(){
  const urlParams = new URLSearchParams(window.location.search);
  if(urlParams.has('appVersion')) return urlParams.get('appVersion');
  const meta = document.querySelector('meta[name="app-version"]');
  if(meta) return meta.getAttribute('content');
  return '';
}

function allowedFile(file){
  const name = file.name.toLowerCase();
  if(file.size > CONFIG.MAX_FILE_BYTES) return false;
  return CONFIG.ALLOWED_EXT.some(ext => name.endsWith(ext));
}

async function submitForm(e){
  e.preventDefault();
  const form = e.target;
  const fd = new FormData();
  const name = form.name.value.trim();
  const email = form.email.value.trim();
  const subject = form.subject.value.trim();
  const message = form.message.value.trim();
  const consent = form.consent.checked;

  // client-side validation
  if(!name || !email || !subject || !message || !consent){
    showStatus('Lütfen tüm zorunlu alanları doldurun ve gizlilik politikasını kabul edin.', true);
    return;
  }
  if(message.length < 20){
    showStatus('Mesaj en az 20 karakter olmalıdır.', true);
    return;
  }

  // file
  const fileInput = form.logs;
  if(fileInput && fileInput.files.length){
    const file = fileInput.files[0];
    if(!allowedFile(file)){
      showStatus('Dosya geçersiz veya çok büyük (maks 10MB).', true);
      return;
    }
    fd.append('logs', file, file.name);
  }

  // ensure all fields appended with correct keys
  fd.append('name', name);
  fd.append('email', email);
  fd.append('appVersion', form.appVersion.value || '');
  fd.append('device', form.device.value || '');
  fd.append('subject', subject);
  fd.append('message', message);

  // logging before submit
  try{
    console.debug('Submitting support form', { name, email, subject, appVersion: form.appVersion.value, device: form.device && form.device.value, file: (fileInput && fileInput.files.length) ? { name: fileInput.files[0].name, size: fileInput.files[0].size } : null });
  }catch(e){ console.debug('Pre-submit logging failed', e); }

  // optimistic UI
  showStatus('Gönderiliyor...');
  try{
    const resp = await fetch(CONFIG.FORMSPREE_ENDPOINT, {
      method: 'POST',
      body: fd,
      // Do not set content-type; let browser set multipart/form-data
      headers: {
        'Accept': 'application/json'
      }
    });

    console.log('Formspree response:', resp.status, resp.statusText);
    const text = await resp.text().catch(()=>null);
    console.log('body', text);

    if(resp.ok){
      if(CONFIG.SHOW_INLINE_SUCCESS){
        showStatus('Teşekkürler — talebiniz alındı. En kısa sürede yanıt vereceğiz.');
        form.reset();
        // refill appVersion after reset
        $('#appVersion').value = getAppVersion();
      }

      if(CONFIG.REDIRECT_ON_SUCCESS && CONFIG.SUCCESS_PAGE){
        // short delay to allow screen readers to hear the inline message
        setTimeout(()=>{
          window.location.href = CONFIG.SUCCESS_PAGE;
        }, 500);
      }
      return;
    }else{
      // try to parse JSON error message
      let parsed = null;
      try{ parsed = JSON.parse(text); }catch(e){ parsed = null; }
      const msg = (parsed && (parsed.error || parsed.message)) ? (parsed.error || parsed.message) : 'Form gönderilemedi. Lütfen e‑posta ile gönderin.';
      console.warn('Formspree returned error:', msg);
      showStatus(msg, true);
    }
  }catch(err){
    console.error('Submit failed', err);
    showStatus('Sunucuya ulaşamadı — e‑posta ile gönder seçeneğini deneyin.', true);
  }
}

function mailFallback(){
  const form = $('#support-form');
  const name = form.name.value.trim();
  const email = form.email.value.trim();
  const subject = form.subject.value.trim();
  const message = form.message.value.trim();
  const appVersion = form.appVersion.value;
  const device = form.device.value;

  if(!name || !email || !subject || !message){
    showStatus('Lütfen zorunlu alanları doldurun.', true);
    return;
  }
  const body = encodeURIComponent(`Name: ${name}\nEmail: ${email}\nApp Version: ${appVersion}\nDevice: ${device}\n\nMessage:\n${message}\n\n(If you attached logs, please attach them manually to the email.)`);
  const mailto = `mailto:${CONFIG.SUPPORT_EMAIL}?subject=${encodeURIComponent('[Pomodoro Pro Support] ' + subject)}&body=${body}`;
  window.location.href = mailto;
}

function init(){
  // i18n toggle
  const langToggle = $('#lang-toggle');
  let lang = 'tr';
  setLang(lang);
  langToggle.addEventListener('click', ()=>{
    lang = (lang === 'tr') ? 'en' : 'tr';
    setLang(lang);
  });

  copyEmailButtons();

  // fill app version
  $('#appVersion').value = getAppVersion();

  // form handlers
  const form = $('#support-form');
  form.addEventListener('submit', submitForm);
  $('#mail-fallback').addEventListener('click', mailFallback);

  // Accessibility: enable keyboard to open details via Enter
  document.querySelectorAll('details > summary').forEach(s => {
    s.addEventListener('keydown', e => {
      if(e.key === 'Enter' || e.key === ' '){
        e.preventDefault();
        s.parentElement.open = !s.parentElement.open;
      }
    });
  });

  // Prefill support email buttons
  $$('#copy-email, #footer-copy-email').forEach(btn => btn.dataset.email = CONFIG.SUPPORT_EMAIL);
}

document.addEventListener('DOMContentLoaded', init);

/*
  Optional reCAPTCHA integration (server-side verification recommended):
  1) Add site key and render widget in the form (client).
  2) On submit, include token in FormData and verify server-side.
  Example (commented):
  // fd.append('g-recaptcha-response', token);
*/
