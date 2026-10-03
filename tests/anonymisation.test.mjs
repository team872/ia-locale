// Tests de l'anonymisation — lancer : node tests/anonymisation.test.mjs
// Ils lisent le code DANS app/IA-Locale.html : c'est lui qui est livré.
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const html = readFileSync(new URL('../app/IA-Locale.html', import.meta.url), 'utf8');
const debut = html.indexOf('/* ============================================================\n   ANONYMISATION');
const fin = html.indexOf('/** Rétablit les vrais noms');
const finR = html.indexOf('\n}\n', fin) + 3;
assert.ok(debut > 0 && fin > debut, 'module d\'anonymisation introuvable dans IA-Locale.html');
const { anonymiserTextes, reidentifier } = new Function(html.slice(debut, finR) + '\nreturn { anonymiserTextes, reidentifier };')();

const anon = (t, o) => anonymiserTextes([t], o).textes[0];
let ok = 0;
function cas(nom, f) { f(); ok++; }

cas('prénoms accentués (bug de la 1.1)', () => {
  assert.equal(anon('Chloé et Zoé ont rendu leur copie.'), 'Élève A et Élève B ont rendu leur copie.');
  assert.equal(anon('Élise a oublié son cahier, Émile aussi.'), 'Élève A a oublié son cahier, Élève B aussi.');
});
cas('prénoms courants absents de la 1.1', () => {
  assert.equal(anon('Thomas, Marie, Nicolas et Kevin sont absents.'), 'Élève A, Élève B, Élève C et Élève D sont absents.');
});
cas('nom de famille après le prénom', () => {
  assert.equal(anon('Léa Martin a eu 8/20.'), 'Élève A a eu 8/20.');
});
cas('NOM en capitales avant le prénom', () => {
  assert.equal(anon('MARTIN Léa : absente.'), 'Élève A : absente.');
});
cas('nom seul déjà vu ailleurs, même avant', () => {
  const r = anonymiserTextes(['Martin a progressé.', 'Bilan de Léa Martin.']).textes;
  assert.deepEqual(r, ['Élève A a progressé.', 'Bilan de Élève A.']);
});
cas('prénoms composés', () => {
  assert.equal(anon('Jean-Pierre et Marie-Claire'), 'Élève A et Élève B');
});
cas('personnalités jamais masquées', () => {
  assert.equal(anon('Prépare un cours sur Victor Hugo et Rose Valland.'), 'Prépare un cours sur Victor Hugo et Rose Valland.');
  assert.equal(anon('Louis XIV et Henri IV'), 'Louis XIV et Henri IV');
});
cas('mot ambigu en début de phrase', () => {
  assert.equal(anon('Rose est une couleur. Je parle à Rose.'), 'Rose est une couleur. Je parle à Élève A.');
});
cas('civilité : adultes', () => {
  assert.equal(anon('Mme Dupont a appelé pour Lucas.'), 'Mme Personne A a appelé pour Élève A.');
});
cas('même élève, même libellé dans toute la conversation (bug de la 1.1)', () => {
  const r = anonymiserTextes(['Feedback pour Chloé', 'Et pour Hugo ?', 'Reprends Chloé.']).textes;
  assert.deepEqual(r, ['Feedback pour Élève A', 'Et pour Élève B ?', 'Reprends Élève A.']);
});
cas('liste personnelle et liste « jamais »', () => {
  assert.equal(anon('Kenjiro et Hugo', { prenoms: ['Kenjiro'], jamais: ['Hugo'] }), 'Élève A et Hugo');
});
cas('rien à masquer', () => {
  assert.equal(anon('Propose 3 activités sur les fractions en CM1.'), 'Propose 3 activités sur les fractions en CM1.');
});
cas('réidentification à l\'affichage', () => {
  const { correspondances } = anonymiserTextes(['Chloé et Léa Martin']);
  assert.equal(reidentifier('Élève A progresse ; Élève B aussi.', correspondances), 'Chloé progresse ; Léa Martin aussi.');
});
console.log(`${ok} cas d'anonymisation : tous verts`);
