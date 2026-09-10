# Diario — contesto del progetto

Questo è un diario personale per Android, pensato per chi rimugina e ripensa
molto alle decisioni. Non è solo un diario: ha anche un flusso guidato per
prendere decisioni e "restarci sopra" senza rimuginare all'infinito.

## Cos'è, in breve
- App HTML/JS a file singolo (`www/index.html`), impacchettata con **Capacitor**
  per Android. Nessun framework (no React/Vue): vanilla JS, funzioni che
  ri-renderizzano `innerHTML`.
- **Tutto locale**: nessun server, nessun cloud. Dati in `localStorage`,
  cifrati con **AES-GCM 256 bit**; la chiave si deriva dal **PIN a 4 cifre**
  con **PBKDF2** (200.000 iterazioni). Il PIN non viene mai salvato in chiaro.
- Tema visivo "taccuino/Moleskine": scuro di default, con un tema chiaro
  alternabile. Font serif per i contenuti, sans-serif maiuscoletto per le
  etichette (date, badge).

## Le due sezioni principali
1. **Pensieri** (tab "Pensieri"): diario libero. Streak di giorni consecutivi,
   conteggio parole, uno spunto di scrittura diverso ogni giorno (14 in
   rotazione), preferiti con stella.
2. **Decisioni** (tab "Decisioni"): il pezzo originale del progetto.
   - Flusso guidato a 5 passi (NON pro/contro — è stato scartato apposta
     perché il pro/contro fomenta il rimuginio): domanda → istinto di pancia
     → il freno principale → rimpianto a un anno → reversibilità.
   - Alla chiusura: la decisione in una frase + un motivo scritto per il
     "te di domani" che vorrà riaprirla.
   - **Cancello anti-rimuginio**: riaprendo una decisione già chiusa, non si
     modifica nulla — si vede solo cosa fu deciso e perché, con un pulsante
     opzionale "Vedi come ci sei arrivato" che mostra il percorso completo
     (istinto/freno/rimpianto), tenuto chiuso di default per non invitare a
     rimuginare. Poi una sola domanda: è successo un fatto nuovo e concreto?
     Se sì, si riapre (con quel fatto registrato); se no, si conta come
     "rimuginio lasciato andare" — è una statistica positiva, non una sconfitta.

## Funzioni trasversali
- Swipe a sinistra per eliminare (pensieri e decisioni), con conferma in
  finestra di dialogo **in tema** (mai popup di sistema Android).
- Backup: **esporta testo** (.txt leggibile) ed **esporta cifrato completo**
  (pensieri + decisioni, formato interno `{app:"Diario",v:3,salt,blob}` dove
  `blob` è la stringa cifrata JSON `{iv,ct}` — NON scomporre/ricomporre con
  JSON.parse/stringify, causava un bug serio, vedi sotto).
- Import: il PIN si inserisce col **tastierino a 4 cifre dell'app**, MAI con
  un campo di testo/tastiera di sistema (causava un bug, vedi sotto).
- Cambio PIN: richiede il PIN attuale, poi ricifra tutto con la nuova chiave.

## Bug già risolti — utile saperlo per non reintrodurli
1. **Popup nativi Android** (confirm/prompt/alert) rompevano l'estetica →
   sostituiti con `appModal()`, un sistema di dialoghi in tema.
2. **Export che non salvava nulla**: le API browser (`showSaveFilePicker`,
   `navigator.share`) non funzionano bene dentro la webview Capacitor.
   Soluzione: uso i plugin nativi **Filesystem** e **Share** di Capacitor
   quando `window.Capacitor.isNativePlatform()` è vero.
3. **`FILE_NOTCREATED`** scrivendo in `Directory.DOCUMENTS`: quella cartella
   richiede permessi speciali su molte versioni Android. Soluzione: scrivo in
   `CACHE`/`EXTERNAL` (sempre scrivibili, condivisibili con altre app tramite
   FileProvider), con fallback a cascata su più cartelle, e **verifico
   rileggendo il file** che non sia vuoto prima di offrirlo in condivisione.
4. **"File vuoto" condividendo su WhatsApp**: scrivevo nella cartella dati
   privata dell'app, illeggibile da altre app. Risolto passando a
   CACHE/EXTERNAL (vedi sopra).
