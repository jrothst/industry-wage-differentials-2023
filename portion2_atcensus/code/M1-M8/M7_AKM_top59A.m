% M7: AKM, worker and industry and CZ FEs, time-varying controls

%path to the matlabBGL files 
path(path,'[MABLAB_BGL]'); 

clear

disp('AKM estimation - model 7 - top 59A')

%LASTN=maxNumCompThreads(1);
l='all';


s=['Loading data for all , ' l '...'];
disp(s);

%% LOAD DATA
s='[YIDATA]/mig5_pikqtime_1018_top59A.raw';
tic
data=importdata(s);

% id ('uint32')
id=data(:,1);

% year ('int16')
year=data(:,2);

% firmid ('uint32')
% firmid=data(:,3);

% y ('double')
y=data(:,4);

% fsize ('uint16')
fsize_temp=round(data(:,5));

% age ('uint8')
age=data(:,6);

% cz ('uint16')
cz=data(:,7);

% naics4d ('uint8') NOTE: this is named firmid
firmid=data(:,8);
toc
clear data

%% create fsize
groupsums=accumarray(firmid,fsize_temp);
fsize=groupsums(firmid);
clear groupsums fsize_temp

% create lagged firm id
lagid=[NaN;id(1:end-1)];
sameid=lagid==id;
lagfirmid=[NaN;firmid(1:end-1)];
lagfirmid(~sameid)=NaN;
clear sameid

% rename original firmid, id, cz, naics variables
firmid_old=firmid;
id_old=id;
cz_old=cz;
% naics4d_old=naics4d;

fprintf('\n')

    big=fsize==max(fsize);
    ref=min(firmid(big));
    s=['Reference firm is: ' int2str(ref)];
    disp(s)
    s=['Reference firm has minimum size: ' int2str(min(fsize(firmid==ref)))];
    disp(s)
    maxid=max(firmid);
    firmid(firmid==ref)=maxid+1;
    lagfirmid(lagfirmid==ref)=maxid+1;

fprintf('\n')

lagfirmid(lagfirmid==-9)=NaN;


%% RENAME
disp('Relabeling ids...')
N=length(y);
sel=~isnan(lagfirmid);

%relabel the firms
[firms,m,n]=unique([firmid;lagfirmid(sel)]);

firmid=n(1:N);
lagfirmid(sel)=n(N+1:end);

%relabel the workers
[ids,m,n]=unique(id);
id=n;

%initial descriptive stats
fprintf('\n')
disp('Some descriptive stats:')
s=['# of p-y obs: ' int2str(length(y))];
disp(s);
s=['# of workers: ' int2str(max(id))];
disp(s);
s=['# of firms: ' int2str(max(firmid))];
disp(s);

s=['mean wage: ' num2str(mean(y))];
disp(s)
s=['variance of wage: ' num2str(var(y))];
disp(s)
fprintf('\n')


%% FIND CONNECTED SET
disp('Finding connected set...')
A=sparse(lagfirmid(sel),firmid(sel),1); %adjacency matrix
%make it square
[m,n]=size(A);
if m>n
    A=[A,zeros(m,m-n)];
end
if m<n
    A=[A;zeros(n-m,n)];
