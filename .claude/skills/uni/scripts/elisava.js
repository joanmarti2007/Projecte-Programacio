#!/usr/bin/env node
// Acceso al campus de Elisava (campus.elisava.net) tras el login de Microsoft.
//
// Credenciales: variables de entorno ELISAVA_USER y ELISAVA_PASSWORD.
// La sesión se guarda en .elisava_state.json (raíz del repo, fuera de git).
//
// Uso:
//   elisava.js login            Inicia sesión. Si Microsoft pide Authenticator,
//                               imprime "NUMERO: <n>" y espera la aprobación.
//                               Si pide un código, imprime "CODIGO_REQUERIDO" y
//                               espera a que se escriba en .elisava_code.
//   elisava.js get <url> [--links]   Texto de una página del campus (y sus enlaces).
//                               Imprime "SESION_CADUCADA" si hay que volver a hacer login.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '../../../..');
const STATE = path.join(ROOT, '.elisava_state.json');
const CODE_FILE = path.join(ROOT, '.elisava_code');
const CAMPUS = 'https://campus.elisava.net/';
const TIMEOUT_MS = 180000;

const visible = async (page, sel) => (await page.$(sel).then(e => e && e.isVisible()).catch(() => false));

async function login() {
  const { ELISAVA_USER, ELISAVA_PASSWORD } = process.env;
  if (!ELISAVA_USER || !ELISAVA_PASSWORD) throw new Error('Faltan ELISAVA_USER / ELISAVA_PASSWORD');
  fs.rmSync(CODE_FILE, { force: true });

  const browser = await chromium.launch();
  const ctx = await browser.newContext({ locale: 'es-ES' });
  const page = await ctx.newPage();
  await page.goto(CAMPUS);

  await page.fill('#i0116', ELISAVA_USER);
  await page.click('#idSIButton9');
  await page.waitForSelector('#i0118', { state: 'visible' });
  await page.fill('#i0118', ELISAVA_PASSWORD);
  await page.click('#idSIButton9');

  let shownNumber = null, askedCode = false;
  const end = Date.now() + TIMEOUT_MS;
  while (Date.now() < end) {
    await page.waitForTimeout(1500);
    if (new URL(page.url()).host === 'campus.elisava.net') {
      await ctx.storageState({ path: STATE });
      fs.chmodSync(STATE, 0o600);
      console.log('LOGIN_OK');
      await browser.close();
      return;
    }
    for (const sel of ['#usernameError', '#passwordError', '#idTD_Error', '#idDiv_SAASDS_Description']) {
      if (await visible(page, sel)) throw new Error(`Microsoft: ${(await page.innerText(sel)).trim()}`);
    }
    if (await visible(page, '#idRichContext_DisplaySign')) {
      const n = (await page.innerText('#idRichContext_DisplaySign')).trim();
      if (n !== shownNumber) console.log(`NUMERO: ${(shownNumber = n)}`);
    } else if (await visible(page, '#idTxtBx_SAOTCC_OTC')) {
      if (!askedCode) { console.log('CODIGO_REQUERIDO'); askedCode = true; }
      if (fs.existsSync(CODE_FILE)) {
        await page.fill('#idTxtBx_SAOTCC_OTC', fs.readFileSync(CODE_FILE, 'utf8').trim());
        fs.rmSync(CODE_FILE);
        await page.click('#idSubmit_SAOTCC_Continue');
      }
    } else if (await visible(page, '#KmsiCheckboxField') || await visible(page, '#KmsiDescription')) {
      await page.click('#idSIButton9'); // "¿Quiere mantener la sesión iniciada?" → Sí
    } else if (await visible(page, '#idDiv_SAOTCAS_Title') && !shownNumber) {
      console.log('APROBAR_EN_AUTHENTICATOR'); shownNumber = '-';
    }
  }
  const where = new URL(page.url());
  const text = (await page.innerText('body').catch(() => '')).replace(/\s+/g, ' ').slice(0, 400);
  throw new Error(`Tiempo agotado esperando la aprobación (en ${where.host}${where.pathname}: "${text}")`);
}

async function get(url, withLinks) {
  if (!fs.existsSync(STATE)) { console.log('SESION_CADUCADA'); return; }
  const browser = await chromium.launch();
  const ctx = await browser.newContext({ storageState: STATE, locale: 'es-ES' });
  const page = await ctx.newPage();
  await page.goto(new URL(url, CAMPUS).href, { waitUntil: 'networkidle' });
  if (new URL(page.url()).host !== 'campus.elisava.net') {
    console.log('SESION_CADUCADA');
  } else {
    await ctx.storageState({ path: STATE }); // refresca cookies
    console.log(`URL: ${page.url()}\n`);
    console.log(await page.innerText('main').catch(() => page.innerText('body')));
    if (withLinks) {
      const links = await page.$$eval('a[href]', as => as.map(a => `${a.innerText.trim().replace(/\s+/g, ' ')} -> ${a.href}`));
      console.log('\n--- ENLACES ---\n' + [...new Set(links)].join('\n'));
    }
  }
  await browser.close();
}

const [cmd, arg] = process.argv.slice(2);
(cmd === 'login' ? login() : cmd === 'get' && arg ? get(arg, process.argv.includes('--links')) : Promise.reject(new Error('Uso: elisava.js login | get <url> [--links]')))
  .catch(e => { console.error(`ERROR: ${e.message}`); process.exit(1); });
