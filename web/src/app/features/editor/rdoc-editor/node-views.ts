import { Editor, NodeViewRendererProps } from '@tiptap/core';
import { Node as PmNodeType } from '@tiptap/pm/model';
import { NodeView, ViewMutationRecord } from '@tiptap/pm/view';
import type { IconNode } from 'lucide';
// One file per icon, not the `lucide` barrel (see editor-icons.ts).
import Camera from 'lucide/dist/esm/icons/camera.mjs';
import Info from 'lucide/dist/esm/icons/info.mjs';
import Lightbulb from 'lucide/dist/esm/icons/lightbulb.mjs';
import OctagonX from 'lucide/dist/esm/icons/octagon-x.mjs';
import Plus from 'lucide/dist/esm/icons/plus.mjs';
import Trash2 from 'lucide/dist/esm/icons/trash.mjs';
import TriangleAlert from 'lucide/dist/esm/icons/triangle-alert.mjs';
import X from 'lucide/dist/esm/icons/x.mjs';
import { CalloutVariant, CodeTab } from '../../../shared/rdoc/rdoc.models';
import { youtubeId } from '../../../shared/rdoc/rdoc.utils';
import { RDocEditorHost } from './editor-host';
import { CODE_LANGUAGES, PLAIN_CODE_LANG, codeLanguageName } from './rdoc-convert';

/** shared/rdoc/rdoc.schema.json limits. */
export const IMAGE_ALT_MAX = 300;
export const PLAIN_TEXT_MAX = 500;
export const FILENAME_MAX = 200;
export const TAB_LABEL_MAX = 40;
export const MAX_CODE_TABS = 8;

const CALLOUT_ICONS: Record<CalloutVariant, IconNode> = { tip: Lightbulb, info: Info, warning: TriangleAlert, danger: OctagonX };
export const CALLOUT_VARIANTS: readonly CalloutVariant[] = ['tip', 'info', 'warning', 'danger'];

type Attrs = Record<string, unknown>;

/** `document.createElement` with attributes, classes and children. */
function el<K extends keyof HTMLElementTagNameMap>(
  tag: K,
  props: { class?: string; attrs?: Record<string, string>; text?: string } = {},
  children: (Node | null)[] = [],
): HTMLElementTagNameMap[K] {
  const element = document.createElement(tag);
  if (props.class) element.className = props.class;
  for (const [name, value] of Object.entries(props.attrs ?? {})) element.setAttribute(name, value);
  if (props.text !== undefined) element.textContent = props.text;
  for (const child of children) if (child) element.appendChild(child);
  return element;
}

const SVG_NS = 'http://www.w3.org/2000/svg';

/** A Lucide icon as an SVG element (line icon, 24-unit grid, current color). */
function icon(node: IconNode, size = 16): SVGElement {
  const svg = document.createElementNS(SVG_NS, 'svg');
  const attrs: Record<string, string> = {
    width: String(size),
    height: String(size),
    viewBox: '0 0 24 24',
    fill: 'none',
    stroke: 'currentColor',
    'stroke-width': '2',
    'stroke-linecap': 'round',
    'stroke-linejoin': 'round',
    'aria-hidden': 'true',
  };
  for (const [name, value] of Object.entries(attrs)) svg.setAttribute(name, value);
  for (const [tag, childAttrs] of node) {
    const child = document.createElementNS(SVG_NS, tag);
    for (const [name, value] of Object.entries(childAttrs)) child.setAttribute(name, String(value));
    svg.appendChild(child);
  }
  return svg;
}

let controlId = 0;
function nextId(prefix: string): string {
  return `${prefix}-${++controlId}`;
}

/**
 * Base for the block node views: plain DOM with form controls outside `contentDOM` (titles, captions, languages).
 * Control events stay out of ProseMirror; edits are written back as node attributes in one transaction.
 */
