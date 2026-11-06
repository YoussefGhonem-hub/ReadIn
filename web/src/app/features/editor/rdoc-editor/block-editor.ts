import {
  ChangeDetectionStrategy,
  Component,
  DestroyRef,
  ElementRef,
  ViewEncapsulation,
  afterNextRender,
  computed,
  effect,
  inject,
  input,
  output,
  signal,
  untracked,
  WritableSignal,
  viewChild,
} from '@angular/core';
import { TranslocoPipe, TranslocoService } from '@jsverse/transloco';
import { LucideDynamicIcon } from '@lucide/angular';
import { Editor, Extension, Range } from '@tiptap/core';
import { NodeSelection, PluginKey, TextSelection } from '@tiptap/pm/state';
import { Suggestion, SuggestionKeyDownProps, SuggestionOptions, SuggestionProps } from '@tiptap/suggestion';
import { firstValueFrom } from 'rxjs';
import { environment } from '../../../../environments/environment';
import { CommentsApi } from '../../../core/api/comments.api';
import { GlossaryApi } from '../../../core/api/glossary.api';
import { ArticleLanguage, GlossaryTermSummaryDto, MentionCandidateDto } from '../../../core/api/models';
import { LanguageService } from '../../../core/i18n/language.service';
import { BdiText } from '../../../shared/directives/bdi-text';
import { BlockDir, RDoc } from '../../../shared/rdoc/rdoc.models';
import { languageDir, safeHttpUrl } from '../../../shared/rdoc/rdoc.utils';
import { Avatar } from '../../../shared/ui/avatar';
import { ImageUploader, largestVariant } from '../image-upload';
import {
  BLOCK_MENU,
  BlockKind,
  BlockMenuItem,
  TABLE_MAX_COLS,
  TABLE_MAX_ROWS,
  TableSize,
  TermTarget,
  currentBlockDir,
  currentTextKind,
  filterBlockMenu,
  insertBlock,
  insertTable,
  markTerm,
  setBlockDir,
  tableShape,
  termTarget,
  unmarkTerm,
} from './block-commands';
import { BlockStage } from './block-stage';
import { RDocEditorHost } from './editor-host';
import { ensureBlockIds } from './editor-plugins';
import { PopupAnchor } from './popup-place';
import { PmNode, editorToRDoc, rdocToEditor } from './rdoc-convert';
import { rdocExtensions } from './rdoc-schema';
import { TableSizePicker } from './table-size-picker';

/** The editor tells the page about changes this long after the last keystroke. */
export const CHANGE_DEBOUNCE_MS = 300;
/** Mention suggestions are asked for this long after the last keystroke. */
const MENTION_DEBOUNCE_MS = 250;
/** The glossary is searched this long after the last keystroke in the term picker. */
const TERM_DEBOUNCE_MS = 250;

/** An edited version: `language` is the one the editor content was loaded for. */
export interface ContentChange {
  language: ArticleLanguage;
  content: RDoc;
}

interface Popup<T> {
  items: T[];
  index: number;
  left: number;
  top: number;
  command: (item: T) => void;
}

const TEXT_KINDS: readonly BlockKind[] = ['paragraph', 'heading2', 'heading3', 'quote', 'callout', 'summary'];
const MARKS = [
  { mark: 'bold', icon: 'Bold', key: 'bold' },
  { mark: 'italic', icon: 'Italic', key: 'italic' },
  { mark: 'strike', icon: 'Strikethrough', key: 'strike' },
  { mark: 'highlight', icon: 'Highlighter', key: 'highlight' },
  { mark: 'code', icon: 'Code', key: 'code' },
] as const;

let nextEditorId = 0;

/**
 * The block editor (F05): Tiptap over the RDoc schema, with a toolbar (block type, marks, link, glossary term (F21),
 * direction, insert, table rows/columns, undo), a slash menu (`/`), `@` mentions and markdown shortcuts. A new table's
 * size comes from a picker; every block has a handle to drag, move or delete it (block-stage.ts). It loads `content`
 * (again when `contentKey` changes) and reports the edited RDoc through `changed` (debounced; `flush()` reports at once).
 */
