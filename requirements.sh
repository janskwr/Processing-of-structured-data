sudo apt-get update
echo -n "Do you want to install R (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    sudo apt -y install r-base
else
    echo You already have R.
fi
sudo apt -y install r-base
sudo su - -c "R -e \"install.packages('stringi', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('data.table', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('XML', repos='http://cran.rstudio.com/')\""
sudo wget "https://archive.org/download/stackexchange/beer.stackexchange.com.7z"
sudo wget "https://archive.org/download/stackexchange/gaming.stackexchange.com.7z"
sudo wget "https://archive.org/download/stackexchange/health.stackexchange.com.7z"
echo -n "Do you want to install R-S this a good question (y/n)? "
read answer