abstract class BlockView implements NodeView {
  dom!: HTMLElement;
  contentDOM?: HTMLElement;
  protected node: PmNodeType;
  protected readonly editor: Editor;
  protected readonly getPos: () => number | undefined;

  constructor(
    props: NodeViewRendererProps,
    protected readonly host: RDocEditorHost,
  ) {
    this.node = props.node;
    this.editor = props.editor;
    this.getPos = props.getPos as () => number | undefined;
  }

  protected get attrs(): Attrs {
    return this.node.attrs as Attrs;
  }

  /** Writes attribute changes to the document (undoable, triggers autosave). */
  protected setAttrs(patch: Attrs): void {
    const pos = this.getPos();
    if (typeof pos !== 'number' || !this.editor.isEditable) return;
    const { state, view } = this.editor;
    view.dispatch(state.tr.setNodeMarkup(pos, undefined, { ...this.node.attrs, ...patch }));
  }

  update(node: PmNodeType): boolean {
    if (node.type !== this.node.type) return false;
    this.node = node;
    if (this.dom.dataset['blockId'] !== (node.attrs['id'] ?? '')) this.dom.dataset['blockId'] = String(node.attrs['id'] ?? '');
    this.render();
    return true;
  }

  /** Refreshes the controls from `this.node` (never overwrites the control that has focus). */
  protected abstract render(): void;

  stopEvent(event: Event): boolean {
    const target = event.target;
    return target instanceof Element && !!target.closest('[data-nv-control]');
  }

  ignoreMutation(mutation: ViewMutationRecord): boolean {
    if (!this.contentDOM) return true;
    if (mutation.type === 'selection') return false;
    return !this.contentDOM.contains(mutation.target);
  }

  protected input(attrs: { label: string; value: string; max: number; placeholder?: string; dir?: string; multiline?: boolean }, onInput: (value: string) => void) {
    const field = attrs.multiline ? el('textarea', { attrs: { rows: '2' } }) : el('input', { attrs: { type: 'text' } });
    field.className = 'rd-input rd-ed-input';
    field.setAttribute('data-nv-control', '');
    field.setAttribute('aria-label', attrs.label);
    field.setAttribute('maxlength', String(attrs.max));
    field.setAttribute('dir', attrs.dir ?? 'auto');
    if (attrs.placeholder) field.setAttribute('placeholder', attrs.placeholder);
    field.value = attrs.value;
    field.addEventListener('input', () => onInput(field.value));
    return field;
  }

  protected syncValue(field: HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement, value: string): void {
    if (field.value !== value && document.activeElement !== field) field.value = value;
  }

  protected select(label: string, options: { value: string; label: string }[], value: string, onChange: (value: string) => void): HTMLSelectElement {
    const select = el('select', { class: 'rd-ed-select', attrs: { 'data-nv-control': '', 'aria-label': label } });
    for (const option of options) select.appendChild(el('option', { attrs: { value: option.value }, text: option.label }));
    select.value = value;
    select.addEventListener('change', () => onChange(select.value));
    return select;
  }

  protected button(label: string, content: (Node | string)[], onClick: () => void, extraClass = ''): HTMLButtonElement {
    const button = el('button', { class: `rd-ed-btn ${extraClass}`.trim(), attrs: { type: 'button', 'data-nv-control': '', 'aria-label': label, title: label } });
    for (const part of content) button.append(part);
    button.addEventListener('click', (event) => {
      event.preventDefault();
      onClick();
    });
    return button;
  }

  protected deleteSelf(): void {
    const pos = this.getPos();
    if (typeof pos !== 'number') return;
    const { state, view } = this.editor;
    view.dispatch(state.tr.delete(pos, pos + this.node.nodeSize));
    view.focus();
  }
}

// ── Callout ─────────────────────────────────────────────────

export class CalloutView extends BlockView {
  private readonly box: HTMLElement;
  private readonly iconSlot: HTMLElement;
  private readonly variant: HTMLSelectElement;
  private readonly title: HTMLInputElement;