@Component({
  selector: 'rd-block-editor',
  imports: [TranslocoPipe, LucideDynamicIcon, Avatar, BdiText, BlockStage, TableSizePicker],
  changeDetection: ChangeDetectionStrategy.OnPush,
  encapsulation: ViewEncapsulation.None,
  host: { class: 'block' },
  // The RDoc styles (not global: shared/rdoc/rdoc-renderer.ts loads them too), then the editor's own after them.
  styleUrls: ['../../../../styles/rdoc.css', '../../../../styles/rdoc-blocks.css', './block-editor.css'],
  template: `
    <div class="rd-ed-toolbar" role="toolbar" [attr.aria-label]="'editor.toolbar.label' | transloco" [attr.aria-controls]="editorId" data-toolbar>
      <select
        class="rd-ed-select rd-ed-kind"
        [attr.aria-label]="'editor.toolbar.blockType' | transloco"
        [value]="textKind() ?? ''"
        data-block-type-select
        (change)="setKind($event)"
      >
        @if (!textKind() || !isTextKind(textKind())) {
          <option value="" disabled [selected]="true">{{ (textKind() ? 'editor.blocks.menu.' + textKind() : 'editor.toolbar.otherBlock') | transloco }}</option>
        }
        @for (kind of textKinds; track kind) {
          <option [value]="kind" [selected]="kind === textKind()">{{ 'editor.blocks.menu.' + kind | transloco }}</option>
        }
      </select>
      <span class="rd-ed-sep" aria-hidden="true"></span>
      @for (item of marks; track item.mark) {
        <button
          type="button"
          class="rd-ed-tool"
          [attr.aria-label]="'editor.toolbar.' + item.key | transloco"
          [title]="'editor.toolbar.' + item.key | transloco"
          [attr.aria-pressed]="isActive(item.mark)"
          [disabled]="!canMark()"
          [attr.data-mark]="item.mark"
          (mousedown)="$event.preventDefault()"
          (click)="toggleMark(item.mark)"
        >
          <svg [lucideIcon]="item.icon" [size]="16" aria-hidden="true"></svg>
        </button>
      }
      <button
        type="button"
        class="rd-ed-tool"
        [attr.aria-label]="'editor.toolbar.link' | transloco"
        [title]="'editor.toolbar.link' | transloco"
        [attr.aria-pressed]="isActive('link')"
        [attr.aria-expanded]="linkOpen()"
        [disabled]="!canMark()"
        data-link
        (mousedown)="$event.preventDefault()"
        (click)="openLink()"
      >
        <svg lucideIcon="Link" [size]="16" aria-hidden="true"></svg>
      </button>
      <button
        type="button"
        class="rd-ed-tool"
        [attr.aria-label]="'editor.toolbar.term' | transloco"
        [title]="'editor.toolbar.termHint' | transloco"
        [attr.aria-pressed]="isActive('term')"
        [attr.aria-expanded]="termOpen()"
        [disabled]="!canTerm()"
        data-term
        (mousedown)="$event.preventDefault()"
        (click)="openTerm()"
      >
        <svg lucideIcon="BookOpen" [size]="16" aria-hidden="true"></svg>
      </button>
      <span class="rd-ed-sep" aria-hidden="true"></span>
      <div class="rd-ed-dir" role="group" [attr.aria-label]="'editor.toolbar.direction' | transloco">
        @for (dir of dirs; track dir) {
          <button
            type="button"
            class="rd-ed-tool rd-ed-tool-text"
            [attr.aria-pressed]="blockDir() === dir"
            [disabled]="blockDir() === null"
            [title]="'editor.toolbar.dir.' + dir | transloco"
            [attr.data-dir-option]="dir"
            (mousedown)="$event.preventDefault()"
            (click)="setDir(dir)"
          >
            {{ 'editor.toolbar.dirShort.' + dir | transloco }}
          </button>
        }
      </div>
      <span class="rd-ed-sep" aria-hidden="true"></span>
      <button
        type="button"
        class="rd-ed-tool rd-ed-tool-text"
        [attr.aria-expanded]="insertOpen()"
        aria-haspopup="listbox"
        data-insert
        (mousedown)="$event.preventDefault()"
        (click)="toggleInsert($event)"
      >
        <svg lucideIcon="Plus" [size]="16" aria-hidden="true"></svg>
        {{ 'editor.toolbar.insert' | transloco }}
      </button>
      @if (!gutter()) {
        <!-- No room for the block handle beside the text (phones, narrow windows): its menu, for the current block. -->
        <button
          #blockButton
          type="button"
          class="rd-ed-tool"
          aria-haspopup="menu"
          [attr.aria-expanded]="!!stage()?.menuOpen()"
          [attr.aria-label]="'editor.blockHandle.options' | transloco"
          [title]="'editor.blockHandle.options' | transloco"
          data-block-options
          (mousedown)="$event.preventDefault()"
          (click)="toggleBlockMenu(blockButton, $event.detail === 0)"
        >
          <svg lucideIcon="GripVertical" [size]="16" aria-hidden="true"></svg>
        </button>
      }
      <span class="ms-auto flex gap-1">
        <button type="button" class="rd-ed-tool" [attr.aria-label]="'editor.toolbar.undo' | transloco" [title]="'editor.toolbar.undo' | transloco" [disabled]="!canUndo()" (mousedown)="$event.preventDefault()" (click)="run('undo')">
          <svg lucideIcon="Undo2" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
        </button>
        <button type="button" class="rd-ed-tool" [attr.aria-label]="'editor.toolbar.redo' | transloco" [title]="'editor.toolbar.redo' | transloco" [disabled]="!canRedo()" (mousedown)="$event.preventDefault()" (click)="run('redo')">
          <svg lucideIcon="Redo2" [size]="16" class="rd-flip-rtl" aria-hidden="true"></svg>
        </button>
      </span>
      @if (inTable()) {
        <div class="rd-ed-table-tools" role="group" [attr.aria-label]="'editor.table.label' | transloco" data-table-tools>
          <button
            type="button"
            class="rd-ed-tool rd-ed-tool-text"
            [disabled]="(tableSize()?.rows ?? 0) >= maxRows"
            [attr.title]="(tableSize()?.rows ?? 0) >= maxRows ? ('editor.table.maxRows' | transloco: { max: maxRows }) : null"
            data-table-add-row
            (mousedown)="$event.preventDefault()"
            (click)="run('addRowAfter')"
          >
            {{ 'editor.table.addRow' | transloco }}
          </button>
          @for (side of columnSides; track side) {
            <button
              type="button"
              class="rd-ed-tool rd-ed-tool-text"
              [disabled]="(tableSize()?.cols ?? 0) >= maxCols"
              [attr.title]="(tableSize()?.cols ?? 0) >= maxCols ? ('editor.table.maxColumns' | transloco: { max: maxCols }) : null"
              [attr.data-table-add-column]="side"
              (mousedown)="$event.preventDefault()"
              (click)="run(side === 'before' ? 'addColumnBefore' : 'addColumnAfter')"
            >
              {{ (side === 'before' ? 'editor.table.addColumnBefore' : 'editor.table.addColumnAfter') | transloco }}
            </button>
          }
          <button type="button" class="rd-ed-tool rd-ed-tool-text" (mousedown)="$event.preventDefault()" (click)="run('deleteRow')">{{ 'editor.table.deleteRow' | transloco }}</button>
          <button type="button" class="rd-ed-tool rd-ed-tool-text" (mousedown)="$event.preventDefault()" (click)="run('deleteColumn')">{{ 'editor.table.deleteColumn' | transloco }}</button>
          <button type="button" class="rd-ed-tool rd-ed-tool-text text-error" (mousedown)="$event.preventDefault()" (click)="run('deleteTable')">{{ 'editor.table.delete' | transloco }}</button>
        </div>
      }
    </div>

    @if (linkOpen()) {
      <form class="rd-ed-linkbar" (submit)="applyLink($event)" data-link-form>
        <label class="sr-only" [for]="editorId + '-link'">{{ 'editor.toolbar.linkUrl' | transloco }}</label>
        <input
          #linkInput
          [id]="editorId + '-link'"
          class="rd-input min-h-9 flex-1"
          type="url"
          dir="ltr"
          inputmode="url"
          placeholder="https://"
          [value]="linkUrl()"
          [attr.aria-invalid]="linkInvalid() ? 'true' : null"
          (input)="linkUrl.set(valueOf($event)); linkInvalid.set(false)"
          (keydown.escape)="closeLink()"
        />
        <button type="submit" class="rd-btn rd-btn-primary min-h-9 px-3 text-sm">{{ 'editor.toolbar.linkApply' | transloco }}</button>
        @if (isActive('link')) {
          <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-3 text-sm" (click)="removeLink()">{{ 'editor.toolbar.linkRemove' | transloco }}</button>
        }
        <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-3 text-sm" (click)="closeLink()">{{ 'common.cancel' | transloco }}</button>
        @if (linkInvalid()) {
          <p class="m-0 w-full text-xs text-error" role="alert">{{ 'editor.invalidUrl' | transloco }}</p>
        }
      </form>
    }

    @if (termOpen() && termSelection(); as target) {
      <div class="rd-ed-linkbar rd-ed-termbar" role="group" [attr.aria-label]="'editor.toolbar.term' | transloco" data-term-bar (keydown.escape)="closeTerm()">
        <p class="m-0 w-full text-sm text-text-secondary" data-term-for>
          {{ (target.termId ? 'editor.toolbar.termCurrent' : 'editor.toolbar.termFor') | transloco }}
          <bdi class="font-semibold text-text-primary">{{ target.text }}</bdi>
          @if (target.termId) {
            <bdi dir="ltr" class="ms-1 text-xs">({{ target.termId }})</bdi>
          }
        </p>
        <label class="sr-only" [for]="editorId + '-term'">{{ 'editor.toolbar.termSearch' | transloco }}</label>
        <input
          #termInput
          [id]="editorId + '-term'"
          class="rd-input min-h-9 flex-1"
          type="search"
          dir="ltr"
          autocomplete="off"
          [placeholder]="'editor.toolbar.termSearchPlaceholder' | transloco"
          [value]="termQuery()"
          [attr.aria-controls]="editorId + '-term-results'"
          (input)="searchTerms(valueOf($event))"
        />
        @if (target.termId) {
          <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-3 text-sm" data-term-remove (click)="removeTerm()">{{ 'editor.toolbar.termRemove' | transloco }}</button>
        }
        <button type="button" class="rd-btn rd-btn-ghost min-h-9 px-3 text-sm" (click)="closeTerm()">{{ 'common.cancel' | transloco }}</button>
        <ul [id]="editorId + '-term-results'" class="rd-ed-termlist" [attr.aria-label]="'editor.toolbar.termResults' | transloco" [attr.aria-busy]="termStatus() === 'loading'" data-term-results>
          @for (term of termResults(); track term.slug) {
            <li>
              <button
                type="button"
                class="rd-ed-termopt"
                [attr.aria-current]="term.slug === target.termId ? 'true' : null"
                [attr.data-term-option]="term.slug"
                (click)="applyTerm(term)"
              >
                <bdi dir="ltr" class="block text-sm font-semibold">{{ term.term }}</bdi>
                <span dir="ltr" class="block truncate text-xs text-text-secondary">{{ term.definitionEn }}</span>
              </button>
            </li>
          }
        </ul>
        <p class="m-0 w-full text-xs text-text-secondary" aria-live="polite" data-term-status>
          @switch (termStatus()) {
            @case ('loading') {
              {{ 'editor.toolbar.termSearching' | transloco }}
            }
            @case ('error') {
              <span class="text-error">{{ 'editor.toolbar.termError' | transloco }}</span>
              <button type="button" class="rd-btn rd-btn-ghost ms-2 min-h-8 px-2 text-xs" (click)="searchTerms(termQuery(), true)">{{ 'common.retry' | transloco }}</button>
            }
            @case ('loaded') {
              @if (!termResults().length) {
                {{ (termQuery().trim() ? 'editor.toolbar.termNoMatches' : 'editor.toolbar.termType') | transloco }}
              }
            }
          }
        </p>
      </div>
    }

    <rd-block-stage [editor]="editorRef()" [tick]="tick()" [dir]="contentDir()" (gutterChange)="gutter.set($event)">
      <div #host class="rd-ed-surface" [attr.lang]="language()" [attr.dir]="contentDir()" data-editor-surface></div>
    </rd-block-stage>

    @if (tablePicker(); as anchor) {
      <rd-table-size-picker [anchor]="anchor" [dir]="contentDir()" (picked)="insertTableOf($event)" (cancelled)="closeTablePicker(true)" />
    }

    @if (blockMenu(); as menu) {
      <ul
        [id]="editorId + '-menu'"
        class="rd-ed-popup"
        role="listbox"
        [attr.aria-label]="'editor.blocks.menuLabel' | transloco"
        [style.left.px]="menu.left"
        [style.top.px]="menu.top"
        data-slash-menu
      >
        @for (item of menu.items; track item.kind; let i = $index) {
          <li
            [id]="editorId + '-opt-' + i"
            role="option"
            [attr.aria-selected]="i === menu.index"
            [attr.data-block-option]="item.kind"
            tabindex="-1"
            (mousedown)="$event.preventDefault()"
            (mousemove)="setMenuIndex(i)"
            (click)="menu.command(item)"
            (keydown.enter)="menu.command(item)"
          >
            <span class="rd-ed-popup-icon" aria-hidden="true"><svg [lucideIcon]="item.icon" [size]="18" [class.rd-flip-rtl]="flips(item)"></svg></span>
            <span class="min-w-0">
              <span class="block text-sm font-semibold">{{ 'editor.blocks.menu.' + item.kind | transloco }}</span>
              <span class="block truncate text-xs text-text-secondary">{{ 'editor.blocks.menu.' + item.kind + 'Hint' | transloco }}</span>
            </span>
          </li>
        } @empty {
          <li class="px-3 py-2 text-sm text-text-secondary" aria-disabled="true">{{ 'editor.blocks.noMatch' | transloco }}</li>
        }
      </ul>
    }

    @if (mentionMenu(); as menu) {
      <ul
        [id]="editorId + '-mentions'"
        class="rd-ed-popup"
        role="listbox"
        [attr.aria-label]="'comments.composer.suggestions' | transloco"
        [style.left.px]="menu.left"
        [style.top.px]="menu.top"
        data-mention-list
      >
        @for (person of menu.items; track person.id; let i = $index) {
          <li
            [id]="editorId + '-person-' + i"
            role="option"
            [attr.aria-selected]="i === menu.index"
            [attr.data-mention-option]="person.username"
            tabindex="-1"
            (mousedown)="$event.preventDefault()"
            (click)="menu.command(person)"
            (keydown.enter)="menu.command(person)"
          >
            <rd-avatar [name]="person.displayName" [src]="person.avatarUrl" [size]="28" />
            <span class="min-w-0">
              <span class="block truncate text-sm font-semibold"><rd-bdi-text [text]="person.displayName" /></span>
              <bdi dir="ltr" class="block text-xs text-text-secondary">&#64;{{ person.username }}</bdi>
            </span>
          </li>
        }
      </ul>
    }
  `,
})
export class BlockEditor {
  private readonly transloco = inject(TranslocoService);
  private readonly uploader = inject(ImageUploader);
  private readonly comments = inject(CommentsApi);
  private readonly glossary = inject(GlossaryApi);
  private readonly uiLang = inject(LanguageService).lang;

