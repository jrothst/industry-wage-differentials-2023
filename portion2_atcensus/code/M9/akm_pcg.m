function [statistics, estimates]=akm_pcg(depvar, id_ind, time, id_firm, options)
  %Arguments:
  %%REQUIRED
  %  depvar   Dependent variable
  %  id_ind   Individual ID
  %  time     Time variable (year, quarter, etc.). Obs should be uniquely identified by [id_ind, time].
  %  id_firm  Firm ID
  %%OPTIONAL
  %  options.samp       Logical variable indicating which observations to use
  %  options.reffirm    ID number of firm to use as reference. MUST BE IN LARGEST CONNECTED SET!
  %  options.normalize  Indicator for group of observations (e.g., an industry) whose firm effects
  %                     will be normalized to zero
  %  options.age        Age variable
  %  options.agecontrol Functional form of age control
  %  options.saving     Path/filename to save results
  
  arguments
  	depvar 				(:,1) 	{mustBeNumeric,mustBeReal}
  	id_ind				(:,1)	{mustBeNumeric,mustBeReal,mustBeEqualSize(id_ind,depvar)}
  	time				(:,1)	{mustBeNumeric,mustBeReal,mustBeEqualSize(time,depvar)}
  	id_firm				(:,1)	{mustBeNumeric,mustBeReal,mustBeEqualSize(id_firm,depvar)}
  	options.samp		(:,1)	{logical,mustBeEqualSize(options.samp, depvar)}
  	options.reffirm		(1,1)	double
  	options.normalize   (:,1)  {mustBeNumeric,mustBeReal,mustBeEqualSize(options.normalize,depvar)}
  	options.age		    (:,1)	{mustBeNumeric,mustBeReal,mustBeEqualSize(options.age,depvar)}
  	options.agecontrol			{mustBeMember(options.agecontrol,["none","quadratic","cubic"])}="none"
  	options.saving				char
  end	
  
  %Prep the data. 
  if ~isfield(options,'samp')
      options.samp=true(size(depvar));
  end
  id=id_ind(options.samp);
  firmid=id_firm(options.samp);
  y=depvar(options.samp);
  t=time(options.samp);
  sample=options.samp;
  if ~isfield(options,'age')
    age=double.empty(length(y),0);
  else
     age=options.age(options.samp);
  end
  if ~isfield(options,'normalize');
    disp(['Normalize option not specified. Average firm effect in full connected set will be set to zero.'])
    normalize=true(size(y));
  else
    normalize=logical(options.normalize(options.samp));
    nnorm=sum(normalize)
    disp(['Normalize option specified. Normalization set contains ' int2str(nnorm) ' observations'])
  end
    
  %Keep track of original values, since we will be renumbering these;
  id_orig=id;
  firmid_orig=firmid;
  
  %Pick the reference firm. If specified, use it. Otherwise, select the largest firm in the sample
  if isfield(options,'reffirm')
     if max(id_firm==options.reffirm)==1
       ref=options.reffirm;
       disp(['Reference firm is specified as ' int2str(options.reffirm)])
     end
  end
  if ~exist('ref')==1
     %Code to pick largest firm
     disp(['Calculating largest firm as reference'])
     firmfreq=tabulate(firmid);
     big=max(firmfreq(:,2));
     bigfirm=firmfreq(:,2)==big;
     ref=firmfreq(bigfirm,1);
  end  
  maxfirm=max(firmid);
  s=['Reference firm is: ' int2str(ref) '. Recoded to ' int2str(maxfirm+1)];
  disp(s)
  results.reffirm=ref;
  firmid(firmid==ref)=maxfirm+1;
   
  %Identify lagged firms 
  lagid=[NaN; id(1:end-1)];
  sameid=lagid==id;
  lagfirmid=[NaN; firmid(1:end-1)];
  lagfirmid(~sameid)=NaN;
  %samefirm=lagfirmid==firmid;
  
  %Relabel the firms;
  N=length(y);
  sel=~isnan(lagfirmid);
  [~, ~, n]=unique([firmid; lagfirmid(sel)]);
  firmid=n(1:N);
  lagfirmid(sel)=n(N+1:end);
  
  %Relabel the workers
  [~, ~, n]=unique(id);
  id=n;
  
  %initial descriptive stats
  fprintf('\n')
  results.numpy=length(y);
  results.nump=max(id);
  results.numf=max(firmid);
  results.meany=mean(y);
  results.vary=var(y);
  disp('Some descriptive stats - original sample:')
  s=['# of p-y obs: ' int2str(results.numpy)];
  disp(s);
  s=['# of workers: ' int2str(results.nump)];
  disp(s);
  s=['# of firms: ' int2str(results.numf)];
  disp(s);
  s=['mean wage: ' num2str(results.meany)];
  disp(s)
  s=['variance of wage: ' num2str(results.vary)];
  disp(s)
  fprintf('\n')

  %FIND CONNECTED SET
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
  firmlst=find(sindex==idx); %firms in connected set
  sel=ismember(firmid,firmlst);  
  %sample(sample==1)=sel;
  %Relabel again
  y=y(sel); firmid=firmid(sel); id=id(sel);
  t=t(sel); age=age(sel,:); normalize=normalize(sel);
  id_orig=id_orig(sel); firmid_orig=firmid_orig(sel);
  disp('Relabeling ids again...')
  %relabel the firms
  [~,~,n]=unique(firmid);
  firmid=n;
  %relabel the workers
  [~,~,n]=unique(id);
  id=n;
  
  %Descriptive statistics for largest connected set
  results.numsets=length(sz);
  
  results.numpy_c=length(y);
  results.nump_c=max(id);
  results.numf_c=max(firmid);
  results.meany_c=mean(y);
  results.vary_c=var(y);
  disp('Some descriptive stats - largest connected set:')
  s=['# connected sets:' int2str(length(sz))];
  disp(s);
  s=['Largest connected set contains ' int2str(max(sz)) ' firms'];
  disp(s);
  s=['# of p-y obs: ' int2str(results.numpy_c) ' (' num2str(100*results.numpy_c/results.numpy,3) '% of total)'];
  disp(s);
  s=['# of workers: ' int2str(results.nump_c) ' (' num2str(100*results.nump_c/results.nump,3) '% of total)'];
  disp(s);
  s=['# of firms: ' int2str(results.numf_c) ' (' num2str(100*results.numf_c/results.numf,3) '% of total)'];
  disp(s);
  s=['mean wage: ' num2str(results.meany_c)];
  disp(s)
  s=['variance of wage: ' num2str(results.vary_c)];
  disp(s)
  fprintf('\n')
  clear A lagfirmid
  
  %Build control variable matrix for AKM
  disp('Building matrices...')
  NT=length(y);
  N=max(id);
  J=max(firmid);
  D=sparse(1:NT,id',1);
  F=sparse(1:NT,firmid',1);
  S=speye(J-1);
  S=[S;sparse(-zeros(1,J-1))];  %N+JxN+J-1 restriction matrix 
  
  %Build controls
  %Time controls
   newtime=(t-min(t)+1);
   R=sparse(1:NT, newtime,1);
   R(:,max(newtime))=[];   %Drop last time period;
  %Age controls 
  if isfield(options,'agecontrol')
    age=(age-40)/40; %Rescale to avoid big numbers
    if string(options.agecontrol)=='quadratic'
      A=age.^2;
      disp(['quadratic age control specified'])
    end
    if string(options.agecontrol)=='cubic'
      A=[age.^2, age.^3];
      disp(['cubic age control specified'])
    end
  else
    A=double.empty(NT,0);
  end
  Z=[R, A];
  clear R A;
  
  X=[D, F*S, Z];
  
  %Estimate AKM
  disp('Running AKM...')
  tic
  xx=X'*X;
  xy=X'*y;
  L=ichol(xx,struct('type','ict','droptol',1e-2,'diagcomp',.2));
  b=pcg(xx,xy,1e-10,1000,L,L');
  toc
  disp('Done')
  clear xx xy L
  
  %ANALYZE RESULTS
  xb=X*b;
  r=y-xb;

  disp('DOF:')
  dof=NT-J-N+1-size(Z,2)
  disp('Goodness of fit (RMSE, TSS, R2, adjR2):')
  RMSE=sqrt(sum(r.^2)/dof);
  TSS=sum((y-mean(y)).^2);
  R2=1-sum(r.^2)/TSS;
  adjR2=1-sum(r.^2)/TSS*(NT-1)/dof;
  [RMSE TSS/NT R2 adjR2]
  results.dof=dof; results.RMSE=RMSE; results.TSS=TSS; results.R2=R2; results.adjR2=adjR2;

  ahat=b(1:N);
  ghat=b(N+1:N+J-1);
  bhat=b(N+J:end);
  disp('check for problems with covariate coefficients. should report zero')
  sum(bhat==0)

  pe=D*ahat;
  fe=F*S*ghat;
  xb=X(:,N+J:end)*bhat;

  disp('Normalizing firm effects')
  cons=mean(fe(normalize));
  fe=fe-cons;
  pe=pe+cons;
  clear cons

  clear D F X b

  disp('Variance-Covariance of worker and firm effs (p-y weighted)');
  results.covpefe=cov(pe,fe);
  results.covpefe
  disp('Correlation coefficient');
  results.corrpefe=corr(pe,fe);
  results.corrpefe
  disp('Means of person/firm effs')
  results.meanpe=mean(pe);
  results.meanfe=mean(fe);
  [results.meanpe results.meanfe]

  disp('Full Covariance Matrix of Components')
  disp('    y      pe      fe      xb      r')
  C=cov([y,pe,fe,xb,r])
  results.C=C;

  disp('Decomposition #1')
  disp('var(y) = cov(pe,y) + cov(fe,y) + cov(xb,y) + cov(r,y)');
  c11=C(1,1); c21=C(2,1); c31=C(3,1); c41=C(4,1); c51=C(5,1);
  results.decomp1=[c11, c21, c31, c41, c51];
  s=[num2str(c11) ' = ' num2str(c21) ' + ' num2str(c31) ' + ' num2str(c41) ' + ' num2str(c51)];
  disp(s)
  fprintf('\n')
  disp('explained shares:    pe       fe       xb       r')
  s=['explained shares: ' num2str(c21/c11) '  ' num2str(c31/c11) '  ' num2str(c41/c11) '  ' num2str(c51/c11)];
  disp(s)
  results.decomp1_shares=[1, c21/c11, c31/c11, c41/c11, c51/c11];

  fprintf('\n')
  disp('Decomposition #2')
  disp('var(y) = var(pe) + var(fe) + var(xb) + 2*cov(pe,fe) + 2*cov(pe,xb) + 2*cov(fe,xb) + var(r)');
  c11=C(1,1); c22=C(2,2); c33=C(3,3); c44=C(4,4); c55=C(5,5); 
  c23=C(2,3); c24=C(2,4); c34=C(3,4);
  results.decomp2=[c11, c22, c33, c44, 2*c23, 2*c24, 2*c34, c55];
  s=[num2str(c11) ' = ' num2str(c22) ' + ' num2str(c33) ' + ' num2str(c44) ' + '  num2str(2*c23) ' + ' num2str(2*c24) ' + ' num2str(2*c34) ' + ' num2str(c55)];
  disp(s)
  fprintf('\n')
  disp('explained shares:    pe      fe      xb   cov(pe,fe)   cov(pe,xb)   cov(fe,xb)   r')
  s=['explained shares: ' num2str(c22/c11) '  ' num2str(c33/c11) '  ' num2str(c44/c11) '  ' num2str(2*c23/c11) '  ' num2str(2*c24/c11) '  ' num2str(2*c34/c11) '  ' num2str(c55/c11)];
  disp(s)
  results.decomp2_shares=[1, c22/c11, c33/c11, c44/c11, 2*c23/c11, 2*c24/c11, 2*c34/c11, c55/c11];
  fprintf('\n')

  %joint distribution and separability
  fedec = ceil(10 * tiedrank(fe) / length(fe));
  pedec = ceil(10 * tiedrank(pe) / length(pe));
  p=NaN(10,10);
  meanr=p;
  for j=1:10
    for k=1:10
        p(j,k)=mean((pedec==j)&(fedec==k));
        meanr(j,k)=mean(r.*(pedec==j).*(fedec==k))/p(j,k);
    end
  end
  disp('Joint distribution of effects (rows are deciles of pe, cols are deciles of fe)') 
  p
  disp('Mean residual by pe/fe decile')
  meanr
  results.jointdist_p=p;
  results.jointdist_e=meanr;

  clear fedec pedec

  %match effects
  disp('Match Effects Model')
  dig=ceil(max(log10(firmid)));
  firmiddec=firmid./(10^dig);
  matchid=id+firmiddec;
  [matchnew,m,n]=unique(matchid);
  matchid=n;
  M=sparse(1:NT,matchid',1);
  X=[M,Z];
  xx=X'*X;
  xy=X'*y;
  L=ichol(xx,struct('type','ict','droptol',1e-2,'diagcomp',.1));
  b=pcg(xx,xy,1e-10,1000,L,L');
  r_match=y-X*b;
  dof_match=NT-size(X,2)
  RMSE_match=sqrt(sum(r_match.^2)/dof_match)
  R2_match=1-sum(r_match.^2)/TSS
  adjR2_match=1-sum(r_match.^2)/TSS*(NT-1)/dof_match
  results.dof_match=dof_match;
  results.RMSE_match=RMSE_match;
  results.R2_match=R2_match;
  results.adjR2_match=adjR2_match;
  clear Z r_match b

  %further decomposition
  fprintf('\n')
  disp('Further Decompositions:')
  disp('Decomposing residual into match and transitory component')
  xx=M'*M;
  xy=M'*r;
  m=M*(xx\xy);
  e=r-m;
  disp('Full Covariance Matrix of Components')
  disp('    y      pe      fe      xb      m      e')
  C=cov([y,pe,fe,xb,m,e])
  results.decomp4_cov=C;
  clear M
  %even further decomposition
  disp('Decomposing transitory component into firm/time and person component')
  F2=sparse(1:NT,newtime*J+firmid,1);
  F2=F2(:,any(F2,1));
  xx=F2'*F2;
  xy=F2'*e;
  L=ichol(xx,struct('type','ict','droptol',1e-2));
  bf=pcg(xx,xy,1e-10,1000,L,L');
  f=F2*bf;
  e2=e-f;
  disp('Full Covariance Matrix of Components')
  disp('    y      pe      fe      xb      m      f      e2')
  C=cov([y,pe,fe,xb,m,f,e2])
  results.decomp4_cov=C;
  clear F2 xx xy m f e e2

  out=[id_orig firmid_orig t pe fe xb r y];
  results
  if isfield(options,'saving')
    disp(['Finished calculation - saving results to ' options.saving])
    tic
    writematrix(out, options.saving);
    %dlmwrite(options.saving, out, 'delimiter', '\t', 'precision', 16);
    disp(['Results saved to ' options.saving])
    toc
  end
  statistics=results;
  estimates=out;
end

% Custom validation function
function mustBeEqualSize(a,b)
    % Test for equal size
    if ~isequal(size(a),size(b))
        eid = 'Size:notEqual';
        msg = 'Size of first input must equal size of second input.';
        throwAsCaller(MException(eid,msg))
    end
end

