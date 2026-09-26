package mmo.petfightnew.common.fightcontroller
{
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.pm.data.custom.PMSkill;
   import mmo.interfaces.pet.pm.data.custom.PMSkillTypes;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.interfaces.team.ITeamService;
   import mmo.interfaces.team.TeamInfo;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.petfightnew.common.event.FightInnerEvent;
   import mmo.petfightnew.common.handler.SkillTargetSelecter;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.petfightnew.common.useskill.SkillRange;
   import mmo.play.petfight.common.data.SkillType;
   
   public class UseBigSkillHandler
   {
      
      private static var _instance:UseBigSkillHandler;
      
      private var _isUsing:Boolean;
      
      private var _skillId:int = 0;
      
      private var _skillType:int = 2;
      
      private var petInfo:PetBriefInfo;
      
      private var _index:int;
      
      public function UseBigSkillHandler()
      {
         super();
      }
      
      public static function get instance() : UseBigSkillHandler
      {
         if(_instance == null)
         {
            _instance = new UseBigSkillHandler();
         }
         return _instance;
      }
      
      public function handlerAutoUse(param1:PetBriefInfo, param2:int, param3:int) : void
      {
         if(this._isUsing)
         {
            return;
         }
         this._isUsing = true;
         this._skillId = param2;
         this._skillType = param3;
         this.petInfo = param1;
         var _loc4_:ITeamService = ServicePool.instance.getService(ITeamService);
         var _loc5_:TeamInfo = _loc4_.getMyTeam();
         var _loc6_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         var _loc7_:int = int(_loc6_.getPetSkillMes(this._skillId).range);
         FightEventDispatcher.instance.dispatchEvent(new FightInnerEvent(FightInnerEvent.CHANGE_USING_SKILL,{"skillBtn":null}));
         FightData.instance.targetSlot = SkillTargetSelecter.getDefaultSkillTarget(this._skillId,FightData.instance.myInfo.operatingPlayer.slotId);
         this.startUseSkill(-1,true);
      }
      
      public function handleUse(param1:PetBriefInfo, param2:int, param3:int, param4:int = -1) : void
      {
         if(this._isUsing)
         {
            return;
         }
         this._isUsing = true;
         this._skillId = param2;
         this._skillType = param3;
         this.petInfo = param1;
         this._index = -1;
         var _loc5_:ITeamService = ServiceContainer.instance.getService("TeamService") as ITeamService;
         var _loc6_:TeamInfo = _loc5_.getMyTeam();
         var _loc7_:IPetSkillMesService = ServicePool.instance.getService(IPetSkillMesService);
         var _loc8_:int = int(_loc7_.getPetSkillMes(this._skillId).range);
         FightEventDispatcher.instance.dispatchEvent(new FightInnerEvent(FightInnerEvent.CHANGE_USING_SKILL,{"skillBtn":null}));
         if(this._skillType == PMSkillTypes.GQ_XIANJINGJI_SKILL)
         {
            this.startUseSkill(param4);
            return;
         }
         switch(_loc8_)
         {
            case SkillRange.TEAMMATE:
               if(Boolean(FightData.instance.teammates) && FightData.instance.teammates.length <= 1)
               {
                  FightData.instance.targetSlot = FightData.instance.myInfo.operatingPlayer.slotId;
                  this.startUseSkill(param4);
                  break;
               }
               this._index = param4;
               this.addClickListener(true);
               break;
            case SkillRange.ENEMY_ONE:
               if(Boolean(FightData.instance.opponents) && FightData.instance.opponents.length <= 1)
               {
                  FightData.instance.targetSlot = FightData.instance.vsSlot;
                  this.startUseSkill(param4);
                  break;
               }
               if(Boolean(FightData.instance.opponents) && FightData.instance.getCanBattlePlayerNum(FightData.instance.opponents) <= 1)
               {
                  FightData.instance.targetSlot = FightData.instance.getCanBattleSlot(FightData.instance.opponents);
                  this.startUseSkill();
                  break;
               }
               this._index = param4;
               this.addClickListener(false);
               break;
            default:
               FightData.instance.targetSlot = FightData.instance.myInfo.operatingPlayer.slotId;
               this.startUseSkill(param4);
         }
      }
      
      private function addClickListener(param1:Boolean) : void
      {
         var _loc2_:PlayerBattleInfo = null;
         for each(_loc2_ in FightData.instance.playerInfo)
         {
            if(param1 && FightData.instance.isMySide(_loc2_.locaId) || !param1 && !FightData.instance.isMySide(_loc2_.locaId))
            {
               if(FightController.instance.fightPanel.contains(FightController.instance.fightPanel.petMCList[_loc2_.locaId]))
               {
                  FightController.instance.fightPanel.petMCList[_loc2_.locaId].addListen(_loc2_.slotId,param1);
               }
            }
         }
         FightEventDispatcher.instance.addEventListener(FightInnerEvent.CHANGE_USING_SKILL,this.changeUsingSkill);
         FightEventDispatcher.instance.addEventListener(PetFightEvent.CLICK_SKILL,this.onClickSkill);
      }
      
      private function onClickItemHolder(param1:PetFightEvent) : void
      {
         this.removeEventListener();
         this._isUsing = false;
         this.removePetListener();
      }
      
      private function changeUsingSkill(param1:FightInnerEvent) : void
      {
         this.removeEventListener();
         if(param1.params.skillBtn != null)
         {
            this._isUsing = false;
            this.removePetListener();
         }
      }
      
      private function onClickSkill(param1:PetFightEvent) : void
      {
         this.removeEventListener();
         if(param1.params.haveHit)
         {
            this.startUseSkill(this._index);
            this._index = -1;
         }
      }
      
      private function removeEventListener() : void
      {
         FightEventDispatcher.instance.removeEventListener(FightInnerEvent.CHANGE_USING_SKILL,this.changeUsingSkill);
         FightEventDispatcher.instance.removeEventListener(PetFightEvent.CLICK_SKILL,this.onClickSkill);
      }
      
      private function removePetListener() : void
      {
         var _loc1_:PlayerBattleInfo = null;
         try
         {
            for each(_loc1_ in FightData.instance.playerInfo)
            {
               if(FightController.instance.fightPanel.contains(FightController.instance.fightPanel.petMCList[_loc1_.locaId]))
               {
                  (FightController.instance.fightPanel.petMCList[_loc1_.locaId] as MCPetContainer).removeListen();
               }
            }
         }
         catch(e:Error)
         {
         }
      }
      
      public function cancelUse() : void
      {
         this._isUsing = false;
         this.removeEventListener();
         this.removePetListener();
      }
      
      private function startUseSkill(param1:int = -1, param2:Boolean = false) : void
      {
         this._isUsing = false;
         this.removePetListener();
         var _loc3_:IPMService = ServicePool.instance.getService(IPMService);
         var _loc4_:PMSkill = _loc3_.customData.pmSkillMap.getSkill(this._skillId);
         if(this._skillType == SkillType.AOYI_BIG)
         {
            this.petInfo.isUsedAoYiSkill = true;
         }
         else if(_loc4_.getSkillType() == PMSkillTypes.DEGENERATOR_KILL_BIG || _loc4_.getSkillType() == PMSkillTypes.DEGENERATOR_YU_KILL_BIG)
         {
            this.petInfo.curDegeneratorSoulNum -= _loc4_.costSoulNum;
         }
         else if(_loc4_.isLegendBigSkill())
         {
            this.petInfo.curSoulNum -= _loc4_.costSoulNum;
         }
         else if(PMSkillTypes.isXinghuiKillBig(_loc4_.getSkillType()))
         {
            this.petInfo.curXinghuiSoulNum -= _loc4_.costSoulNum;
         }
         else if(Boolean(PMSkillTypes.isGQKillBig(_loc4_.getSkillType())) || Boolean(PMSkillTypes.isGQSpiritSkill(_loc4_.getSkillType())))
         {
            this.petInfo.curGQSoulNum -= _loc4_.costSoulNum;
         }
         var _loc5_:PlayerBattleInfo = FightData.instance.myInfo.operatingPlayer;
         FightController.instance.useSkill(this._skillId,FightData.instance.targetSlot,_loc5_.slotId,param2,param1);
      }
      
      public function dispose() : void
      {
         _instance = null;
      }
      
      public function isHandling() : Boolean
      {
         return this._isUsing;
      }
      
      public function isUsingSkill(param1:int, param2:int) : Boolean
      {
         return this._skillType == param1 && this._skillId == param2;
      }
   }
}