  /** The article version being edited. */
  readonly content = input.required<RDoc>();
  readonly language = input.required<ArticleLanguage>();
  /** The content is (re)loaded when this changes. */
  readonly contentKey = input<string | number>(0);
  readonly label = input('');
  readonly changed = output<ContentChange>();
  /** Image block uploads in flight. */
  readonly uploadsChange = output<number>();

  protected readonly editorId = `rd-editor-${++nextEditorId}`;
  protected readonly textKinds = TEXT_KINDS;
  protected readonly marks = MARKS;
  protected readonly dirs: readonly BlockDir[] = ['auto', 'rtl', 'ltr'];
  protected readonly contentDir = computed(() => languageDir(this.language()));

  private readonly hostEl = viewChild.required<ElementRef<HTMLElement>>('host');
  private readonly linkInput = viewChild<ElementRef<HTMLInputElement>>('linkInput');
  private readonly termInput = viewChild<ElementRef<HTMLInputElement>>('termInput');
  protected readonly stage = viewChild(BlockStage);
  private editor: Editor | null = null;
  /** The Tiptap editor, for the block handle. */
  protected readonly editorRef = signal<Editor | null>(null);
  /** Whether the block handle fits beside the text; until measured, a guess from the screen. */
  protected readonly gutter = signal(typeof matchMedia === 'function' && matchMedia('(min-width: 64rem) and (pointer: fine)').matches);
  /** Insert → Table: the size picker, opened under this rectangle. */
  protected readonly tablePicker = signal<PopupAnchor | null>(null);
  protected readonly columnSides = ['before', 'after'] as const;
  protected readonly maxCols = TABLE_MAX_COLS;
  protected readonly maxRows = TABLE_MAX_ROWS;
  /** Bumped on every transaction so the toolbar state recomputes. */
  protected readonly tick = signal(0);
  private emitTimer: ReturnType<typeof setTimeout> | null = null;
  private uploads = 0;
  private loadedKey: string | null = null;
  /** The language the current content was loaded for (reported with every change). */
  private loadedLanguage: ArticleLanguage | null = null;