  constructor(props: NodeViewRendererProps, host: RDocEditorHost) {
    super(props, host);
    const t = host.t.bind(host);
    this.iconSlot = el('span', { class: 'rd-callout-icon mt-1 shrink-0', attrs: { contenteditable: 'false' } });
    this.variant = this.select(
      t('editor.blocks.calloutVariant'),
      CALLOUT_VARIANTS.map((v) => ({ value: v, label: t(`rdoc.callout.${v}`) })),
      String(this.attrs['variant'] ?? 'tip'),
      (variant) => this.setAttrs({ variant }),
    );
    this.title = this.input(
      { label: t('editor.blocks.calloutTitle'), value: String(this.attrs['title'] ?? ''), max: PLAIN_TEXT_MAX, placeholder: t('editor.blocks.calloutTitlePlaceholder') },
      (title) => this.setAttrs({ title: title || null }),
    ) as HTMLInputElement;
    this.contentDOM = el('div', { class: 'rd-ed-content' });
    const head = el('div', { class: 'rd-ed-row', attrs: { contenteditable: 'false' } }, [this.variant, this.title]);
    this.box = el('aside', { attrs: { 'data-block-type': 'callout', role: 'note' } }, [this.iconSlot, el('div', { class: 'min-w-0 flex-1' }, [head, this.contentDOM])]);
    this.dom = this.box;
    this.dom.dataset['blockId'] = String(this.attrs['id'] ?? '');
    this.render();
  }

  protected render(): void {
    const variant = (CALLOUT_VARIANTS.includes(this.attrs['variant'] as CalloutVariant) ? this.attrs['variant'] : 'tip') as CalloutVariant;
    this.box.className = `rd-callout rd-callout-${variant} rd-ed-block`;
    this.box.dataset['variant'] = variant;
    this.iconSlot.replaceChildren(icon(CALLOUT_ICONS[variant], 20));
    this.syncValue(this.variant, variant);
    this.syncValue(this.title, String(this.attrs['title'] ?? ''));
  }
}

// ── Quote ───────────────────────────────────────────────────

export class QuoteView extends BlockView {
  private readonly cite: HTMLInputElement;

  constructor(props: NodeViewRendererProps, host: RDocEditorHost) {
    super(props, host);
    const t = host.t.bind(host);
    this.contentDOM = el('p', { class: 'rd-ed-content' });
    this.cite = this.input(
      { label: t('editor.blocks.quoteCite'), value: String(this.attrs['cite'] ?? ''), max: PLAIN_TEXT_MAX, placeholder: t('editor.blocks.quoteCitePlaceholder') },
      (cite) => this.setAttrs({ cite: cite || null }),
    ) as HTMLInputElement;
    this.dom = el('blockquote', { class: 'rd-ed-block', attrs: { 'data-block-type': 'quote' } }, [
      this.contentDOM,
      el('cite', { class: 'rd-ed-row', attrs: { contenteditable: 'false' } }, [el('span', { text: '—', attrs: { 'aria-hidden': 'true' } }), this.cite]),
    ]);
    this.dom.dataset['blockId'] = String(this.attrs['id'] ?? '');
  }

  protected render(): void {
    this.syncValue(this.cite, String(this.attrs['cite'] ?? ''));
  }
}

// ── Summary (TL;DR) ─────────────────────────────────────────

export class SummaryView extends BlockView {
  constructor(props: NodeViewRendererProps, host: RDocEditorHost) {
    super(props, host);
    this.contentDOM = el('div', { class: 'rd-ed-content' });
    this.dom = el('aside', { class: 'rd-summary rd-ed-block', attrs: { 'data-block-type': 'summary', role: 'note' } }, [
      el('span', { class: 'rd-summary-label', attrs: { contenteditable: 'false' }, text: host.t('rdoc.summary') }),
      this.contentDOM,
    ]);
    this.dom.dataset['blockId'] = String(this.attrs['id'] ?? '');
  }

