/** The words on a streak milestone card, already translated. */
export interface MilestoneCardText {
  /** Under the number: "days in a row". */
  headline: string;
  /** The milestone's title: "A full week!". */
  title: string;
  tagline: string;
  dir: 'rtl' | 'ltr';
}

const SIZE = 1080;
const CENTER = SIZE / 2;
const TEXT_WIDTH = 860;

/**
 * Draws the shareable streak milestone card (F08) as a 1080×1080 PNG in the active theme: the colors are read from the
 * design tokens on `<html>`, so a dark UI shares a dark card (SPEC §15.5 rule 8). Resolves null when the browser
 * can't draw (no canvas).
 */
export async function renderMilestoneCard(document: Document, streak: number, text: MilestoneCardText): Promise<Blob | null> {
  const canvas = document.createElement('canvas');
  canvas.width = SIZE;
  canvas.height = SIZE;
  const ctx = context2d(canvas);
  if (!ctx) return null;
  await document.fonts?.ready.catch(() => undefined);

  const view = document.defaultView;
  const style = view ? view.getComputedStyle(document.documentElement) : null;
  const color = (token: string, fallback: string) => style?.getPropertyValue(`--rd-color-${token}`).trim() || fallback;
  const uiFont = style?.getPropertyValue('--rd-font-ui').trim() || 'sans-serif';
  const latinFont = style?.getPropertyValue('--rd-font-latin').trim() || 'sans-serif';

  // Background and card
  ctx.fillStyle = color('bg', 'Canvas');
  ctx.fillRect(0, 0, SIZE, SIZE);
  ctx.beginPath();
  if (typeof ctx.roundRect === 'function') ctx.roundRect(64, 64, SIZE - 128, SIZE - 128, 48);
  else ctx.rect(64, 64, SIZE - 128, SIZE - 128);
  ctx.fillStyle = color('surface', 'Canvas');
  ctx.fill();
  ctx.lineWidth = 4;
  ctx.strokeStyle = color('border', 'GrayText');
  ctx.stroke();

  // A soft accent disc behind the flame and the number
  ctx.beginPath();
  ctx.arc(CENTER, 500, 225, 0, Math.PI * 2);
  ctx.fillStyle = color('accent-container', 'Canvas');
  ctx.fill();

  // "ReadIn" wordmark: always English and LTR (SPEC §15.1)
  ctx.direction = 'ltr';
  ctx.textBaseline = 'alphabetic';
  ctx.textAlign = 'left';
  ctx.font = `700 64px ${latinFont}`;
  const readWidth = ctx.measureText('Read').width;
  const start = CENTER - (readWidth + ctx.measureText('In').width) / 2;
  ctx.fillStyle = color('text-primary', 'CanvasText');
  ctx.fillText('Read', start, 196);
  ctx.fillStyle = color('primary', 'LinkText');
  ctx.fillText('In', start + readWidth, 196);

  ctx.textAlign = 'center';
  ctx.font = `110px ${uiFont}`;
  ctx.fillText('🔥', CENTER, 400);
  ctx.font = `700 210px ${latinFont}`;
  ctx.fillStyle = color('text-primary', 'CanvasText');
  ctx.fillText(String(streak), CENTER, 615, TEXT_WIDTH);

  ctx.direction = text.dir;
  ctx.font = `600 58px ${uiFont}`;
  ctx.fillText(text.headline, CENTER, 800, TEXT_WIDTH);
  ctx.font = `600 42px ${uiFont}`;
  ctx.fillStyle = color('primary', 'LinkText');
  ctx.fillText(text.title, CENTER, 872, TEXT_WIDTH);
  ctx.font = `400 34px ${uiFont}`;
  ctx.fillStyle = color('text-secondary', 'GrayText');
  ctx.fillText(text.tagline, CENTER, 958, TEXT_WIDTH);

  return new Promise((resolve) => {
    try {
      canvas.toBlob((blob) => resolve(blob), 'image/png');
    } catch {
      resolve(null);
    }
  });
}

/** Null where canvas isn't available (jsdom throws "not implemented"). */
function context2d(canvas: HTMLCanvasElement): CanvasRenderingContext2D | null {
  try {
    return canvas.getContext('2d');
  } catch {
    return null;
  }
}