  protected readonly blockMenu = signal<Popup<BlockMenuItem> | null>(null);
  protected readonly mentionMenu = signal<Popup<MentionCandidateDto> | null>(null);
  protected readonly insertOpen = signal(false);
  protected readonly linkOpen = signal(false);
  protected readonly linkUrl = signal('');
  protected readonly linkInvalid = signal(false);
  /** The glossary term picker: what it marks (kept while the search field has focus), the query and the matches. */
  protected readonly termOpen = signal(false);
  protected readonly termSelection = signal<TermTarget | null>(null);
  protected readonly termQuery = signal('');
  protected readonly termResults = signal<GlossaryTermSummaryDto[]>([]);
  protected readonly termStatus = signal<'loading' | 'loaded' | 'error'>('loaded');
  private termTimer: ReturnType<typeof setTimeout> | null = null;
  private termSearch = 0;

  protected readonly textKind = computed(() => (this.tick(), this.editor ? currentTextKind(this.editor) : null));
  protected readonly blockDir = computed(() => (this.tick(), this.editor ? currentBlockDir(this.editor) : null));
  protected readonly inTable = computed(() => (this.tick(), !!this.editor?.isActive('table')));
  /** Columns and rows of the table holding the cursor (the add buttons stop at the RDoc limits). */
  protected readonly tableSize = computed(() => (this.tick(), this.editor ? tableShape(this.editor.state) : null));
  protected readonly canUndo = computed(() => (this.tick(), !!this.editor?.can().undo()));
  protected readonly canRedo = computed(() => (this.tick(), !!this.editor?.can().redo()));
  /** Marks apply to text, not to code blocks or atoms. */
  protected readonly canMark = computed(() => {
    this.tick();
    const editor = this.editor;
    if (!editor) return false;
    const { $from } = editor.state.selection;
    return $from.parent.inlineContent && !$from.parent.type.spec.code && !(editor.state.selection instanceof NodeSelection);
  });
  /** Words selected in one text block, or a glossary term node selected. */
  protected readonly canTerm = computed(() => (this.tick(), !!this.editor && termTarget(this.editor) !== null));

