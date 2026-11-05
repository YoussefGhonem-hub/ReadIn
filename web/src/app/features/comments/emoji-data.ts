/**
 * The emoji the comment box's picker offers (F11), by category. A short, hand-picked list of the ones people use in
 * comments, all well supported (Unicode 12 or older), so they look right on every system. Part of the picker's lazy
 * chunk: it loads only when someone presses the emoji button.
 */
export interface EmojiCategory {
  /** Its name: `emojiPicker.{id}`. */
  id: 'smileys' | 'people' | 'hearts' | 'nature' | 'food' | 'activities' | 'travel' | 'objects' | 'symbols';
  emoji: readonly string[];
}

const list = (text: string): readonly string[] => text.split(' ').filter(Boolean);

export const EMOJI_CATEGORIES: readonly EmojiCategory[] = [
  {
    id: 'smileys',
    emoji: list(
      '😀 😃 😄 😁 😆 😅 😂 🤣 😊 😇 🙂 🙃 😉 😌 😍 🥰 😘 😗 😙 😚 😋 😛 😝 😜 🤪 🤨 🧐 🤓 😎 🤩 🥳 😏 😒 😞 😔 😟 😕 🙁 😣 😖 😫 😩 🥺 😢 😭 😤 😠 😡 🤯 😳 🥵 🥶 😱 😨 😰 😥 😓 🤗 🤔 🤭 🤫 🤥 😶 😐 😑 😬 🙄 😯 😦 😧 😮 😲 🥱 😴 🤤 😪 😵 🤐 🥴 🤢 🤮 🤧 😷 🤒 🤕',
    ),
  },
  {
    id: 'people',
    emoji: list(
      '👍 👎 👏 🙌 👐 🤲 🤝 🙏 ✌️ 🤞 🤟 🤘 👌 🤏 👈 👉 👆 👇 ☝️ ✋ 🤚 🖐️ 🖖 👋 🤙 💪 ✍️ 👀 🧠 👶 🧒 👦 👧 🧑 👨 👩 🧓 👴 👵 👨‍💻 👩‍💻 👨‍🏫 👩‍🏫 👨‍⚕️ 👩‍⚕️ 👨‍🎓 👩‍🎓 🤷 🤦 🙋 🙆 🙅 💁',
    ),
  },
  {
    id: 'hearts',
    emoji: list('❤️ 🧡 💛 💚 💙 💜 🤎 🖤 🤍 💔 ❣️ 💕 💞 💓 💗 💖 💘 💝 💟 💯 💢 💥 💫 💦 💨 🔥 ✨ ⭐ 🌟'),
  },
  {
    id: 'nature',
    emoji: list(
      '🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐨 🐯 🦁 🐮 🐷 🐸 🐵 🙈 🙉 🙊 🐔 🐧 🐦 🦅 🦉 🐝 🦋 🐌 🐞 🐢 🐍 🐙 🐬 🐳 🐟 🌵 🌲 🌳 🌴 🌱 🌿 🍀 🍁 🍂 🌷 🌹 🌻 🌼 🌸 🌍 🌙 ☀️ ⛅ 🌧️ ⛈️ ❄️ 🌈 🌊',
    ),
  },
  {
    id: 'food',
    emoji: list(
      '🍏 🍎 🍐 🍊 🍋 🍌 🍉 🍇 🍓 🍒 🍑 🥭 🍍 🥥 🥝 🍅 🥑 🥦 🥒 🌶️ 🌽 🥕 🥔 🥐 🍞 🧀 🥚 🍳 🥞 🍔 🍟 🍕 🌭 🥪 🌮 🥙 🧆 🍝 🍜 🍲 🍛 🍣 🍰 🎂 🧁 🍩 🍪 🍫 🍬 🍿 ☕ 🍵 🧃 🥤 🧋',
    ),
  },
  {
    id: 'activities',
    emoji: list('⚽ 🏀 🏈 ⚾ 🎾 🏐 🏓 🏸 🥊 🏋️ 🚴 🏊 🧘 🏆 🥇 🥈 🥉 🏅 🎯 🎮 🎲 🧩 ♟️ 🎨 🎬 🎤 🎧 🎼 🎹 🎸 🎻 🎉 🎊 🎈 🎁 🎀'),
  },
  {
    id: 'travel',
    emoji: list('🚗 🚕 🚌 🚑 🚒 🚲 🛵 🚀 ✈️ 🚁 🚂 🚇 ⛵ 🚢 🗺️ 🧭 🏔️ 🏖️ 🏝️ 🏜️ 🏛️ 🕌 🏠 🏡 🏢 🏥 🏫 🏙️ 🌆 🌃 🌅 🗽 🗼 🕋'),
  },
  {
    id: 'objects',
    emoji: list(
      '💻 🖥️ ⌨️ 🖱️ 📱 📞 🔋 🔌 💡 🔦 📷 🎥 📺 ⏰ ⌛ ⏳ 📚 📖 📝 ✏️ 🖊️ 📌 📎 📐 📏 📊 📈 📉 🗂️ 📁 📅 📋 🔍 🔎 🔒 🔓 🔑 🛠️ 🔧 🔨 ⚙️ 🧪 🔬 🔭 💊 🩺 💉 💰 💳 📦 ✉️ 📢 🔔 🎓 🧳',
    ),
  },
  {
    id: 'symbols',
    emoji: list('✅ ☑️ ✔️ ❌ ❎ ➕ ➖ ❓ ❗ ‼️ ⁉️ ⚠️ 🚫 ⛔ ♻️ 🔆 🔅 🆗 🆕 🆒 🔝 🔜 ▶️ ⏸️ ⏹️ 🔁 🔄 ➡️ ⬅️ ⬆️ ⬇️ ↩️ 🔴 🟠 🟡 🟢 🔵 🟣 ⚫ ⚪'),
  },
];
