sudo apt-get update
sudo apt -y install r-base
sudo su - -c "R -e \"install.packages('stringi', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('data.table', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('XML', repos='http://cran.rstudio.com/')\""
