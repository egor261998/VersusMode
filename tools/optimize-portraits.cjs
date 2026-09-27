// Offline only: bound immediate GUI work without retained engine objects.
const fs = require('fs');
const path = require('path');
const file = path.join(__dirname, '../scripts/mods/VersusMode/VersusMode_portrait_images.lua');
const LIMIT = 2048;
let totalBefore = 0, totalAfter = 0, count = 0;
const output = fs.readFileSync(file, 'utf8').replace(
  /width = (\d+), height = (\d+), packed = "((?:\\\d{3})+)"/g,
  (_, ws, hs, encoded) => {
    const width = +ws, height = +hs;
    const bytes = [...encoded.matchAll(/\\(\d{3})/g)].map(m => +m[1]);
    totalBefore += bytes.length / 7;
    count++;
    if (bytes.length / 7 <= LIMIT) {
      totalAfter += bytes.length / 7;
      return `width = ${width}, height = ${height}, packed = "${encoded}"`;
    }
    const pixels = new Uint8Array(width * height * 3);
    for (let i = 0; i < bytes.length; i += 7) {
      const [x, y, w, h, r, g, b] = bytes.slice(i, i + 7);
      for (let yy = y; yy < y + h; yy++) for (let xx = x; xx < x + w; xx++)
        pixels.set([r, g, b], (yy * width + xx) * 3);
    }
    // Integral sums give constant-time mean and colour error for each block.
    const stride = width + 1, area = stride * (height + 1);
    const sums = Array.from({length: 6}, () => new Float64Array(area));
    for (let y = 1; y <= height; y++) for (let x = 1; x <= width; x++) {
      const at = y * stride + x;
      for (let c = 0; c < 6; c++) {
        const v = pixels[((y - 1) * width + x - 1) * 3 + c % 3];
        const a = sums[c];
        a[at] = (c < 3 ? v : v * v) + a[at - 1] + a[at - stride] - a[at - stride - 1];
      }
    }
    function block(x, y, w, h) {
      const n = w * h, rgb = []; let error = 0;
      for (let c = 0; c < 3; c++) {
        const sum = a => a[(y+h)*stride+x+w] - a[y*stride+x+w] - a[(y+h)*stride+x] + a[y*stride+x];
        const s = sum(sums[c]);
        rgb.push(Math.round(s / n));
        error += Math.max(0, sum(sums[c+3]) - s * s / n);
      }
      return {x,y,w,h,rgb,error};
    }
    const leaves = [block(0, 0, width, height)];
    while (leaves.length < LIMIT) {
      let index = -1, best = 0;
      for (let i = 0; i < leaves.length; i++) {
        if (leaves[i].error > best && (leaves[i].w > 1 || leaves[i].h > 1)) {
          index = i; best = leaves[i].error;
        }
      }
      if (index < 0) break;
      const {x,y,w,h} = leaves[index];
      let horizontal, vertical;
      if (w > 1) { const k = Math.floor(w/2); horizontal = [block(x,y,k,h),block(x+k,y,w-k,h)]; }
      if (h > 1) { const k = Math.floor(h/2); vertical = [block(x,y,w,k),block(x,y+k,w,h-k)]; }
      const error = pair => pair[0].error + pair[1].error;
      const split = !horizontal ? vertical : !vertical ? horizontal : error(horizontal) <= error(vertical) ? horizontal : vertical;
      leaves[index] = split[0]; leaves.push(split[1]);
    }
    totalAfter += leaves.length;
    const packed = leaves.map(p => [p.x,p.y,p.w,p.h,...p.rgb].map(v => '\\' + String(v).padStart(3,'0')).join('')).join('');
    return `width = ${width}, height = ${height}, packed = "${packed}"`;
  });
if (count !== 30) throw Error(`Unexpected portrait count: ${count}`);
fs.writeFileSync(file, output);
console.log(`${count} portraits: ${totalBefore} -> ${totalAfter} rectangles; maximum ${LIMIT} per portrait`);
