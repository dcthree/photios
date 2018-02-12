const puppeteer = require('puppeteer');

(async() => {
const browser = await puppeteer.launch();
const page = await browser.newPage();
await page.goto('http://127.0.0.1:4000/index-dynamic.html', {waitUntil: 'networkidle2'});
await page.waitForSelector('#urn_cts_greekLit_tlg4040_lexicon_dc3_δ_148a');
var valid_urns = await page.evaluate(() => document.getElementById('valid_urns').outerHTML);
const fs = require('fs');
var ws = fs.createWriteStream(
	'valid_urns.html'
);
ws.write(valid_urns);
ws.end();
await browser.close();
})();
