// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!

function preview(){
	preprocess(true);
	calculate(true);
	printout(true);
}

function preprocess(is_preview){
	// add requirements etc. here
	if(is_preview) {
		echo("if(!base::require(haven)){stop(" + i18n("Preview not available, because package haven is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(haven)\n");
	}	if(is_preview) {
		echo("if(!base::require(dplyr)){stop(" + i18n("Preview not available, because package dplyr is not installed or cannot be loaded.") + ")}\n");
	} else {
		echo("require(dplyr)\n");
	}
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, "\\'").replace(/"/g, '\\"');
    }
  
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
        var args = [ "'" + file + "'" ];
        if (enc !== 'UTF-8') args.push("encoding = '" + enc + "'");
        if (user_na && fmt !== 'xpt') args.push("user_na = TRUE");
        if (nmax > 0) args.push("n_max = " + nmax);
        if (cols !== '') args.push("col_select = " + cols);

        var cmd = read_func + "(" + args.join(', ') + ")";

        // Apply Pipes
        if (clean) {
            echo('require(janitor)\n');
            cmd += " %>% janitor::clean_names()";
        }
        if (val_lbl === 'factor') cmd += " %>% haven::as_factor()";
        if (val_lbl === 'zap') cmd += " %>% haven::zap_labels()";

        // PASO 1: Respetamos la Regla 3 para el sistema interno
        echo('imported_data <- ' + cmd + '\n');

        // PASO 2: Sincronizamos metadatos inyectando .rk.meta (Más estable)
        if (sync_rk) {
            echo('# Synchronize Variable Labels natively for RKWard\n');
            echo('for (col_name in names(imported_data)) {\n');
            echo('  lbl <- attr(imported_data[[col_name]], "label", exact = TRUE)\n');
            echo('  if (!is.null(lbl)) {\n');
            echo('    attr(imported_data[[col_name]], ".rk.meta") <- list(label = lbl)\n');
            echo('  }\n');
            echo('}\n');
        }

        // PASO 3 y 4: Separación entre Preview y Ejecución Final (Evaluado en Javascript)
        if (is_preview) {
            echo('# Lógica exclusiva de la Previsualización (Ahorro de memoria)\n');
            echo('preview_data <- head(imported_data, 50)\n');
        } else {
            echo('# Ejecución final: Guardar en GlobalEnv y abrir editor completo\n');
            echo('assign("' + final_name + '", imported_data, envir = .GlobalEnv)\n');

            if (do_edit) {
                echo('rk.edit(.GlobalEnv[["' + final_name + '"]])\n');
            }
        }
    }
  
}

function printout(is_preview){
	// read in variables from dialog


	// printout the results
	if(!is_preview) {
		new Header(i18n("Professional Import (haven) results")).print();	
	}
    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, "\\'").replace(/"/g, '\\"');
    }
  
    var glimpse = getValue('c1_glimpse') == 'TRUE';
    var final_name = getValue('c1_save');

    // EVITAR SPAM: Solo imprimir en la ventana de resultados si NO es un preview
    if (!is_preview) {
        echo('rk.header("Data Import via haven", level = 2)\n');
        echo('rk.print("<b>Source File:</b> <code>' + cleanStr(getValue('c1_file')) + '</code>")\n');
        echo('rk.print("<b>Saved in workspace as:</b> <code>' + final_name + '</code>")\n');

        if (glimpse) {
            echo('require(dplyr)\n');
            echo('rk.header("Dataset Structure (Codebook)", level = 4)\n');
            echo('rk.print("<pre>")\n');
            // GLIMPSE LEE EL OBJETO FINAL
            echo('dplyr::glimpse(.GlobalEnv[["' + final_name + '"]])\n');
            echo('rk.print("</pre>")\n');
        }
    }
  
	if(!is_preview) {
		//// save result object
		// read in saveobject variables
		var c1Save = getValue("c1_save");
		var c1SaveActive = getValue("c1_save.active");
		var c1SaveParent = getValue("c1_save.parent");
		// assign object to chosen environment
		if(c1SaveActive) {
			echo(".GlobalEnv$" + c1Save + " <- imported_data\n");
		}	
	}

}

