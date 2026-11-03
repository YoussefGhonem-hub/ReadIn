import { encode } from 'blurhash';
import { blurHashAverageColor, isValidBlurHash } from './blurhash';

function solid(r: number, g: number, b: number, size = 4): Uint8ClampedArray {
  const pixels = new Uint8ClampedArray(size * size * 4);
  for (let i = 0; i < size * size; i++) pixels.set([r, g, b, 255], i * 4);
  return pixels;
}

describe('BlurHash average color (SSR placeholder)', () => {
  it('reads the DC component of a BlurHash as an sRGB color', () => {
    // https://blurha.sh reference hashes
    expect(blurHashAverageColor('LEHV6nWB2yk8pyo0adR*.7kCMdnj')).toBe('rgb(151, 150, 149)');
    expect(blurHashAverageColor('LKO2?U%2Tw=w]~RBVZRi};RPxuwH')).toBe('rgb(209, 178, 163)');
  });

  it('matches the color of a solid image encoded by the blurhash library', () => {
    expect(blurHashAverageColor(encode(solid(200, 100, 50), 4, 4, 4, 3))).toBe('rgb(200, 100, 50)');
    expect(blurHashAverageColor(encode(solid(15, 94, 82), 4, 4, 1, 1))).toBe('rgb(15, 94, 82)');
  });

  it('is pure math, so the server and the first client render agree', () => {
    const hash = 'LEHV6nWB2yk8pyo0adR*.7kCMdnj';
    expect(blurHashAverageColor(hash)).toBe(blurHashAverageColor(hash));
  });

  it('returns null for missing or malformed hashes', () => {
    expect(blurHashAverageColor(null)).toBeNull();
    expect(blurHashAverageColor('')).toBeNull();
    expect(blurHashAverageColor('LEHV6')).toBeNull();
    expect(blurHashAverageColor('LEHV6nWB2yk8pyo0adR*.7kCMdn')).toBeNull(); // one character short
    expect(blurHashAverageColor('LEHV6nWB2yk8pyo0adR*.7kCMdn"')).toBeNull(); // not base83
    expect(isValidBlurHash('LEHV6nWB2yk8pyo0adR*.7kCMdnj')).toBe(true);
  });
});
