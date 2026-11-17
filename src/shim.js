// What only the browser knows, for Book.bend: its clock. Main.bend asks
// (bend-frp's Host effect) with the slots' starts, minutes since 1970 in UTC,
// space-separated, and gets back one line:
//
//   NOW H12 ZONE OFF...
//
// the time now in seconds, 1 if the visitor's clock shows 12-hour time (else
// 0), their zone's name, and for each slot how many minutes their clock is
// then ahead of UTC, plus 1440 (so it is never negative). Everything else,
// the dates, the grouping and the email, is Bend.

(globalThis.bendFrp ??= {}).clock = (arg) => {
  const o = new Intl.DateTimeFormat(undefined, { hour: "numeric" }).resolvedOptions();
  const h12 = o.hourCycle ? o.hourCycle === "h12" || o.hourCycle === "h11" : !!o.hour12;
  const zone = (o.timeZone || "").replace(/[^A-Za-z0-9_+\-\/]/g, "") || "local";
  const offs = arg.split(" ").filter(Boolean)
    .map((m) => 1440 - new Date(Number(m) * 60000).getTimezoneOffset());
  return [Math.floor(Date.now() / 1000), h12 ? 1 : 0, zone, ...offs].join(" ");
};