  protected render(): void {
    // Nothing besides the content.
  }
}

// ── Code ────────────────────────────────────────────────────

function languageOptions(current: string): { value: string; label: string }[] {
  const options = CODE_LANGUAGES.map((l) => ({ value: l.id, label: l.label }));
  return options.some((o) => o.value === current) ? options : [...options, { value: current, label: current }];
}

export class CodeBlockView extends BlockView {
  private readonly lang: HTMLSelectElement;
  private readonly filename: HTMLInputElement;

  constructor(props: NodeViewRendererProps, host: RDocEditorHost) {
    super(props, host);
    const t = host.t.bind(host);
    const current = String(this.attrs['language'] || PLAIN_CODE_LANG);
    this.lang = this.select(t('editor.blocks.codeLanguage'), languageOptions(current), current, (language) => this.setAttrs({ language }));
    this.filename = this.input(
      { label: t('editor.blocks.codeFilename'), value: String(this.attrs['filename'] ?? ''), max: FILENAME_MAX, placeholder: t('editor.blocks.codeFilenamePlaceholder'), dir: 'ltr' },
      (filename) => this.setAttrs({ filename: filename || null }),
    ) as HTMLInputElement;
    this.contentDOM = el('code', { attrs: { spellcheck: 'false' } });
    this.dom = el('div', { class: 'rd-code rd-ed-block rd-ed-code', attrs: { 'data-block-type': 'code', dir: 'ltr' } }, [
      el('div', { class: 'rd-code-head rd-ed-row', attrs: { contenteditable: 'false' } }, [this.lang, this.filename]),
      el('pre', {}, [this.contentDOM]),
    ]);
    this.dom.dataset['blockId'] = String(this.attrs['id'] ?? '');
  }

  protected render(): void {
    const current = String(this.attrs['language'] || PLAIN_CODE_LANG);
    if (![...this.lang.options].some((o) => o.value === current)) this.lang.appendChild(el('option', { attrs: { value: current }, text: current }));
    this.syncValue(this.lang, current);
    this.syncValue(this.filename, String(this.attrs['filename'] ?? ''));
  }
}

// ── Code tabs (atom: every tab lives in the `tabs` attribute) ──

export class CodeTabsView extends BlockView {
  private active = 0;
  private readonly tablist: HTMLElement;
  private readonly label: HTMLInputElement;
  private readonly lang: HTMLSelectElement;
  private readonly filename: HTMLInputElement;
  private readonly code: HTMLTextAreaElement;
  private readonly remove: HTMLButtonElement;

