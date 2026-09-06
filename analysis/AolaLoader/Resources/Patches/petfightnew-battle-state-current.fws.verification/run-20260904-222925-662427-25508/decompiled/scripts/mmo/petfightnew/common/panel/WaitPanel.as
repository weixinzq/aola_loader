package mmo.petfightnew.common.panel
{
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.text.TextField;
   import flash.utils.Timer;
   import mmo.common.ModalDialog;
   import mmo.common.dialog.NewDialog;
   import mmo.common.user.UserInfo;
   import mmo.framework.comm.PetClient;
   import mmo.framework.comm.PetFightClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.user.IUserNameManager;
   import mmo.interfaces.user.UserNameEvent;
   import mmo.play.actthings.helper.ActLifeObj;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2529")]
   public class WaitPanel extends Sprite
   {
      
      private static const WAITE_TIME:int = 30;
      
      public var btnClose:SimpleButton;
      
      public var txtMyName:TextField;
      
      public var txtVsName:TextField;
      
      private var nameService:IUserNameManager;
      
      private var defender:String;
      
      private var timer:Timer;
      
      private var _closeCallback:Function;
      
      public function WaitPanel(param1:String, param2:Function = null)
      {
         super();
         this.defender = param1;
         this._closeCallback = param2;
         this.nameService = ServiceContainer.instance.getService("UserNameManager") as IUserNameManager;
         var _loc3_:String = this.nameService.getNickName(UserInfo.userName);
         TextField(this.txtMyName).text = _loc3_;
         this.nameService.addEventListener(UserNameEvent.getNicknameByName,this.onGetNickName);
         this.nameService.getNicknameByName(param1);
         SimpleButton(this.btnClose).addEventListener(MouseEvent.CLICK,this.onClose);
         SocketClient.instance.addEventListener(PetFightClient.cmdRefuse,this.onRefuse);
         SocketClient.instance.addEventListener(PetClient.RSPN_START_BATTLE,this.onStart);
         SocketClient.instance.addEventListener(PetFightClient.cmdChallenge_LingYu,this.needClose);
         this.timer = new Timer(1000,WAITE_TIME);
         this.timer.addEventListener(TimerEvent.TIMER_COMPLETE,this.onTimesup);
         this.timer.start();
         ActLifeObj.bind(this,this.closeAndDispose);
      }
      
      private function onTimesup(param1:TimerEvent) : void
      {
         this.timer.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onTimesup);
         this.timer.stop();
         this.timer = null;
         NewDialog.showFailMessage("你已经等待了30秒，可能该小奥拉正在忙其他的事情，请稍候再挑战他吧！");
      }
      
      private function onGetNickName(param1:UserNameEvent) : void
      {
         this.nameService.removeEventListener(UserNameEvent.getNicknameByName,this.onGetNickName);
         var _loc2_:String = this.nameService.getNickName(this.defender);
         TextField(this.txtVsName).text = _loc2_;
      }
      
      private function onStart(param1:SocketClientEvent) : void
      {
         this.closeAndDispose();
      }
      
      private function onClose(param1:MouseEvent) : void
      {
         SocketClient.instance.removeEventListener(PetFightClient.cmdRefuse,this.onRefuse);
         PetFightClient.instance.cancel();
         this.closeAndDispose();
      }
      
      private function onRefuse(param1:SocketClientEvent) : void
      {
         this.closeAndDispose();
         NewDialog.showFailMessage("对方拒绝了你的对战请求！");
      }
      
      private function needClose(param1:SocketClientEvent) : void
      {
         if(param1.params.r != 1)
         {
            this.closeAndDispose();
         }
      }
      
      private function closeAndDispose() : void
      {
         if(this.timer != null)
         {
            this.timer.removeEventListener(TimerEvent.TIMER_COMPLETE,this.onTimesup);
            this.timer.stop();
            this.timer = null;
         }
         SocketClient.instance.removeEventListener(PetClient.RSPN_START_BATTLE,this.onStart);
         SocketClient.instance.removeEventListener(PetFightClient.cmdRefuse,this.onRefuse);
         SocketClient.instance.removeEventListener(PetFightClient.cmdChallenge_LingYu,this.needClose);
         ModalDialog.closeDialog(this);
         if(this._closeCallback != null)
         {
            this._closeCallback();
            this._closeCallback = null;
         }
      }
   }
}

