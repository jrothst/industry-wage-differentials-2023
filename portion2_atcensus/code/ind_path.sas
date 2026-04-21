/********************************
    This sets all the libnames and
    other programs
    ***************************/;
%let main =    [YIDATA] ;    
libname ppath "[LEHD2018]";
libname ddata "[YIDATA]";

%let acspath =    [ACS] ;
%let acsxwkpath = [ACSXWK];

libname acs (
    "/&acsxwkpath/2001",
    "/&acsxwkpath/2002",
    "/&acsxwkpath/2003",
    "/&acsxwkpath/2004",
    "/&acsxwkpath/2005",
    "/&acsxwkpath/2006",
    "/&acsxwkpath/2007",
    "/&acsxwkpath/2008",
    "/&acsxwkpath/2009",
    "/&acsxwkpath/2010",
    "/&acsxwkpath/2011",
    "/&acsxwkpath/2012",
    "/&acsxwkpath/2013",
    "/&acsxwkpath/2014",
    "/&acsxwkpath/2015",
    "/&acsxwkpath/2016",
    "/&acsxwkpath/2017",
    "/&acspath/2001",
    "/&acspath/2002",
    "/&acspath/2003",
    "/&acspath/2004",
    "/&acspath/2005",
    "/&acspath/2006",
    "/&acspath/2007",
    "/&acspath/2008",
    "/&acspath/2009",
    "/&acspath/2010",
    "/&acspath/2011",
    "/&acspath/2012",
    "/&acspath/2013",
    "/&acspath/2014",
    "/&acspath/2015",
    "/&acspath/2016",
    "/&acspath/2017");