  private readonly host: RDocEditorHost = {
    t: (key, params) => this.transloco.translate(key, params ?? {}),
    uploadImage: async (file, onProgress, signal) => {
      const asset = await this.uploader.upload(file, 'image', onProgress, signal);
      return { src: largestVariant(asset)!.url, width: asset.width, height: asset.height };
    },
    uploadsChanged: (delta) => {
      this.uploads = Math.max(0, this.uploads + delta);
      this.uploadsChange.emit(this.uploads);
    },
    resolveAsset: (src) => {
      if (src.startsWith('rdoc-asset://')) return `${environment.assetsBaseUrl}/${src.slice('rdoc-asset://'.length)}`;
      return safeHttpUrl(src);
    },
    fallbackDir: () => languageDir(this.language()),
  };

  constructor() {
    const destroyRef = inject(DestroyRef);
    afterNextRender(() => this.create());
    // New content (another language version, a restored revision, a reload): start over, dropping unreported typing
    // (the page flushes before it switches). Only the UI language changed (node view labels): keep the typing.
    effect(() => {
      const key = `${this.language()}|${this.contentKey()}`;
      const ui = this.uiLang();
      untracked(() => {
        if (!this.editor) return;
        if (key !== this.loadedKey) this.create(false);
        else if (ui !== this.loadedUi) this.create(true);
      });
    });
    destroyRef.onDestroy(() => {
      if (this.termTimer) clearTimeout(this.termTimer);
      this.flush();
      this.editor?.destroy();
      this.editor = null;
      this.editorRef.set(null);
    });
  }

  /** Reports the current content at once (before saving, publishing or switching the language version). */
  flush(): void {
    if (!this.emitTimer || !this.editor || !this.loadedLanguage) return;
    clearTimeout(this.emitTimer);
    this.emitTimer = null;
    this.changed.emit({ language: this.loadedLanguage, content: this.currentRDoc() });
  }

  currentRDoc(): RDoc {
    return editorToRDoc(this.editor?.getJSON() as PmNode, this.loadedLanguage ?? this.language());
  }

