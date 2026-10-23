import assert from 'node:assert/strict';
import { compareRoster, nextAppointment } from '../Backend/Dashboard/lib/care-roster.ts';
const patients = [{id:'a',name:'Alex'},{id:'b',name:'Bea'},{id:'c',name:'Chris'},{id:'d',name:'Dana'}];
const dates = {a:{appointment:'2026-11-02T15:00:00Z'},b:{appointment:'2026-11-01T16:00:00Z'},c:{lab:'2026-10-22'},d:{}};
assert.deepEqual([...patients].sort((a,b)=>compareRoster(a,b,dates,'appointment')).map(p=>p.id), ['b','a','c','d']);
assert.equal(nextAppointment([{fields:{status:'cancelled',startsAt:'2026-11-01T00:00:00Z'}},{fields:{status:'confirmed',startsAt:'2020-01-01T00:00:00Z'}},{fields:{status:'confirmed',startsAt:'2026-11-02T10:00:00-05:00'}},{fields:{status:'confirmed',startsAt:'2026-11-02T14:00:00Z'}}],Date.parse('2026-10-23')), '2026-11-02T14:00:00Z');
assert.equal(compareRoster({id:'a',name:'Same'},{id:'b',name:'Same'}, {},'appointment'), -1);
assert.ok(compareRoster(patients[0],patients[1],{a:{lab:'2026-01-01'},b:{}},'oldest') < 0);
console.log('Roster checks passed: upcoming order, cancelled/past exclusion, offsets, missing dates, stable ties.');