  constructor(props: NodeViewRendererProps, host: RDocEditorHost) {
    super(props, host);
    const t = host.t.bind(host);
    this.tablist = el('div', { attrs: { role: 'tablist', 'aria-label': t('editor.blocks.codeTabs') } });
    this.label = this.input({ label: t('editor.blocks.tabLabel'), value: '', max: TAB_LABEL_MAX, placeholder: t('editor.blocks.tabLabel'), dir: 'ltr' }, (label) =>
      this.patchTab({ label }),
    ) as HTMLInputElement;
    this.lang = this.select(t('editor.blocks.codeLanguage'), languageOptions(PLAIN_CODE_LANG), PLAIN_CODE_LANG, (lang) => {
      const tab = this.tabs()[this.active];
      // A label that still names the old language follows the new one.
      const relabel = !tab?.label || tab.label === codeLanguageName(tab.lang);
      this.patchTab(relabel ? { lang, label: codeLanguageName(lang) } : { lang });
    });
    this.filename = this.input(
      { label: t('editor.blocks.codeFilename'), value: '', max: FILENAME_MAX, placeholder: t('editor.blocks.codeFilenamePlaceholder'), dir: 'ltr' },
      (filename) => this.patchTab({ filename: filename || undefined }),
    ) as HTMLInputElement;
    this.code = el('textarea', { class: 'rd-ed-code-area', attrs: { 'data-nv-control': '', spellcheck: 'false', dir: 'ltr', 'aria-label': t('editor.blocks.code') } });
    this.code.addEventListener('input', () => {
      this.fitCode();
      this.patchTab({ code: this.code.value });
    });
    this.code.addEventListener('keydown', (event) => {
      if (event.key === 'Tab' && !event.shiftKey) {
        event.preventDefault();
        const { selectionStart, selectionEnd, value } = this.code;
        this.code.value = value.slice(0, selectionStart) + '  ' + value.slice(selectionEnd);
        this.code.selectionStart = this.code.selectionEnd = selectionStart + 2;
        this.code.dispatchEvent(new Event('input'));
      }
    });
    this.remove = this.button(t('editor.blocks.removeTab'), [icon(Trash2)], () => this.removeTab());
    this.dom = el('div', { class: 'rd-code rd-code-tabs rd-ed-block rd-ed-codetabs', attrs: { 'data-block-type': 'codeTabs', dir: 'ltr', contenteditable: 'false' } }, [
      this.tablist,
      el('div', { class: 'rd-code-head rd-ed-row' }, [this.label, this.lang, this.filename, this.remove]),
      this.code,
    ]);
    this.dom.dataset['blockId'] = String(this.attrs['id'] ?? '');
    this.render();
  }

  private tabs(): CodeTab[] {
    const tabs = this.attrs['tabs'];
    return Array.isArray(tabs) ? (tabs as CodeTab[]) : [];
  }

  private patchTab(patch: Partial<CodeTab>): void {
    const tabs = this.tabs().map((tab, i) => {
      if (i !== this.active) return tab;
      const next = { ...tab, ...patch };
      if (next.filename === undefined) delete next.filename;
      return next;
    });
    this.setAttrs({ tabs });
  }

  private addTab(): void {
    const tabs = this.tabs();
    if (tabs.length >= MAX_CODE_TABS) return;
    this.active = tabs.length;
    this.setAttrs({ tabs: [...tabs, { label: codeLanguageName(PLAIN_CODE_LANG), lang: PLAIN_CODE_LANG, code: '' }] });
    queueMicrotask(() => this.label.focus());
  }

  private removeTab(): void {
    const tabs = this.tabs();
    if (tabs.length <= 1) {
      this.deleteSelf();
      return;
    }
    const next = tabs.filter((_, i) => i !== this.active);
    this.active = Math.min(this.active, next.length - 1);
    this.setAttrs({ tabs: next });
  }

  private fitCode(): void {
    this.code.rows = Math.min(30, Math.max(3, this.code.value.split('\n').length));
  }

  protected render(): void {
    const tabs = this.tabs();
    this.active = Math.max(0, Math.min(this.active, tabs.length - 1));
    const buttons = tabs.map((tab, i) => {
      const button = el('button', {
        attrs: { type: 'button', role: 'tab', 'aria-selected': String(i === this.active), 'data-nv-control': '', 'data-tab': String(i) },
        text: tab.label || codeLanguageName(tab.lang),
      });
      button.addEventListener('click', () => {
        this.active = i;
        this.render();
      });
      return button;
    });
    const add = this.button(this.host.t('editor.blocks.addTab'), [icon(Plus, 14)], () => this.addTab(), 'rd-ed-tab-add');
    add.disabled = tabs.length >= MAX_CODE_TABS;
    this.tablist.replaceChildren(...buttons, add);
    const tab = tabs[this.active];
    this.syncValue(this.label, tab?.label ?? '');
    const lang = tab?.lang || PLAIN_CODE_LANG;
    if (![...this.lang.options].some((o) => o.value === lang)) this.lang.appendChild(el('option', { attrs: { value: lang }, text: lang }));
    this.syncValue(this.lang, lang);
    this.syncValue(this.filename, tab?.filename ?? '');
    this.syncValue(this.code, tab?.code ?? '');
    this.fitCode();
  }
}

