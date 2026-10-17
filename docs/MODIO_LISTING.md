# mod.io listing answers: WhereAmIFacing

Copy each field into the mod.io "Create Plugin" form. You're making the listing image yourself (16:9, min 512x288, max 8MB).

---

## Basics

**Plugin name**
```
WhereAmIFacing
```

**Summary** (250 character max; this is 212)
```
Always know which way your character is facing. A compass arrow shows your direction as N, NE, E, SE, S, SW, W or NW. Change the arrow to any colour you like. Calibrates itself as you walk. Display only. By 6ing.
```

**Homepage**
```
https://github.com/6inq/whereamifacing
```

**Profile URL**
```
https://mod.io/g/runescape/m/whereamifacing
```

**Community**
- Allow comments: **checked**
- Allow dependants: **unchecked**

---

## Description

Click the `<>` (source code) button in the editor toolbar and paste this:

```html
<p>WhereAmIFacing shows which way your character is facing, as an arrow and a compass direction: <strong>N, NE, E, SE, S, SW, W or NW</strong>.</p>

<h2>Features</h2>
<ul>
<li><strong>Compass arrow</strong> in a small window you can drag anywhere.</li>
<li><strong>Any colour you want:</strong> pick any hue for the arrow in the settings.</li>
<li><strong>Direction text</strong> under the arrow (can be hidden).</li>
<li><strong>Turning in place works:</strong> once calibrated, the arrow follows your character even when you turn to face an NPC or object without moving.</li>
</ul>

<h2>How to use</h2>
<ol>
<li>Enable the plugin. The Facing window appears.</li>
<li>Walk a few steps in different directions the first time so it can calibrate. Until then it shows the direction you last walked.</li>
<li>Open the settings to change the arrow colour, hide the text, or hide the compass.</li>
</ol>

<h2>Why it calibrates</h2>
<p>The game tells plugins your character's facing as a raw number. WhereAmIFacing learns how that number maps to the compass by watching a few of your steps, then remembers it. If the arrow ever points the wrong way, press <strong>Recalibrate</strong> in the settings.</p>

<h2>Fair play</h2>
<p>Display only. It never moves, clicks or acts for you, and sends nothing anywhere.</p>

<h2>Requires</h2>
<p><strong>PrettyUI</strong> (installed automatically).</p>

<p>Created by <strong>6ing</strong>. Free. Feedback welcome in the comments.</p>
```

---

## Tag selection

**Gameplay**: none

**Theme**
- Navigation: **checked**
- Interface: **checked**
- Accessibility: **checked**

**Technical**: none

**Permissions**: **none**

**Mobile**
- Mobile UI friendly: **unchecked**

---

## Visibility
Start with **Private**, then switch to **Public** after testing in the live client.

## Before you submit
- [ ] Test in the live client: walk a short lap, check the arrow, then turn in place.
- [ ] Build with `python tools/build.py` and upload `dist/where-am-i-facing-1.0.0.zip`.
- [ ] Upload your listing image.