  /** Scrolls to a block (a live-check problem), highlights it and puts the cursor (or focus) in it. */
  focusBlock(blockId: string): boolean {
    const editor = this.editor;
    if (!editor) return false;
    let target: { pos: number; atom: boolean } | null = null;
    editor.state.doc.forEach((node, pos) => {
      if (!target && node.attrs['id'] === blockId) target = { pos, atom: node.isAtom };
    });
    const found = target as { pos: number; atom: boolean } | null;
    if (!found) return false;
    const dom = this.hostEl().nativeElement.querySelector<HTMLElement>(`[data-block-id="${CSS.escape(blockId)}"]`);
    dom?.scrollIntoView?.({ block: 'center', behavior: 'smooth' });
    dom?.classList.add('rd-ed-flash');
    setTimeout(() => dom?.classList.remove('rd-ed-flash'), 1600);
    const { state, view } = editor;
    const selection = found.atom ? NodeSelection.create(state.doc, found.pos) : TextSelection.near(state.doc.resolve(found.pos + 1));
    view.dispatch(state.tr.setSelection(selection));
    const field = dom?.querySelector<HTMLElement>('[data-image-alt]');
    if (field) field.focus({ preventScroll: true });
    else view.focus();
    return true;
  }

  /** Puts the cursor at the start of the content. */
  focusStart(): void {
    this.editor?.commands.focus('start');
    this.hostEl().nativeElement.scrollIntoView?.({ block: 'start', behavior: 'smooth' });
  }

  private loadedUi: string | null = null;

  private create(keepTyping = true): void {
    if (keepTyping) this.flush();
    else if (this.emitTimer) clearTimeout(this.emitTimer);
    this.emitTimer = null;
    this.editor?.destroy();
    this.blockMenu.set(null);
    this.mentionMenu.set(null);
    this.tablePicker.set(null);
    this.termOpen.set(false); // its positions belong to the old document
    this.loadedKey =`${this.language()}|${this.contentKey()}`;
    this.loadedUi = this.uiLang();
    this.loadedLanguage = this.language();
    const element = this.hostEl().nativeElement;
    element.replaceChildren();
    const editor = new Editor({
      element,
      extensions: rdocExtensions(this.host, [this.slashMenu(), this.mentions()]),
      content: rdocToEditor(this.content()) as never,
      editorProps: {
        attributes: {
          id: this.editorId,
          class: 'rdoc rd-ed',
          role: 'textbox',
          'aria-multiline': 'true',
          'aria-label': this.label() || this.transloco.translate('editor.contentLabel'),
          spellcheck: 'true',
          'data-editor': '',
        },
      },
      onTransaction: ({ transaction }) => {
        this.tick.update((n) => n + 1);
        // The picker's positions are the document's before this change.
        if (transaction.docChanged && this.termOpen()) this.closeTerm(false);
      },
      onUpdate: () => this.scheduleEmit(),
    });
    editor.view.dispatch(ensureBlockIds(editor.state.tr, undefined).setMeta('addToHistory', false));
    this.editor = editor;
    this.editorRef.set(editor);
    this.tick.update((n) => n + 1);
  }

  private scheduleEmit(): void {
    if (this.emitTimer) clearTimeout(this.emitTimer);
    this.emitTimer = setTimeout(() => {
      this.emitTimer = null;
      if (this.editor && this.loadedLanguage) this.changed.emit({ language: this.loadedLanguage, content: this.currentRDoc() });
    }, CHANGE_DEBOUNCE_MS);
  }

  // ── Toolbar ────────────────────────────────────────────

  protected isTextKind(kind: BlockKind | null): boolean {
    return !!kind && TEXT_KINDS.includes(kind);
  }

  protected isActive(name: string): boolean {
    this.tick();
    return !!this.editor?.isActive(name);
  }

  protected flips(item: BlockMenuItem): boolean {
    return item.icon === 'List' || item.icon === 'ListOrdered' || item.icon === 'ListChecks';
  }

  protected setKind(event: Event): void {
    const kind = (event.target as HTMLSelectElement).value as BlockKind;
    if (this.editor && kind) insertBlock(this.editor, kind);
  }

  protected toggleMark(mark: (typeof MARKS)[number]['mark']): void {
    const chain = this.editor?.chain().focus();
    if (!chain) return;
    switch (mark) {
      case 'bold':
        chain.toggleBold().run();
        break;
      case 'italic':
        chain.toggleItalic().run();
        break;
      case 'strike':
        chain.toggleStrike().run();
        break;
      case 'highlight':
        chain.toggleHighlight().run();
        break;
      case 'code':
        chain.toggleCode().run();
        break;
    }
  }

  protected setDir(dir: BlockDir): void {
    if (this.editor) setBlockDir(this.editor, dir);
  }

  protected run(command: 'undo' | 'redo' | 'addRowAfter' | 'addColumnBefore' | 'addColumnAfter' | 'deleteRow' | 'deleteColumn' | 'deleteTable'): void {
    const chain = this.editor?.chain().focus();
    if (!chain) return;
    switch (command) {
      case 'undo':
        chain.undo().run();
        break;
      case 'redo':
        chain.redo().run();
        break;
      case 'addRowAfter':
        chain.addRowAfter().run();
        break;
      case 'addColumnBefore':
        chain.addColumnBefore().run();
        break;
      case 'addColumnAfter':
        chain.addColumnAfter().run();
        break;
      case 'deleteRow':
        chain.deleteRow().run();
        break;
      case 'deleteColumn':
        chain.deleteColumn().run();
        break;
      case 'deleteTable':
        chain.deleteTable().run();
        break;
    }
  }

