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


# funkcja parsuje plik file w formacie XML i generuje strukture jezyka R repre-
# zentujaca drzewo XML. Nastepnie wymusza na objekcie typ 'data.table'.
load_xml <- function(file) {
  xml <- xmlTreeParse(file,
                      useInternalNodes = TRUE)
  as.data.table(rbindlist(lapply(xml["//row"],
                                 function(x)as.list(xmlAttrs(x))), fill=TRUE))
}


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


# Zastosowujemy formatowanie dla poszczegolnych paczek. Najpierw piwo.
BeerCommentsDT <- fix_comments(load_xml("beer_stackexchange/Comments.xml"))
BeerPostsDT <- fix_posts(load_xml("beer_stackexchange/Posts.xml"))
BeerUsersDT <- fix_users(load_xml("beer_stackexchange/Users.xml"))


HealthCommentsDT <- fix_comments(load_xml("health_stackexchange/Comments.xml"))
HealthPostsDT <- fix_posts(load_xml("health_stackexchange/Posts.xml"))
HealthUsersDT <- fix_users(load_xml("health_stackexchange/Users.xml"))


GamingCommentsDT <- fix_comments(load_xml("gaming_stackexchange/Comments.xml"))
GamingPostsDT <- fix_posts(load_xml("gaming_stackexchange/Posts.xml"))
GamingUsersDT <- fix_users(load_xml("gaming_stackexchange/Users.xml"))


# Funkcja analizujaca jakie tematy najbardziej interesuja uzytkownikow.
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


# Sprawdzamy aktywnosc uzytkownikow w czasie. Definiuje ja liczba postow
# i komentarzy w poszczegolnych watkach.
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


# Projektujemy wykres porównawczy.
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
}


# Generujemy wykres.
plot_aot(haot, gaot, baot)


# Analiza odchylen:
# 1. Wzrost zainteresowania Grami w połowie 2016 roku spowodowany premiera
#    viralowej gry Pokemon GO na Androida i IOS.
# 2. Wzrost zainteresowania Zdrowiem w 2020 roku zwiazany jest z epidemia
#    koronawirusa na swiecie.
# 3. Wzrost zainteresowania w srodku 2017 roku Piwem moze byc spowodowany
#    slynna juz partia piw pewnej ukrainskiej browarni ktora postanowila
#    wypuscic serie piw majacych na etykietach swiatowych liderow. Na jednym z
#    nich pojawil sie Donald Trump. Zapoczatkowala to pewien trend, w ktorym 
#    przerozne browarnie z calego swiata umieszczaly Trump'a na swoich etykietach.


# 22 pierwsze tagi ~~ 50% ilosci wyswietlen
hmvt <- most_viewed_tags(HealthPostsDT)
gmvt <- most_viewed_tags(GamingPostsDT)
bmvt <- most_viewed_tags(BeerPostsDT)


# Projektujemy wykres najpopularniejszych tagów w poszczegolnych kategoriach.
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


# Generujemy wykresy.
plot_mvt(hmvt)
plot_mvt(gmvt)
plot_mvt(bmvt)


# W ciagu ostatnich lat spoleczenstwo bardzo zainteresowalo sie zdrowym trybem
# zycia. A jak wiadomo nie ma zdrowego trybu zycia bez diety. Weganstwo mozna by
# powiedziec ze stalo sie w pewnym momencie modne, szczegolnie wsrod mieszkancow
# wielkich miast i klasy sredniej. Ostatnie lata byly wyjatkowe plodne jezeli
# chodzi o powstanie firm kateringowych oferujacych 'pudelkowa diete na dowoz'.
# Widac wiec ze trend zostal zauwazony.


# Jezeli chodzi o gry to nieprzerwanie od kilku lat kroluje Minecraft. Gra nadal
# sie cieszy mianem najpopularniejszej gry na swiecie. Drugi jest Skyrim, ktory
# przezywal w ciagu ostatnich lat druga mlodosc. W 2016 roku wyszla jego zrema-
# sterowana wersja. Ponadto gra, rok pozniej, doczekala sie wersji VR.


# Smak to glowna, najwazniejsza cecha kazdego piwa. 'Zdrowie' na drugim miejscu
# potwierdza hipoteze z poprzedniego wykresu. Zdrowe zycie jest modne.


# Funkcja ta, na podstawie zamieszczanych przez uzytkownikow postow i komentarzy
# analizuje 'najgoretsze' godziny.
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


# Ustawiamy wykres.
plot_activity <- function(Activity) {
  barplot(Activity$NumberOfPostsAndComms, names.arg = Activity$CreationHour,col = c('cyan','green'), xlab = "Godzina utworzenia postu lub komentarza", ylab = "Ilosc", space = 0)
}


ah <- activity_hours(BeerPostsDT, BeerCommentsDT)
ahGaming <- activity_hours(GamingPostsDT,GamingCommentsDT)
ahHealth <- activity_hours(HealthPostsDT, HealthCommentsDT)


# Generujemy wykresy.
plot_activity(ah)
plot_activity(ahGaming)
plot_activity(ahHealth)


# Wykres prezentujący najpopularniejsze godziny utworzenia postu lub komentarza
# w watkach dotyczacych piwa jasno wskazuje ze milosnicy tego trunku uaktywniaja
# sie dopiero popoludniu. Nie jest to dziwne patrzac na to w jaki sposob dziala
# alkohol.


# W przypadku gier rozstrzal jest troche mniejszy ale wyglada podobnie. Ludzie
# oddaja sie rozrywkom czy relaksowi raczej w pozniejszych godzinach dnia.


# W przypadku Zdrowia sprawa ma sie nieco inaczej. Istnieje tutaj oczywiscie
# rowniez przewaga godzin pozniejszych ale roznica miedzy innymi godzinami jest
# znacznie mniejsza. Sugeruje to ze ludzie jednak sa sklonni rozmawiac o swoim
# zdrowiu w kazdej chwili bo jak wiadomo zdrowie to sprawa wazna, a nie jak w 
# przypadku piwa i gier - w wolnym czasie.


# Funkcja sprawdza, w ktorych godzinach najwiecej uzytkownikow jest sklonna
# komus odpowiedziec.
most_answers_hours <- function(Posts) {
  x <- Posts[, .(Id, PostTypeId, CreationHour = substr(CreationDate,12,13))]
  x <- x[PostTypeId == 2]
  x <- x[,.(.N), by = "CreationHour"]
  x <- x[order(CreationHour)]
}


# Projektujemy wykres.
most_answers_plot <- function(anserwsHours) {
  barplot(anserwsHours$N, names.arg = anserwsHours$CreationHour,col = c('cyan','green'), xlab = "Godzina udzielenia odpowiedźi", ylab = "Ilosc", space = 0, axisnames = TRUE)
}


answersHoursBeer <- most_answers_hours(BeerPostsDT)
answersHoursGaming <- most_answers_hours(GamingPostsDT)
answersHoursHealth <- most_answers_hours(HealthPostsDT)


# Generujemy wykresy.
most_answers_plot(answersHoursBeer)
most_answers_plot(answersHoursGaming)
most_answers_plot(answersHoursHealth)


# Wykresy wygladaja bardzo podobnie do tych poprzednich. Potwierdzaja tylko 
# wyprowadzone przez nas hipotezy. Jest jednak subtelna roznica. Wykres Zdrowia
# bardziej upodabnia sie do wykresu gier. Ludzie podchodza do swojego zdrowia
# bardzo powaznie, ale jezeli chodzi o zdrowie innych - moze zaczekac.


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

