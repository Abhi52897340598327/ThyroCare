export type RosterDates = { appointment?: string; lab?: string };
export type RosterSort = "appointment" | "lab" | "oldest" | "name";
export function compareRoster(a: { id: string; name: string }, b: { id: string; name: string }, dates: Record<string, RosterDates>, sort: string): number {
    const x = dates[a.id] ?? {}, y = dates[b.id] ?? {};
    const stamp = (s: string | undefined) => s && Number.isFinite(Date.parse(s)) ? Date.parse(s) : undefined;
    function compareDate(left: number | undefined, right: number | undefined, direction: number) {
        if (left === undefined && right === undefined) return 0;
        if (left === undefined) return 1;
        if (right === undefined) return -1;
        return (left - right) * direction;
    }
    let result = 0;
    if (sort === "appointment") result = compareDate(stamp(x.appointment), stamp(y.appointment), 1);
    if (sort !== "name" && result === 0) result = compareDate(stamp(x.lab), stamp(y.lab), sort === "oldest" ? 1 : -1);
    return result || a.name.localeCompare(b.name) || a.id.localeCompare(b.id);
}
export function nextAppointment(records: { fields: Record<string, string> }[], now: number): string | undefined {
    return records.filter(r => r.fields.status === "confirmed" && Date.parse(r.fields.startsAt) > now)
        .sort((a,b) => Date.parse(a.fields.startsAt) - Date.parse(b.fields.startsAt))[0]?.fields.startsAt;
}
