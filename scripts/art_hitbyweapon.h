
FearRecovery() 
{ 

	
     if (DecreasingFear==1) return (1);  // better to use signals here


     DecreasingFear = 1;
     while(fear > 0) 
          { 
          fear = fear - RecoverConstant; 
          sleep RecoverRate; 
          } 
start-script RestoreAfterCover(); 
DecreasingFear=0; 
 
return (1); 
}


HitByWeaponId(z,x,id,damage)
{	
	if (Id<=300 || Id>700)
		return (100); // DON'T NEED BRACKETS FOR return STATEMENTS!
	
	if (300<Id && Id<=400) //301-400=small arms or very small calibre cannon: MGs, snipers, LMGs, 20mm
		fear = fear + LittleFear;
	if (400<Id && Id<=500) //401-500=small/med explosions: mortars, 75mm guns and under
		fear = fear + MedFear;
	if (500<Id && Id<=600) //501-600=large explosions: small bombs, 155mm - 88mm guns,
		fear = fear + BigFear;
	if (600<Id && Id<=700) //601-700=omgwtfbbq explosions: medium/large bombs, 170+mm guns, rocket arty 
		fear = fear + MortalFear;

	if (fear > FearLimit) fear = FearLimit; // put this line AFTER increasing fear var
		
	start-script TakeCover();
	sleep 100; // what is this for??
	start-script FearRecovery();
	
	return (1); //if it gets to here, its a nondamaging suppression weapon anyways, so 1% doesn't matter. // You can return 0 now
}

