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

HealthCommentsDT <- fix_comments(load_xml("health_stackexchange/Comments.xml"))
HealthPostsDT <- fix_posts(load_xml("health_stackexchange/Posts.xml"))
HealthUsersDT <- fix_users(load_xml("health_stackexchange/Users.xml"))

GamingCommentsDT <- fix_comments(load_xml("gaming_stackexchange/Comments.xml"))
GamingPostsDT <- fix_posts(load_xml("gaming_stackexchange/Posts.xml"))
GamingUsersDT <- fix_users(load_xml("gaming_stackexchange/Users.xml"))

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
  x[order(x$TotalViews, decreasing=TRUE)]
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

# haot <- activity_over_time(HealthPostsDT, HealthCommentsDT)
# gaot <- activity_over_time(GamingPostsDT, GamingCommentsDT)
# baot <- activity_over_time(BeerPostsDT, BeerCommentsDT)

plot_aot <- function(aot1, aot2, aot3) {
  aot1 <- aot1[Year > 2015,]
  aot2 <- aot2[Year > 2015,]
  aot3 <- aot3[Year > 2015,]
  max_act1 <- max(aot1$Activity)
  aot1 <- aot1[, c("ActivityPercentage") := round(aot1$Activity*100/max_act1, 2)]
  max_act2 <- max(aot2$Activity)
  aot2 <- aot2[, c("ActivityPercentage") := round(aot2$Activity*100/max_act2, 2)]
  max_act3 <- max(aot3$Activity)
  aot3 <- aot3[, c("ActivityPercentage") := round(aot3$Activity*100/max_act3, 2)]
  
  plot.new()
  old_mar <- par('mar')
  old_xaxt <- par('xaxt')
  par(mar=c(5,5,5,5))
  par(xaxt="n")
  
  plot(aot1$ActivityPercentage, type="l", col='blue', xlab="ROk",
       ylab="Procent najwyzszej aktywnosci forum", main="Aktywność",
       ylim=c(0,100), lty=1, lwd=2, cex.lab=0.8)
  par(xaxt='s')
  axis(1, at=seq(0,61,by=12), labels=2016:2021)
  lines(aot2$ActivityPercentage, type="l",lty = 2,col='green', lwd=2)
  lines(aot3$ActivityPercentage, type="l",lty = 3, col='red', lwd=2)
  
  legend(1, 15, legend=c("Health", "Gaming", "Beer"),
         col=c("blue", "green", "red"), lty=1:3, cex=0.7,
         box.lty=0)
  par(mar=old_mar)
  par(xaxt=old_xaxt)
  # Wzrost w Gaming związany z wydaniem Pokemon GO, w Health z Covidem
}

# plot_aot(haot, gaot, baot)

hmvt <- most_viewed_tags(HealthPostsDT)
gmvt <- most_viewed_tags(GamingPostsDT)
bmvt <- most_viewed_tags(BeerPostsDT)
# 22 pierwsze tagi ~~ 50% ilosci wyswietlen

plot_mvt <- function(mvt) {
  
  mvt <- mvt[1:15]
  plot.new()
  old_mar <- par('mar')
  old_las <- par('las')
  par(las = 2)
  par(mar = c(6,10,4,4))
  
  barplot(mvt$TotalViews/1000, names.arg=mvt$Tag, horiz=TRUE, cex.names=0.75,
          col='cyan', space=0, main="Najpopularniejsze tagi", cex.axis=0.75,
          xlab="Liczba wyświetleń w tys.")
  
  par(mar = old_mar)
  par(las = old_las)
}

plot_mvt(hmvt)
plot_mvt(gmvt)
plot_mvt(bmvt)