// ── Image ───────────────────────────────────────────────────

/** Set by the slash menu right before it inserts an empty image block: the new block opens the file picker. */
let pickOnCreate = false;
export function openPickerForNextImage(): void {
  pickOnCreate = true;
}

const IMAGE_ACCEPT = 'image/jpeg,image/png,image/webp,image/heic,image/heif,.heic,.heif';

export class ImageView extends BlockView {
  private readonly media: HTMLElement;
  private readonly alt: HTMLTextAreaElement;
  private readonly altError: HTMLElement;
  private readonly caption: HTMLInputElement;
  private readonly darkRow: HTMLElement;
  private readonly picker: HTMLInputElement;
  private uploading: { target: 'src' | 'darkSrc'; progress: number; controller: AbortController } | null = null;
  private error: string | null = null;

  constructor(props: NodeViewRendererProps, host: RDocEditorHost) {
    super(props, host);
    const t = host.t.bind(host);
    const altId = nextId('rd-ed-alt');
    this.media = el('div', { class: 'rd-ed-media' });
    this.picker = el('input', { class: 'hidden', attrs: { type: 'file', accept: IMAGE_ACCEPT, tabindex: '-1', 'aria-hidden': 'true', 'data-nv-control': '', 'data-image-block-input': '' } });
    this.picker.addEventListener('change', () => {
      const file = this.picker.files?.[0];
      const target = (this.picker.dataset['target'] as 'src' | 'darkSrc' | undefined) ?? 'src';
      this.picker.value = '';
      if (file) void this.upload(file, target);
    });
    this.alt = this.input({ label: t('editor.blocks.imageAlt'), value: String(this.attrs['alt'] ?? ''), max: IMAGE_ALT_MAX, placeholder: t('attachments.altPlaceholder'), multiline: true }, (alt) => {
      this.setAttrs({ alt });
    }) as HTMLTextAreaElement;
    this.alt.id = altId;
    this.alt.setAttribute('data-image-alt', '');
    this.altError = el('p', { class: 'rd-ed-error', attrs: { id: `${altId}-error` }, text: t('attachments.altRequired') });
    this.caption = this.input({ label: t('editor.blocks.imageCaption'), value: String(this.attrs['caption'] ?? ''), max: PLAIN_TEXT_MAX, placeholder: t('editor.blocks.imageCaption') }, (caption) =>
      this.setAttrs({ caption: caption || null }),
    ) as HTMLInputElement;
    this.caption.setAttribute('data-image-caption', '');
    this.darkRow = el('div', { class: 'rd-ed-row rd-ed-dark' });
    const altLabel = el('label', { class: 'rd-ed-label', attrs: { for: altId }, text: `${t('editor.blocks.imageAlt')} *` });
    this.dom = el('figure', { class: 'rd-figure rd-ed-block rd-ed-image', attrs: { 'data-block-type': 'image', contenteditable: 'false' } }, [
      this.media,
      this.picker,
      el('div', { class: 'rd-ed-fields' }, [altLabel, this.alt, this.altError, this.caption, this.darkRow]),
    ]);
    this.dom.dataset['blockId'] = String(this.attrs['id'] ?? '');
    this.dom.addEventListener('dragover', (event) => {
      if (event.dataTransfer?.types.includes('Files')) event.preventDefault();
    });
    this.dom.addEventListener('drop', (event) => {
      const file = event.dataTransfer?.files?.[0];
      if (!file) return;
      event.preventDefault();
      event.stopPropagation();
      void this.upload(file, 'src');
    });
    this.render();
    if (pickOnCreate) {
      pickOnCreate = false;
      this.pick('src');
    }
  }

  override stopEvent(event: Event): boolean {
    if (event.type === 'drop' || event.type === 'dragover') return true;
    return super.stopEvent(event);
  }