5. **Falso "PIN errato" in import** — il bug più insidioso, causa duplice:
   a) il blob cifrato veniva scomposto/ricomposto con JSON.parse/stringify
      invece di restare stringa intatta → possibile corruzione;
   b) **causa vera e definitiva**: l'auto-blocco dell'app (che scatta quando
      va in background) si attivava mentre l'utente sceglieva il file da
      importare (il selettore file mette l'app in background), azzerando
      `cryptoKey` PRIMA del salvataggio finale. La decifratura del backup
      riusciva (usa la sua chiave locale), ma `persistEntries()` falliva
      perché la chiave di sessione globale era sparita nel frattempo.
      Soluzione: flag `suspendAutoLock` attivato prima di aprire il file
      picker o il foglio Condividi, con tolleranza di 2s sul ritorno.
6. **Icona Android generica (logo Capacitor)**: `capacitor-assets generate`
   non aggiornava sempre il foreground dell'icona adattiva. Soluzione:
   icona applicata a mano nelle cartelle `mipmap-*dpi`, disegnata centrata
   e compatta per stare nella "safe zone" del ritaglio adattivo (un soggetto
   largo e orizzontale veniva tagliato/invisibile).
7. **PowerShell blocca npm/npx** (`ExecutionPolicy`): l'utente deve usare
   `cmd` (Prompt dei comandi), non PowerShell, oppure lanciare
   `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.
8. **Build che non si aggiornava**: serve sempre `npx cap sync` PRIMA di
   ricompilare in Android Studio, e un **Clean Project** prima di
   **Generate APKs** — altrimenti Android Studio riusa la cache vecchia.

## Persona e stile richiesto dall'utente
- L'utente (Paolo) tende a rimuginare molto sulle decisioni: da qui il senso
  di tutta la sezione Decisioni. Il tono dell'app è pensato per essere un
  argine gentile ma fermo contro il rimuginio, mai giudicante.
- Estetica: "elegante ma non appariscente", ispirata a un taccuino Moleskine.
  Font unificati (niente sans-serif MAIUSCOLO nei pulsanti — è stato corretto
  una volta, non reintrodurlo). Layout responsive (telefono/tablet).
- L'utente lavora spesso da PC Windows con Android Studio; a volte da
  telefono. Preferisce risposte operative, passo-passo, con comandi esatti
  da copiare. Ama capire la causa reale di un problema, non solo la patch.

## Struttura dei file in questa cartella
- `Diario-ultima-versione.html` — il codice sorgente più recente e completo,
  identico a `diario-capacitor/www/index.html`.
- `diario-capacitor/` — il progetto Capacitor completo (package.json,
  capacitor.config.json, www/, setup.bat, icona già pronta in mipmap-*).
- `versioni-precedenti/` — le versioni v1…v18 in ordine, utili solo come
  archivio storico se serve confrontare o recuperare qualcosa; NON lavorarci
  sopra, usa sempre `Diario-ultima-versione.html`/`diario-capacitor/www/index.html`.

## Cosa NON è ancora stato fatto (idee sospese)
- Note vocali (tab "Voce"): discusso ma accantonato per ora — richiederebbe
  salvare audio come file cifrati (non in localStorage, troppo piccolo) via
  plugin Filesystem. Riprendere da qui se l'utente lo richiede.
- Sblocco con impronta: implementato in una versione (v16) ma poi scartato
  su richiesta esplicita dell'utente. Non reintrodurlo senza che lo chieda.
- Versione desktop (Electron): esiste un progetto separato
  (`diario-desktop`, non incluso qui) ma l'utente ha chiesto di NON
  toccarlo/ricompilarlo finché non lo richiede di nuovo.

## Comandi tipici per build (Windows, cmd non PowerShell)
```
npm install                      (solo se cambiano le dipendenze)
npx cap sync                     (SEMPRE dopo aver modificato www/index.html)
```
Poi in Android Studio: Build → Clean Project → Build → Generate App Bundles
or APKs → Generate APKs. L'APK esce in
`android\app\build\outputs\apk\debug\app-debug.apk`.
