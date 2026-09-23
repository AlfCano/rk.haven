# rk.haven

![Version](https://img.shields.io/badge/Version-0.0.1-blue.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![RKWard](https://img.shields.io/badge/Platform-RKWard-green)
[![R Linter](https://github.com/AlfCano/rk.haven/actions/workflows/lintr.yml/badge.svg)](https://github.com/AlfCano/rk.haven/actions/workflows/lintr.yml)
![AI Gemini](https://img.shields.io/badge/AI-Gemini-4285F4?logo=googlegemini&logoColor=white)

**A Professional RKWard GUI Plugin for Importing and Exporting SPSS, Stata, and SAS Datasets**

`rk.haven` provides a robust, point-and-click graphical interface for the popular [`haven`](https://haven.tidyverse.org/) package. Designed for researchers working with proprietary statistical software formats, this plugin ensures flawless data migration into and out of R, automatically handling complex value labels, legacy text encodings, and large datasets without writing a single line of code.

---

## 🌟 Key Features

* **Universal Compatibility:** Read and write `.sav`, `.zsav`, `.dta`, `.sas7bdat`, and `.xpt` files effortlessly.
* **Value Label Management:** Smartly convert proprietary value labels into native R factors, extract numeric codes, or keep the original `haven_labelled` structure intact.
* **Native RKWard Integration:** Automatically synchronizes variable labels (metadata) with RKWard's internal environment (`.rk.meta`), ensuring your codebooks look perfect in the RKWard Data Editor.
* **Legacy Encoding Fixes:** Easily fix broken accents and special characters (like *ñ* or *ü*) by forcing specific character encodings (e.g., UTF-8, Latin1, Windows CP1252).
* **Big Data Optimization:** Save RAM when importing massive census or survey files by reading only the first *N* rows or selectively importing specific columns.
* **Multilingual:** Fully translated into English, Spanish, French, German, and Portuguese (Brazil).

---

## What's New in Version 0.0.1

**🚀 Initial Release: Complete Import/Export Lifecycle**

*   **Two-Way Migration:** The initial release includes two full-featured modules: a Professional Importer and a Professional Exporter, allowing a complete round-trip of data between R and other statistical suites.
*   **Crash-Proof Previews:** Features a native RKWard data preview button. Users can safely inspect the first 50 rows of their imported dataset in a spreadsheet view to tweak encodings or test label conversions *before* committing to a full memory-heavy import.
*   **Automated Data Cleaning:** Includes a built-in toggle to instantly sanitize messy, proprietary column names into standard `snake_case` using `janitor::clean_names()`.
*   **Robust XML Parsing:** Hardened UI logic and safe string rendering to prevent RKWard XML parsing crashes when handling complex `dplyr` syntax examples.

---

## ⚙️ Prerequisites

You must have [RKWard](https://rkward.kde.org/) installed along with the following R packages:

```R
install.packages(c("haven", "dplyr", "janitor"))
```

---

## 🚀 Installation

You can install this plugin directly from GitHub using `remotes` inside your RKWard console:

```R
# Install the plugin
library("remotes")
install_github("AlfCano/rk.haven")
```

Once installed, restart RKWard, navigate to **Settings -> Configure RKWard -> Plugins**, and activate `rk.haven`.

---

## 🛠️ Usage Workflow

This plugin integrates cleanly into RKWard's native file management menus. It adds two powerful tools located under **Workspace ➔ Import** and **Workspace ➔ Export**:

### 1. Professional Import (haven)
*Migrate databases from SPSS, Stata, or SAS into your R Workspace.*
*   **File & Format:** Auto-detects formats based on extensions. Override encodings to fix broken text.
*   **Metadata & Labels:** Decide how to treat value labels (Factors, Numeric, or Keep). Toggle RKWard metadata synchronization.
*   **Big Data Optimization:** Use `col_select` to grab only what you need, or cap the row count to save memory. Clean names automatically.
*   **Post-Import Actions:** Print a `dplyr::glimpse` codebook, open the RKWard Data Editor automatically, or safely Preview the first 50 rows.

### 2. Professional Export (haven)
*Send your cleaned datasets back to colleagues using other software.*
*   **Seamless Export:** Select any data frame from your workspace and export it to SPSS (`.sav`), Stata (`.dta`), or SAS (`.xpt`) formats in one click.
*   **Auto-Extension:** Smartly appends the correct file extension if you forget to type it in the destination path.

---

## 🌍 Internationalization (i18n)

The graphical interface automatically adapts to your RKWard language settings. Currently supported languages:
* 🇺🇸 English (Default)
* 🇪🇸 Spanish (Español)
* 🇫🇷 French (Français)
* 🇩🇪 German (Deutsch)
* 🇧🇷 Portuguese (Português do Brasil)

---

## 📝 License and Author

**Author:** Alfonso Cano ([@AlfCano](https://github.com/AlfCano))  
**Email:** alfonso.cano@correo.buap.mx  
*   **Assisted by:** Gemini, a large language model from Google.
*   **License:** GPL (>= 3)

This project is licensed under the **GPL (>= 3)** License.
