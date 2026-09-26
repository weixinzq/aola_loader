package mmo.petfightnew.common.panel
{
   import flash.events.MouseEvent;
   import mmo.common.DisplayUtil;
   import mmo.common.member.MemberManager;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.PetClient;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.interfaces.team.ITeamService;
   import mmo.interfaces.team.TeamInfo;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.event.FightEventDispatcher;
   import mmo.petfightnew.common.fightcontroller.CatchPm;
   import mmo.petfightnew.common.panel.item.NewItemHolder;
   
   public class CatchItemHolder extends NewItemHolder
   {
      
      public function CatchItemHolder()
      {
         super();
      }
      
      override public function update(param1:Object) : void
      {
         super.update(param1);
         if(this._itemId == 164 && !MemberManager.instance.isMember())
         {
            DisplayUtil.applyGray(this);
            this.buttonMode = false;
            TipsManager.getInstance().removeTips(this);
            TipsManager.getInstance().addTips(this,"蓝宝石亚比球无法使用哦,快去成为蓝宝石骑士吧",0,-85);
         }
         else
         {
            DisplayUtil.clearFilters(this);
            this.buttonMode = true;
         }
      }
      
      override public function dispose() : void
      {
         super.dispose();
         FightEventDispatcher.instance.removeEventListener(PetFightEvent.CLICK_SKILL,this.onClickCatch);
      }
      
      override protected function onClickItem(param1:MouseEvent) : void
      {
         var _loc4_:PlayerBattleInfo = null;
         if(!FightController.instance.canCatch || this._itemId == 164 && !MemberManager.instance.isMember())
         {
            return;
         }
         CatchPm.instance.selectedCatchItemId = this._itemId;
         FightController.instance.fightPanel.stopTimer();
         var _loc2_:ITeamService = ServiceContainer.instance.getService("TeamService") as ITeamService;
         var _loc3_:TeamInfo = _loc2_.getMyTeam();
         if(_loc3_ == null || _loc3_.teamLength == 1)
         {
            PetClient.instance.catchPM(FightData.instance.vsSlot,this._itemId,FightController.instance.turnCount);
            FightController.instance.fightPanel.setFightClicked();
            FightController.instance.fightPanel.disableClick();
         }
         else
         {
            FightController.instance.fightPanel.disableOperateBtnClick();
            this.parent.mouseChildren = false;
            for each(_loc4_ in FightData.instance.playerInfo)
            {
               if(_loc4_.locaId >= 5)
               {
                  FightController.instance.fightPanel.petMCList[_loc4_.locaId].addListen(_loc4_.slotId);
               }
            }
            FightEventDispatcher.instance.addEventListener(PetFightEvent.CLICK_SKILL,this.onClickCatch);
         }
      }
      
      private function onClickCatch(param1:PetFightEvent) : *
      {
         FightEventDispatcher.instance.removeEventListener(PetFightEvent.CLICK_SKILL,this.onClickCatch);
         PetClient.instance.catchPM(FightData.instance.targetSlot,this._itemId,FightController.instance.turnCount);
         FightController.instance.fightPanel.setFightClicked();
         FightController.instance.fightPanel.disableClick();
      }
   }
}

