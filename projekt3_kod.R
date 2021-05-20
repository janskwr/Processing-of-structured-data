if ( options()$stringsAsFactors )
  options(stringsAsFactors=FALSE) # dla R w wersji < 4.0


# install.packages('XML')
# chyba że znacie lepszy sposób na wczytanie .xml
# duże pliki to używać będziemy data.table bo jest najszybszy
library(XML)
library(data.table)


# To zamienia xml na dataframe
# file to lokacja pliku
load_xml <- function(file) {
  xml <- xmlTreeParse(file,
                      useInternalNodes = TRUE)
  as.data.table(rbindlist(lapply(xml["//row"],
                                 function(x)as.list(xmlAttrs(x))), fill=TRUE))
}

# To usuwa tagi z html (np. <p></p>)
clear_html <- function(html) {
  return(gsub("<.*?>", "", html))
}

# Tylko ze load_xml traktuje wszystko jako stringi wiec trzeba pozmieniać XD
fix_posts <- function(Posts) {
  transform(Posts, Id = as.numeric(Id),
            PostTypeId = as.numeric(PostTypeId),
            AcceptedAnswerId = as.numeric(AcceptedAnswerId),
            Score = as.numeric(Score),
            ViewCount = as.numeric(ViewCount),
            OwnerUserId = as.numeric(OwnerUserId),
            LastEditorUserId = as.numeric(LastEditorUserId),
            AnswerCount = as.numeric(AnswerCount),
            CommentCount = as.numeric(CommentCount),
            ParentId = as.numeric(ParentId),
            FavoriteCount = as.numeric(FavoriteCount),
            Body = clear_html(Body))
}

fix_users <- function(Users) {
  transform(Users, Id = as.numeric(Id),
            Reputation = as.numeric(Reputation),
            Views = as.numeric(Views),
            UpVotes = as.numeric(UpVotes),
            DownVotes = as.numeric(DownVotes),
            AccountId = as.numeric(AccountId),
            AboutMe = clear_html(AboutMe))
}

fix_comments <- function(Comments) {
  transform(Comments, Id = as.numeric(Id),
            PostId = as.numeric(PostId),
            Score = as.numeric(Score),
            UserId = as.numeric(UserId))
}

BeerCommentsDT <- fix_comments(load_xml("beer_stackexchange/Comments.xml"))
BeerPostsDT <- fix_posts(load_xml("beer_stackexchange/Posts.xml"))
BeerUsersDT <- fix_users(load_xml("beer_stackexchange/Users.xml"))

# Jakie tematy najbardziej interesują ludzi
most_viewed_tags <- function(Posts) {
  x <- Posts[, lapply(Tags, function(x) sub('.','',unlist(tstrsplit(x ,">")))),
             by = Id] 
  setkey(x, Id)
  setkey(Posts, Id)
  x <- x[Posts[, -"Tags"], nomatch=0]
  setnames(x, "V1", "Tag")
  x <- x[PostTypeId==1, c(1,2,6,7)]
  x <- x[, .(TotalViews=sum(ViewCount)), by=Tag]
  x[order(x$TotalViews, decreasing=TRUE)][1:25]
}

# Miesieczna aktywnosc (liczba postow i komentarzy)
activity_over_time <- function(Posts, Comments) {
  Dat1 <- Comments[, .(CreationDate)]
  Dat2 <- Posts[, .(CreationDate)]
  
  Dat1[, Id:="Posts"]
  Dat2[, Id:="Comments"]
  
  setkey(Dat1, Id)
  setkey(Dat2, Id)
  
  x <- merge(Dat1, Dat2, all=TRUE)
  x[Id=="Posts", .(CreationDate.y=CreationDate.x)]
  x <- transform(x, "CreationDate"=fifelse(Id=="Posts", CreationDate.x,
                                           CreationDate.y))
  x[, c("Id", "CreationDate.x", "CreationDate.y"):=NULL]
  
  x[, c("Year", "Month", "Day") := tstrsplit(CreationDate, "-")]
  x[, Day:=substr(Day, 1, 2)]
  
  x[, CreationDate:=NULL]
  x <- x[, .(Activity=.N), by=.(Year, Month)]
  transform(x, Year=as.numeric(Year), Month=as.numeric(Month))
  
}

