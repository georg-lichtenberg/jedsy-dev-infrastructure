# Makefile für die Erstellung von LaTeX/PDF Dokumenten aus Markdown

# Variablen
DOCS_DIR = /Users/georg/projects/jedsy/jedsy-dev-infrastructure/docs
TIMERECORD_DIR = $(DOCS_DIR)/timerecord
MONTH_DIR = $(TIMERECORD_DIR)/month
DAILY_DIR = $(TIMERECORD_DIR)/daily
OUTPUT_DIR = $(TIMERECORD_DIR)/output
TEMPLATE_DIR = $(DOCS_DIR)/templates
PANDOC = pandoc
TEMPLATE = $(TEMPLATE_DIR)/jedsy-report-template.tex

# Erstelle Ausgabeverzeichnis falls es nicht existiert
$(shell mkdir -p $(OUTPUT_DIR))

# Liste aller Monatsdateien ermitteln (nur .md Dateien)
MONTH_FILES = $(wildcard $(MONTH_DIR)/*.md)
MONTH_PDFS = $(patsubst $(MONTH_DIR)/%.md,$(OUTPUT_DIR)/%.pdf,$(MONTH_FILES))

# Standard-Ziel
all: months workflow

# Alle Monatsberichte erstellen
months: $(MONTH_PDFS)

# Regel für die Erstellung eines Monats-PDF aus einer .md-Datei
$(OUTPUT_DIR)/%.pdf: $(MONTH_DIR)/%.md
	@echo "Erstelle PDF für Monat $*"
	@$(DOCS_DIR)/scripts/better_pdf.sh $< $@

# Erstellt das PDF für den aktuellen Monat (Jahr und Monat werden abgefragt)
current-month:
	@read -p "Jahr-Monat (Format YYYYMM, z.B. 202510 für Oktober 2025): " yearmonth; \
	if [ ! -f "$(MONTH_DIR)/$$yearmonth.md" ]; then \
		echo "Fehler: Die Datei $(MONTH_DIR)/$$yearmonth.md existiert nicht."; \
		exit 1; \
	fi; \
	$(DOCS_DIR)/scripts/better_pdf.sh $(MONTH_DIR)/$$yearmonth.md $(OUTPUT_DIR)/$$yearmonth.pdf

# Erstellt ein tägliches Berichts-PDF
daily:
	@read -p "Datum (Format YYYYMMDD, z.B. 20251014 für 14. Oktober 2025): " date; \
	if [ ! -f "$(DAILY_DIR)/$$date.md" ]; then \
		echo "Warnung: Die Datei $(DAILY_DIR)/$$date.md existiert nicht."; \
		echo "Möchten Sie eine neue Datei basierend auf der Vorlage erstellen? (j/n) "; \
		read answer; \
		if [ "$$answer" = "j" ]; then \
			cp $(DAILY_DIR)/template.md $(DAILY_DIR)/$$date.md; \
			echo "Tagesprotokoll-Vorlage nach $(DAILY_DIR)/$$date.md kopiert."; \
			echo "Bitte füllen Sie die Datei aus und führen Sie diesen Befehl erneut aus."; \
		fi; \
		exit 1; \
	fi; \
	$(DOCS_DIR)/scripts/better_pdf.sh $(DAILY_DIR)/$$date.md $(OUTPUT_DIR)/$$date.pdf

# Neues Tagesprotokoll erstellen
new-daily:
	@read -p "Datum (Format YYYYMMDD, z.B. 20251014 für 14. Oktober 2025): " date; \
	if [ -f "$(DAILY_DIR)/$$date.md" ]; then \
		echo "Die Datei $(DAILY_DIR)/$$date.md existiert bereits."; \
		echo "Möchten Sie sie überschreiben? (j/n) "; \
		read answer; \
		if [ "$$answer" != "j" ]; then \
			exit 1; \
		fi; \
	fi; \
	cp $(DAILY_DIR)/template.md $(DAILY_DIR)/$$date.md && \
	echo "✓ Neues Tagesprotokoll erstellt: $(DAILY_DIR)/$$date.md"

# Neues Tagesprotokoll für heute erstellen
today:
	@current_date=`date "+%Y%m%d"`; \
	if [ -f "$(DAILY_DIR)/$$current_date.md" ]; then \
		echo "Die Datei $(DAILY_DIR)/$$current_date.md existiert bereits."; \
		echo "Möchten Sie sie überschreiben? (j/n) "; \
		read answer; \
		if [ "$$answer" != "j" ]; then \
			exit 1; \
		fi; \
	fi; \
	cp $(DAILY_DIR)/template.md $(DAILY_DIR)/$$current_date.md; \
	today_date=`date "+%d.%m.%Y"`; \
	sed -i '' "s/\[Datum eintragen\]/$$today_date/" $(DAILY_DIR)/$$current_date.md; \
	echo "✓ Neues Tagesprotokoll für heute ($$today_date) erstellt: $(DAILY_DIR)/$$current_date.md"

# Erstellt das PDF für die Workflow-Dokumentation
workflow:
	$(DOCS_DIR)/scripts/better_pdf.sh $(DOCS_DIR)/markdown_latex_workflow.md $(OUTPUT_DIR)/markdown_latex_workflow.pdf

# Installiert die benötigten LaTeX-Pakete
install-latex-deps:
	sudo tlmgr install lastpage titlesec babel-german microtype booktabs framed

# Hilfe anzeigen
help:
	@echo "Verfügbare Befehle:"
	@echo "  make                - Erstellt alle PDFs"
	@echo "  make months         - Erstellt PDFs für alle Monatsberichte"
	@echo "  make current-month  - Erstellt PDF für einen bestimmten Monat (fragt nach Jahr-Monat)"
	@echo "  make daily          - Erstellt ein PDF für einen täglichen Bericht (fragt nach Datum)"
	@echo "  make new-daily      - Erstellt ein neues Tagesprotokoll basierend auf der Vorlage"
	@echo "  make today          - Erstellt ein neues Tagesprotokoll für den aktuellen Tag"
	@echo "  make workflow       - Erstellt das PDF für die Markdown/LaTeX Workflow-Dokumentation"
	@echo "  make install-latex-deps - Installiert die benötigten LaTeX-Pakete"
	@echo "  make create-month   - Erstellt automatisch MD- und CSV-Dateien für einen Monat aus Git-Commits"
	@echo "  make git-log        - Erstellt ein Git-Log für einen bestimmten Monat"
	@echo "  make help           - Zeigt diese Hilfe an"

# Erstelle ein Git-Log für einen bestimmten Monat
git-log:
	@read -p "Jahr-Monat (Format YYYYMM, z.B. 202510 für Oktober 2025): " yearmonth; \
	year=$${yearmonth:0:4}; \
	month=$${yearmonth:4:2}; \
	read -p "Repository-Pfad: " repo_path; \
	if [ ! -d "$$repo_path" ]; then \
		echo "Fehler: Das Repository $$repo_path existiert nicht."; \
		exit 1; \
	fi; \
	cd "$$repo_path" && \
	echo "Git-Commits für $$month/$$year:" && \
	git log --since="$$year-$$month-01" --until="$$year-$$month-31" --pretty=format:"%ad | %s" --date=short | \
	sed 's/🔒/[SECURITY]/g' | \
	sed 's/🚀/[LAUNCH]/g' | \
	sed 's/📊/[STATS]/g' | \
	sed 's/🐛/[BUG]/g' | \
	sed 's/✨/[FEATURE]/g' | \
	sed 's/🔥/[CRITICAL]/g' > "$(MONTH_DIR)/$$yearmonth-git-log.txt" && \
	echo "✓ Git-Log erstellt: $(MONTH_DIR)/$$yearmonth-git-log.txt"

# Erstelle automatisch eine Monats-Markdown und CSV-Datei aus Git-Commits
create-month:
	@$(DOCS_DIR)/scripts/create_month.sh