end
A=max(A,A'); %connections are undirected

[sindex, sz]=components(A); %get connected sets
idx=find(sz==max(sz)); %find largest set
s=['# of firms: ' int2str(length(A))];
disp(s);
s=['# connected sets:' int2str(length(sz))];
disp(s);
s=['Largest connected set contains ' int2str(max(sz)) ' firms'];
disp(s);
fprintf('\n')
clear A lagfirmid
firmlst=find(sindex==idx); %firms in connected set
sel=ismember(firmid,firmlst);


% Use obs in connected set
y=y(sel); firmid=firmid(sel); id=id(sel); year=year(sel); 
id_old=id_old(sel); firmid_old=firmid_old(sel); fsize=fsize(sel); 
age=age(sel); cz=cz(sel); cz_old=cz_old(sel); N=length(y); 
% naics4d=naics4d(sel); naics4d_old=naics4d_old(sel);

clear exp

disp('Relabeling ids again...')
%relabel the firms
[firms,m,n]=unique(firmid);
firmid=n;
[czs,m,n]=unique(cz);
cz=n;
% [naics2ds,m,n]=unique(naics4d);
% naics4d=n;

%relabel the workers
[ids,m,n]=unique(id);
id=n;

%% SAVE TEMP OUTPUT (this will write to the current directory)
% disp('Saving STATA TEST FILE')
% out=[id year firmid y fsize id_old firmid_old naics4d naics4d_old cz age ];
% s=['[DATA]/testing_estfile' int2str(i) '.txt'];
% dlmwrite(s, out, 'delimiter', '\t', 'precision', 16);
% clear out

%descriptive stats for connected set
fprintf('\n')
disp('Now restricted to the largest connected set');
s=['# of p-y obs: ' int2str(length(y))];
disp(s);
s=['# of workers: ' int2str(max(id))];
disp(s);
s=['# of firms: ' int2str(max(firmid))];
disp(s);

s=['mean wage: ' num2str(mean(y))];
disp(s)
s=['variance of wage: ' num2str(var(y))];
disp(s)
fprintf('\n')

%% ESTIMATE AKM
disp('Building matrices...')
NT=length(y);
N=max(id);
J=max(firmid);
K=max(cz);

% Dummy out fixed effects
D=sparse(1:NT,id',1);
F=sparse(1:NT,firmid',1);
G=sparse(1:NT,cz',1);
G(:,1)=[]; %drop first effect

S=speye(J-1);
S=[S;sparse(-zeros(1,J-1))];  %N+JxN+J-1 restriction matrix 

% Build time trends
yrmin=min(year); yrmax=max(year);

R=sparse(1:NT,(year-yrmin+1),1); 
idx=1+(yrmax-yrmin+1);
R(:,1)=[]; %drop first year effect
size(R)
% v5 - drop additional qtime effect too
disp('Change 12/22/20 - drop additional quarter - 5th one for seasonality')
disp('size now should be 32')
R(:,4)=[]; %drop second qtime effect
size(R)

% age cubic
age=((age-40)/40); %rescale to avoid big numbers
A=[age, age.^2, age.^3];

% tabulate(year)
size(R)
Z=[R, A];
clear R A 

X=[D,F*S,G,Z];

disp('Running AKM...')
tic
xx=X'*X;
xy=X'*y;
L=ichol(xx,struct('type','ict','droptol',1e-2,'diagcomp',.2));
b=pcg(xx,xy,1e-10,1000,L,L');
toc
disp('Done')
clear xx xy L

%% ANALYZE RESULTS
xb=X*b;
r=y-xb;

disp('Goodness of fit:')
dof=NT-J-K-N+1-size(Z,2)
RMSE=sqrt(sum(r.^2)/dof)

TSS=sum((y-mean(y)).^2)
R2=1-sum(r.^2)/TSS
adjR2=1-sum(r.^2)/TSS*(NT-1)/dof

% separate coefficients
ahat=b(1:N); %N pe
ghat=b(N+1:N+J-1); %J-1 fe
chat=b(N+J:N+J+K-2); %K-1 ce
bhat=b(N+J+K-1:end);
disp('check for problems with year effects. should report zero')
sum(bhat==0)
bhat

pe=D*ahat;
fe=F*S*ghat;
ce=G*chat;
xb=X(:,N+J+K-1:end)*bhat;

clear D F X b

disp('Variance-Covariance of worker and firm effs (p-y weighted)');
cov(pe,fe)
disp('Correlation coefficient');
corr(pe,fe)
disp('Correlation coefficient pe xb');
corr(pe,xb)
disp('Means of person/firm effs')
mean([pe,fe])

disp('Full Covariance Matrix of Components')
disp('    y      pe      fe      ce      xb      r')
C=cov([y,pe,fe,ce,xb,r])

disp('Decomposition #1')
disp('var(y) = cov(pe,y) + cov(fe,y) + cov(xb,y) + cov(r,y)');
c11=C(1,1); c21=C(2,1); c31=C(3,1); c41=C(4,1); c51=C(5,1);
s=[num2str(c11) ' = ' num2str(c21) ' + ' num2str(c31) ' + ' num2str(c41) ' + ' num2str(c51)];
disp(s)
fprintf('\n')
disp('explained shares:    pe       fe       xb       r')
s=['explained shares: ' num2str(c21/c11) '  ' num2str(c31/c11) '  ' num2str(c41/c11) '  ' num2str(c51/c11)];
disp(s)

fprintf('\n')
disp('Decomposition #2')
disp('var(y) = var(pe) + var(fe) + var(xb) + 2*cov(pe,fe) + 2*cov(pe,xb) + 2*cov(fe,xb) + var(r)');
c11=C(1,1); c22=C(2,2); c33=C(3,3); c44=C(4,4); c55=C(5,5); 
c23=C(2,3); c24=C(2,4); c34=C(3,4);
s=[num2str(c11) ' = ' num2str(c22) ' + ' num2str(c33) ' + ' num2str(c44) ' + '  num2str(2*c23) ' + ' num2str(2*c24) ' + ' num2str(2*c34) ' + ' num2str(c55)];
disp(s)
fprintf('\n')
disp('explained shares:    pe      fe      xb   cov(pe,fe)   cov(pe,xb)   cov(fe,xb)   r')
s=['explained shares: ' num2str(c22/c11) '  ' num2str(c33/c11) '  ' num2str(c44/c11) '  ' num2str(2*c23/c11) '  ' num2str(2*c24/c11) '  ' num2str(2*c34/c11) '  ' num2str(c55/c11)];
disp(s)
fprintf('\n')
clear age ahat cz firmid firmlst firms fsize id ids lagid m naics4d Z


%% SAVE OUTPUT (this will write to the current directory)

disp('Saving FEs only')
out1=[firmid_old fe pe];
[ii,jj,kk]=unique(out1(:,1:2), 'rows', 'stable');
out2=[ii,accumarray(kk,1),accumarray(kk,out1(:,3),[],@mean)];
s=['[DATA]/M7_AKM_top59A.txt'];
dlmwrite(s, out2, 'delimiter', '\t', 'precision', 16);
clear out1 out2;

disp('Saving main effects')
out=[id_old firmid_old year pe fe];
s=['[DATA]/M7_AKM_top59A_all.txt'];
dlmwrite(s, out, 'delimiter', '\t', 'precision', 16);
clear out;

diary off;
