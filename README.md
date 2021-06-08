# IiAD-PDU-PD3
Processing of structured data - project 3.
Copyright © 2021 Patryk Rakus, Jan Skwarek, Daniel Tytkowski. All rights reserved. Do not redistribute. Do not reproduce or use in any manner whatsoever without the express written permission.  
Email: janskwarek@protonmail.ch

# Requirements
GNU R version 4 https://www.r-project.org/  
Package stringi https://cran.r-project.org/web/packages/stringi/index.html  
Package data.table https://cran.r-project.org/web/packages/data.table/index.html  
Package XML https://cran.r-project.org/web/packages/XML/index.html  
gaming.stackexchange.com.7z https://archive.org/details/stackexchange  
beer.stackexchange.com.7z https://archive.org/details/stackexchange  
health.stackexchange.com.7z https://archive.org/details/stackexchange  
any integrated development environment for R (we recommend using RStudio) https://www.rstudio.com/

# Tutorial
1. Download/clone all files from this repository.
2. Open folder with files in terminal.
3. Type:
```console
./requirements.sh
```
4. If it doesn't work try:
```console
sudo chmod +x requirements.sh
```
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;and then again:
```console
./requirements.sh
```
5. Unpack 7z folders with data and place them in appropriately named folders created inside project directory:
```console
gaming.stackexchange.com.7z ---> gaming_stackexchange
beer.stackexchange.com.7z ---> beer_stackexchange
health.stackexchange.com.7z ---> health_stackexchange
```
6. Now you can open and use our R program with full functionality!

# Authors
Patryk Rakus (Email:)  
Jan Skwarek (Email: janskwarek@protonmail.ch)  
Daniel Tytkowski (Email:)
