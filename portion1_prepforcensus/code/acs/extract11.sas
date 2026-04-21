options ls=100 nocenter nofmterr;
libname here '../../tmp';

proc freq data=here.acs2011;
tables agep / missing;

data here.extract2011;
set here.acs2011;
if agep>=18 and agep<=66;

drop ddrs dear deye dout dphy drat dratx drem gcl gcm gcr hins1-hins7
     jwrip jwtr mlpa mlpb mlpc mlpd mlpe mlpf mlpg mlph mlpi mlpj mlpk 
     nwab nwav nwla nwlk nwre anc anc1p anc2p drivesp
     jwap jwdp fagep fcitp fcitwp 
     fddrsp fdearp fdeyep fdisp fdoutp fdphyp fdratp fdratxp fdremp
     fengp fesrp fferp ffodp fgclp fgcmp fgcrp fhins1p fhins2p
     fhins3c fhins30 fhins4c fhins40 fhins5c fhins5p fhins6p fhins7p 
     fhisp findp fintp fjwdp fjwmnp fjwrip fjwtrp 
     flanp flanxp fmarp fmarhdp fmarhtp fmarhwp fmarhyp 
     fmilpp fmilsp foccp foip fpap 
     fpobp fpowsp fprivcovp fpubcovp fracp frelp fretp 
     fschgp fschlp fschp   
     fssip fssp  fwkhp fwklp fwkwp fwrkp fyoep pwgtp1-pwgtp80 ;

proc means;