  /** Opens the file picker for the picture or its dark-mode version. */
  pick(target: 'src' | 'darkSrc'): void {
    this.picker.dataset['target'] = target;
    this.picker.click();
  }

  private async upload(file: File, target: 'src' | 'darkSrc'): Promise<void> {
    this.uploading?.controller.abort();
    const controller = new AbortController();
    this.uploading = { target, progress: 0, controller };
    this.error = null;
    this.render();
    this.host.uploadsChanged(1);
    try {
      const image = await this.host.uploadImage(
        file,
        (progress) => {
          if (this.uploading?.controller === controller) {
            this.uploading.progress = progress;
            this.renderMedia();
          }
        },
        controller.signal,
      );
      if (this.uploading?.controller !== controller) return;
      this.uploading = null;
      this.setAttrs(target === 'src' ? { src: image.src, width: image.width, height: image.height } : { darkSrc: image.src });
    } catch (error) {
      if (this.uploading?.controller !== controller) return;
      this.uploading = null;
      this.error = controller.signal.aborted ? null : typeof error === 'string' ? error : 'unknown';
      this.render();
    } finally {
      this.host.uploadsChanged(-1);
    }
  }

  private cancel(): void {
    const uploading = this.uploading;
    if (!uploading) return;
    this.uploading = null;
    uploading.controller.abort();
    this.render();
  }

  destroy(): void {
    this.uploading?.controller.abort();
  }

  protected render(): void {
    this.renderMedia();
    const alt = String(this.attrs['alt'] ?? '');
    this.syncValue(this.alt, alt);
    const missing = !!this.attrs['src'] && !alt.trim();
    this.alt.setAttribute('aria-invalid', String(missing));
    if (missing) this.alt.setAttribute('aria-describedby', this.altError.id);
    else this.alt.removeAttribute('aria-describedby');
    this.altError.hidden = !missing;
    this.syncValue(this.caption, String(this.attrs['caption'] ?? ''));
    this.renderDark();
  }

  private renderMedia(): void {
    const t = this.host.t.bind(this.host);
    const src = this.attrs['src'] ? this.host.resolveAsset(String(this.attrs['src'])) : null;
    const parts: Node[] = [];
    if (src) {
      const img = el('img', { attrs: { src, alt: '', draggable: 'false' } });
      const width = this.attrs['width'];
      const height = this.attrs['height'];
      if (typeof width === 'number' && typeof height === 'number') img.style.aspectRatio = `${width} / ${height}`;
      parts.push(img);
      parts.push(
        el('div', { class: 'rd-ed-overlay' }, [
          this.button(t('editor.blocks.imageReplace'), [icon(Camera), t('editor.blocks.imageReplace')], () => this.pick('src')),
          this.button(t('editor.blocks.remove'), [icon(Trash2)], () => this.deleteSelf()),
        ]),
      );
    } else if (!this.uploading || this.uploading.target !== 'src') {
      const choose = this.button(t('editor.blocks.imageChoose'), [icon(Camera, 24), el('span', { text: t('editor.blocks.imageChoose') })], () => this.pick('src'), 'rd-ed-drop');
      choose.setAttribute('data-image-choose', '');
      parts.push(choose);
    }
    if (this.uploading) {
      const percent = Math.round(this.uploading.progress * 100);
      const bar = el('span', { class: 'rd-ed-progress', attrs: { role: 'progressbar', 'aria-valuemin': '0', 'aria-valuemax': '100', 'aria-valuenow': String(percent) } }, [
        el('span', {}),
      ]);
      (bar.firstChild as HTMLElement).style.width = `${percent}%`;
      parts.push(
        el('div', { class: 'rd-ed-status', attrs: { 'data-image-uploading': '' } }, [
          el('span', { text: t('attachments.uploading', { percent }) }),
          bar,
          this.button(t('attachments.cancel'), [t('attachments.cancel')], () => this.cancel(), 'rd-ed-link'),
        ]),
      );
    }
    if (this.error) {
      parts.push(el('p', { class: 'rd-ed-error', attrs: { role: 'alert' }, text: `${t('attachments.failed')}: ${this.host.t(`errors.${this.error}`)}` }));
    }
    this.media.replaceChildren(...parts);
  }

