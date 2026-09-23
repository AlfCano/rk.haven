# make_rk.haven

local({
  # =========================================================================================
  # 1. Package Definition and Metadata
  # =========================================================================================
  require(rkwarddev)
  rkwarddev.required("0.10-3")

  package_about <- rk.XML.about(
    name = "rk.haven",
    author = person(
      given = "Alfonso",
      family = "Cano",
      email = "alfonso.cano@correo.buap.mx",
      role = c("aut", "cre")
    ),
    about = list(
      desc = "Professional GUI importer for SPSS, Stata, and SAS datasets using the haven package. Manages encodings, value labels, and RKWard metadata synchronization.",
      version = "0.0.1",
      url = "https://github.com/AlfCano/rk.haven",
      license = "GPL (>= 3)"
    )
  )

  # Custom Hierarchy for importing data
  h_haven <- list("file", "import")

  js_sanitize <- "
    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, \"\\\\'\").replace(/\"/g, '\\\\\"');
    }
  "

  # =========================================================================================
  # COMPONENT 1: Haven Importer
  # =========================================================================================
  help_haven <- rk.rkh.doc(
      title = rk.rkh.title("Import SPSS / Stata / SAS"),
      summary = rk.rkh.summary("Advanced importer handling labels, encodings, and large datasets.")
  )

  # --- Block 1: File Selection & Format ---
  c1_file <- rk.XML.browser("Data File (SPSS, Stata, SAS)", type = "file", required = TRUE, id.name = "c1_file")

  c1_fmt <- rk.XML.dropdown("File Format", options = list(
      "Auto-detect from extension" = list(val = "auto", chk = TRUE),
      "SPSS (.sav, .zsav)" = list(val = "spss"),
      "Stata (.dta)" = list(val = "stata"),
      "SAS (.sas7bdat)" = list(val = "sas"),
      "SAS Transport (.xpt)" = list(val = "xpt")
  ), id.name = "c1_fmt")

  c1_enc <- rk.XML.dropdown("Character Encoding (Fixes accents/ñ)", options = list(
      "UTF-8 (Modern standard)" = list(val = "UTF-8", chk = TRUE),
      "Latin1 (ISO-8859-1 / Old SPSS)" = list(val = "latin1"),
      "Windows CP1252" = list(val = "cp1252")
  ), id.name = "c1_enc")

  # --- Block 2 & 3: Metadata, Value Labels & Missing Values ---
  c1_val_lbl <- rk.XML.radio("Treatment of Value Labels", options = list(
      "A. Keep original structure (haven_labelled)" = list(val = "keep", chk = TRUE),
      "B. Convert to R Factors (haven::as_factor)" = list(val = "factor"),
      "C. Extract numeric codes only (haven::zap_labels)" = list(val = "zap")
  ), id.name = "c1_val_lbl")

  c1_user_na <- rk.XML.cbox("Preserve User-Defined NAs (e.g., 99 = Not Applicable)", value = "TRUE", chk = FALSE, id.name = "c1_user_na")
  c1_sync_rk <- rk.XML.cbox("Synchronize Variable Labels with RKWard Environment", value = "TRUE", chk = TRUE, id.name = "c1_sync_rk")

  # --- Block 4: Large Database Optimization ---
   c1_nmax <- rk.XML.spinbox("Import only the first N rows (0 = Import All)", min = 0, max = 100000000, initial = 0, real = FALSE, id.name = "c1_nmax")

  c1_cols_text <- rk.XML.text("Tip: You can use dplyr syntax like c(id, age) or starts_with('q')")
  c1_cols <- rk.XML.input("Select columns (leave blank for all)", id.name = "c1_cols")

  c1_clean <- rk.XML.cbox("Sanitize column names to snake_case (janitor::clean_names)", value = "TRUE", chk = FALSE, id.name = "c1_clean")

  # --- Block 5: Post-import Integration ---
  c1_save <- rk.XML.saveobj("Save Dataset as", initial = "imported_data", chk = TRUE, id.name = "c1_save")
  c1_edit <- rk.XML.cbox("Open RKWard Data Editor after import", value = "TRUE", chk = TRUE, id.name = "c1_edit")
  c1_glimpse <- rk.XML.cbox("Print Codebook/Structure (dplyr::glimpse)", value = "TRUE", chk = TRUE, id.name = "c1_glimpse")

 btn_preview <- XiMpLe::XMLNode("preview", attrs=list(id="preview_results", mode="data", label="Preview (First 50 rows)"))

  dialog_haven <- rk.XML.dialog(label = "Professional Data Importer (haven)", child = rk.XML.tabbook(tabs = list(
      "File & Format" = rk.XML.col(c1_file, rk.XML.frame(c1_fmt, c1_enc), c1_save, rk.XML.stretch()),
      "Metadata & Labels" = rk.XML.col(rk.XML.frame(c1_val_lbl, c1_user_na), c1_sync_rk, rk.XML.stretch()),
      "Big Data Optimization" = rk.XML.col(rk.XML.frame(label="Memory Savers", c1_nmax, c1_cols_text, c1_cols, c1_clean), rk.XML.stretch()),
      "Post-Import Actions" = rk.XML.col(c1_edit, c1_glimpse, btn_preview, rk.XML.stretch())
  )))

  js_calc_haven <- paste0(js_sanitize, "
    var file = cleanStr(getValue('c1_file'));
    var fmt = getValue('c1_fmt');
    var enc = getValue('c1_enc');
    var val_lbl = getValue('c1_val_lbl');
    var user_na = getValue('c1_user_na') == 'TRUE';
    var sync_rk = getValue('c1_sync_rk') == 'TRUE';
    var nmax = getValue('c1_nmax');
    var cols = getValue('c1_cols');
    var clean = getValue('c1_clean') == 'TRUE';
    var do_edit = getValue('c1_edit') == 'TRUE';

    // EL FIX: Capturamos el nombre final elegido por el usuario (ej. 'datos_encuesta')
    var final_name = getValue('c1_save');

    if (file !== '') {
        // Auto-detect format based on extension
        if (fmt === 'auto') {
            var lower_file = file.toLowerCase();
            if (lower_file.indexOf('.sav') > -1 || lower_file.indexOf('.zsav') > -1) fmt = 'spss';
            else if (lower_file.indexOf('.dta') > -1) fmt = 'stata';
            else if (lower_file.indexOf('.sas7bdat') > -1) fmt = 'sas';
            else if (lower_file.indexOf('.xpt') > -1) fmt = 'xpt';
            else fmt = 'spss'; // Default fallback
        }

        // Map to haven functions
        var read_func = 'haven::read_sav';
        if (fmt === 'stata') read_func = 'haven::read_dta';
        if (fmt === 'sas') read_func = 'haven::read_sas';
        if (fmt === 'xpt') read_func = 'haven::read_xpt';

        // Build base command arguments
        var args = [ \"'\" + file + \"'\" ];
        if (enc !== 'UTF-8') args.push(\"encoding = '\" + enc + \"'\");
        if (user_na && fmt !== 'xpt') args.push(\"user_na = TRUE\");
        if (nmax > 0) args.push(\"n_max = \" + nmax);
        if (cols !== '') args.push(\"col_select = \" + cols);

        var cmd = read_func + \"(\" + args.join(', ') + \")\";

        // Apply Pipes
        if (clean) {
            echo('require(janitor)\\n');
            cmd += \" %>% janitor::clean_names()\";
        }
        if (val_lbl === 'factor') cmd += \" %>% haven::as_factor()\";
        if (val_lbl === 'zap') cmd += \" %>% haven::zap_labels()\";

        // PASO 1: Respetamos la Regla 3 para el sistema interno
        echo('imported_data <- ' + cmd + '\\n');

        // PASO 2: Sincronizamos metadatos inyectando .rk.meta (Más estable)
        if (sync_rk) {
            echo('# Synchronize Variable Labels natively for RKWard\\n');
            echo('for (col_name in names(imported_data)) {\\n');
            echo('  lbl <- attr(imported_data[[col_name]], \"label\", exact = TRUE)\\n');
            echo('  if (!is.null(lbl)) {\\n');
            echo('    attr(imported_data[[col_name]], \".rk.meta\") <- list(label = lbl)\\n');
            echo('  }\\n');
            echo('}\\n');
        }

        // PASO 3 y 4: Separación entre Preview y Ejecución Final (Evaluado en Javascript)
        if (is_preview) {
            echo('# Lógica exclusiva de la Previsualización (Ahorro de memoria)\\n');
            echo('preview_data <- head(imported_data, 50)\\n');
        } else {
            echo('# Ejecución final: Guardar en GlobalEnv y abrir editor completo\\n');
            echo('assign(\"' + final_name + '\", imported_data, envir = .GlobalEnv)\\n');

            if (do_edit) {
                echo('rk.edit(.GlobalEnv[[\"' + final_name + '\"]])\\n');
            }
        }
    }
  ")



  js_print_haven <- paste0(js_sanitize, "
    var glimpse = getValue('c1_glimpse') == 'TRUE';
    var final_name = getValue('c1_save');

    // EVITAR SPAM: Solo imprimir en la ventana de resultados si NO es un preview
    if (!is_preview) {
        echo('rk.header(\"Data Import via haven\", level = 2)\\n');
        echo('rk.print(\"<b>Source File:</b> <code>' + cleanStr(getValue('c1_file')) + '</code>\")\\n');
        echo('rk.print(\"<b>Saved in workspace as:</b> <code>' + final_name + '</code>\")\\n');

        if (glimpse) {
            echo('require(dplyr)\\n');
            echo('rk.header(\"Dataset Structure (Codebook)\", level = 4)\\n');
            echo('rk.print(\"<pre>\")\\n');
            // GLIMPSE LEE EL OBJETO FINAL
            echo('dplyr::glimpse(.GlobalEnv[[\"' + final_name + '\"]])\\n');
            echo('rk.print(\"</pre>\")\\n');
        }
    }
  ")

  comp_haven <- rk.plugin.component(
      "Professional Import (haven)",
      xml = list(dialog = dialog_haven),
      js = list(require = c("haven", "dplyr"), calculate = js_calc_haven, printout = js_print_haven),
      hierarchy = h_haven, rkh = list(help = help_haven)
  )

  # =========================================================================================
  # COMPONENT 2: Haven Exporter
  # =========================================================================================
  help_export <- rk.rkh.doc(
      title = rk.rkh.title("Export SPSS / Stata / SAS"),
      summary = rk.rkh.summary("Export R dataframes to SPSS, Stata, or SAS formats.")
  )

  # Lo colocamos en el menú nativo de "Exportar" de RKWard
  h_export <- list("file", "export")

  exp_sel <- rk.XML.varselector(id.name = "exp_sel")
  exp_df <- rk.XML.varslot("Dataframe to export", source = "exp_sel", classes = "data.frame", required = TRUE, id.name = "exp_df")

  exp_fmt <- rk.XML.dropdown("Export Format", options = list(
      "SPSS (.sav)" = list(val = "spss", chk = TRUE),
      "Stata (.dta)" = list(val = "stata"),
      "SAS Transport (.xpt)" = list(val = "xpt")
  ), id.name = "exp_fmt")

  exp_file <- rk.XML.browser("Destination File", type = "savefile", required = TRUE, id.name = "exp_file")
  exp_auto_ext <- rk.XML.cbox("Automatically append extension if missing", value = "TRUE", chk = TRUE, id.name = "exp_auto_ext")

  dialog_export <- rk.XML.dialog(label = "Professional Data Exporter (haven)", child = rk.XML.row(
      exp_sel,
      rk.XML.col(
          exp_df,
          rk.XML.frame(exp_fmt),
          rk.XML.frame(exp_file, exp_auto_ext, label="Save Options"),
          rk.XML.stretch()
      )
  ))

  js_calc_export <- paste0(js_sanitize, "
    var df = getValue('exp_df');
    var file = cleanStr(getValue('exp_file'));
    var fmt = getValue('exp_fmt');
    var auto_ext = getValue('exp_auto_ext') == 'TRUE';

    echo('out_file <- \"' + file + '\"\\n');

    if (auto_ext) {
        var ext = (fmt === 'spss') ? 'sav' : (fmt === 'stata' ? 'dta' : 'xpt');
        // Usamos regex en R para revisar si el archivo ya termina en .sav, .dta, etc.
        echo('if (!grepl(paste0(\"\\\\\\\\.\", \"' + ext + '\", \"$\"), out_file, ignore.case = TRUE)) {\\n');
        echo('  out_file <- paste0(out_file, \".\", \"' + ext + '\")\\n');
        echo('}\\n');
    }

    echo('require(haven)\\n');
    if (fmt === 'spss') {
        echo('haven::write_sav(' + df + ', out_file)\\n');
    } else if (fmt === 'stata') {
        echo('haven::write_dta(' + df + ', out_file)\\n');
    } else if (fmt === 'xpt') {
        echo('haven::write_xpt(' + df + ', out_file)\\n');
    }
  ")

  js_print_export <- paste0(js_sanitize, "
    var df = getValue('exp_df');
    var fmt = getValue('exp_fmt');
    var fmt_name = 'SPSS (.sav)';
    if (fmt === 'stata') fmt_name = 'Stata (.dta)';
    if (fmt === 'xpt') fmt_name = 'SAS Transport (.xpt)';

    echo('rk.header(\"Data Export via haven\", level = 2)\\n');
    echo('rk.print(\"<b>Dataset exported:</b> <code>' + df + '</code>\")\\n');
    echo('rk.print(\"<b>Format:</b> ' + fmt_name + '\")\\n');

    echo('rk.print(paste0(\"<b>Destination File:</b> <code>\", out_file, \"</code>\"))\\n');
  ")

  comp_export <- rk.plugin.component(
      "Professional Export (haven)",
      xml = list(dialog = dialog_export),
      js = list(require = "haven", calculate = js_calc_export, printout = js_print_export),
      hierarchy = h_export, rkh = list(help = help_export)
  )

  # =========================================================================================
  # 3. BUILD SKELETON
  # =========================================================================================


  rk.plugin.skeleton(
    about = package_about,
    path = ".",
    # 1. Feed the UI, JS, and Help directly to the skeleton
    xml = list(dialog = dialog_haven),
    js = list(require = c("haven", "dplyr"), calculate = js_calc_haven, printout = js_print_haven),
    rkh = list(help = help_haven),
    components = list(comp_export),
    # 2. Assign the hierarchy
    pluginmap = list(name = "Professional Import (haven)", hierarchy = h_haven),
    # 3. Create the files (NO "components = list(...)" needed for a single-dialog plugin)
    create = c("pmap", "xml", "js", "desc", "rkh"),
    load = TRUE, overwrite = TRUE, show = FALSE
  )

  cat("\nPlugin package 'rk.haven' (v0.0.1) generated successfully.\n")
})
