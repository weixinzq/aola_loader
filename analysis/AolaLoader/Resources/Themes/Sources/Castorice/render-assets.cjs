// Render the approved native SVG/CSS interface. Character PNG pixels remain unchanged.
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const [specFile, output] = process.argv.slice(2);
(async () => {
  fs.mkdirSync(output, { recursive: true });
  const browser = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true });
  const page = await browser.newPage({ deviceScaleFactor: 2 });
  for (const item of JSON.parse(fs.readFileSync(specFile, 'utf8'))) {
    await page.setViewportSize({ width: Math.ceil(item.width), height: Math.ceil(item.height) });
    await page.setContent(`<style>html,body{margin:0;background:transparent}svg{display:block}</style>${item.svg}`);
    await page.evaluate(() => document.fonts.ready);
    await page.screenshot({ path: path.join(output, item.name + '.png'), omitBackground: true });
  }
  await browser.close();
})().catch(error => { console.error(error); process.exit(1); });