  /** The "Insert" button opens the same list as `/`, under the button. */
  protected toggleInsert(event: Event): void {
    if (this.blockMenu() && this.insertOpen()) {
      this.closeInsert();
      return;
    }
    const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
    this.insertOpen.set(true);
    this.blockMenu.set({
      items: [...BLOCK_MENU],
      index: 0,
      ...this.place(rect),
      command: (item) => {
        this.closeInsert();
        if (!this.editor) return;
        if (item.kind === 'table') this.tablePicker.set(anchorOf(rect));
        else insertBlock(this.editor, item.kind);
      },
    });
    queueMicrotask(() => document.addEventListener('mousedown', this.closeInsertOnOutside, { once: true }));
  }

  private readonly closeInsertOnOutside = (event: MouseEvent) => {
    const target = event.target as Element | null;
    if (target?.closest('[data-slash-menu]')) {
      document.addEventListener('mousedown', this.closeInsertOnOutside, { once: true });
      return;
    }
    this.closeInsert();
  };

  private closeInsert(): void {
    this.insertOpen.set(false);
    this.blockMenu.set(null);
  }

  protected setMenuIndex(index: number): void {
    this.blockMenu.update((menu) => (menu ? { ...menu, index } : menu));
  }

  // ── Table size, block menu ─────────────────────────────

  /** Slash menu → Table: the typed `/query` goes, and the size picker opens at the caret. */
  private openTablePicker(editor: Editor, range: Range): void {
    const caret = editor.view.coordsAtPos(range.from);
    editor.chain().focus().deleteRange(range).run();
    this.tablePicker.set(anchorOf(caret));
  }

  protected insertTableOf(size: TableSize): void {
    this.closeTablePicker(false);
    if (this.editor) insertTable(this.editor, size);
  }

  protected closeTablePicker(refocus: boolean): void {
    this.tablePicker.set(null);
    if (refocus) this.editor?.commands.focus();
  }

  /** The toolbar's block button (when the handle has no room beside the text). */
  protected toggleBlockMenu(button: HTMLElement, viaKeyboard: boolean): void {
    const stage = this.stage();
    if (!stage) return;
    if (stage.menuOpen()) stage.closeMenu(viaKeyboard);
    else stage.openMenu(button, viaKeyboard);
  }

  // ── Link ───────────────────────────────────────────────

  protected openLink(): void {
    if (!this.editor) return;
    this.termOpen.set(false);
    this.linkUrl.set(String(this.editor.getAttributes('link')['href'] ?? ''));
    this.linkInvalid.set(false);
    this.linkOpen.set(true);
    afterNextRenderFocus(() => this.linkInput()?.nativeElement);
  }

  protected applyLink(event: Event): void {
    event.preventDefault();
    const editor = this.editor;
    const href = safeHttpUrl(this.linkUrl().trim());
    if (!editor || !href) {
      this.linkInvalid.set(true);
      return;
    }
    const { empty } = editor.state.selection;
    if (empty && !editor.isActive('link')) {
      editor.chain().focus().insertContent({ type: 'text', text: href, marks: [{ type: 'link', attrs: { href } }] }).run();
    } else {
      editor.chain().focus().extendMarkRange('link').setLink({ href }).run();
    }
    this.linkOpen.set(false);
  }

  protected removeLink(): void {
    this.editor?.chain().focus().extendMarkRange('link').unsetLink().run();
    this.linkOpen.set(false);
  }

  protected closeLink(): void {
    this.linkOpen.set(false);
    this.editor?.commands.focus();
  }

  // ── Glossary term (F21) ────────────────────────────────

  /** Opens the picker for the selected words (searching for them) or the selected term (searching for its id). */
  protected openTerm(): void {
    const target = this.editor ? termTarget(this.editor) : null;
    if (!target) return;
    this.linkOpen.set(false);
    this.termSelection.set(target);
    this.termOpen.set(true);
    this.searchTerms(target.termId ?? target.text, true);
    afterNextRenderFocus(() => this.termInput()?.nativeElement);
  }

  /** Searches the glossary for `query` (debounced unless `now`); an older answer never replaces a newer one. */
  protected searchTerms(query: string, now = false): void {
    this.termQuery.set(query);
    if (this.termTimer) clearTimeout(this.termTimer);
    const q = query.trim();
    const search = ++this.termSearch;
    if (!q) {
      this.termResults.set([]);
      this.termStatus.set('loaded');
      return;
    }
    this.termStatus.set('loading');
    this.termTimer = setTimeout(
      async () => {
        this.termTimer = null;
        try {
          const results = await firstValueFrom(this.glossary.search(q, 8));
          if (search !== this.termSearch) return;
          this.termResults.set(results);
          this.termStatus.set('loaded');
        } catch {
          if (search === this.termSearch) this.termStatus.set('error');
        }
      },
      now ? 0 : TERM_DEBOUNCE_MS,
    );
  }

  protected applyTerm(term: GlossaryTermSummaryDto): void {
    const target = this.termSelection();
    if (this.editor && target) markTerm(this.editor, target, term.slug);
    this.closeTerm(false);
  }

  protected removeTerm(): void {
    const target = this.termSelection();
    if (this.editor && target) unmarkTerm(this.editor, target);
    this.closeTerm(false);
  }

