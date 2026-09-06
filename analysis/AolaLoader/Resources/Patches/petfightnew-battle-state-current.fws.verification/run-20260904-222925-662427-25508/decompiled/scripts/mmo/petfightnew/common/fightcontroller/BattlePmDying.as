package mmo.petfightnew.common.fightcontroller
{
   import mmo.framework.comm.PetClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.DocPetFight;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.config.FightConfig;
   import mmo.petfightnew.common.data.MyInfo;
   import mmo.petfightnew.common.ui.WaitTips;
   import mmo.petfightnew.common.util.StatusUtil;
   
   public class BattlePmDying implements IDispose
   {
      
      private static var _instance:BattlePmDying;
      
      private var fightPanel:FightPanel;
      
      private var switchType:int = 0;
      
      public function BattlePmDying()
      {
         super();
      }
      
      public static function get instance() : BattlePmDying
      {
         if(_instance == null)
         {
            _instance = new BattlePmDying();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
      }
      
      public function battlePmDying(param1:Object) : void
      {
         FightData.instance.myInfo.resetDieForSwitchSlots();
         var _loc2_:String = param1.ss || "";
         var _loc3_:String = param1.xx || "";
         if(_loc2_.length == 0 && _loc3_.length == 0)
         {
            FightController.instance.handle();
            return;
         }
         _loc2_ = _loc2_.replace(/-/g,"");
         _loc3_ = _loc3_.replace(/-/g,"");
         if(FightController.instance.isReplay)
         {
            this.handlerReplayDying(_loc2_,_loc3_);
         }
         else
         {
            this.handlerBattleDying(_loc2_,_loc3_);
         }
      }
      
      private function handlerBattleDying(param1:String, param2:String) : void
      {
         var _loc7_:int = 0;
         var _loc3_:String = "";
         var _loc4_:Boolean = FightController.isAutoUseSkill;
         var _loc5_:Function = this.handleOtherSwitch;
         this.setMyNeedSwitchSlotIds(param1);
         var _loc6_:Array = FightData.instance.myInfo.getDieForSwitchSlots();
         if(_loc6_.length > 0)
         {
            for each(_loc7_ in _loc6_)
            {
               FightData.instance.myInfo.setPlayerOperatedState(_loc7_,false);
            }
            if(_loc4_ || !FightData.instance.myInfo.haveCanSwitchUpPetOnDying())
            {
               _loc5_ = this.handleAuto;
            }
            else
            {
               _loc5_ = this.startManualSwitch;
            }
         }
         if(Boolean(param1) && param1.length > 0)
         {
            _loc3_ = param1;
            if(Boolean(param2) && param2.length > 0)
            {
               _loc3_ += "#" + param2;
            }
         }
         else
         {
            _loc3_ = param2;
         }
         this.parseDieInfoAndShow(_loc3_,_loc5_);
         if(param1.length > 0)
         {
            if(this.switchType > 0)
            {
               this.fightPanel.showWaitTips(this.switchType);
            }
         }
      }
      
      private function setMyNeedSwitchSlotIds(param1:String) : void
      {
         var _loc3_:String = null;
         var _loc4_:int = 0;
         if(param1 == null || param1.length == 0)
         {
            return;
         }
         var _loc2_:Array = param1.split("#");
         for each(_loc3_ in _loc2_)
         {
            _loc4_ = parseInt(_loc3_.split("-")[0]);
            if(FightData.instance.myInfo.isMyControlSlotId(_loc4_))
            {
               FightData.instance.myInfo.addDieForSwitchSlot(_loc4_);
            }
         }
      }
      
      private function handlerReplayDying(param1:String, param2:String) : void
      {
         var _loc3_:String = "";
         var _loc4_:Function = this.handleOtherSwitch;
         if(Boolean(param1) && param1.length > 0)
         {
            _loc3_ = param1;
            if(Boolean(param2) && param2.length > 0)
            {
               _loc3_ += "#" + param2;
            }
         }
         else
         {
            _loc3_ = param2;
         }
         this.parseDieInfoAndShow(_loc3_,_loc4_);
      }
      
      private function handleAuto() : void
      {
         var _loc1_:Array = FightData.instance.myInfo.getDieForSwitchSlots();
         var _loc2_:Array = FightData.instance.myInfo.getCanSwitchUpPetsInDyingSwitch();
         var _loc3_:int = 0;
         while(_loc3_ < _loc1_.length)
         {
            if(_loc2_[_loc3_] > 0 && !FightData.instance.myInfo.hasOperated(_loc1_[_loc3_]))
            {
               PetClient.instance.switchPM(_loc2_[_loc3_],FightController.instance.turnCount,_loc1_[_loc3_]);
            }
            else
            {
               PetClient.instance.standby(FightController.instance.turnCount + 1,true,_loc1_[_loc3_]);
            }
            _loc3_++;
         }
         this.fightPanel.stopTimer();
         FightController.instance.handle();
      }
      
      public function handleManualSwitch() : void
      {
         var _loc1_:MyInfo = FightData.instance.myInfo;
         var _loc2_:Array = _loc1_.getCanSwitchUpPetsInDyingSwitch();
         if(_loc2_.length <= 0)
         {
            this.handleAuto();
            return;
         }
         var _loc3_:Array = _loc1_.getDieForSwitchSlots();
         var _loc4_:int = int(_loc1_.operatingPlayer.slotId);
         if(_loc3_.indexOf(_loc4_) == -1)
         {
            this.fightPanel.setPlayerOperating(_loc3_[0]);
         }
         this.fightPanel.setPetsClicked();
         this.fightPanel.disableOperateBtnClick();
         FightController.instance.handle();
      }
      
      private function startManualSwitch() : void
      {
         this.fightPanel.countDown(FightConfig.getTempSwitchOperateSeconds(),this.handleAuto);
         this.handleManualSwitch();
      }
      
      private function handleOtherSwitch() : void
      {
         FightController.instance.handle();
      }
      
      private function parseDieInfoAndShow(param1:String, param2:Function) : void
      {
         var count:int = 0;
         var info:String = null;
         var slotId:int = 0;
         var locaId:int = 0;
         var player:PlayerBattleInfo = null;
         var pbi:PetBriefInfo = null;
         var dieInfo:String = param1;
         var onEnd:Function = param2;
         var infos:Array = dieInfo.split("#");
         count = int(infos.length);
         var counter:int = 0;
         var onEffectEnd:Function = function():*
         {
            if(++counter >= count)
            {
               BossMovieHelper.instance.checkMovieAndPlay(function():void
               {
                  onEnd.apply();
               });
            }
         };
         this.switchType = 0;
         for each(info in infos)
         {
            slotId = int(info);
            locaId = FightData.instance.getLocaId(slotId);
            player = FightData.instance.playerInfo[slotId];
            if(player != null)
            {
               if(!FightData.instance.isMySide(locaId))
               {
                  this.switchType = WaitTips.VS_SELECTING_PET;
               }
               else if(!FightData.instance.myInfo.isMyControlSlotId(slotId))
               {
                  this.switchType = WaitTips.TEAMMATE_OPERATING;
               }
               if(player.myPets != null && player.myPets[0] != null)
               {
                  pbi = player.myPets[0];
                  if(StatusUtil.getIsInLiangziXinglianState(pbi))
                  {
                     if(FightData.instance.myInfo.isMyControlSlotId(slotId))
                     {
                        --FightData.instance.canControlPetNum;
                        FightData.instance.myInfo.delPlayerInfos(player);
                        FightData.instance.myInfo.updateRealTimeRoleHpData(pbi.uqi,pbi.id,pbi);
                     }
                     FightData.instance.delPlayer(slotId,false);
                  }
                  else if(StatusUtil.getIsInHunDunJueDouState(pbi))
                  {
                     if(FightData.instance.myInfo.isMyControlSlotId(slotId))
                     {
                        if(FightData.instance.isSummonedPetOfLocalPosition(player.locaId))
                        {
                           --FightData.instance.canControlPetNum;
                           FightData.instance.myInfo.delPlayerInfos(player);
                        }
                        FightData.instance.myInfo.updateRealTimeRoleHpData(pbi.uqi,pbi.id,pbi);
                     }
                     if(FightData.instance.isSummonedPetOfLocalPosition(player.locaId))
                     {
                        FightData.instance.delPlayer(slotId,false);
                     }
                     (player.myPets[0] as PetBriefInfo).status = "";
                  }
                  else if(StatusUtil.getIsAsDyingButHasHp(pbi))
                  {
                     pbi.curHp = StatusUtil.getAsDyingHpNum(pbi);
                     FightData.instance.myInfo.updateRealTimeRoleHpData(pbi.uqi,pbi.id,pbi);
                     pbi.curHp = 0;
                  }
                  else
                  {
                     pbi.curHp = 0;
                     FightData.instance.myInfo.updateRealTimeRoleHpData(pbi.uqi,pbi.id,pbi);
                  }
                  FightController.instance.useSkillCacher.dispatchPetDie({
                     "dieLocaId":locaId,
                     "raceId":player.myPets[0].raceId
                  });
                  this.fightPanel.refreshHunDunState(locaId,player.myPets[0]);
               }
            }
            this.removeIconBySlotId(slotId);
            this.showPetDieEffect(slotId,onEffectEnd);
         }
      }
      
      private function showPetDieEffect(param1:int, param2:Function) : void
      {
         var slotId:int = param1;
         var onEnd:Function = param2;
         var locaId:int = FightData.instance.getLocaId(slotId);
         var petMc:MCPetContainer = this.fightPanel.petMCList[locaId];
         if(DocPetFight.skipBattlePresentation)
         {
            if(petMc)
            {
               petMc.disposeMouseResponder();
               petMc.visible = false;
            }
            onEnd();
            return;
         }
         if(petMc)
         {
            petMc.disposeMouseResponder();
            petMc.showDieEffect(function():void
            {
               onEnd.apply(null,[]);
            });
         }
         else
         {
            onEnd();
         }
      }
      
      private function removeIconBySlotId(param1:int) : void
      {
         var _loc2_:int = FightData.instance.getLocaId(param1);
         this.fightPanel.hidePetInfoMC(_loc2_);
         (this.fightPanel.petMCList[_loc2_] as MCPetContainer).hideMyMark();
      }
      
      public function dispose() : void
      {
         this.fightPanel = null;
         _instance = null;
      }
   }
}

