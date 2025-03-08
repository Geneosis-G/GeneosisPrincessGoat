class PrincessGoat extends GGMutator;

struct CharmedNPCInfo{
	var GGGoat charmer;
	var GGAIController contr;
	var float oldAttackRange;
	var NPCAnimationInfo oldAngyAnim;
	var ProtectInfo oldProtectInfo;
};

var float charmRadius;
var array<CharmedNPCInfo> charmedNPCs;
var array<CharmedNPCInfo> uncharmedNPCs;

//Charm target NPC
function CharmNPC(GGNpc npc, GGGoat charmer)
{
	local CharmedNPCInfo cNPCInf;

	cNPCInf.charmer=charmer;
	cNPCInf.contr=GGAIController(npc.Controller);
	if(!npc.mIsRagdoll && cNPCInf.contr != none)
	{
		if(charmedNPCs.Find('contr', cNPCInf.contr) == INDEX_NONE)
		{
			npc.PlaySoundFromAnimationInfoStruct( npc.mApplaudAnimationInfo );
			cNPCInf.oldAttackRange=npc.mAttackRange;
			cNPCInf.oldAngyAnim=npc.mAngryAnimationInfo;
			cNPCInf.oldProtectInfo=cNPCInf.contr.mCurrentlyProtecting;
			npc.mAngryAnimationInfo=npc.mApplaudAnimationInfo;
			charmedNPCs.AddItem(cNPCInf);
		}
	}
}

event Tick( float deltaTime )
{
	local CharmedNPCInfo cNPCInf;
	local int index;

	super.Tick( deltaTime );

	//Make charmed NPCs run at the goat
	uncharmedNPCs.Length=0;
	//gMe.WorldInfo.Game.Broadcast(gMe, "charmedNPCs.Length=" $ charmedNPCs.Length);
	foreach charmedNPCs(cNPCInf)
	{
		ControlCharmedNPC(cNPCInf);
	}
	//Remove NPCs that are not charmed any more
	foreach uncharmedNPCs(cNPCInf)
	{
		cNPCInf.contr.EndAttack();
		cNPCInf.contr.mPawnToAttack=none;
		cNPCInf.contr.mMyPawn.mAttackRange=cNPCInf.oldAttackRange;
		cNPCInf.contr.mAttackIntervalInfo.LastTimeStamp=0.f;
		cNPCInf.contr.mMyPawn.mAngryAnimationInfo=cNPCInf.oldAngyAnim;
		cNPCInf.contr.mCurrentlyProtecting=cNPCInf.oldProtectInfo;
		cNPCInf.contr.mLastSeenGoat=none;
		index=charmedNPCs.Find('contr', cNPCInf.contr);
		charmedNPCs.Remove(index, 1);
	}
}

function ControlCharmedNPC(CharmedNPCInfo cNPCInf)
{
	local GGNpc charmedNpc;
	local GGAIController charmedNPCController;
	local float distToGoat, r, r2, h;
	local vector dir;

	charmedNPCController=cNPCInf.contr;
	charmedNpc=charmedNPCController.mMyPawn;
	dir=cNPCInf.charmer.Location - charmedNpc.Location;
	dir.Z=0.f;
	distToGoat=VSize(dir);

	cNPCInf.charmer.GetBoundingCylinder(r, h);
	charmedNpc.GetBoundingCylinder(r2, h);
	if(!charmedNpc.mIsRagdoll && distToGoat < r+r2)
	{
		charmedNpc.SetRagdoll(true);
	}

	if(charmedNpc.mIsRagdoll || distToGoat > charmRadius*2.f)
	{
		uncharmedNPCs.AddItem(cNPCInf);
		return;
	}

	charmedNPCController.mCurrentlyProtecting.ProtectItem=charmedNpc;
	charmedNPCController.mCurrentlyProtecting.ProtectRadius=charmRadius*2.f;
	charmedNPCController.mPawnToAttack=cNPCInf.charmer;
	charmedNpc.mAttackRange=0.f;
	charmedNPCController.mAttackIntervalInfo.LastTimeStamp=WorldInfo.TimeSeconds + 10.f;

	charmedNPCController.UnlockDesiredRotation();
	charmedNpc.SetDesiredRotation( rotator( Normal2D( cNPCInf.charmer.Location - charmedNpc.Location ) ) );
	charmedNpc.LockDesiredRotation( true );
	if(charmedNPCController.mCurrentState != 'ProtectItem')
	{
		charmedNPCController.GotoState('ProtectItem');
	}
	if(charmedNPCController.IsTimerActive( 'DelayedGoToProtect' ))
	{
		charmedNPCController.ClearTimer( 'DelayedGoToProtect' );
		charmedNPCController.DelayedGoToProtect();
	}
}

DefaultProperties
{
	mMutatorComponentClass=class'PrincessGoatComponent'

	charmRadius=2000.f
}