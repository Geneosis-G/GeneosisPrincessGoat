class PrincessGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var StaticMeshComponent CrownMesh;
var SkeletalMeshComponent hairMesh;

var array<Material> goatMaterials;
var ParticleSystem transformationEffect;
var SoundCue transformationSound;

var bool isRightClicking;
var float charmTimer;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		CrownMesh.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( CrownMesh, 'hairSocket' );
		hairMesh.SetLightEnvironment( gMe.mesh.LightEnvironment );
		gMe.mesh.AttachComponentToSocket( hairMesh, 'hairSocket' );
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if( localInput.IsKeyIsPressed( "GBA_Jump", string( newKey ) ) )
		{
			if(gMe.mGrabbedItem != none && isRightClicking)
			{
				MakeItGoat();
			}
		}

		if( localInput.IsKeyIsPressed( "GBA_FreeLook", string( newKey ) ) )
		{
			isRightClicking=true;
		}

		if( localInput.IsKeyIsPressed( "GBA_Baa", string( newKey ) ) )
		{
			gMe.SetTimer( charmTimer, false, NameOf( charmNPCs ), self);
		}
	}
	else if( keyState == KS_Up )
	{
		if( localInput.IsKeyIsPressed( "GBA_Baa", string( newKey ) ) )
		{
			if(gMe.IsTimerActive(NameOf( charmNPCs ), self))
			{
				gMe.ClearTimer(NameOf( charmNPCs ), self);
			}
		}

		if( localInput.IsKeyIsPressed( "GBA_FreeLook", string( newKey ) ) )
		{
			isRightClicking=false;
		}
	}
}

//Transform NPCs into goats
function MakeItGoat()
{
	local vector newLoc;
	local GGNpc grabbedNpc;
	local GGNpcGoat newGoat;
	local int i;

	grabbedNpc=GGNpc(gMe.mGrabbedItem);
	if(grabbedNpc == none || GGNpcGoat(grabbedNpc) != none || grabbedNpc.Controller == none)
	{
		return;
	}
	newLoc=grabbedNpc.Mesh.GetPosition();
	newLoc.Z+=30.f;

	//Play effect
	gMe.PlaySound( transformationSound, true, true, , newLoc );
	gMe.WorldInfo.MyEmitterPool.SpawnEmitter( transformationEffect, newLoc );

	//Destroy old NPC
	gMe.DropGrabbedItem();
	grabbedNpc.Controller.Destroy();
	for( i = 0; i < grabbedNpc.Attached.Length; i++ )
	{
		if(GGGoat(grabbedNpc.Attached[i]) == none)
		{
			grabbedNpc.Attached[i].ShutDown();
			grabbedNpc.Attached[i].Destroy();
		}
	}
	grabbedNpc.SetPhysics(PHYS_None);
	grabbedNpc.SetLocation(vect(0, 0, -1000));
	grabbedNpc.SetHidden(true);
	grabbedNpc.ShutDown();
	grabbedNpc.Destroy();

	//Spawn NPC goat
	newGoat=gMe.Spawn(class'GGNpcGoat',,, newLoc, Rotator(Normal(gMe.Location-newLoc)),, true);
	newGoat.mesh.SetMaterial(0, goatMaterials[Rand(goatMaterials.Length)]);
	newGoat.SpawnDefaultController();
}

//Charm nearby NPCs
function CharmNPCs()
{
	local GGNpc npc;

	foreach gMe.CollidingActors( class'GGNpc', npc, PrincessGoat(myMut).charmRadius, gMe.Location )
	{
		PrincessGoat(myMut).CharmNPC(npc, gMe);
	}
}

defaultproperties
{
	charmTimer=1.f

	goatMaterials(0)=Material'goat.Materials.Goat_Mat_01'
	goatMaterials(1)=Material'goat.Materials.Goat_Mat_04'
	goatMaterials(2)=Material'goat.Materials.Goat_Mat_05'
	goatMaterials(3)=Material'goat.Materials.Goat_Mat_07'

	Begin Object class=StaticMeshComponent Name=StaticMeshComp1
		StaticMesh=StaticMesh'Hats.Mesh.Crown'
		Translation=(X=0.f,Y=0.f,Z=6.f)
		Scale3D=(X=1.f,Y=1.f,Z=0.5f)
		Materials(0)=Material'Kitchen_01.Materials.Chrome_Mat_01'
		Materials(1)=Material'Zombie_Particles.Materials.Crystal_Glow_Mat'
		Materials(2)=Material'Hats.Materials.Ruby_Mat'
	End Object
	CrownMesh=StaticMeshComp1

	Begin Object class=SkeletalMeshComponent Name=SkeletalMeshComponent1
		SkeletalMesh=SkeletalMesh'SanctumStuff.Mesh.Sweet_Hair'
		Scale=1.1f
	End Object
	hairMesh=SkeletalMeshComponent1

	transformationEffect=ParticleSystem'MMO_Effects.Effects.Effects_Hit_Server_01'
	transformationSound=SoundCue'Goat_Sounds.Cue.Effect_Goat_MagicMushroom_cue'
}