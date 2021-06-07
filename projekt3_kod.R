# -----------------------------------------------------------------------------
# Program analizuje wybrane fora z portalu stackexchange.com i sporzadza
# na ich podstawie szczegolowe wykresy. W szczegolnosci odpowiada on na
# sformulowane przez nas pytania i tezy.
# -----------------------------------------------------------------------------


# Traktujemy napisy jako zwykle napisy, a nie jako elementy/parametry. Dla
# starszych wersji GNU R domyślnie traktujemy je jako elementy/parametry.
if ( options()$stringsAsFactors )
  options(stringsAsFactors=FALSE)


# Wczytujemy potrzebne paczki. W projekcie będziemy używać data.table, poniewaz
# jest to srednio najszybszy i najwydajniejszy sposob pracy na duzych plikach.
# Stringi pozwalaja nam w wygodny sposob operowac napisami, natomiast XML poz-
# wala parsowac i generowac XML w R.
library(XML)
library(data.table)
library(stringi)


# funkcja load_xml:=
#   parametr file:= {lokalizacja pliku}
# funkcja parsuje plik file w formacie XML i generuje strukture jezyka R repre-
# zentujaca drzewo XML. Nastepnie wymusza na objekcie typ 'data.table'.
load_xml <- function(file) {
  xml <- xmlTreeParse(file,
                      useInternalNodes = TRUE)
  as.data.table(rbindlist(lapply(xml["//row"],
                                 function(x)as.list(xmlAttrs(x))), fill=TRUE))
}


# funkcja clear_html:=
#   html:= {sekcja mogoca zawierac tagi}
# Funkcja usuwa wszystkie tagi z html.
clear_html <- function(html) {
  return(gsub("<.*?>", "", html))
}


# Funkcja load_xml wszystko bierze jako napisy. Szereg funkcji naprawiajacych
# formatowanie (konwertujemy poszczegolne kolumny do 'numeric', usuwamy tagi).
# Funkcja przygotowuje 'Posts' do analizy.
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


# Naprawiamy 'Users'.
fix_users <- function(Users) {
  transform(Users, Id = as.numeric(Id),
            Reputation = as.numeric(Reputation),
            Views = as.numeric(Views),
            UpVotes = as.numeric(UpVotes),
            DownVotes = as.numeric(DownVotes),
            AccountId = as.numeric(AccountId),
            AboutMe = clear_html(AboutMe))
}


# Poprawiamy 'Comments'.
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

haot <- activity_over_time(HealthPostsDT, HealthCommentsDT)
gaot <- activity_over_time(GamingPostsDT, GamingCommentsDT)
baot <- activity_over_time(BeerPostsDT, BeerCommentsDT)

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

plot_aot(haot, gaot, baot)

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

#Godziny najwiekszej aktywnosci na forach

activity_hours <- function(Posts, Comments) {
  
  x <- Posts[, .(Id, CreationHour = substr(CreationDate,12,13))]
  x <- x[,.(.N), by = "CreationHour"]
  y <- Comments[,.(Id, CreationHour = substr(CreationDate,12,13))]
  y <- y[,.(.N), by = "CreationHour"]
  setkey(x,CreationHour)
  setkey(y,CreationHour)
  x <- merge(x, y, all = TRUE)
  setkey(x,CreationHour)
  x <- x[,.(CreationHour,NumberOfPostsAndComms = N.y + N.x)]
  #x <- x[order(-NumberOfPostsAndComms),]
}
# wykres
plot_activity <- function(Activity) {
  
  
  barplot(Activity$NumberOfPostsAndComms, names.arg = Activity$CreationHour,col = c('red','green'), xlab = "Godzina utworzenia postu lub komentarza", ylab = "Ilosc", space = 0)
  
}

ah <- activity_hours(BeerPostsDT, BeerCommentsDT)
ahGaming <- activity_hours(GamingPostsDT,GamingCommentsDT)
ahHealth <- activity_hours(HealthPostsDT, HealthCommentsDT)

plot_activity(ah)
plot_activity(ahGaming)
plot_activity(ahHealth)


# godziny w których najwięcej użytkowników odpowiada
most_answers_hours <- function(Posts) {
  x <- Posts[, .(Id, PostTypeId, CreationHour = substr(CreationDate,12,13))]
  x <- x[PostTypeId == 2]
  x <- x[,.(.N), by = "CreationHour"]
  x <- x[order(CreationHour)]
}

most_answers_plot <- function(anserwsHours) {
  
  barplot(anserwsHours$N, names.arg = anserwsHours$CreationHour,col = c('red','green'), xlab = "Godzina udzielenia odpowiedźi", ylab = "Ilosc", space = 0, axisnames = TRUE)
  
}



answersHoursBeer <- most_answers_hours(BeerPostsDT)
answersHoursGaming <- most_answers_hours(GamingPostsDT)
answersHoursHealth <- most_answers_hours(HealthPostsDT)
most_answers_plot(answersHoursBeer)
most_answers_plot(answersHoursGaming)
most_answers_plot(answersHoursHealth)



#najwiecej pytan o minecraft - nie dziala jeszcze
MC_answers <- function(Posts) {
  
  x <- Posts[PostTypeId == 1]
  x <- MC_interest(x)
  x <- x[,.(.N), by = substr(CreationDate,1,4) ]
  
}

MC_interest <- function(dt) {
  dt <- dt[stri_detect_regex(dt$Title,'minecraft', ignoreCases = TRUE) == TRUE]
}

McPosts <- MC_answers(GamingPostsDT)
barplot(McPosts$N, names.arg = McPosts$substr, col = 'cyan', xlab = "Rok", ylab = "Ilość pytań")

