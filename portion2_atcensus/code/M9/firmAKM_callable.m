function firmAKM_callable(infile, outfile)

%% Introduction/setup
disp('Starting matlab function to estimate AKM model')
path(path,'[MABLAB_BGL]'); %path to the matlabBGL files

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
 id=(rawdata(:,1));
 time=(rawdata(:,2)); 
 firmid_orig=(rawdata(:,3));
 y=(rawdata(:,4));
 age=(rawdata(:,5));
 cz=rawdata(:,6);
 normind=rawdata(:,7);
 [~, ~, firmid]=unique(firmid_orig); 
 disp('Raw data prepped')
 
 %% Call to AKM -- loop over CZs;
 tic
     [stats,ests]=akm_pcg(y, id, time, firmid,  "age", age, "agecontrol", "cubic", "normalize", normind);
 disp('All done running AKM!')
 toc
 elapsedtime=toc(startprog)
 
%% Save results
outfile_person=[outfile '_person.raw']; 
outfile_firm=[outfile '_firm.raw']; 
outfile_xbr=[outfile '_xbr.raw']; 
outfile_cz=[outfile '_cz.raw']; 
outfile_stats=[outfile '_stats.raw']; 
%% moises change allfx=(ests(:,[1 2 3 4 5 6 7 8]),'rows');
personfx=unique(ests(:,[1 4]),'rows');
firmfx=unique(ests(:,[2 5]),'rows');
xbr=unique(ests(:,[1 3 6 7]),'rows');
cz=unique(cz);
%Make a table of the stats output;
varnames={'numpy_c', 'nump_c', 'numf_c', 'numpy', 'nump', 'numf', 'meany_c', 'vary_c', 'meany', 'vary', 'reffirm', 'dof', 'RMSE', 'TSS', 'R2', 'adjR2', 'meanpe', 'meanfe', 'corrpefe', 'R2_match', 'adjR2_match'};
stattable=table(stats.numpy_c, stats.nump_c, stats.numf_c, stats.numpy, stats.nump, stats.numf, stats.meany_c, stats.vary_c, stats.meany, stats.vary, stats.reffirm, stats.dof, stats.RMSE, stats.TSS, stats.R2, stats.adjR2, stats.meanpe, stats.meanfe, stats.corrpefe, stats.R2_match, stats.adjR2_match, 'VariableNames', varnames)
dlmwrite(outfile_xbr, xbr, 'precision', 16);
dlmwrite(outfile_person, personfx, 'precision', 16);
dlmwrite(outfile_firm, firmfx, 'precision', 16);
%% moises change dlmwrite(outfile_all, allfx, 'precision', 16); 
dlmwrite(outfile_cz, unique(cz), 'precision', 16);
writetable(stattable, outfile_stats,'FileType','text');
disp('Done saving!');

disp('Finished matlab function to estimate AKM model')
disp(['Output saved to' outfile])

%% end
end


