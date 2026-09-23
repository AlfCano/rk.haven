// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(haven)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, "\\'").replace(/"/g, '\\"');
    }
  
    var df = getValue('exp_df');
    var file = cleanStr(getValue('exp_file'));
    var fmt = getValue('exp_fmt');
    var auto_ext = getValue('exp_auto_ext') == 'TRUE';

    echo('out_file <- "' + file + '"\n');

    if (auto_ext) {
        var ext = (fmt === 'spss') ? 'sav' : (fmt === 'stata' ? 'dta' : 'xpt');
        // Usamos regex en R para revisar si el archivo ya termina en .sav, .dta, etc.
        echo('if (!grepl(paste0("\\\\.", "' + ext + '", "$"), out_file, ignore.case = TRUE)) {\n');
        echo('  out_file <- paste0(out_file, ".", "' + ext + '")\n');
        echo('}\n');
    }

    echo('require(haven)\n');
    if (fmt === 'spss') {
        echo('haven::write_sav(' + df + ', out_file)\n');
    } else if (fmt === 'stata') {
        echo('haven::write_dta(' + df + ', out_file)\n');
    } else if (fmt === 'xpt') {
        echo('haven::write_xpt(' + df + ', out_file)\n');
    }
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("Professional Export (haven) results")).print();

    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, "\\'").replace(/"/g, '\\"');
    }
  
    var df = getValue('exp_df');
    var fmt = getValue('exp_fmt');
    var fmt_name = 'SPSS (.sav)';
    if (fmt === 'stata') fmt_name = 'Stata (.dta)';
    if (fmt === 'xpt') fmt_name = 'SAS Transport (.xpt)';

    echo('rk.header("Data Export via haven", level = 2)\n');
    echo('rk.print("<b>Dataset exported:</b> <code>' + df + '</code>")\n');
    echo('rk.print("<b>Format:</b> ' + fmt_name + '")\n');

    echo('rk.print(paste0("<b>Destination File:</b> <code>", out_file, "</code>"))\n');
  

}

