sudo apt-get update
echo -n "Do you want to install R (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    sudo apt -y install r-base
else
    echo OK.
fi
echo -n "Do you want to install Package stringi (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    sudo su - -c "R -e \"install.packages('stringi', repos='http://cran.rstudio.com/')\""
else
    echo OK.
fi
echo -n "Do you want to install Package data.table (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    sudo su - -c "R -e \"install.packages('data.table', repos='http://cran.rstudio.com/')\""
else
    echo OK.
fi
echo -n "Do you want to install Package XML (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    sudo su - -c "R -e \"install.packages('XML', repos='http://cran.rstudio.com/')\""
else
    echo OK.
fi
echo -n "Do you want to download stackexchange data about beer (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    sudo wget "https://archive.org/download/stackexchange/beer.stackexchange.com.7z"
else
    echo OK.
fi
echo -n "Do you want to download stackexchange data about gaming (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    sudo wget "https://archive.org/download/stackexchange/gaming.stackexchange.com.7z"
else
    echo OK.
fi
echo -n "Do you want to download stackexchange data about health (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    sudo wget "https://archive.org/download/stackexchange/health.stackexchange.com.7z"
else
    echo OK.
fi
echo -n "Do you want to install RStudio (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ] ;then
    sudo apt-get install gdebi-core
    wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.4.1717-amd64.deb
    sudo gdebi rstudio-server-1.4.1717-amd64.deb
else
    echo OK.
fi
