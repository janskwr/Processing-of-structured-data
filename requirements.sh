sudo apt-get update
echo -n "Do you want to install R (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    sudo apt -y install r-base
else
    echo OK.
fi
sudo su - -c "R -e \"install.packages('stringi', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('data.table', repos='http://cran.rstudio.com/')\""
sudo su - -c "R -e \"install.packages('XML', repos='http://cran.rstudio.com/')\""
sudo wget "https://archive.org/download/stackexchange/beer.stackexchange.com.7z"
sudo wget "https://archive.org/download/stackexchange/gaming.stackexchange.com.7z"
sudo wget "https://archive.org/download/stackexchange/health.stackexchange.com.7z"
echo -n "Do you want to install RStudio (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    sudo apt-get install gdebi-core
    wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.4.1717-amd64.deb
    sudo gdebi rstudio-server-1.4.1717-amd64.deb
else
    echo OK.
fi
