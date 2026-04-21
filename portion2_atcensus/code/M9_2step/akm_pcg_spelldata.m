function [statistics, estimates]=akm_pcg_spelldata(depvar, id_ind, id_firm, options)
  %Arguments:
  %%REQUIRED
  %  depvar   Dependent variable
  %  id_ind   Individual ID
  %  id_firm  Firm ID
  %%OPTIONAL
  %  options.samp       Logical variable indicating which observations to use
  %  options.reffirm    ID number of firm to use as reference. MUST BE IN LARGEST CONNECTED SET!
  %  options.weight     Frequency weight for this observation (i.e., number of quarters at job spell)
  %  options.normalize  Indicator for group of observations (e.g., an industry) whose firm effects
  %                     will be normalized to zero
  %  options.saving     Path/filename to save results
  
  arguments
  	depvar 				(:,1) 	{mustBeNumeric,mustBeReal}
  	id_ind				(:,1)	{mustBeNumeric,mustBeReal,mustBeEqualSize(id_ind,depvar)}
  	id_firm				(:,1)	{mustBeNumeric,mustBeReal,mustBeEqualSize(id_firm,depvar)}
  	options.samp		(:,1)	{logical,mustBeEqualSize(options.samp, depvar)}
  	options.reffirm		(1,1)	double
  	options.normalize   (:,1)   {mustBeNumeric,mustBeReal,mustBeEqualSize(options.normalize,depvar)}
  	options.weight      (:,1)   {mustBeNumeric,mustBeReal,mustBeEqualSize(options.weight,depvar)}
  	options.saving				char
  end	
  
  %Prep the data. 
  if ~isfield(options,'samp')
      options.samp=true(size(depvar));
  end
  id=id_ind(options.samp);
  firmid=id_firm(options.samp);
  y=depvar(options.samp);
  sample=options.samp;
  if ~isfield(options,'weight')
    weight=1+zeros(length(y),1);
  else
    weight=options.weight(options.samp);
  end
  if ~isfield(options,'normalize');
    disp(['Normalize option not specified. Average firm effect in full connected set will be set to zero.'])
    normalize=true(size(y));
  else
    normalize=logical(options.normalize(options.samp));
    nnorm=sum(normalize);
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
     firmfreq=accumarray(firmid,weight,[],[],[],true);
     [big, ref]=max(firmfreq(:,1))     
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
  wnorm=weight./sum(weight);
  results.numpj=length(y);
  results.numpt=sum(weight);
  results.nump=max(id);
  results.numf=max(firmid);
  results.meany=(wnorm.'*y);
  results.vary=var(y, wnorm);
  disp('Some descriptive stats - original sample:')
  s=['# of person-job obs: ' int2str(results.numpj)];
  disp(s);
  s=['# of person-time obs: ' int2str(results.numpt)];
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
  %%%FOR TESTING, ASSUME ALL OBS IN LARGEST CONNECTED SET
     %sindex=[1];
     %sz=[max(m,n)];
     %firmlst=unique(firmid);

  sel=ismember(firmid,firmlst);  
  %sample(sample==1)=sel;
  %Relabel again
  y=y(sel); firmid=firmid(sel); id=id(sel);
  normalize=normalize(sel);
  weight=weight(sel); wnorm=weight./sum(weight);
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
  
  results.numpt_c=sum(weight);
  results.nump_c=max(id);
  results.numf_c=max(firmid);
  results.meany_c=wnorm.'*y;
  results.vary_c=var(y,wnorm);
  disp('Some descriptive stats - largest connected set:')

  s=['# connected sets:' int2str(length(sz))];
  disp(s);
  s=['Largest connected set contains ' int2str(max(sz)) ' firms'];
  disp(s);
  s=['# of p-t obs: ' int2str(results.numpt_c) ' (' num2str(100*results.numpt_c/results.numpt,3) '% of total)'];
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
  NJ=length(y);
  NT=sum(weight);
  N=max(id);
  J=max(firmid);

  D=sparse(1:NJ,id',1);
  F=sparse(1:NJ,firmid',1);
  S=speye(J-1);
  S=[S;sparse(-zeros(1,J-1))];  %N+JxN+J-1 restriction matrix 
  
  %%%For Raffa's version
  %%%X=[D, -F*S];
  X=[D,F*S];
  W=spdiags(weight,0,NJ,NJ);
  
  %Estimate AKM
  disp('Running AKM...')
  tic
  xx=X'*W*X;
  xy=X'*W*y;
  L=ichol(xx,struct('type','ict','droptol',1e-2,'diagcomp',.2));
  b=pcg(xx,xy,1e-10,1000,L,L');
  %Raffa code
  % L = cmg_sdd(xx); %preconditioner for Laplacian matrices.
  % b= pcg(xx,xy,1e-10,1000,L); %LS estimates are going to be in b.  
  toc
  disp('Done')
  clear xx xy L
  
  %ANALYZE RESULTS
  xb=X*b;
  r=y-xb;

  disp('DOF:')
  dof=NT-J-N+1
  disp('Goodness of fit (RMSE, TSS, R2, adjR2):')
  RMSE=sqrt(weight.'*(r.^2)/dof);
  TSS=weight.'*((y-mean(y)).^2);
  R2=1-weight.'*(r.^2)/TSS;
  adjR2=1-weight.'*(r.^2)/TSS*(NT-1)/dof;
  [RMSE TSS/NT R2 adjR2]
  results.dof=dof; results.RMSE=RMSE; results.TSS=TSS; results.R2=R2; results.adjR2=adjR2;

  ahat=b(1:N);
  ghat=b(N+1:N+J-1);

  pe=D*ahat;
  fe=F*S*ghat;

  disp('Normalizing firm effects')
  cons=weight(normalize).'*fe(normalize)/sum(weight(normalize))
  fe=fe-cons;
  pe=pe+cons;
  clear cons

  clear D F X b

  %NOTE: FOR THIS WEIGHTED AKM MODEL, WE WILL NOT CALCULATE SUMMARY STATISTICS HERE,
  %BUT WILL LEAVE IT TO STATA TO CALCULATE ON THE FULL (NON-SPELL) DATA.

  out=[id_orig firmid_orig weight pe fe xb r y];
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

