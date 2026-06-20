'use strict';

const readline = require('node:readline/promises');
const {stdin, stdout} = require('node:process');
const {applicationDefault, initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {FieldValue, getFirestore} = require('firebase-admin/firestore');

const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || 'bebezen-412c1';

async function question(terminal, label, fallback = '') {
  const suffix = fallback ? ` [${fallback}]` : '';
  const value = (await terminal.question(`${label}${suffix}: `)).trim();
  return value || fallback;
}

async function passwordQuestion(label) {
  if (!stdin.isTTY || typeof stdin.setRawMode !== 'function') {
    const terminal = readline.createInterface({input: stdin, output: stdout});
    const value = await terminal.question(`${label}: `);
    terminal.close();
    return value;
  }

  stdout.write(`${label}: `);
  stdin.setRawMode(true);
  stdin.resume();
  stdin.setEncoding('utf8');
  let value = '';

  return new Promise((resolve, reject) => {
    function cleanup() {
      stdin.setRawMode(false);
      stdin.pause();
      stdin.removeListener('data', onData);
      stdout.write('\n');
    }

    function onData(character) {
      if (character === '\u0003') {
        cleanup();
        reject(new Error('Création annulée.'));
        return;
      }
      if (character === '\r' || character === '\n') {
        cleanup();
        resolve(value);
        return;
      }
      if (character === '\u007f' || character === '\b') {
        if (value.length > 0) {
          value = value.slice(0, -1);
          stdout.write('\b \b');
        }
        return;
      }
      if (character >= ' ') {
        value += character;
        stdout.write('*');
      }
    }

    stdin.on('data', onData);
  });
}

async function main() {
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    throw new Error(
        'GOOGLE_APPLICATION_CREDENTIALS doit pointer vers le fichier JSON ' +
        'du compte de service Firebase.',
    );
  }

  const terminal = readline.createInterface({input: stdin, output: stdout});
  const email = await question(terminal, 'Email administrateur');
  const name = await question(terminal, 'Nom complet', 'Administrateur Bebezen');
  terminal.close();

  if (!email.includes('@')) throw new Error('Adresse email invalide.');
  initializeApp({credential: applicationDefault(), projectId: PROJECT_ID});
  const auth = getAuth();
  let user;
  let created = false;
  try {
    const existing = await auth.getUserByEmail(email);
    user = await auth.updateUser(existing.uid, {
      displayName: name,
      disabled: false,
    });
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    const password = await passwordQuestion(
        'Mot de passe (minimum 8 caractères, masqué)',
    );
    if (password.length < 8) {
      throw new Error('Le mot de passe doit contenir au moins 8 caractères.');
    }
    user = await auth.createUser({
      email,
      password,
      displayName: name,
      emailVerified: false,
      disabled: false,
    });
    created = true;
  }

  await getFirestore().collection('admins').doc(user.uid).set({
    active: true,
    name,
    email: user.email,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});

  stdout.write(
      `\nAdministrateur ${created ? 'créé' : 'activé'} avec succès.\n` +
      `Projet : ${PROJECT_ID}\nEmail : ${email}\nUID : ${user.uid}\n`,
  );
}

main().catch((error) => {
  process.stderr.write(`\nErreur : ${error.message}\n`);
  process.exitCode = 1;
});
