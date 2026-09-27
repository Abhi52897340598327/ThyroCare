async function exportSvg(page) {
  return page.evaluate(async () => {
    const esc = (s) =>
      String(s)
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll('"', "&quot;");
    const out = [],
      defs = [];
    let clipId = 0;
    const color = (c) => c && c !== "transparent" && c !== "rgba(0, 0, 0, 0)";
    const num = (n) => Math.round(n * 100) / 100;
    const rect = (r, c, rad = 0, stroke = "none", sw = 0) =>
      `<rect x="${num(r.x)}" y="${num(r.y)}" width="${num(r.width)}" height="${num(r.height)}" rx="${rad}" fill="${c}" stroke="${stroke}" stroke-width="${sw}"/>`;
    async function walk(el) {
      const s = getComputedStyle(el),
        r = el.getBoundingClientRect();
      if (
        s.display === "none" ||
        s.visibility === "hidden" ||
        Number(s.opacity) === 0 ||
        r.width === 0 ||
        r.height === 0 ||
        el.classList.contains("sr-only") ||
        el.classList.contains("tc-skip")
      )
        return;
      if (r.right <= 0 || r.left >= innerWidth) return;
      if (
        ["SCRIPT", "STYLE", "LINK", "META", "NOSCRIPT", "OPTION"].includes(
          el.tagName,
        )
      )
        return;
      out.push(`<g opacity="${s.opacity}">`);
      if (color(s.backgroundColor))
        out.push(rect(r, s.backgroundColor, parseFloat(s.borderRadius) || 0));
      if (
        parseFloat(s.borderTopWidth) > 0 &&
        s.borderTopWidth === s.borderBottomWidth &&
        s.borderTopWidth === s.borderLeftWidth &&
        s.borderTopWidth === s.borderRightWidth &&
        s.borderTopColor === s.borderBottomColor &&
        s.borderTopColor === s.borderLeftColor &&
        s.borderTopColor === s.borderRightColor
      ) {
        out.push(
          rect(
            r,
            "none",
            parseFloat(s.borderRadius) || 0,
            s.borderTopColor,
            parseFloat(s.borderTopWidth),
          ),
        );
      } else
        for (const edge of ["Top", "Bottom", "Left", "Right"]) {
          const w = parseFloat(s["border" + edge + "Width"]);
          if (w && color(s["border" + edge + "Color"])) {
            const x1 = edge === "Right" ? r.right : r.left,
              x2 = edge === "Left" ? r.left : r.right,
              y1 = edge === "Bottom" ? r.bottom : r.top,
              y2 = edge === "Top" ? r.top : r.bottom;
            out.push(
              `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${s["border" + edge + "Color"]}" stroke-width="${w}"/>`,
            );
          }
        }
      let clipped = false;
      if (
        ["hidden", "auto", "scroll"].includes(s.overflowX) ||
        ["hidden", "auto", "scroll"].includes(s.overflowY)
      ) {
        const id = "clip" + ++clipId;
        defs.push(
          `<clipPath id="${id}">${rect(r, "white", parseFloat(s.borderRadius) || 0)}</clipPath>`,
        );
        out.push(`<g clip-path="url(#${id})">`);
        clipped = true;
      }
      if (el.tagName.toLowerCase() === "svg") {
        const copy = el.cloneNode(true);
        copy.removeAttribute("style");
        copy.setAttribute("x", r.x);
        copy.setAttribute("y", r.y);
        copy.setAttribute("width", r.width);
        copy.setAttribute("height", r.height);
        copy.setAttribute("color", s.color);
        for (const n of copy.querySelectorAll("*")) {
          for (const attr of ["stroke", "fill"])
            if (n.getAttribute(attr) === "currentColor")
              n.setAttribute(attr, s.color);
        }
        out.push(copy.outerHTML);
      } else if (el.tagName === "IMG") {
        try {
          const c = document.createElement("canvas");
          c.width = Math.ceil(r.width * 2);
          c.height = Math.ceil(r.height * 2);
          c.getContext("2d").drawImage(el, 0, 0, c.width, c.height);
          out.push(
            `<image x="${r.x}" y="${r.y}" width="${r.width}" height="${r.height}" href="${c.toDataURL()}"/>`,
          );
        } catch {}
      } else if (["INPUT", "SELECT"].includes(el.tagName)) {
        let text =
          el.tagName === "SELECT"
            ? el.options[el.selectedIndex]?.text
            : el.value || el.placeholder;
        if (el.type === "checkbox") {
          if (el.checked)
            out.push(
              `<path d="M${r.left + 4} ${r.top + r.height / 2}l4 4 8-9" fill="none" stroke="#087F80" stroke-width="2"/>`,
            );
        } else if (text) {
          out.push(
            `<text x="${r.x + parseFloat(s.paddingLeft)}" y="${r.y + r.height / 2 + parseFloat(s.fontSize) * 0.35}" font-family="IBM Plex Sans" font-size="${s.fontSize}" fill="${s.color}">${esc(text)}</text>`,
          );
        }
      } else {
        for (const child of el.childNodes) {
          if (child.nodeType === 1) await walk(child);
          else if (child.nodeType === 3 && child.textContent.trim()) {
            const text = child.textContent,
              lines = [];
            for (let i = 0; i < text.length; i++) {
              const range = document.createRange();
              range.setStart(child, i);
              range.setEnd(child, i + 1);
              const box = range.getBoundingClientRect();
              if (!box.width) continue;
              const last = lines[lines.length - 1];
              if (last && Math.abs(last.y - box.y) < 1) last.text += text[i];
              else
                lines.push({
                  x: box.x,
                  y: box.y,
                  height: box.height,
                  text: text[i],
                });
            }
            for (const l of lines)
              out.push(
                `<text x="${num(l.x)}" y="${num(l.y + l.height * 0.8)}" font-family="IBM Plex Sans" font-size="${s.fontSize}" font-weight="${s.fontWeight}" letter-spacing="${s.letterSpacing === "normal" ? 0 : s.letterSpacing}" fill="${s.color}">${esc(s.textTransform === "uppercase" ? l.text.toUpperCase() : l.text)}</text>`,
              );
          }
        }
      }
      if (clipped) out.push("</g>");
      out.push("</g>");
    }
    await walk(document.body);
    return `<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="${innerWidth}" height="${document.documentElement.scrollHeight}" viewBox="0 0 ${innerWidth} ${document.documentElement.scrollHeight}"><title>ThyroCare dashboard design — sample records</title><defs>${defs.join("")}</defs>${out.join("")}</svg>`;
  });
}
module.exports = exportSvg;
