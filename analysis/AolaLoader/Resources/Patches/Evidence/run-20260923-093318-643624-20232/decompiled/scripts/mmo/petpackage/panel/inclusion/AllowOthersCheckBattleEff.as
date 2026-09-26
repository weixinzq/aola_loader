package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.ProgressFullSprite;
   import mmo.common.utils.tips.TipsManager;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol341")]
   public class AllowOthersCheckBattleEff extends Sprite
   {
      
      public var allowmc:MovieClip;
      
      private var petDataService:IPetDataService;
      
      private var allowMc:MovieClip;
      
      private var isAllow:Boolean;
      
      private var isProcessing:Boolean = false;
      
      private var extensionName:String = "PetExtension2";
      
      private var cmdSetAllowOthersCheckBattleEff:String = "54e_36";
      
      public function AllowOthersCheckBattleEff()
      {
         super();
      }
      
      public function init() : void
      {
         this.allowMc = this.getChildByName("allowmc") as MovieClip;
         this.petDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         this.allowMc.buttonMode = true;
         this.allowMc.addEventListener(MouseEvent.CLICK,this.onClickAllowMc);
         this.isAllow = this.petDataService.getAllowOthersCheckBattleEff();
         this.updateAllowMc();
      }
      
      private function onClickAllowMc(param1:MouseEvent) : void
      {
         if(this.isProcessing)
         {
            return;
         }
         this.isProcessing = true;
         ProgressFullSprite.show();
         SocketClient.instance.addEventListener(this.cmdSetAllowOthersCheckBattleEff,this.onSetReturn);
         SocketClient.instance.sendXtMessage(this.extensionName,this.cmdSetAllowOthersCheckBattleEff,{"access":!this.isAllow});
      }
      
      private function onSetReturn(param1:SocketClientEvent) : void
      {
         ProgressFullSprite.close();
         SocketClient.instance.removeEventListener(this.cmdSetAllowOthersCheckBattleEff,this.onSetReturn);
         this.isProcessing = false;
         this.isAllow = param1.params.access;
         this.petDataService.setAllowOthersCheckBattleEff(this.isAllow);
         this.updateAllowMc();
      }
      
      private function updateAllowMc() : void
      {
         var _loc1_:int = this.isAllow ? 2 : 1;
         this.allowMc.gotoAndStop(_loc1_);
         if(this.isAllow)
         {
            TipsManager.getInstance().replaceTips(this.allowMc,"点击禁止其他玩家查看背包");
         }
         else
         {
            TipsManager.getInstance().replaceTips(this.allowMc,"点击允许其他玩家查看背包");
         }
      }
      
      public function dispose() : void
      {
         this.allowMc.removeEventListener(MouseEvent.CLICK,this.onClickAllowMc);
         SocketClient.instance.removeEventListener(this.cmdSetAllowOthersCheckBattleEff,this.onSetReturn);
      }
   }
}