  protected closeTerm(refocus = true): void {
    if (this.termTimer) clearTimeout(this.termTimer);
    this.termTimer = null;
    this.termSearch++;
    this.termOpen.set(false);
    this.termSelection.set(null);
    this.termResults.set([]);
    if (refocus) this.editor?.commands.focus();
  }

  // ── Slash menu and mentions (Tiptap suggestion plugins) ─

  /** Popup position from the caret, kept inside the viewport (fixed positioning). */
  private place(rect: DOMRect | null | undefined): { left: number; top: number } {
    const width = 288;
    const viewport = typeof window === 'undefined' ? 1024 : window.innerWidth;
    const rtl = document.documentElement.dir === 'rtl';
    const anchor = rect ? (rtl ? rect.right - width : rect.left) : 16;
    return { left: Math.max(8, Math.min(anchor, viewport - width - 8)), top: (rect?.bottom ?? 0) + 6 };
  }

  private popupKeys<T>(menu: WritableSignal<Popup<T> | null>, props: SuggestionKeyDownProps): boolean {
    const current = menu();
    if (!current) return false;
    const count = current.items.length;
    switch (props.event.key) {
      case 'ArrowDown':
        if (count) menu.set({ ...current, index: (current.index + 1) % count });
        return true;
      case 'ArrowUp':
        if (count) menu.set({ ...current, index: (current.index - 1 + count) % count });
        return true;
      case 'Enter':
      case 'Tab':
        if (!count) return false;
        current.command(current.items[current.index]);
        return true;
      case 'Escape':
        menu.set(null);
        return true;
      default:
        return false;
    }
  }

  private popupFrom<T>(props: SuggestionProps<T>, previous: Popup<T> | null): Popup<T> {
    const index = previous && previous.items.length === props.items.length ? Math.min(previous.index, props.items.length - 1) : 0;
    return { items: props.items, index: Math.max(0, index), ...this.place(props.clientRect?.()), command: (item: T) => props.command(item) };
  }

  private slashMenu(): Extension {
    const options: Omit<SuggestionOptions<BlockMenuItem, BlockMenuItem>, 'editor'> = {
      char: '/',
      pluginKey: new PluginKey('rdocSlashMenu'),
      // Blocks start in a top-level paragraph.
      allow: ({ state, range }) => {
        const $from = state.doc.resolve(range.from);
        return $from.depth === 1 && $from.parent.type.name === 'paragraph';
      },
      items: ({ query }) => filterBlockMenu(query, (kind) => this.transloco.translate(`editor.blocks.menu.${kind}`)),
      command: ({ editor, range, props }) => {
        if (props.kind === 'table') this.openTablePicker(editor, range as Range);
        else insertBlock(editor, props.kind, range as Range);
      },
      render: () => ({
        onStart: (props) => {
          this.insertOpen.set(false);
          this.blockMenu.set(this.popupFrom(props, null));
        },
        onUpdate: (props) => this.blockMenu.set(this.popupFrom(props, this.blockMenu())),
        onKeyDown: (props) => this.popupKeys(this.blockMenu, props),
        onExit: () => this.blockMenu.set(null),
      }),
    };
    return suggestionExtension('rdocSlashMenu', options);
  }

  private mentions(): Extension {
    const options: Omit<SuggestionOptions<MentionCandidateDto, MentionCandidateDto>, 'editor'> = {
      char: '@',
      pluginKey: new PluginKey('rdocMentions'),
      debounce: MENTION_DEBOUNCE_MS,
      allow: ({ state, range }) => !state.doc.resolve(range.from).parent.type.spec.code,
      items: async ({ query }) => {
        if (!query) return [];
        try {
          return await firstValueFrom(this.comments.mentionSuggestions(query, 6));
        } catch {
          return [];
        }
      },
      command: ({ editor, range, props }) => {
        editor
          .chain()
          .focus()
          .insertContentAt(range, [
            { type: 'mention', attrs: { userId: props.id, text: `@${props.username}` } },
            { type: 'text', text: ' ' },
          ])
          .run();
      },
      render: () => ({
        onStart: (props) => this.mentionMenu.set(props.items.length ? this.popupFrom(props, null) : null),
        onUpdate: (props) => this.mentionMenu.set(props.items.length ? this.popupFrom(props, this.mentionMenu()) : null),
        onKeyDown: (props) => this.popupKeys(this.mentionMenu, props),
        onExit: () => this.mentionMenu.set(null),
      }),
    };
    return suggestionExtension('rdocMentions', options);
  }

  protected valueOf(event: Event): string {
    return (event.target as HTMLInputElement).value;
  }
}

/** A Tiptap extension running one suggestion plugin (`/` blocks, `@` mentions). */
function suggestionExtension<T>(name: string, options: Omit<SuggestionOptions<T, T>, 'editor'>): Extension {
  return Extension.create({
    name,
    addProseMirrorPlugins() {
      return [Suggestion<T, T>({ editor: this.editor, ...options })];
    },
  });
}

function anchorOf(rect: PopupAnchor): PopupAnchor {
  return { left: rect.left, right: rect.right, top: rect.top, bottom: rect.bottom };
}

/** Focuses an element that appears on the next render. */
function afterNextRenderFocus(element: () => HTMLElement | undefined): void {
  setTimeout(() => element()?.focus(), 0);
}
