package mmo.petfightnew.common.panel
{
   import flash.display.DisplayObject;
   import flash.display.SimpleButton;
   import flash.display.Sprite;
   import flash.events.MouseEvent;
   import mmo.common.dialog.NewDialog;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.framework.comm.PetFightClient;
   import mmo.framework.comm.SocketClient;
   import mmo.framework.comm.SocketClientEvent;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetDataService;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.fight.IPetFight;
   import mmo.play.activity.helper.Panel_Helper;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3917")]
   public class ChallengeChoosePanel extends Sprite
   {
      
      public var btnClose:SimpleButton;
      
      public var btnM:SimpleButton;
      
      public var btnS:SimpleButton;
      
      public var btnYiJieShuangChong:SimpleButton;
      
      private var btn:SimpleButton;
      
      private var isMultiple:Boolean;
      
      private var userName:String;
      
      private var petFightService:IPetFight;
      
      private var _waitPanel:WaitPanel;
      
      public function ChallengeChoosePanel(param1:String)
      {
         super();
         this.userName = param1;
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         this.initMe();
      }
      
      private function initMe() : void
      {
         var _loc4_:int = 0;
         var _loc5_:PetBriefInfo = null;
         var _loc1_:IPetDataService = ServiceContainer.getService(IPetDataService) as IPetDataService;
         var _loc2_:Array = _loc1_.getMyPets();
         var _loc3_:String = "";
         if(_loc2_.length < 4)
         {
            _loc3_ = "开启挑战背包至少需要4只使用新技能的亚比。";
         }
         else
         {
            _loc3_ = "";
            _loc4_ = 0;
            while(_loc4_ < _loc2_.length)
            {
               _loc5_ = _loc2_[_loc4_];
               if(!_loc5_.isUsingGQNewSkill())
               {
                  _loc3_ = "背包有非新技能组的亚比";
                  break;
               }
               _loc4_++;
            }
         }
         ActComHelper.refreshObj(this,"btnYiJieShuangChong",_loc3_ != "",_loc3_,"异界双宠大师战（6选4）");
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         if(Boolean(param1.target.hasOwnProperty("enabled")) && !param1.target.enabled)
         {
            return;
         }
         switch(DisplayObject(param1.target).name)
         {
            case "btnClose":
               this.close();
               break;
            case "btnS":
               this.isMultiple = false;
               PetFightClient.instance.challenge(this.userName,this.isMultiple);
               this.close();
               this.showWaitPanel();
               break;
            case "btnM":
               this.isMultiple = true;
               PetFightClient.instance.challenge(this.userName,this.isMultiple);
               this.close();
               this.showWaitPanel();
               break;
            case "btnLingYu":
               this.close();
               this.showWaitPanel();
               PetFightClient.instance.challenge(this.userName,this.isMultiple,1);
               break;
            case "btnYiJieShuangChong":
               this.onYiJieShuangChongChallenge();
         }
      }
      
      private function onYiJieShuangChongChallenge() : void
      {
         this.close();
         this.showWaitPanel();
         SocketClient.instance.addEventListener("53_1",this.afterChallengeCmdReturn);
         SocketClient.instance.removeEventListener("53_2a",this.afterOtherAccpetPush);
         SocketClient.instance.addEventListener("53_2a",this.afterOtherAccpetPush);
         PetFightClient.instance.challenge(this.userName,true,2);
      }
      
      private function afterChallengeCmdReturn(param1:SocketClientEvent) : void
      {
         var _loc3_:* = null;
         SocketClient.instance.removeEventListener("53_1",this.afterChallengeCmdReturn);
         var _loc2_:int = int(param1.params["r"]);
         if(_loc2_ != 1)
         {
            _loc3_ = _loc2_ + "";
            if(_loc2_ == -1)
            {
               _loc3_ = "已方有不是新技能组亚比";
            }
            else if(_loc2_ == -2)
            {
               _loc3_ = "对方当前背包存在不是新技能组的亚比";
            }
            NewDialog.showMessagePl(_loc3_);
         }
      }
      
      private function afterOtherAccpetPush(param1:SocketClientEvent) : void
      {
         SocketClient.instance.removeEventListener("53_2a",this.afterOtherAccpetPush);
         var _loc2_:Object = param1.params;
         var _loc3_:int = int(_loc2_["res"]);
         NewDialog.getCustomDialog(this._waitPanel).close();
         if(_loc3_ == 1)
         {
            ModalDialogManager.getInstance().clearAll();
            Panel_Helper.loadResAndShow("activityres/activity240208/yijieshuangchongduizhan/yijieshuangchongduizhan_code","mmo.activity240208.yijieshuangchongduizhan.panel.YJSCDZ_MainPl",_loc2_);
         }
         else
         {
            NewDialog.showFailMessage("异次元双宠挑战失败:" + _loc3_);
         }
      }
      
      private function close() : void
      {
         ModalDialogManager.getInstance().removeModalDialog(this);
         this._waitPanel = null;
      }
      
      private function afterCloseWaitPl() : void
      {
         SocketClient.instance.removeEventListener("53_1",this.afterChallengeCmdReturn);
      }
      
      private function showWaitPanel() : void
      {
         this._waitPanel = new WaitPanel(this.userName,this.afterCloseWaitPl);
         NewDialog.getCustomDialog(this._waitPanel).show();
      }
   }
}

