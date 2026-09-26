package mmo.petfightnew.common.fightcontroller
{
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.DateUtil;
   import mmo.common.GlobalVariable;
   import mmo.common.ProgressFullSprite;
   import mmo.common.event.EnterFrameManager;
   import mmo.common.eventdispatcher.CommonEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.sound.SoundManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.ServiceNames;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.ILevelUp;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.pet.petpackage.IPetPackageService;
   import mmo.interfaces.task.ITaskService;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class FinBattle implements IDispose
   {
      
      private static var _instance:FinBattle;
      
      public var isEscape:Boolean = false;
      
      private var isShowEndPanel:Boolean = false;
      
      private var fightPanel:FightPanel;
      
      public function FinBattle()
      {
         super();
      }
      
      public static function get instance() : FinBattle
      {
         if(_instance == null)
         {
            _instance = new FinBattle();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
      }
      
      public function finBattle() : void
      {
         SoundManager.instance.stopBackgroundMusic();
         if(this.isWin())
         {
            FightController.instance.playSound("x7009",false,0.7);
            this.showFailEffect(false);
         }
         else
         {
            FightController.instance.playSound("x7010",false,0.8);
            this.showFailEffect(true);
         }
      }
      
      public function isWin() : Boolean
      {
         var _loc1_:int = FightController.instance.whoWon;
         if(_loc1_ == 2 || _loc1_ == 1)
         {
            return true;
         }
         return false;
      }
      
      private function showFailEffect(param1:Boolean) : void
      {
         var _loc4_:PlayerBattleInfo = null;
         var _loc5_:MCPetContainer = null;
         var _loc2_:Boolean = true;
         var _loc3_:Boolean = false;
         for each(_loc4_ in FightData.instance.playerInfo)
         {
            if(param1 && FightData.instance.isMySide(_loc4_.locaId) || !param1 && !FightData.instance.isMySide(_loc4_.locaId))
            {
               _loc2_ = false;
               this.fightPanel.hidePetInfoMC(_loc4_.locaId);
               _loc5_ = this.fightPanel.petMCList[_loc4_.locaId];
               if(_loc5_)
               {
                  if(_loc3_)
                  {
                     if(_loc5_.showDieEffect(null))
                     {
                        FightController.instance.useSkillCacher.dispatchPetDie({
                           "dieLocaId":_loc4_.locaId,
                           "raceId":_loc4_.myPets[0].raceId
                        });
                     }
                  }
                  else if(_loc5_.showDieEffect(this.delay))
                  {
                     _loc3_ = true;
                     FightController.instance.useSkillCacher.dispatchPetDie({
                        "dieLocaId":_loc4_.locaId,
                        "raceId":_loc4_.myPets[0].raceId
                     });
                  }
               }
            }
         }
         if(_loc2_ && !this.isEscape)
         {
            this.endFight();
         }
      }
      
      private function delay(param1:int) : void
      {
         var locaId:int = param1;
         EnterFrameManager.instance.registerNextFrame(function():void
         {
            onFaildEffectPlayed(locaId);
         });
      }
      
      private function onFaildEffectPlayed(param1:int) : void
      {
         var _loc2_:ILevelUp = null;
         if(FightController.instance.isAuto || !FightController.isHandlePanel)
         {
            _loc2_ = ServicePool.instance.getService(ILevelUp);
            _loc2_.clearDataWhileAuto();
            if(this.fightPanel != null)
            {
               this.fightPanel.close();
            }
         }
         else if(!this.isShowEndPanel)
         {
            this.isShowEndPanel = true;
            this.endFight();
         }
      }
      
      private function endFight() : void
      {
         if(FightController.instance.isReplay || FightController.instance.finishWithNoPanel)
         {
            this.handlerPanel();
            return;
         }
         this.showEndFightPanel();
      }
      
      private function showEndFightPanel() : void
      {
         var _loc1_:Sprite = null;
         var _loc2_:ITaskService = null;
         var _loc3_:Date = null;
         var _loc4_:Date = null;
         CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.SHOW_END_PANEL,{"iswin":this.isWin()}));
         if(this.isWin())
         {
            FightController.instance.handlePanel();
         }
         else
         {
            _loc2_ = ServicePool.instance.getService(ITaskService);
            _loc3_ = new Date(_loc2_.getUserTask(150).finishDate);
            _loc4_ = DateUtil.getServerTime();
            if(Boolean(_loc2_.isNewbie()) || _loc4_.time - _loc3_.time < 1000 * 60 * 60 * 24 * 30)
            {
               GlobalVariable.instance.setVar("LOSE_PANEL_FRAME_2020",{"frame":2});
               new LosePanel(this.handlerPanel,this.handlerPanel,this.handlerPanel).showPanel();
            }
            else
            {
               new LosePanel(this.handlerPanel,this.handlerPanel,this.handlerPanel).showPanel();
            }
         }
      }
      
      private function onClickOK(param1:MouseEvent) : void
      {
         this.handlerPanel();
      }
      
      private function onClickProve(param1:MouseEvent) : void
      {
         var index:int = 0;
         var evt:MouseEvent = param1;
         this.onClickOK(evt);
         index = parseInt(evt.target.name.split("_")[1]);
         ProgressFullSprite.show();
         ServiceContainer.instance.tryGetService(ServiceNames.PET_PACKAGE,function(param1:IPetPackageService, param2:Object):void
         {
            ProgressFullSprite.close();
            param1.showPanel();
            param1.changeToTargetTab([1,index]);
         });
      }
      
      private function onClickBuy(param1:MouseEvent) : void
      {
         this.onClickOK(param1);
         CommonEventDispatcher.instance.dispatchEvent(new CommonEvent("newbie_task_one_buy_discout_180330",{}));
      }
      
      private function handlerPanel() : void
      {
         FightController.instance.handlePanel();
      }
      
      private function showHowToLevelupPanel(param1:MouseEvent) : void
      {
      }
      
      public function dispose() : void
      {
         this.fightPanel = null;
         _instance = null;
      }
   }
}

