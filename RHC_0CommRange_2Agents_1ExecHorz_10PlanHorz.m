
		
		NumAgents = 2;
		CommRange = 0;
		ExecHorz = 1;
		PlanHorz = 10;
		
		[X,U,X_plans,opt_time,cpu_time,NumCollisions] = MinTime_RHC_VaryComm_2D_CVX(NumAgents,CommRange,ExecHorz,PlanHorz);
		
		listOfVariables = {'X','U','X_plans','opt_time','cpu_time','NumCollisions'};
		save('RHC_0CommRange_2Agents_1ExecHorz_10PlanHorz.mat',listOfVariables{:});
		
		