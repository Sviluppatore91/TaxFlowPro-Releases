# Regole d'Oro di Sviluppo (TaxFlowPro)

Le seguenti regole devono essere applicate sistematicamente a tutte le interazioni, modifiche al codice e refactoring del progetto:

1. **Test-Driven Development (TDD):**
   - Prima si scrivono i test, poi il codice vero e proprio.
   - Creare e mantenere **Unit Test** per le funzionalità dei singoli componenti.
   - Creare e mantenere **Integration Test** per i flussi di operazioni.
   - Aggiungere **Test di Non Regressione** per evitare di introdurre bug su codice già esistente quando si integrano nuove funzionalità.
   - Lo sviluppo può andare avanti **solo se i test passano**.

2. **Gestione del Codice e Componenti:**
   - Creare componenti **snelli**, niente boilerplate.
   - Sviluppare componenti **riutilizzabili**.
   - Evitare logica e codice duplicato: estrarre classi/componenti di business condivisi ove necessario.

3. **Architettura e Pattern:**
   - La logica di calcolo deve essere rigorosamente separata dalla presentazione dei dati. La UI si occupa *solo* di mostrare i dati calcolati.
   - Attenzione massima ai tipi numerici (usare `int`, `double`, e classi dedicate ai calcoli fiscali in modo rigoroso, evitando conversioni implicite dannose o arrotondamenti errati).

4. **Refactoring e Versioning:**
   - **Mai fare "Big Bang" refactoring**. Fare refactoring mirati e progressivi dei singoli componenti, seguiti immediatamente da test, e procedere solo se tutto è ok.
   - Preferire piccoli **commit mirati** su git piuttosto che push massivi di migliaia di righe.

5. **User Experience & UI:**
   - UI moderna, snella e con focus assoluto sulla user experience.
