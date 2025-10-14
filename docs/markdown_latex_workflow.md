# Arbeiten mit Markdown und LaTeX bei Jedsy

Diese Dokumentation erklärt, wie Sie bei Jedsy mit Markdown und LaTeX für die Dokumentation arbeiten können, um Word zu vermeiden.

## Überblick

Bei dieser Workflow-Methode:

1. Schreiben Sie Ihre Dokumente in Markdown (einfache Textdateien mit `.md`-Endung)
2. Konvertieren Sie diese mit pandoc und LaTeX-Vorlagen in professionelle PDFs
3. Genießen Sie die Vorteile der Versionskontrolle, einfachen Bearbeitung und konsistenten Formatierung

## Voraussetzungen

- **MacTeX**: Die vollständige LaTeX-Distribution für macOS (bereits installiert)
- **Pandoc**: Ein universelles Dokumentenkonvertierungswerkzeug (bereits installiert)
- **Ein Texteditor**: VS Code wird empfohlen (bereits installiert)

## Verzeichnisstruktur

Die Zeiterfassung ist wie folgt organisiert:

```
docs/
+-- timerecord/         # Hauptverzeichnis für die Zeiterfassung
|   +-- month/          # Monatliche Berichte
|   |   +-- YYYYMM.md   # z.B. 202509.md für September 2025
|   +-- daily/          # Tägliche Protokolle
|   |   +-- template.md # Vorlage für tägliche Protokolle
|   |   +-- YYYYMMDD.md # z.B. 20251014.md für 14. Oktober 2025
|   +-- output/         # Generierte PDF-Dateien
+-- templates/          # LaTeX-Vorlagen
```

## Verfügbare Vorlagen

Es wurden zwei LaTeX-Vorlagen erstellt:

1. `jedsy-template.tex` - Eine einfache Vorlage für Berichte
2. `jedsy-report-template.tex` - Eine erweiterte Vorlage mit Titelseite und Inhaltsverzeichnis

## Verfügbare Befehle im Makefile

Es wurde ein Makefile erstellt, um den Prozess zu automatisieren:

```bash
# Erstellt alle PDFs
make

# Erstellt PDFs für alle Monatsberichte
make months

# Erstellt PDF für einen bestimmten Monat
make current-month

# Erstellt ein PDF für einen täglichen Bericht
make daily

# Erstellt ein neues Tagesprotokoll basierend auf der Vorlage
make new-daily

# Erstellt das PDF für die Workflow-Dokumentation
make workflow

# Erstellt ein Git-Log für einen bestimmten Monat
make git-log

# Zeigt alle verfügbaren Befehle an
make help
```

## Workflow-Empfehlungen

### Tägliche Berichte

1. Erstellen Sie ein neues Tagesprotokoll mit `make new-daily` und geben Sie das Datum ein
2. Bearbeiten Sie die erstellte Markdown-Datei im Verzeichnis `timerecord/daily/`
3. Führen Sie `make daily` aus und geben Sie das Datum ein, um ein PDF zu erstellen
4. Das PDF wird im Verzeichnis `timerecord/output/` gespeichert

### Monatliche Berichte

1. Führen Sie `make git-log` aus, um Git-Commits für einen Monat zu sammeln
2. Erstellen Sie eine neue Markdown-Datei im Verzeichnis `timerecord/month/` mit dem Namen `YYYYMM.md`
3. Führen Sie `make current-month` aus und geben Sie Jahr-Monat ein, um ein PDF zu erstellen
4. Oder führen Sie einfach `make months` aus, um PDFs für alle vorhandenen Monatsberichte zu erstellen

### Anpassung der Vorlagen

Sie können die LaTeX-Vorlagen nach Bedarf anpassen:

1. Öffnen Sie die `.tex`-Datei in einem Texteditor
2. Passen Sie Farben, Kopf-/Fußzeilen oder andere Elemente an
3. Wenn Sie ein echtes Jedsy-Logo haben, ersetzen Sie den Platzhalter in der Vorlage

## Vorteile dieses Ansatzes

1. **Versionskontrolle**: Markdown-Dateien lassen sich hervorragend mit Git verwalten
2. **Einfache Bearbeitung**: Markdown ist leicht zu lernen und zu schreiben
3. **Konsistente Formatierung**: LaTeX sorgt für ein professionelles Layout
4. **Automatisierung**: Mit Pandoc und Makefiles lässt sich der Prozess automatisieren
5. **Plattformunabhängigkeit**: Funktioniert auf allen Betriebssystemen

## Markdown-Grundlagen

Markdown ist eine einfache Auszeichnungssprache:

```markdown
# Überschrift 1
## Überschrift 2
### Überschrift 3

**Fett** oder __Fett__
*Kursiv* oder _Kursiv_

- Listenpunkt 1
- Listenpunkt 2
  - Unterpunkt 2.1

1. Nummerierter Punkt 1
2. Nummerierter Punkt 2

[Link-Text](URL)

![Bild-Alt-Text](Bild-URL)

| Spalte 1 | Spalte 2 |
|----------|----------|
| Zelle 1  | Zelle 2  |
```

## Weiterführende Ressourcen

- [Pandoc-Dokumentation](https://pandoc.org/MANUAL.html)
- [Markdown-Anleitung](https://www.markdownguide.org/)
- [LaTeX-Dokumentation](https://www.latex-project.org/help/documentation/)