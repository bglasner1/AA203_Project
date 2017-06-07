import os

for numAgents in [2, 3, 4, 5]:
	for CommRange in [0, 10, 100]:
	
		matlabstartup = '''
		
NumAgents = %d;
CommRange = %d;
ExecHorz = 1;
PlanHorz = 10;
		
[X,U,X_plans,opt_time,cpu_time,NumCollisions] = MinTime_RHC_VaryComm_2D_CVX(NumAgents,CommRange,ExecHorz,PlanHorz);
		
listOfVariables = {'X','U','X_plans','opt_time','cpu_time','NumCollisions'};
save('RHC_%dCommRange_%dAgents_1ExecHorz_10PlanHorz.mat',listOfVariables{:});
		
''' % (numAgents, CommRange, CommRange, numAgents)
		
		qsubscript = '''#!/bin/bash
#$ -0 job.out
#$ -e job.error
#$ -cwd
#$ /bin/bash##$ -l testq=1
		
module load matlab
matlab -nodesktop -singleCompThread < RHC_%dCommRange_%dAgents_1ExecHorz_10PlanHorz.m
''' %(CommRange, numAgents)
		
		runfile = open('RHC_%dCommRange_%dAgents_1ExecHorz_10PlanHorz.m' % (CommRange, numAgents), 'w')
		runfile.write(matlabstartup)
		runfile.close()
		
		qsubfile = open('RHC_%dCommRange_%dAgents_1ExecHorz_10PlanHorz.submit' % (CommRange, numAgents), 'w')
		qsubfile.write(qsubscript)
		qsubfile.close()
		
		os.system('qsub RHC_%dCommRange_%dAgents_1ExecHorz_10PlanHorz.submit' % (CommRange, numAgents))
		