package mmo.petfightnew.common.fightcontroller
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.ModalDialog;
   import mmo.common.ModalDialogEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.SocketClient;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.FightController;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.MCPetContainer;
   import mmo.petfightnew.common.panel.FailPanel;
   import mmo.petfightnew.common.panel.SuccessPanel;
   
   public class Escape implements IDispose
   {
      
      private static var _instance:Escape;
      
      private var fightPanel:FightPanel;
      
      private var locaId:int;
      
      private var slot:int;
      
      public var isEscape:Boolean = false;
      
      public var isVsEscape:Boolean = false;
      
      public var hasTeamMemberLeave:Boolean = false;
      
      private var _isEscape:Boolean = true;
      
      public function Escape()
      {
         super();
      }
      
      public static function get instance() : Escape
      {
         if(_instance == null)
         {
            _instance = new Escape();
         }
         return _instance;
      }
      
      public function init(param1:FightPanel) : void
      {
         this.fightPanel = param1;
      }
      
      public function escape(param1:int, param2:Boolean) : void
      {
         this._isEscape = param2;
         if(FightData.instance.playerInfo[param1] == null)
         {
            FightController.instance.handle();
            return;
         }
         this.slot = param1;
         this.locaId = FightData.instance.getLocaId(param1);
         this.setEscapeMc(this.locaId);
      }
      
      private function handleEscape(param1:int) : void
      {
         var num:int = 0;
         var player:PlayerBattleInfo = null;
         var localId:int = param1;
         if(FightController.instance.isReplay || !this._isEscape)
         {
            this.doClearPlayer(localId);
            FightController.instance.handle();
            return;
         }
         if(FightData.instance.myInfo.isMyControlLocalId(localId))
         {
            this.isEscape = true;
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.SHOW_END_PANEL,{"iswin":false}));
            this.fightPanel.stopTimer();
            this.fightPanel.closeWaitTips();
         }
         else
         {
            if(FightData.instance.isMySide(this.locaId))
            {
               NewDialog.getMessageDialog("队友离开了",function(param1:ModalDialog):*
               {
                  param1.addEventListener(ModalDialogEvent.OK,onClickOk);
                  param1.show();
               });
               this.hasTeamMemberLeave = true;
            }
            else
            {
               num = 0;
               for each(player in FightData.instance.playerInfo)
               {
                  if(player != null && !FightData.instance.isMySide(player.locaId))
                  {
                     num++;
                  }
               }
               if(num > 1)
               {
                  if(FightController.instance.canEscape)
                  {
                     this.isVsEscape = true;
                     if(!FightData.instance.isPFS2v2)
                     {
                        NewDialog.showMessage("对方逃跑了");
                     }
                  }
                  else if(!FightData.instance.isPFS2v2)
                  {
                     NewDialog.showMessage("对方离开了");
                  }
               }
               else
               {
                  FinBattle.instance.isEscape = true;
                  if(FightController.instance.canEscape)
                  {
                     this.isVsEscape = true;
                     this.showFailPanel("对方逃跑了," + "对方已全部离开。");
                  }
                  else
                  {
                     this.showFailPanel("对方离开了," + "对方已全部离开。");
                  }
                  CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.SHOW_END_PANEL,{"iswin":true}));
                  if(this.fightPanel != null)
                  {
                     this.fightPanel.stopTimer();
                     this.fightPanel.closeWaitTips();
                  }
               }
            }
            this.doClearPlayer(this.locaId);
         }
         FightController.instance.handle();
      }
      
      private function doClearPlayer(param1:int) : void
      {
         this.fightPanel.removeReady(this.locaId);
         this.fightPanel.hidePetInfoMC(this.locaId);
         FightData.instance.delPlayer(this.slot);
         --this.fightPanel.petLoadeNum;
      }
      
      private function setEscapeMc(param1:int) : void
      {
         var _loc2_:MCPetContainer = this.fightPanel.petMCList[param1];
         if(_loc2_)
         {
            _loc2_.disposeMouseResponder();
            _loc2_.showEscapeEffect(this.handleEscape);
         }
      }
      
      public function showSuccessPanel(param1:String) : void
      {
         var _loc2_:Sprite = new SuccessPanel(param1);
         ModalDialogManager.getInstance().addModalDialog(_loc2_);
      }
      
      public function showFailPanel(param1:String) : void
      {
         var _loc2_:Sprite = new FailPanel(param1);
         ModalDialogManager.getInstance().addModalDialog(_loc2_);
      }
      
      private function onClickOk(param1:ModalDialogEvent) : void
      {
         var _loc2_:ModalDialog = param1.target as ModalDialog;
         _loc2_.removeEventListener(ModalDialogEvent.OK,this.onClickOk);
         this.setEscapeAble();
      }
      
      private function setEscapeAble() : void
      {
         if(this.fightPanel.team != null && this.fightPanel.team.leader == SocketClient.instance.myUserName)
         {
            this.setMcEscapeFrame(1);
            MovieClip(this.fightPanel.layerUI.getChildByName("mcEscape")).mouseEnabled = true;
            MovieClip(this.fightPanel.layerUI.getChildByName("mcEscape")).mouseChildren = true;
         }
      }
      
      public function dispose() : void
      {
         this.fightPanel = null;
         _instance = null;
      }
      
      private function setMcEscapeFrame(param1:int) : void
      {
         if(FightController.instance.isEscapeEvacuate)
         {
            if(param1 == 1)
            {
               param1 = 3;
            }
            if(param1 == 2)
            {
               param1 = 4;
            }
         }
         MovieClip(this.fightPanel.layerUI.getChildByName("mcEscape")).gotoAndStop(param1);
      }
   }
}

