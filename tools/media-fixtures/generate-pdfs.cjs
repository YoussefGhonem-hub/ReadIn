// Generates the PDF fixtures for backend/tests/fixtures/media (run once, output committed).
const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');

const [outDir, arabicFont] = process.argv.slice(2);
fs.mkdirSync(outDir, { recursive: true });

function write(name, options, pages, draw) {
  return new Promise((resolve) => {
    const doc = new PDFDocument({ size: 'A4', margin: 56, autoFirstPage: false, info: { Title: name, Producer: 'ReadIn fixtures' }, ...options });
    const out = fs.createWriteStream(path.join(outDir, name));
    doc.pipe(out);
    for (let i = 1; i <= pages; i++) {
      doc.addPage();
      draw(doc, i);
    }
    doc.end();
    out.on('finish', () => resolve(fs.statSync(path.join(outDir, name)).size));
  });
}

const colors = ['#0F5E52', '#F2A93B', '#3FB8A3', '#C0392B'];

function contentPage(doc, i, total) {
  doc.rect(0, 0, doc.page.width, 90).fill(colors[i % colors.length]);
  doc.fillColor('#FFFFFF').font('Helvetica-Bold').fontSize(28).text(`Page ${i} of ${total}`, 56, 30);
  doc.fillColor('#1A1A1A').font('Helvetica').fontSize(14)
    .text(`ReadIn fixture page ${i}. Unique marker: readinmarker${i}.`, 56, 130)
    .moveDown()
    .text('Dependency Injection keeps services loosely coupled. EF Core tracks entities. Clean Architecture keeps the domain pure.');
  if (arabicFont && i === 1) {
    doc.font(arabicFont).fontSize(18).text('مقال كل يوم يفرق معاك', { align: 'right', features: ['rlig', 'calt'] });
  }
  doc.circle(doc.page.width / 2, 520, 80 + (i % 4) * 10).fill(colors[(i + 1) % colors.length]);
}

(async () => {
  console.log('normal-12-pages.pdf', await write('normal-12-pages.pdf', {}, 12, (d, i) => contentPage(d, i, 12)));
  console.log('too-many-pages-101.pdf', await write('too-many-pages-101.pdf', { compress: true }, 101, (d, i) => d.font('Helvetica').fontSize(10).text(`p${i}`)));
  console.log('encrypted.pdf', await write('encrypted.pdf', { userPassword: 'readin', ownerPassword: 'owner', pdfVersion: '1.7' }, 2, (d, i) => contentPage(d, i, 2)));

  // Corrupted: a valid header and the start of a real file, then truncated garbage (no xref, no trailer).
  const normal = fs.readFileSync(path.join(outDir, 'normal-12-pages.pdf'));
  const corrupted = Buffer.concat([normal.subarray(0, 600), Buffer.from('\n%% truncated: this file was cut off during upload\n')]);
  fs.writeFileSync(path.join(outDir, 'corrupted.pdf'), corrupted);
  console.log('corrupted.pdf', corrupted.length);
})();