  private renderDark(): void {
    const t = this.host.t.bind(this.host);
    const darkSrc = this.attrs['darkSrc'] ? this.host.resolveAsset(String(this.attrs['darkSrc'])) : null;
    const parts: Node[] = [];
    if (darkSrc) {
      parts.push(el('img', { class: 'rd-ed-thumb', attrs: { src: darkSrc, alt: '' } }));
      parts.push(el('span', { class: 'flex-1', text: t('editor.blocks.imageDark') }));
      parts.push(this.button(t('editor.blocks.imageDarkRemove'), [icon(X)], () => this.setAttrs({ darkSrc: null })));
    } else if (this.attrs['src']) {
      const add = this.button(t('editor.blocks.imageDarkAdd'), [t('editor.blocks.imageDarkAdd')], () => this.pick('darkSrc'), 'rd-ed-link');
      parts.push(add);
    }
    this.darkRow.replaceChildren(...parts);
  }
}

// ── Embed ───────────────────────────────────────────────────

export function isAllowedEmbed(provider: unknown, url: string): boolean {
  const value = url.trim();
  if (!/^https?:\/\/[^\s<>"']+$/i.test(value)) return false;
  if (provider === 'github-gist') return /^https:\/\/gist\.github\.com\/[\w.-]+\/[0-9a-f]+/i.test(value);
  return !!youtubeId(value);
}

export class EmbedView extends BlockView {
  private readonly provider: HTMLSelectElement;
  private readonly url: HTMLInputElement;
  private readonly hint: HTMLElement;

  constructor(props: NodeViewRendererProps, host: RDocEditorHost) {
    super(props, host);
    const t = host.t.bind(host);
    this.provider = this.select(
      t('editor.blocks.embedProvider'),
      [
        { value: 'youtube', label: 'YouTube' },
        { value: 'github-gist', label: 'GitHub Gist' },
      ],
      String(this.attrs['provider'] ?? 'youtube'),
      (provider) => this.setAttrs({ provider }),
    );
    this.url = this.input({ label: t('editor.blocks.embedUrl'), value: String(this.attrs['url'] ?? ''), max: 2048, placeholder: 'https://', dir: 'ltr' }, (url) => this.setAttrs({ url })) as HTMLInputElement;
    this.url.type = 'url';
    this.url.setAttribute('data-embed-url', '');
    this.hint = el('p', { class: 'rd-ed-hint' });
    this.dom = el('div', { class: 'rd-ed-block rd-ed-embed', attrs: { 'data-block-type': 'embed', contenteditable: 'false' } }, [
      el('div', { class: 'rd-ed-row' }, [this.provider, this.url, this.button(t('editor.blocks.remove'), [icon(Trash2)], () => this.deleteSelf())]),
      this.hint,
    ]);
    this.dom.dataset['blockId'] = String(this.attrs['id'] ?? '');
    this.render();
  }

  protected render(): void {
    const provider = this.attrs['provider'] === 'github-gist' ? 'github-gist' : 'youtube';
    const url = String(this.attrs['url'] ?? '');
    this.syncValue(this.provider, provider);
    this.syncValue(this.url, url);
    const invalid = !!url.trim() && !isAllowedEmbed(provider, url);
    this.url.setAttribute('aria-invalid', String(invalid));
    this.hint.className = invalid ? 'rd-ed-error' : 'rd-ed-hint';
    this.hint.textContent = this.host.t(invalid ? 'editor.blocks.embedInvalid' : provider === 'youtube' ? 'editor.blocks.embedYoutubeHint' : 'editor.blocks.embedGistHint');
  }
}
