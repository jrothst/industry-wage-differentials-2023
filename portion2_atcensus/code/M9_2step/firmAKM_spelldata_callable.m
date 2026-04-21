function firmAKM_spelldata_callable(infile, outfile)

%% Introduction/setup
disp('Starting matlab function to estimate AKM model')
path(path,'[MABLAB_BGL]'); %path to the matlabBGL files
system('rm firmAKM_spelldata.log');
diary('firmAKM_spelldata.log')
LASTN=maxNumCompThreads(1);
disp('Ready to proceed')
startprog=tic;

%% Read raw data
note=['Loading data from ' infile];
disp(note);
 tic
 rawdata=importdata(infile);
 rawdata=rawdata.data;
 toc
disp('Data successfully read')

%% prep raw data 
 %Construct variables;
 %Data come from: <export delimited workerid firmnum jobmean cz normind joblength>
 id=(rawdata(:,1));
 firmid_orig=(rawdata(:,2));
 y=(rawdata(:,3));
 cz=rawdata(:,4);
 normind=rawdata(:,5);
 jobwgt=(rawdata(:,6));
 [~, ~, firmid]=unique(firmid_orig); 
 clear rawdata;
 disp('Raw data prepped')
 
 %% Call to AKM -- loop over CZs
 tic
     [stats,ests]=akm_pcg_spelldata(y, id, firmid, "normalize", normind, "weight", jobwgt);
 disp('All done running AKM!')
 toc
 elapsedtime=toc(startprog)
 
%% Save results
outfile_person=[outfile '_person.raw']; 
outfile_firm=[outfile '_firm.raw']; 
outfile_cz=[outfile '_cz.raw']; 
outfile_stats=[outfile '_stats.raw']; 

personfx=unique(ests(:,[1 4]),'rows');
firmfx=unique(ests(:,[2 5]),'rows');
cz=unique(cz);
 %Make a table of the stats output;
  % Abbreviated version for the weighted model.
  varnames={'numpt_c', 'nump_c', 'numf_c', 'numpj', 'numpt', 'nump', 'numf', 'meany_c', 'vary_c', 'meany', 'vary', 'reffirm', 'dof', 'RMSE', 'TSS', 'R2', 'adjR2'};
  stattable=table(stats.numpt_c, stats.nump_c, stats.numf_c, stats.numpj, stats.numpt, stats.nump, stats.numf, stats.meany_c, stats.vary_c, stats.meany, stats.vary, stats.reffirm, stats.dof, stats.RMSE, stats.TSS, stats.R2, stats.adjR2, 'VariableNames', varnames)
dlmwrite(outfile_person, personfx, 'precision', 16);
dlmwrite(outfile_firm, firmfx, 'precision', 16);
dlmwrite(outfile_cz, unique(cz), 'precision', 16);
writetable(stattable, outfile_stats,'FileType','text');
disp('Done saving!');

disp('Finished matlab function to estimate AKM model via 2-step method')
disp(['Output saved to' outfile])


%% end
end


