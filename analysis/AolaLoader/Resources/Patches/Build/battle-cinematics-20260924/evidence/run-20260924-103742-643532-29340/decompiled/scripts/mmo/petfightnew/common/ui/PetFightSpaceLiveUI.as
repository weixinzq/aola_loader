package mmo.petfightnew.common.ui
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import mmo.common.dialog.NewDialog;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.interfaces.live.ILiveService;
   import mmo.interfaces.pet.fight.PetFightEvent;
   import mmo.petfightnew.common.FightPanel;
   import mmo.petfightnew.common.manager.ServicePool;
   import mmo.play.activity.helper.Panel_Helper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol125")]
   public class PetFightSpaceLiveUI extends Sprite
   {
      
      public var btnClose:SimpleButton;
      
      public var mcPetBar:MovieClip;
      
      public var txtTurn:TextField;
      
      private var _liveSvr:ILiveService = ServicePool.instance.getService(ILiveService);
      
      private var _curTurn:int = 0;
      
      private var _fightPanel:FightPanel = null;
      
      private var _petBar:PetFightSpacePetBar;
      
      public function PetFightSpaceLiveUI()
      {
         super();
      }
      
      public function init(param1:FightPanel) : void
      {
         this._fightPanel = param1;
         this._petBar = new PetFightSpacePetBar(this.getChildByName("mcPetBar") as MovieClip);
         this.addListener();
         this.refresh();
      }
      
      private function addListener() : void
      {
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         CommonEventDispatcher.instance.addEventListener(PetFightEvent.SWITCH_PM,this.onSwitchPM);
         var _loc1_:SimpleButton = this.btnClose;
         _loc1_.addEventListener(MouseEvent.CLICK,this.onClickClose);
      }
      
      private function onNextTurn(param1:PetFightEvent) : void
      {
         ++this._curTurn;
         this.refresh();
      }
      
      private function onSwitchPM(param1:PetFightEvent) : void
      {
         this.refresh();
      }
      
      private function refresh() : void
      {
         Panel_Helper.setTextValue(this,"txtTurn",this._curTurn + "");
         this._petBar.update();
      }
      
      private function onClickClose(param1:MouseEvent) : void
      {
         var e:MouseEvent = param1;
         NewDialog.showConfirmDialog("是否退出战斗返回个人房间？",function():void
         {
            _fightPanel.close();
         });
      }
      
      public function dispose() : void
      {
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.NEXT_TURN,this.onNextTurn);
         CommonEventDispatcher.instance.removeEventListener(PetFightEvent.SWITCH_PM,this.onSwitchPM);
         this._petBar.dispose();
         this._petBar = null;
         this._fightPanel = null;
      }
   }
}

