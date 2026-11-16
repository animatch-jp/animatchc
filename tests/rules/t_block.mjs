import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { readFileSync } from 'fs';
import { doc, setDoc, Timestamp, serverTimestamp } from 'firebase/firestore';
const env = await initializeTestEnvironment({ projectId: 'demo-am', firestore: { rules: readFileSync('firestore.rules','utf8'), host:'127.0.0.1', port:8080 }});
await env.clearFirestore();
const db = u => env.authenticatedContext(u).firestore();
let ok=0, ng=0; const t = async (name, pr, expectOk) => { try { await (expectOk?assertSucceeds:assertFails)(pr); ok++; console.log('OK ', name);} catch(e){ ng++; console.log('NG ', name, e.message.slice(0,160));} };
await env.withSecurityRulesDisabled(async c => { const f=c.firestore();
  for (const [u,n] of [['A','みけ'],['B','ぽち'],['C','たま']]) {
    await setDoc(doc(f,'users',u), {name:n});
    await setDoc(doc(f,`users/${u}/private/birth`), {birthDate:'1990-01-01'});
  }
  await setDoc(doc(f,'blocks/A/blocked/B'), {createdAt: Timestamp.now()}); // A が B をブロック
  await setDoc(doc(f,'petBrags/pa'), {uid:'A'});
  await setDoc(doc(f,'questions/qa'), {uid:'A', name:'みけ', title:'t', body:'b'});
  await setDoc(doc(f,'events/ea'), {organizerUid:'A', organizerName:'みけ', title:'t'});
  await setDoc(doc(f,'volunteers/va'), {orgId:'A', title:'t'});
});
const n = u => ({type:'like', senderUid:u, title:'t', desc:'d', read:false});
await t('Bは、Aに通知を送れない', setDoc(doc(db('B'),'notifications/A/items/n1'), n('B')), false);
await t('Cは、Aに通知を送れる', setDoc(doc(db('C'),'notifications/A/items/n2'), n('C')), true);
await t('Aは、Bに通知を送れる（ブロックした側から）', setDoc(doc(db('A'),'notifications/B/items/n3'), n('A')), true);
await t('Bは、Aのペット自慢にコメントできない', setDoc(doc(db('B'),'petBrags/pa/comments/c1'), {uid:'B', name:'ぽち', text:'x'}), false);
await t('Cは、Aのペット自慢にコメントできる', setDoc(doc(db('C'),'petBrags/pa/comments/c2'), {uid:'C', name:'たま', text:'x'}), true);
await t('Bは、Aのペット自慢に投票できない', setDoc(doc(db('B'),'petBrags/pa/voters/B'), {voteType:'kawaii'}), false);
await t('Cは、Aのペット自慢に投票できる', setDoc(doc(db('C'),'petBrags/pa/voters/C'), {voteType:'kawaii'}), true);
await t('Bは、Aの質問に回答できない', setDoc(doc(db('B'),'questions/qa/answers/a1'), {uid:'B', name:'ぽち', text:'x', helpfulBy:[]}), false);
await t('Cは、Aの質問に回答できる', setDoc(doc(db('C'),'questions/qa/answers/a2'), {uid:'C', name:'たま', text:'x', helpfulBy:[]}), true);
await t('Bは、Aのイベントに参加できない', setDoc(doc(db('B'),'events/ea/participants/B'), {uid:'B'}), false);
await t('Cは、Aのイベントに参加できる', setDoc(doc(db('C'),'events/ea/participants/C'), {uid:'C'}), true);
await t('Bは、Aの募集に「興味あります」できない', setDoc(doc(db('B'),'volunteers/va/interested/B'), {uid:'B', name:'ぽち', createdAt: serverTimestamp()}), false);
await t('Cは、Aの募集に「興味あります」できる', setDoc(doc(db('C'),'volunteers/va/interested/C'), {uid:'C', name:'たま', createdAt: serverTimestamp()}), true);
await t('Bは、Aとの1対1のチャットを作れない', setDoc(doc(db('B'),'chats/A_B'), {participants:['A','B'], lastMessage:'x', lastSenderId:'B'}), false);
console.log(`合計 OK ${ok} / NG ${ng}`);
await env.cleanup(); process.exit(ng?1:0);
