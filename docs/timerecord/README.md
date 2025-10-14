# Zeiterfassung für Jedsy

Dieses Verzeichnis enthält die strukturierte Zeiterfassung und Dokumentation für Jedsy-Projekte.

## Verzeichnisstruktur

```text
timerecord/
+-- month/          # Monatliche Berichte im Format YYYYMM.md (z.B. 202509.md)
+-- daily/          # Tägliche Protokolle im Format YYYYMMDD.md (z.B. 20251014.md)
+-- output/         # Generierte PDF-Dateien
```

## Verwendung

Alle Zeiterfassungsoperationen werden über das Makefile im übergeordneten Verzeichnis gesteuert:

```bash
# Erstelle ein neues Tagesprotokoll
make new-daily

# Erstelle ein PDF aus einem Tagesprotokoll
make daily

# Erstelle PDFs für alle Monatsberichte
make months

# Erstelle ein Git-Log für einen bestimmten Monat
make git-log
```

Weitere Informationen finden Sie in der Datei `../markdown_latex_workflow.md` oder im generierten PDF im output-Verzeichnis.