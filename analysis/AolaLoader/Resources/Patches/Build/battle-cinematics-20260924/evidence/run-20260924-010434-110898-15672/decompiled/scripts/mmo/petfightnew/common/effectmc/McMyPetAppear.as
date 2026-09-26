package mmo.petfightnew.common.effectmc
{
   import flash.display.MovieClip;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.material.fightflauntresource.IFightFlauntResourceService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.petcommon.SuperPetHelper;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.util.DegeneratorPetHelper;
   import mmo.petfightnew.common.util.GQPetHelper;
   import mmo.petfightnew.common.util.LegendPetHelper;
   import mmo.petfightnew.common.util.XinghuiPetHelper;
   
   public class McMyPetAppear extends PetAppearEffect
   {
      
      private var _ffrSvr:IFightFlauntResourceService = ServiceContainer.getService(IFightFlauntResourceService);
      
      private var _pbi:PetBriefInfo;
      
      private var _container:MovieClip;
      
      public function McMyPetAppear(param1:int, param2:int, param3:MovieClip, param4:Function, param5:PetBriefInfo, param6:MovieClip)
      {
         this._pbi = param5;
         this._container = param6;
         super(param1,param2,param3,param4);
      }
      
      override protected function initEffectMc() : void
      {
         var cls:Class = null;
         super.initEffectMc();
         if(GQPetHelper.checkIsGQPet(this.raceId))
         {
            this.startFrame = 11;
            if(this._pbi.fightFlauntResArr[0] != this._ffrSvr.getDefaultFightFlauntResArr()[0])
            {
               this._ffrSvr.getFightFlauntResourceMovie(this._pbi.fightFlauntResArr[0],function(param1:MovieClip):void
               {
                  mcEffect = param1;
                  mcEffect.stop();
                  initEndCall();
               });
               return;
            }
            cls = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.GQAppearMovie") as Class;
         }
         else if(XinghuiPetHelper.checkIsXinghuiPet(this.raceId))
         {
            this.startFrame = 11;
            cls = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.XinghuiAppearMovie") as Class;
         }
         else if(DegeneratorPetHelper.checkIsShikigamiPet(this.raceId))
         {
            this.startFrame = 17;
            cls = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.DegeneratorAppearMovie") as Class;
         }
         else if(DegeneratorPetHelper.checkIsDegeneratorPet(this.raceId))
         {
            this.startFrame = 17;
            cls = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.DegeneratorAppearMovie") as Class;
         }
         else if(LegendPetHelper.checkIsLegendPet(this.raceId))
         {
            this.startFrame = 17;
            cls = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.LegendAppearMovie") as Class;
         }
         else if(SuperPetHelper.isSuperPet(this.raceId))
         {
            this.startFrame = 18;
            cls = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.McMySuperPetAppear") as Class;
         }
         else if(this.isHaveAoYiSkill())
         {
            this.startFrame = 3;
            cls = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.AoYiAppearMovie") as Class;
         }
         else
         {
            this.startFrame = 17;
            cls = FightData.instance.applicationDomain.getDefinition("mmo.petfightnew.McMyPetAppear") as Class;
         }
         this.mcEffect = new cls() as MovieClip;
         this.mcEffect.stop();
         this.initEndCall();
      }
      
      private function initEndCall() : void
      {
         this._container.addChild(this);
         this.play();
      }
      
      private function isHaveAoYiSkill() : Boolean
      {
         var _loc1_:PlayerBattleInfo = FightData.instance.playerInfo[FightData.instance.getSlotId(this.locaId)] as PlayerBattleInfo;
         var _loc2_:PetBriefInfo = _loc1_.myPets[0] as PetBriefInfo;
         return _loc2_.isGetAoYiSkill;
      }
   }
}

