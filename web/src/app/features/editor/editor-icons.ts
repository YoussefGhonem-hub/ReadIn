import { Provider, inject } from '@angular/core';
import { LUCIDE_ICONS, lucideLegacyIconMap } from '@lucide/angular';
// One file per icon, not the `lucide` barrel: through the barrel (used by the initial bundle) they would be bundled there.
import CloudCheck from 'lucide/dist/esm/icons/cloud-check.mjs';
import CloudUpload from 'lucide/dist/esm/icons/cloud-upload.mjs';
import Heading2 from 'lucide/dist/esm/icons/heading-2.mjs';
import Heading3 from 'lucide/dist/esm/icons/heading-3.mjs';
import Highlighter from 'lucide/dist/esm/icons/highlighter.mjs';
import Image from 'lucide/dist/esm/icons/image.mjs';
import Italic from 'lucide/dist/esm/icons/italic.mjs';
import Bold from 'lucide/dist/esm/icons/letter-b.mjs';
import Link from 'lucide/dist/esm/icons/link.mjs';
import ListChecks from 'lucide/dist/esm/icons/list-checks.mjs';
import ListOrdered from 'lucide/dist/esm/icons/list-ordered.mjs';
import List from 'lucide/dist/esm/icons/list.mjs';
import MessageSquareWarning from 'lucide/dist/esm/icons/message-square-warning.mjs';
import Minus from 'lucide/dist/esm/icons/minus.mjs';
import NotebookText from 'lucide/dist/esm/icons/notebook-text.mjs';
import Pilcrow from 'lucide/dist/esm/icons/pilcrow.mjs';
import Quote from 'lucide/dist/esm/icons/quote.mjs';
import Redo2 from 'lucide/dist/esm/icons/redo-2.mjs';
import History from 'lucide/dist/esm/icons/rotate-ccw-clock.mjs';
import RotateCcw from 'lucide/dist/esm/icons/rotate-ccw.mjs';
import SquareCode from 'lucide/dist/esm/icons/square-code.mjs';
import SquarePlay from 'lucide/dist/esm/icons/square-play.mjs';
import Strikethrough from 'lucide/dist/esm/icons/strikethrough.mjs';
import Table from 'lucide/dist/esm/icons/table.mjs';
import Undo2 from 'lucide/dist/esm/icons/undo-2.mjs';

/** Icons only the writing pages use (toolbar, slash menu, save status, revisions). */
const EDITOR_ICONS = {
  Bold,
  CloudCheck,
  CloudUpload,
  Heading2,
  Heading3,
  Highlighter,
  History,
  Image,
  Italic,
  Link,
  List,
  ListChecks,
  ListOrdered,
  MessageSquareWarning,
  Minus,
  NotebookText,
  Pilcrow,
  Quote,
  Redo2,
  RotateCcw,
  SquareCode,
  SquarePlay,
  Strikethrough,
  Table,
  Undo2,
};

/**
 * Adds {@link EDITOR_ICONS} to the app's icon registry for the `/write` pages' component trees (`<svg lucideIcon="Bold">`),
 * so they live in the lazy chunks and the initial bundle keeps only the app-wide icons (shared/ui/icons.ts).
 */
export function provideEditorIcons(): Provider {
  return {
    provide: LUCIDE_ICONS,
    useFactory: () => {
      const icons = { ...inject(LUCIDE_ICONS, { skipSelf: true }) };
      for (const icon of lucideLegacyIconMap(EDITOR_ICONS)) {
        icons[icon.name] = icon;
        for (const alias of icon.aliases ?? []) icons[alias] = icon;
      }
      return icons;
    },
  };
}
